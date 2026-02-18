// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControl.sol";

/*
    GemRegistry Contract:
    Stores each gem's metadata hash, verification status,
    and assigns ownership on registration.
*/

contract GemRegistry is AccessControl {

    enum VerificationStatus { Pending, Verified, Rejected }

    struct Gem {
        uint256 gemId;
        string metadataHash;   // SHA-256 hash of metadata stored off-chain (IPFS)
        address currentOwner;
        VerificationStatus status;
        address verifiedBy;
        uint256 timestamp;
    }

    uint256 public gemCounter = 0;
    mapping(uint256 => Gem) public gems;

    event GemRegistered(uint256 gemId, address owner, string metadataHash);
    event GemVerified(uint256 gemId, address officer);
    event GemRejected(uint256 gemId, address officer);

    // Register new gem (owner uploads metadata hash)
    function registerGem(string memory _metadataHash) external returns (uint256) {
        require(isOwner[msg.sender], "Only Registered Owners Can Register Gems");

        gemCounter++;
        gems[gemCounter] = Gem(
            gemCounter,
            _metadataHash,
            msg.sender,
            VerificationStatus.Pending,
            address(0),
            block.timestamp
        );

        emit GemRegistered(gemCounter, msg.sender, _metadataHash);
        return gemCounter;
    }

    // Government Officer verifies gem
    function verifyGem(uint256 _gemId) external onlyGovOfficer {
        Gem storage g = gems[_gemId];
        g.status = VerificationStatus.Verified;
        g.verifiedBy = msg.sender;

        emit GemVerified(_gemId, msg.sender);
    }

    // Government Officer rejects gem
    function rejectGem(uint256 _gemId) external onlyGovOfficer {
        Gem storage g = gems[_gemId];
        g.status = VerificationStatus.Rejected;
        g.verifiedBy = msg.sender;

        emit GemRejected(_gemId, msg.sender);
    }
}
