// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title GemChain - Gemstone registration, verification, and ownership transfer
/// @notice Optimized single-contract version for a blockchain gemstone provenance system
contract GemChain {
    enum VerificationStatus {
        None,
        Pending,
        Verified,
        Rejected
    }

    struct Gem {
        uint256 gemId;
        string metadataHash;
        address currentOwner;
        VerificationStatus status;
        address verifiedBy;
        uint64 createdAt;
        uint64 updatedAt;
    }

    struct TransferRequest {
        uint256 transferId;
        uint256 gemId;
        address seller;
        address buyer;
        bool buyerConfirmed;
        bool sellerConfirmed;
        bool completed;
        bool cancelled;
        uint64 createdAt;
    }

    address public admin;
    uint256 public gemCounter;
    uint256 public transferCounter;

    mapping(address => bool) public isGovOfficer;
    mapping(address => bool) public isOwner;
    mapping(uint256 => Gem) public gems;
    mapping(uint256 => TransferRequest) public transfers;
    mapping(uint256 => uint256) public activeTransferByGem;

    error OnlyAdmin();
    error OnlyGovOfficer();
    error OnlyRegisteredOwner();
    error ZeroAddress();
    error EmptyMetadataHash();
    error AlreadyGovOfficer();
    error OfficerNotFound();
    error AlreadyRegisteredOwner();
    error GemNotFound();
    error GemNotPending();
    error GemNotVerified();
    error NotGemOwner();
    error InvalidBuyer();
    error TransferAlreadyExists();
    error TransferNotFound();
    error TransferAlreadyCompleted();
    error TransferCancelled();
    error OnlyBuyer();
    error OnlySeller();
    error SellerNoLongerOwner();

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event GovOfficerAdded(address indexed officer);
    event GovOfficerRemoved(address indexed officer);
    event OwnerRegistered(address indexed owner);
    event GemRegistered(uint256 indexed gemId, address indexed owner, string metadataHash);
    event GemVerified(uint256 indexed gemId, address indexed officer);
    event GemRejected(uint256 indexed gemId, address indexed officer);
    event TransferInitiated(uint256 indexed transferId, uint256 indexed gemId, address indexed seller, address buyer);
    event BuyerConfirmed(uint256 indexed transferId, address indexed buyer);
    event SellerConfirmed(uint256 indexed transferId, address indexed seller);
    event TransferCancelled(uint256 indexed transferId, address indexed cancelledBy);
    event OwnershipTransferred(uint256 indexed gemId, address indexed from, address indexed to);

    modifier onlyAdmin() {
        if (msg.sender != admin) revert OnlyAdmin();
        _;
    }

    modifier onlyGovOfficer() {
        if (!isGovOfficer[msg.sender]) revert OnlyGovOfficer();
        _;
    }

    modifier onlyRegisteredOwner() {
        if (!isOwner[msg.sender]) revert OnlyRegisteredOwner();
        _;
    }

    constructor() {
        admin = msg.sender;
        emit AdminTransferred(address(0), msg.sender);
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert ZeroAddress();
        address oldAdmin = admin;
        admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }

    function addGovOfficer(address officer) external onlyAdmin {
        if (officer == address(0)) revert ZeroAddress();
        if (isGovOfficer[officer]) revert AlreadyGovOfficer();
        isGovOfficer[officer] = true;
        emit GovOfficerAdded(officer);
    }

    function removeGovOfficer(address officer) external onlyAdmin {
        if (!isGovOfficer[officer]) revert OfficerNotFound();
        isGovOfficer[officer] = false;
        emit GovOfficerRemoved(officer);
    }

    function registerOwner(address owner) external onlyAdmin {
        if (owner == address(0)) revert ZeroAddress();
        if (isOwner[owner]) revert AlreadyRegisteredOwner();
        isOwner[owner] = true;
        emit OwnerRegistered(owner);
    }

    function registerGem(string calldata metadataHash) external onlyRegisteredOwner returns (uint256 gemId) {
        if (bytes(metadataHash).length == 0) revert EmptyMetadataHash();

        gemId = ++gemCounter;
        uint64 ts = uint64(block.timestamp);

        gems[gemId] = Gem({
            gemId: gemId,
            metadataHash: metadataHash,
            currentOwner: msg.sender,
            status: VerificationStatus.Pending,
            verifiedBy: address(0),
            createdAt: ts,
            updatedAt: ts
        });

        emit GemRegistered(gemId, msg.sender, metadataHash);
    }

    function verifyGem(uint256 gemId) external onlyGovOfficer {
        Gem storage gem = gems[gemId];
        if (gem.gemId == 0) revert GemNotFound();
        if (gem.status != VerificationStatus.Pending) revert GemNotPending();

        gem.status = VerificationStatus.Verified;
        gem.verifiedBy = msg.sender;
        gem.updatedAt = uint64(block.timestamp);

        emit GemVerified(gemId, msg.sender);
    }

    function rejectGem(uint256 gemId) external onlyGovOfficer {
        Gem storage gem = gems[gemId];
        if (gem.gemId == 0) revert GemNotFound();
        if (gem.status != VerificationStatus.Pending) revert GemNotPending();

        gem.status = VerificationStatus.Rejected;
        gem.verifiedBy = msg.sender;
        gem.updatedAt = uint64(block.timestamp);

        emit GemRejected(gemId, msg.sender);
    }

    function initiateTransfer(uint256 gemId, address buyer)
        external
        onlyRegisteredOwner
        returns (uint256 transferId)
    {
        Gem storage gem = gems[gemId];
        if (gem.gemId == 0) revert GemNotFound();
        if (gem.currentOwner != msg.sender) revert NotGemOwner();
        if (gem.status != VerificationStatus.Verified) revert GemNotVerified();
        if (buyer == address(0)) revert ZeroAddress();
        if (!isOwner[buyer] || buyer == msg.sender) revert InvalidBuyer();
        if (activeTransferByGem[gemId] != 0) revert TransferAlreadyExists();

        transferId = ++transferCounter;
        transfers[transferId] = TransferRequest({
            transferId: transferId,
            gemId: gemId,
            seller: msg.sender,
            buyer: buyer,
            buyerConfirmed: false,
            sellerConfirmed: false,
            completed: false,
            cancelled: false,
            createdAt: uint64(block.timestamp)
        });
        activeTransferByGem[gemId] = transferId;

        emit TransferInitiated(transferId, gemId, msg.sender, buyer);
    }

    function buyerConfirm(uint256 transferId) external {
        TransferRequest storage t = _getActiveTransfer(transferId);
        if (msg.sender != t.buyer) revert OnlyBuyer();

        t.buyerConfirmed = true;
        emit BuyerConfirmed(transferId, msg.sender);
        _tryFinalizeTransfer(transferId);
    }

    function sellerConfirm(uint256 transferId) external {
        TransferRequest storage t = _getActiveTransfer(transferId);
        if (msg.sender != t.seller) revert OnlySeller();

        t.sellerConfirmed = true;
        emit SellerConfirmed(transferId, msg.sender);
        _tryFinalizeTransfer(transferId);
    }

    function cancelTransfer(uint256 transferId) external {
        TransferRequest storage t = _getActiveTransfer(transferId);
        if (msg.sender != t.seller && msg.sender != t.buyer && msg.sender != admin) revert OnlyAdmin();

        t.cancelled = true;
        activeTransferByGem[t.gemId] = 0;
        emit TransferCancelled(transferId, msg.sender);
    }

    function getGem(uint256 gemId) external view returns (Gem memory) {
        Gem memory gem = gems[gemId];
        if (gem.gemId == 0) revert GemNotFound();
        return gem;
    }

    function getTransfer(uint256 transferId) external view returns (TransferRequest memory) {
        TransferRequest memory t = transfers[transferId];
        if (t.transferId == 0) revert TransferNotFound();
        return t;
    }

    function _getActiveTransfer(uint256 transferId) internal view returns (TransferRequest storage t) {
        t = transfers[transferId];
        if (t.transferId == 0) revert TransferNotFound();
        if (t.completed) revert TransferAlreadyCompleted();
        if (t.cancelled) revert TransferCancelled();
    }

    function _tryFinalizeTransfer(uint256 transferId) internal {
        TransferRequest storage t = transfers[transferId];
        if (!(t.buyerConfirmed && t.sellerConfirmed)) return;

        Gem storage gem = gems[t.gemId];
        if (gem.currentOwner != t.seller) revert SellerNoLongerOwner();
        if (gem.status != VerificationStatus.Verified) revert GemNotVerified();

        gem.currentOwner = t.buyer;
        gem.updatedAt = uint64(block.timestamp);

        t.completed = true;
        activeTransferByGem[t.gemId] = 0;

        emit OwnershipTransferred(t.gemId, t.seller, t.buyer);
    }
}
