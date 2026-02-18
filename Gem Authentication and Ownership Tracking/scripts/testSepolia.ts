import { ethers } from "hardhat";
import { formatEther } from "ethers";

async function main() {
    const [deployer] = await ethers.getSigners();
    const balance = await ethers.provider.getBalance(deployer.address);

    console.log("Address:", deployer.address);
    console.log("Balance:", formatEther(balance), "ETH");
}

main().catch((e) => {
    console.error(e);
    process.exitCode = 1;
});