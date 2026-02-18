// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./GemRegistry.sol";

/*
    OwnershipTransfer Contract:
    Handles buying/selling of registered gems.
    Requires both buyer & seller confirmation.
*/

contract OwnershipTransfer is GemRegistry {

    struct TransferRequest {
        uint256 gemId;
        address seller;
        address buyer;
        bool buyerConfirmed;
        bool sellerConfirmed;
        bool completed;
    }

    uint256 public transferCounter = 0;
    mapping(uint256 => TransferRequest) public transfers;

    event TransferInitiated(uint256 transferId, uint256 gemId, address seller, address buyer);
    event BuyerConfirmed(uint256 transferId, address buyer);
    event SellerConfirmed(uint256 transferId, address seller);
    event OwnershipTransferred(uint256 gemId, address from, address to);

    // Seller initiates transfer
    function initiateTransfer(uint256 _gemId, address _buyer) external returns (uint256) {
        require(gems[_gemId].currentOwner == msg.sender, "Not the Gem Owner");
        require(isOwner[_buyer], "Buyer must be a registered owner");

        transferCounter++;
        transfers[transferCounter] = TransferRequest(
            _gemId,
            msg.sender,
            _buyer,
            false,
            false,
            false
        );

        emit TransferInitiated(transferCounter, _gemId, msg.sender, _buyer);
        return transferCounter;
    }

    function buyerConfirm(uint256 _transferId) external {
        TransferRequest storage t = transfers[_transferId];
        require(msg.sender == t.buyer, "Only Buyer Can Confirm");
        require(!t.completed, "Already Completed");

        t.buyerConfirmed = true;
        emit BuyerConfirmed(_transferId, msg.sender);

        _tryFinalizeTransfer(_transferId);
    }

    function sellerConfirm(uint256 _transferId) external {
        TransferRequest storage t = transfers[_transferId];
        require(msg.sender == t.seller, "Only Seller Can Confirm");
        require(!t.completed, "Already Completed");

        t.sellerConfirmed = true;
        emit SellerConfirmed(_transferId, msg.sender);

        _tryFinalizeTransfer(_transferId);
    }

    // Once both confirm → transfer finalized
    function _tryFinalizeTransfer(uint256 _transferId) internal {
        TransferRequest storage t = transfers[_transferId];

        if (t.buyerConfirmed && t.sellerConfirmed && !t.completed) {
            gems[t.gemId].currentOwner = t.buyer;
            t.completed = true;

            emit OwnershipTransferred(t.gemId, t.seller, t.buyer);
        }
    }
}
