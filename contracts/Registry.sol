// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/IRegistry.sol";
import "./Space.sol";

contract RegistryLogic is IRegistry {

    mapping(address => bytes32) private ownerToName;
    mapping(bytes32 => address) private nameToOwner;
    mapping(bytes32 => address) private nameToOperator;
    mapping(bytes32 => address) private nameToNewOperator;
    mapping(address /*owner*/ => address) private ownerToApprovedContract;
    mapping(bytes32 => address) public spaceTable;

    function Registry(){}

    function register(bytes32 accountName, address operator) external returns (bool) {
        if (nameToOwner[accountName] == address(0)) {
            bytes32 memory oldAccount = ownerToName[msg.sender];
            ownerToName[msg.sender] = accountName;
            delete nameToOwner[oldAccount];
            delete nameToOperator[oldAccount];
            delete nameToNewOperator[oldAccount];
            nameToOwner[accountName] = msg.sender;
            nameToOperator[accountName] = operator;
            address spaceAddr = newSpace(msg.sender, accountName, operator, address(0));
            spaceTable[accountName] = spaceAddr;
            emit Register(accountName, msg.sender, operator);
            return true;
        }
        return false;
    }

    // Maybe we should emit an event for this?
    function appointNewOperator(bytes32 accountName, address operator) external {
        require(nameToOwner[accountName] == msg.sender);
        nameToNewOperator[accountName] = operator;
    }

    // Switch to a newly-appointed operator. Only the newly-appointed operator can call this function.
    function switchToNewOperator(bytes32 accountName) external {
        require(nameToNewOperator[accountName] == msg.sender);
        nameToOperator[accountName] = msg.sender;
        delete nameToNewOperator[accountName];
        address space = spaceTable[accountName];
        if (space != address(0)) {
            IMySpace(space).switchToNewOperator();
        }
        emit ChangeOperator(accountName, msg.sender);
    }

    // Approve a smart contract to transfer name's ownership
    //todo: like erc721, ownership can only approve one address the same time
    function approve(address contractAddr) external {
        ownerToApprovedContract[msg.sender] = contractAddr;
    }

    // Transfer accountName's ownership from oldOwner to newOwner
    //todo: only owner can transfer, oldOwner not need
    function transfer(bytes32 accountName, address oldOwner, address newOwner) external {
        require(nameToOwner[accountName] == msg.sender);
        ownerToName[newOwner] = accountName;
        delete ownerToName[msg.sender];
        nameToOwner[accountName] = newOwner;
        address tmp = ownerToApprovedContract[msg.sender];
        if (tmp != address(0)) {
            delete ownerToApprovedContract[msg.sender];
            ownerToApprovedContract[newOwner] = tmp;
        }
        address space = spaceTable[accountName];
        if (space != address(0)) {
            IMySpace(space).switchToNewOwner(newOwner);
        }
    }

    // Given the owner's address, query the corresponding accountName
    function getAccountNameByOwner(address owner) external view returns (bytes32) {
        return ownerToName[owner];
    }

    // Given the operator's address, query the corresponding accountName
    //todo: not need, can get operator by accountName, reverse query can make out of chain
    function getAccountNameByOperator(address operator) external view returns (bytes32) {
        return bytes32(0);
    }

    // Given the accountName, query the addresses of the owner and operator
    function getOwnerAndOperatorByAccountName(bytes32 accountName) external view returns (address, address) {
        address owner = nameToOwner[accountName];
        address operator = nameToOperator[accountName];
        return (owner, operator);
    }

    // Given the accountName, query the newly-appointed operator
    function getNewOperator(bytes32 accountName) external view returns (address) {
        return nameToNewOperator[accountName];
    }

    //todo: add this
    function getOperatorByOwner(address owner) external view returns (address) {
        bytes32 accName = ownerToName[owner];
        return nameToOperator[accName];
    }

    //todo: add this
    // Create Space, only owner
    function newSpace(byte32 accountName, address owner, address operator, address voteCoin) internal returns (address) {
        //call Space contract
        byte32 salt = keccak256(bytes32(accountName));
        address space = new Space{salt : salt}(owner, operator, address(this), voteCoin);
        return space;
    }

    //todo: add this
    function getSpaceByAccountName(byte32 accountName) external view returns (address) {
        return spaceTable[accountName];
    }

    function getSpaceByOwner(address owner) external view returns (address) {
        return spaceTable[accountName];
    }
}
