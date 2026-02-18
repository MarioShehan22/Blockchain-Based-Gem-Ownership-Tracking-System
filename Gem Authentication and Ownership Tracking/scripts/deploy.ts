import * as hre from "hardhat";
import { formatEther } from "ethers";

async function main(): Promise<void> {
    const { ethers, network } = hre;

    const [deployer] = await ethers.getSigners();

    // Automatically fund deployer if using a forked network
    if (network.name.includes("fork") || network.name === "localhost") {
        console.log(`💰 Fork detected (${network.name}). Setting deployer balance...`);
        const balanceHex = "0x10000000000000000000000"; // 10,000 ETH

        await hre.network.provider.send("hardhat_setBalance", [
            deployer.address,
            balanceHex,
        ]);
    }

    const balance = await ethers.provider.getBalance(deployer.address);

    console.log("Network:", network.name);
    console.log("Deployer:", deployer.address);
    console.log("Balance:", formatEther(balance), "ETH");

    console.log("🚀 Starting contract deployment...");

    // 1. Deploy AccessControl
    const AccessControl = await ethers.getContractFactory("AccessControl");
    const accessControl = await AccessControl.deploy();
    await accessControl.waitForDeployment();
    const accessControlAddr = await accessControl.getAddress();
    console.log("✔ AccessControl deployed at:", accessControlAddr);

    // 2. Deploy GemRegistry
    const GemRegistry = await ethers.getContractFactory("GemRegistry");
    const gemRegistry = await GemRegistry.deploy();
    await gemRegistry.waitForDeployment();
    const gemRegistryAddr = await gemRegistry.getAddress();
    console.log("✔ GemRegistry deployed at:", gemRegistryAddr);

    // 3. Deploy OwnershipTransfer
    const OwnershipTransfer = await ethers.getContractFactory("OwnershipTransfer");
    const ownershipTransfer = await OwnershipTransfer.deploy();
    await ownershipTransfer.waitForDeployment();
    const ownershipTransferAddr = await ownershipTransfer.getAddress();
    console.log("✔ OwnershipTransfer deployed at:", ownershipTransferAddr);

    console.log("\n📌 Deployment Summary:");
    console.log("------------------------------");
    console.log("AccessControl:     ", accessControlAddr);
    console.log("GemRegistry:       ", gemRegistryAddr);
    console.log("OwnershipTransfer: ", ownershipTransferAddr);
    console.log("------------------------------");
}

main().catch((error) => {
    console.error("❌ Deployment Error:", error);
    process.exitCode = 1;
});