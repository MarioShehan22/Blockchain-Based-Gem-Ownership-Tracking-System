// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    AccessControl contract manages user roles:
    - Admin
    - Government Officer
    - Gem Owner (default after registration)
*/

contract AccessControl {
    address public admin;

    mapping(address => bool) public isGovOfficer;
    mapping(address => bool) public isOwner;

    event GovOfficerAdded(address officer);
    event GovOfficerRemoved(address officer);
    event OwnerRegistered(address owner);

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin Allowed");
        _;
    }

    modifier onlyGovOfficer() {
        require(isGovOfficer[msg.sender], "Not a Government Officer");
        _;
    }

    function addGovOfficer(address _officer) external onlyAdmin {
        isGovOfficer[_officer] = true;
        emit GovOfficerAdded(_officer);
    }

    function removeGovOfficer(address _officer) external onlyAdmin {
        isGovOfficer[_officer] = false;
        emit GovOfficerRemoved(_officer);
    }

    function registerOwner(address _owner) external onlyAdmin {
        isOwner[_owner] = true;
        emit OwnerRegistered(_owner);
    }
}
