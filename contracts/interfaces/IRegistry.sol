// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IRegistry {
    // 'owner' registers an 'accountName' and let 'operator' to act for this account.
    event Register(bytes32 indexed accountName, address indexed owner, address indexed operator);
    // Another 'operator' will act for this account with 'accountName'.
    event ChangeOperator(bytes32 indexed accountName, address indexed operator);

    function register(bytes32 accountName, address operator) external returns (bool);
    // Appoint a new operator to act for 'accountName'. Only owner of 'accountName' can call this function.
    function appointNewOperator(bytes32 accountName, address operator) external returns (bool);
    // Switch to a newly-appointed operator. Only the newly-appointed operator can call this function.
    function switchToNewOperator(bytes32 accountName) external;

    // Given the owner's address, query the corresponding accountName
    function getAccountNameByOwner(address owner) external view returns (bytes32);
    // Given the operator's address, query the corresponding accountName
    function getAccountNameByOperator(address operator) external view returns (bytes32);
    // Given the accountName, query the addresses of the owner and operator
    function getOwnerAndOperatorByAccountName(bytes32 accountName) external view returns (address, address);
    // Given the accountName, query the newly-appointed operator
    function getNewOperator(bytes32 accountName) external view returns (address);
}

