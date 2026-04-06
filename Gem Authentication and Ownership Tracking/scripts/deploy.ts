import { ethers } from "hardhat";

async function main(): Promise<void> {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with:", deployer.address);

  const GemChain = await ethers.getContractFactory("GemChain");
  const gemChain = await GemChain.deploy();
  await gemChain.waitForDeployment();

  console.log("GemChain deployed at:", await gemChain.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
