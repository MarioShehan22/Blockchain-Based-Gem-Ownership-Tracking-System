import { ethers } from "hardhat";

async function main() {

  const [deployer] = await ethers.getSigners();

  console.log(
      "Deploying contracts with:",
      deployer.address
  );

  /*
   * 1️⃣ Deploy AccessControl
   */
  const AccessControl =
      await ethers.getContractFactory(
          "AccessControl"
      );

  const accessControl =
      await AccessControl.deploy();

  await accessControl.waitForDeployment();

  const accessControlAddress =
      await accessControl.getAddress();

  console.log(
      "AccessControl:",
      accessControlAddress
  );

  /*
   * 2️⃣ Deploy GemRegistry
   */
  const GemRegistry =
      await ethers.getContractFactory(
          "GemRegistry"
      );

  const gemRegistry =
      await GemRegistry.deploy();

  await gemRegistry.waitForDeployment();

  const gemRegistryAddress =
      await gemRegistry.getAddress();

  console.log(
      "GemRegistry:",
      gemRegistryAddress
  );

  /*
   * 3️⃣ Deploy OwnershipTransfer
   */
  const OwnershipTransfer =
      await ethers.getContractFactory(
          "OwnershipTransfer"
      );

  const ownershipTransfer =
      await OwnershipTransfer.deploy();

  await ownershipTransfer.waitForDeployment();

  const ownershipTransferAddress =
      await ownershipTransfer.getAddress();

  console.log(
      "OwnershipTransfer:",
      ownershipTransferAddress
  );

  /*
   * 4️⃣ Deploy GemChain
   */
  const GemChain =
      await ethers.getContractFactory(
          "GemChain"
      );

  const gemChain =
      await GemChain.deploy();

  await gemChain.waitForDeployment();

  const gemChainAddress =
      await gemChain.getAddress();

  console.log(
      "GemChain:",
      gemChainAddress
  );

  await gemChain.registerOwner(
      deployer.address
  );

  console.log(
      "Owner Registered:",
      deployer.address
  );
  console.log("\n✅ ALL CONTRACTS DEPLOYED");

  const accounts =
      await ethers.getSigners();

  /*
   * Register deployer
   */
  await gemChain.registerOwner(
      accounts[0].address
  );

  /*
   * Register buyer
   */
  await gemChain.registerOwner(
      accounts[1].address
  );

  console.log(
      "Owners Registered"
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});