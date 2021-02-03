// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IRegistry {
    event Register(bytes32 indexed accountName, address indexed owner, address successor, address guardian);
    event SwitchOwner(bytes32 indexed accountName, address indexed owner);

    function register(bytes32 accountName, address successor, address guardian) external returns (bool);
    function switchOwner(bytes32 accountName) external;
    function setSuccessor(address _successor) external;
    function setGuardian(address _successor) external;
    function setSpace(address _newLogic) external;

    // Given the owner's address, query the corresponding accountName
    function getAccountNameByOwner(address owner) external view returns (bytes32);
    // Given the accountName, query the addresses of the owner
    function getOwnerByAccountName(bytes32 accountName) external view returns (address);
    function getSuccessor(address owner) external view returns (address);
    function getGuardian(address owner) external view returns (address);
    function getDefaultGuardian() external view returns (address);
    function getSpaceLogic() external view returns (address);
    function getSpaceByAccountName(bytes32 accountName) external view returns (address);
    function getSpaceByOwner(address owner) external view returns (address);
}
