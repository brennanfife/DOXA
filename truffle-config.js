const path = require("path");
require("dotenv").config();
let HDWalletProvider = require("@truffle/hdwallet-provider");
const INFURA_ID = process.env.INFURA_KEY;
const MNEMONIC = process.env.MNEMONIC;

module.exports = {
  contracts_build_directory: path.join(__dirname, "client/src/contracts"),
  networks: {
    develop: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
    },
    rinkeby: {
      provider: function () {
        return new HDWalletProvider(
          MNEMONIC,
          `https://rinkeby.infura.io/v3/${INFURA_ID}`
        );
      },
      network_id: 4,
      gas: 10000000,
    },
    kovan: {
      provider: function () {
        return new HDWalletProvider(
          MNEMONIC,
          `https://kovan.infura.io/v3/${INFURA_ID}`
        );
      },
      network_id: 42,
    },
  },
  compilers: {
    solc: {
      version: "0.6.6",
    },
  },
};
