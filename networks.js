require('dotenv').config();

const HDWalletProvider = require('truffle-hdwallet-provider');

module.exports = {
  networks: {
    development: {
      protocol: 'http',
      host: 'localhost',
      port: 8545,
      gas: 5000000,
      gasPrice: 5e9,
      networkId: '*',
    },
    ropsten: {
       provider: () => new HDWalletProvider(process.env.DEV_MNEMONIC, "http://localhost:8545"),
       networkId: 3,
    }
  },
};
