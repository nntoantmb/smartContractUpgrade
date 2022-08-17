import { HardhatUserConfig } from "hardhat/config";
import "@openzeppelin/hardhat-upgrades";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";

import dotenv from "dotenv";
dotenv.config()

function getEnv(val: string): string {
  if (val in process.env) {
    return (process.env as any)[val];
  }

  throw `Missing env ${val}`;
}

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
    },
    ropsten: {
      url: getEnv('ROPSTEN_ETH_URL'),
      accounts: [getEnv('ROPSTEN_PRIVATE_KEY')],
      gas: parseInt(getEnv('ROPSTEN_GAS_LIMIT')),
      gasPrice: parseInt(getEnv('ROPSTEN_GAS_PRICE')),
    },
    mainnet: {
      url: getEnv('MAINNET_ETH_URL'),
      accounts: [getEnv('MAINNET_PRIVATE_KEY')],
      gas: parseInt(getEnv('MAINNET_GAS_LIMIT')),
      gasPrice: parseInt(getEnv('MAINNET_GAS_PRICE')),
    },
    bsctest: {
      url: getEnv('BSCTESTNET_URL'),
      accounts: [getEnv('BSCTESTNET_PRIVATE_KEY')],
      gas: parseInt(getEnv('BSCTESTNET_GAS_LIMIT')),
      gasPrice: parseInt(getEnv('BSCTESTNET_GAS_PRICE')),
      chainId: parseInt(getEnv('BSCTESTNET_CHAINID'))
    },
    bsc: {
      url: getEnv('BSCMAINET_URL'),
      accounts: [getEnv('BSCMAINET_PRIVATE_KEY')],
      gas: parseInt(getEnv('BSCMAINET_GAS_LIMIT')),
      gasPrice: parseInt(getEnv('BSCMAINET_GAS_PRICE')),
      chainId: parseInt(getEnv('BSCMAINET_CHAINID'))
    }
  },


  solidity: {
    compilers: [
      {
        version: "0.8.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.2",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ],

  },
  gasReporter: {
    enabled: true,
    currency: "ETH",
    gasPrice: 100
  },

  etherscan: {
    apiKey: {
      ropsten: 'JKXR76EA1NK9XSKES1T2BNYBZ41T3BJ2JH',
      rinkeby: 'JKXR76EA1NK9XSKES1T2BNYBZ41T3BJ2JH'
    }
  }
}

export default config