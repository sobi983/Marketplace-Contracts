require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();
require("@nomiclabs/hardhat-etherscan");
require("hardhat-gas-reporter");
require("solidity-coverage");



module.exports = {
solidity: {
  compilers: [
      {
          version: "0.8.1",
          settings: {
              optimizer: {
                  enabled: true,
                  runs: 100
              }
          }
      },
      {
          version: "0.6.0",
          settings: {
              optimizer: {
                  enabled: true,
                  runs: 100
              }
          }
      },
      {
          version: "0.6.2",
          settings: {
              optimizer: {
                  enabled: true,
                  runs: 100
              }
          }
      },
      {
          version: "0.6.6",
          settings: {
              optimizer: {
                  enabled: true,
                  runs: 100
              }
          }
      },
  ],
},
defaultNetwork: "hardhat",
  networks: {
    hardhat: {
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [`${process.env.RINKEBY_PRIVATE_KEY}`]
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.MAINNET_API_KEY}`,
      accounts: [`${process.env.RINKEBY_PRIVATE_KEY}`]
    }
  },
  gasReporter: {
    enabled: false,
    currency: "USD",
    coinmarketcap: process.env.Coinmarketcap
  },
  etherscan : {
    apiKey : {
      rinkeby : process.env.EtherScanAPI,
      mainnet : process.env.EtherScanAPI
    } 
  }
}

















  



