import { expect } from "chai";
import { ethers } from "hardhat";

describe("Gem Authentication + Ownership Tracking", function () {
    async function deployFixture() {
        const [admin, officer, owner1, owner2, stranger] = await ethers.getSigners();

        // Deploy OwnershipTransfer (inherits GemRegistry -> AccessControl)
        const OwnershipTransfer = await ethers.getContractFactory("OwnershipTransfer");
        const ot = await OwnershipTransfer.deploy();
        await ot.waitForDeployment();

        return { ot, admin, officer, owner1, owner2, stranger };
    }

    it("sets deployer as admin", async () => {
        const { ot, admin } = await deployFixture();
        expect(await ot.admin()).to.equal(admin.address);
    });

    it("only admin can add gov officer + register owners", async () => {
        const { ot, admin, officer, owner1, stranger } = await deployFixture();

        await expect(ot.connect(stranger).addGovOfficer(officer.address))
            .to.be.revertedWith("Only Admin Allowed");

        await expect(ot.connect(stranger).registerOwner(owner1.address))
            .to.be.revertedWith("Only Admin Allowed");

        await ot.connect(admin).addGovOfficer(officer.address);
        expect(await ot.isGovOfficer(officer.address)).to.equal(true);

        await ot.connect(admin).registerOwner(owner1.address);
        expect(await ot.isOwner(owner1.address)).to.equal(true);
    });

    it("registered owner can register gem; non-owner cannot", async () => {
        const { ot, admin, owner1, stranger } = await deployFixture();

        await expect(ot.connect(owner1).registerGem("ipfsHash"))
            .to.be.revertedWith("Only Registered Owners Can Register Gems");

        await ot.connect(admin).registerOwner(owner1.address);

        const tx = await ot.connect(owner1).registerGem("ipfsHash");
        await expect(tx).to.emit(ot, "GemRegistered");

        const gemId = await ot.gemCounter();
        const gem = await ot.gems(gemId);

        expect(gem.gemId).to.equal(gemId);
        expect(gem.metadataHash).to.equal("ipfsHash");
        expect(gem.currentOwner).to.equal(owner1.address);
        // enum Pending = 0
        expect(gem.status).to.equal(0);
    });

    it("only gov officer can verify/reject gems", async () => {
        const { ot, admin, officer, owner1, stranger } = await deployFixture();

        await ot.connect(admin).addGovOfficer(officer.address);
        await ot.connect(admin).registerOwner(owner1.address);

        await ot.connect(owner1).registerGem("hash1");
        const gemId = await ot.gemCounter();

        await expect(ot.connect(stranger).verifyGem(gemId))
            .to.be.revertedWith("Not a Government Officer");

        await expect(ot.connect(officer).verifyGem(gemId))
            .to.emit(ot, "GemVerified")
            .withArgs(gemId, officer.address);

        const gem = await ot.gems(gemId);
        // Verified = 1
        expect(gem.status).to.equal(1);
        expect(gem.verifiedBy).to.equal(officer.address);
    });

    it("full transfer flow: initiate -> buyer confirm -> seller confirm -> owner changes", async () => {
        const { ot, admin, owner1, owner2, stranger } = await deployFixture();

        await ot.connect(admin).registerOwner(owner1.address);
        await ot.connect(admin).registerOwner(owner2.address);

        await ot.connect(owner1).registerGem("hash2");
        const gemId = await ot.gemCounter();

        // Only owner1 is current owner, so stranger cannot initiate
        await expect(ot.connect(stranger).initiateTransfer(gemId, owner2.address))
            .to.be.revertedWith("Not the Gem Owner");

        const initTx = await ot.connect(owner1).initiateTransfer(gemId, owner2.address);
        await expect(initTx).to.emit(ot, "TransferInitiated");

        const transferId = await ot.transferCounter();
        const t = await ot.transfers(transferId);
        expect(t.gemId).to.equal(gemId);
        expect(t.seller).to.equal(owner1.address);
        expect(t.buyer).to.equal(owner2.address);

        await expect(ot.connect(stranger).buyerConfirm(transferId))
            .to.be.revertedWith("Only Buyer Can Confirm");

        await expect(ot.connect(owner2).buyerConfirm(transferId))
            .to.emit(ot, "BuyerConfirmed")
            .withArgs(transferId, owner2.address);

        await expect(ot.connect(owner1).sellerConfirm(transferId))
            .to.emit(ot, "SellerConfirmed")
            .withArgs(transferId, owner1.address);

        const gem = await ot.gems(gemId);
        expect(gem.currentOwner).to.equal(owner2.address);

        const done = await ot.transfers(transferId);
        expect(done.completed).to.equal(true);

        // cannot confirm again after completion
        await expect(ot.connect(owner1).sellerConfirm(transferId))
            .to.be.revertedWith("Already Completed");
    });
});