pragma solidity 0.6.6;

// uniswap router address = 0xcDbE04934d89e97a24BCc07c3562DC8CF17d8167;
// daiAddress = 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa;
// cdaiAddress = 0x6D7F0754FFeb405d23C51CE938289d4835bE3b14;

// import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
// import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
// import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
// import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol";
// import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Pausable.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";


interface ICERC20 {
    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function getCash() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address account) external returns (uint256);
}


/**
 * @title The Lottery contract
 * @author Brennan Fife
 * @notice This contract will allow users to enter a new lottery.
 * Open - A period where users can join the lottery
 * Committing - A period where savings will accrue interest
 * Rewarding - The final stage in which a user is selected
 */
contract LotteryPot is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 public underlying;
    ICERC20 public cToken;
    uint256 public creationTime;
    uint256 public potsDaiBalance;
    address public winningAddress;
    uint256 public winningsAmount;
    address[] public entrants;
    mapping(address => uint256) private entrantBalance;
    mapping(address => uint256) private entryList;
    enum States {OPEN, COMMITTING, REWARDING}
    States public state;
    bool hasNotBeenRewarded;

    // EVENTS
    event EntrantEntered(address indexed sender);
    event EntrantWithdrawn(address indexed sender, uint256 amount);
    event StateChange(States state);
    event WinnerSelected(address indexed winner);
    event LogValue(string, uint256);
    event ReceiveFallback(address);
    event WinnerWinnings(uint256);

    // MODIFIERS
    modifier checkState(States currentState) {
        require(
            state == currentState,
            "function cannot be called at this time"
        );
        _;
    }

    // modifier checkIfWinnerDeclared() {
    //     require(
    //         entrants.length >= 2,
    //         "There must be at least 2 players in the current lottery"
    //     );
    //     _;
    // }

    modifier requiredTimePassed {
        require((now - creationTime) > 4 weeks, "4 weeks must have passed"); //block.timestamp
        _;
    }

    modifier minAmount {
        require(
            msg.value >= 100 finney,
            "Must submit at least 100 finney worth of Eth"
        );
        _;
    }

    modifier canWithdraw {
        require(
            entrantBalance[msg.sender] > 0,
            "Entrant has nothing to withdraw"
        );
        _;
    }

    modifier winnerNotDeclared() {
        require(hasNotBeenRewarded, "Winner has been declared");
        _;
    }

    constructor(address _owner, address _daiAddress, address _cdaiAddress)
        public
        payable
    {
        state = States.OPEN;
        creationTime = 0;
        winningsAmount = 0;
        if (_owner != msg.sender) {
            transferOwnership(_owner);
        }
        underlying = IERC20(_daiAddress);
        cToken = ICERC20(_cdaiAddress);
        hasNotBeenRewarded = true;
    }

    // function deposit(uint256 daiAmount, address daiAddress, address cdaiAddress)
    function deposit(uint256 daiAmount)
        public
        checkState(States.OPEN)
        whenNotPaused
        nonReentrant
    {
        underlying = IERC20(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa);
        cToken = ICERC20(0x6D7F0754FFeb405d23C51CE938289d4835bE3b14);
        // underlying = IERC20(daiAddress);
        // cToken = ICERC20(cdaiAddress);
        require(
            underlying.balanceOf(msg.sender) >= daiAmount,
            "Requested Dai deposit is greater than current balance"
        );
        require(daiAmount >= 10000000000000000000, "Must save at least 10 Dai");
        require(
            underlying.transferFrom(msg.sender, address(this), daiAmount),
            "Transfer DAI failed"
        );
        if (entrantBalance[msg.sender] == 0) entrants.push(msg.sender);
        entryList[msg.sender] = entrants.length.add(1);
        emit EntrantEntered(msg.sender);
        entrantBalance[msg.sender] = entrantBalance[msg.sender].add(daiAmount);

        //potsDaiBalance = potsDaiBalance.add(daiAmount);
        mint(
            daiAmount,
            0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa,
            0x6D7F0754FFeb405d23C51CE938289d4835bE3b14
        );
    }

    // nonReentrant canWithdraw
    // function withdraw(uint256 amount) public {
    //     cToken = ICERC20(0x6D7F0754FFeb405d23C51CE938289d4835bE3b14);
    //     // require(
    //     //     state != States.COMMITTING,
    //     //     "Cannot withdraw during committing period"
    //     // );
    //     uint256 balance = entrantBalance[msg.sender];
    //     //require(balance >= amount, "Taking out too much");
    //     entrantBalance[msg.sender] = balance.sub(amount);
    //     potsDaiBalance = potsDaiBalance.sub(amount);
    //     //cToken.redeemUnderlying(amount) == 0;
    //     msg.sender.transfer(amount);
    //     emit EntrantWithdrawn(msg.sender, amount);
    // }

    function withdraw(uint256 amount) public {
        _withdraw(msg.sender, amount);
    }

    function _withdraw(address sender, uint256 amount) private {
        underlying = IERC20(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa);
        cToken = ICERC20(0x6D7F0754FFeb405d23C51CE938289d4835bE3b14);
        uint256 balance = entrantBalance[msg.sender];
        require(balance >= amount, "Taking out too much");
        entrantBalance[sender] = balance.sub(amount);
        potsDaiBalance = potsDaiBalance.sub(amount);

        require(cToken.redeemUnderlying(amount) == 0, "Redeem");
        require(underlying.transfer(sender, amount), "Transfer");
    }

    //nonReentrant
    function mint(
        uint256 _numberOfDaiToSupply,
        address daiAddress,
        address cDaiAddress
    ) private {
        underlying = IERC20(daiAddress);
        cToken = ICERC20(cDaiAddress);
        require(
            underlying.approve(address(cToken), _numberOfDaiToSupply),
            "Failed to approve sending token"
        );
        require(
            cToken.mint(_numberOfDaiToSupply) == 0,
            "Failed to mint cToken"
        );

        potsDaiBalance = potsDaiBalance.add(_numberOfDaiToSupply);
    }

    function lockLottery() public whenNotPaused onlyOwner {
        require((now - creationTime) > 2 weeks, "Two weeks must have passed"); //block.timestamp
        incrementState();
    }

    function incrementState() public whenNotPaused onlyOwner {
        require(uint256(state) < 2, "state cannot be incremented");
        state = States(uint256(state) + 1);
        emit StateChange(state);
    }

    function selectWinnerAndReward()
        public
        checkState(States.COMMITTING)
        onlyOwner
        winnerNotDeclared
    {
        selectWinner();
        reward();
        // incrementState();
        hasNotBeenRewarded = false;
    }

    function selectWinner() public onlyOwner returns (address) {
        uint256 reducer = getRandomNumber(potsDaiBalance);
        uint256 i = 0;
        while (reducer > entrantBalance[entrants[i]]) {
            reducer = reducer.sub(entrantBalance[entrants[i]]);
            i += 1;
        }
        // require(entrants[i] != address(0));
        winningAddress = entrants[i];
        emit WinnerSelected(winningAddress);
        return winningAddress;
    }

    // checkState(States.REWARDING)
    function reward() private whenNotPaused returns (uint256) {
        uint256 underlyingBalance = cToken.balanceOfUnderlying(address(this)); //dai held in compound

        if (underlyingBalance > potsDaiBalance) {
            winningsAmount = underlyingBalance.sub(potsDaiBalance);
        }
        if (winningAddress != address(0) && winningsAmount != 0) {
            potsDaiBalance = underlyingBalance;
            entrantBalance[winningAddress] = entrantBalance[winningAddress].add(
                winningsAmount
            );
            emit WinnerWinnings(winningsAmount);
        }
    }

    function getRandomNumber(uint256 entropy) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.number,
                        block.difficulty
                    )
                )
            )
                .mod(entropy);
    }

    function redeemDaiFromCompound() public onlyOwner returns (uint256) {
        uint256 targetRedeemTargetTokenAmount = cToken.balanceOf(address(this));
        uint256 redeemResult = cToken.redeem(targetRedeemTargetTokenAmount);
        emit LogValue("redeem result", redeemResult);
        return redeemResult;
    }

    function removeEntrant() private {
        entrants[entryList[msg.sender]] = entrants[entrants.length - 1];
        entryList[msg.sender] = 0;
        if (entrants.length > 1) entrants.pop();
        else entrants[0] = owner();
    }

    function getLotterySize() public view returns (uint256) {
        return entrants.length;
    }

    function accountBalance(address entrantAddress)
        public
        view
        returns (uint256)
    {
        return (entrantBalance[entrantAddress]);
    }

    function disableContract() public onlyOwner returns (bool) {
        _pause();
    }

    receive() external payable {}

    fallback() external payable {
        emit ReceiveFallback(address(msg.sender));
    }
}
