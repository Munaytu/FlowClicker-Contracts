import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";

const SONIC_PRIVATE_KEY = process.env.SONIC_PRIVATE_KEY || "0xkey";

const config: HardhatUserConfig = {
  solidity: "0.8.26",
  networks: {
    sonic: {
      url: "https://rpc.soniclabs.com",
      chainId: 146,
      accounts: [SONIC_PRIVATE_KEY],
    },
    sonicTestnet: {
      url: "https://rpc.testnet.soniclabs.com",
      chainId: 14601,
      accounts: [SONIC_PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: {
      sonic: process.env.SONICSCAN_API_KEY,
      sonicTestnet: process.env.SONICSCAN_API_KEY,
    },
    customChains: [
      {
        network: "sonic",
        chainId: 146,
        urls: {
          apiURL: "https://api.sonicscan.org/api",
          browserURL: "https://sonicscan.org",
        },
      },
      {
        network: "sonicTestnet",
        chainId: 14601,
        urls: {
          apiURL: "https://api-testnet.sonicscan.org/api",
          browserURL: "https://testnet.sonicscan.org",
        },
      },
    ],
  },
};

export default config;
