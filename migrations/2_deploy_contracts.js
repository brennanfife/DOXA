const LotteryPotFactory = artifacts.require("LotteryPotFactory");

module.exports = function (deployer) {
  deployer.deploy(
    LotteryPotFactory,
    "0x1d9999be880e7e516deefda00a3919bdde9c1707",
    "0xe7bc397dbd069fc7d0109c0636d06888bb50668c"
  );
};
