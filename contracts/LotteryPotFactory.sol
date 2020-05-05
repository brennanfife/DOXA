pragma solidity 0.6.6;

// PRAGMA6
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
// import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

import "./LotteryPot.sol";


contract LotteryPotFactory is Ownable, Pausable {
    mapping(address => bool) mappingOfLotteryPots;
    address[] public lotteryPots;
    address public daiAddress;
    address public cdaiAddress;

    event LotteryPotCreated(address contractAddress);

    modifier createdByThisFactory(address potAddr) {
        require(
            mappingOfLotteryPots[potAddr],
            "Must be created by this factory"
        );
        _;
    }

    constructor(address _daiAddress, address _cdaiAddress) public {
        daiAddress = _daiAddress;
        cdaiAddress = _cdaiAddress;
    }

    function createLotteryPot()
        public
        payable
        whenNotPaused
        returns (LotteryPot)
    {
        LotteryPot newContract = new LotteryPot({
            _owner: msg.sender,
            _daiAddress: daiAddress,
            _cdaiAddress: cdaiAddress
        });

        address newAddress = address(newContract);

        lotteryPots.push(newAddress);
        mappingOfLotteryPots[newAddress] = true;
        emit LotteryPotCreated(address(newAddress));
        return newContract;
    }

    function getLotteryPots() public view returns (address[] memory) {
        return lotteryPots;
    }

    // need to make sure this is safe
    function destroy() public onlyOwner whenPaused {
        selfdestruct(msg.sender);
    }

    function disableLotteryPot(address payable potAddress)
        public
        onlyOwner
        createdByThisFactory(potAddress)
        returns (bool)
    {
        return LotteryPot(potAddress).disableContract();
    }
}
