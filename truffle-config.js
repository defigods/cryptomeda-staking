require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  networks: {
    development: {
      host: '127.0.0.1',
      port: 8545,
      network_id: '*',
    },
    rinkeby: {
      provider: () =>
        new HDWalletProvider(
          process.env.mnemonic,
          `https://rinkeby.infura.io/v3/${process.env.infuraKey}`,
        ),
      network_id: 4,
      skipDryRun: true,
      networkCheckTimeout: 20000,
    },
    mainnet: {
      provider: () =>
        new HDWalletProvider(
          process.env.mnemonic,
          `wss://mainnet.infura.io/v3/${process.env.infuraKey}`,
        ),
      network_id: 1,
      networkCheckTimeout: 20000,
      gas: 3183641,
      gasPrice: 60,
    },
  },
  plugins: ['truffle-plugin-verify'],
  api_keys: { etherscan: process.env.etherscan },
  compilers: {
    solc: {
      version: '^0.8.0',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
    },
  },
};
