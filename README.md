<p align="center">
  <img src="client/src/assets/images/doxa.png" alt="DOXA" width="300" />
</p>

<h2 align="center">Loseless Ethereum Savings</h2>

<br/>

[![#built_with_Truffle](https://img.shields.io/badge/built%20with-Truffle-blueviolet?style=flat-square)](https://www.trufflesuite.com/)
[![built-with openzeppelin](https://img.shields.io/badge/built%20with-OpenZeppelin-3677FF?style=flat-square)](https://docs.openzeppelin.com/)
![#solc 0.6.6](https://img.shields.io/badge/solc-0.6.6-brown?style=flat-square)
![#testnet rinkeby](https://img.shields.io/badge/testnet-Rinkeby-yellow?style=flat-square)

## Installation

Make sure you have [node](https://nodejs.org/en/) installed on your machine

## Inside the root folder

- Run `npm install`
- Then, `truffle compile` to compile
- Finally, `truffle develop` to spawn a development blockchain and `truffle migrate --reset` to migrate contracts
- With Ropsten, run `truffle deploy --network ropsten`

### truffle-config.js

```javascript
module.exports = {
  ...
  networks: {
    develop: {
      ...
      port: 8545,
      ...
    },
  },
};
```

## Issues

## License
