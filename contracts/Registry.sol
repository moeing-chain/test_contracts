// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/IRegistry.sol";

contract Registry is IRegistry {

    mapping(address => bytes32) private accountTable;
    mapping(bytes32 => address) private ownerTable;
    mapping(bytes32 => address) private operatorTable;
    mapping(bytes32 => address) private newOperatorTable;
    mapping(address /*owner*/ => address) private allowanceTable;
    mapping(address => address) public spaceTable;

    function Registry(){}

    function register(bytes32 accountName, address operator) external returns (bool) {
        if (ownerTable[msg.sender] == address(0)) {
            bytes32 memory oldAccount = accountTable[msg.sender];
            accountTable[msg.sender] = accountName;
            delete ownerTable[oldAccount];
            delete operatorTable[oldAccount];
            delete newOperatorTable[oldAccount];
            ownerTable[accountName] = msg.sender;
            operatorTable[accountName] = operator;
            emit Register(accountName, msg.sender, operator);
            return true;
        }
        return false;
    }

    function appointNewOperator(bytes32 accountName, address operator) external {
        require(ownerTable[accountName] == msg.sender);
        newOperatorTable[accountName] = operator;
    }

    // Switch to a newly-appointed operator. Only the newly-appointed operator can call this function.
    function switchToNewOperator(bytes32 accountName) external {
        require(newOperatorTable[accountName] == msg.sender);
        operatorTable[accountName] = msg.sender;
        delete newOperatorTable[accountName];
        emit ChangeOperator(accountName, msg.sender);
    }

    // Approve a smart contract to transfer name's ownership
    //todo: like erc721, ownership can only approve one address the same time
    function approve(address contractAddr) external {
        allowanceTable[msg.sender] = contractAddr;
    }

    // Transfer accountName's ownership from oldOwner to newOwner
    //todo: only owner can transfer, oldOwner not need
    function transfer(bytes32 accountName, address oldOwner, address newOwner) external {
        require(ownerTable[accountName] == msg.sender);
        accountTable[newOwner] = accountName;
        delete accountTable[msg.sender];
        ownerTable[accountName] = newOwner;
        address tmp = allowanceTable[msg.sender];
        if (tmp != address(0)) {
            delete allowanceTable[msg.sender];
            allowanceTable[newOwner] = tmp;
        }
    }

    // Given the owner's address, query the corresponding accountName
    function getAccountNameByOwner(address owner) external view returns (bytes32) {
        return accountTable[owner];
    }

    // Given the operator's address, query the corresponding accountName
    //todo: not need, can get operator by accountName, reverse query can make out of chain
    function getAccountNameByOperator(address operator) external view returns (bytes32) {
        return bytes32(0);
    }

    // Given the accountName, query the addresses of the owner and operator
    function getOwnerAndOperatorByAccountName(bytes32 accountName) external view returns (address, address) {
        address owner = ownerTable[accountName];
        address operator = operatorTable[accountName];
        return (owner, operator);
    }

    // Given the accountName, query the newly-appointed operator
    function getNewOperator(bytes32 accountName) external view returns (address) {
        return newOperatorTable[accountName];
    }

    //todo: add this
    function getOperatorByOwner(address owner) external view returns (address) {
        bytes32 accName = accountTable[owner];
        return operatorTable[accName];
    }

    //todo: add this
    // Create Space, only owner
    function newSpace() external {
        //call Space contract
    }
}
