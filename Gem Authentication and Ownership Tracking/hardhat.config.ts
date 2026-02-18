import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.28",
  networks: {
    tenderlyFork: {
      url: "https://virtual.mainnet.eu.rpc.tenderly.co/d40e9a0b-bfe1-4b38-ab93-c0c7f2dc4a41",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 1, // matches Mainnet
    },
    localhost: {},
  },
};


export default config;
