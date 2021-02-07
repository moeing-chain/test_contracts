// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./interfaces/IRegistry.sol";
import "./Space.sol";

contract RegistryLogic is IRegistry {

    struct bakAddressInfo {
        address bakAddress;
        uint64 startTime;
    }

    address private owner; //placeholder
    address private registerLogic; //placeholder
    address private defaultGuardian; //placeholder
    address private spaceLogic; //placeholder
    uint64 latencyTime; //placeholder
    mapping(address => bytes32) private ownerToName;
    mapping(bytes32 => address) private nameToOwner;
    mapping(address => address) private ownerToSuccessor;
    mapping(address => bakAddressInfo) private ownerToSuccessorBak;
    mapping(address => address) private ownerToGuardian;
    mapping(address => bakAddressInfo) private ownerToGuardianBak;
    mapping(bytes32 => address) public spaceTable;

    //not support change name
    function register(bytes32 accountName, address successor, address guardian) external override returns (bool) {
        if (nameToOwner[accountName] == address(0)) {
            nameToOwner[accountName] = msg.sender;
            ownerToName[msg.sender] = accountName;
            ownerToSuccessor[msg.sender] = successor;
            ownerToGuardian[msg.sender] = guardian;
            address spaceAddr = newSpace(accountName, msg.sender);
            spaceTable[accountName] = spaceAddr;
            emit Register(accountName, msg.sender, successor, guardian);
            return true;
        }
        return false;
    }

    //by owner, guardian
    function switchOwner(bytes32 accountName) external override {
        address _owner = nameToOwner[accountName];
        bakAddressInfo memory guardianInfo = ownerToGuardianBak[_owner];
        address _guardian;
        if (guardianInfo.startTime > 0 && block.timestamp > latencyTime + guardianInfo.startTime) {
            _guardian = guardianInfo.bakAddress;
            ownerToGuardian[_owner] = _guardian;
            delete ownerToGuardianBak[_owner];
        } else {
            _guardian = ownerToGuardian[_owner];
        }
        require(_owner != address(0) && (_owner == msg.sender || _guardian == msg.sender || (_guardian == address(0) && defaultGuardian == msg.sender)));
        bakAddressInfo memory info = ownerToSuccessorBak[_owner];
        address _successor;
        if (info.startTime > 0 && block.timestamp > latencyTime + info.startTime) {
            _successor = info.bakAddress;
            delete ownerToSuccessorBak[_owner];
        } else {
            _successor = ownerToSuccessor[_owner];
        }
        nameToOwner[accountName] = _successor;
        ownerToName[_successor] = accountName;
        delete ownerToName[_owner];
        address space = spaceTable[accountName];
        if (space != address(0)) {
            IMySpace(space).switchToNewOwner(_successor);
        }
        emit SwitchOwner(accountName, _successor);
    }

    function setSuccessor(address _successor) external override {
        bakAddressInfo memory info;
        info.bakAddress = _successor;
        info.startTime = uint64(block.timestamp);
        ownerToSuccessorBak[msg.sender] = info;
    }

    function setGuardian(address _guardian) external override {
        bakAddressInfo memory info;
        info.bakAddress = _guardian;
        info.startTime = uint64(block.timestamp);
        ownerToGuardianBak[msg.sender] = info;
    }

    // Given the owner's address, query the corresponding accountName
    function getAccountNameByOwner(address _owner) external view override returns (bytes32) {
        return ownerToName[_owner];
    }

    // Given the accountName, query the addresses of the owner and operator
    function getOwnerByAccountName(bytes32 accountName) external view override returns (address) {
        return nameToOwner[accountName];
    }

    // Given the accountName, query the newly-appointed operator
    function getSuccessor(address _owner) external view override returns (address) {
        return ownerToSuccessor[_owner];
    }

    function getGuardian(address _owner) external view override returns (address) {
        return ownerToGuardian[_owner];
    }

    function getDefaultGuardian() external view override returns (address) {
        return defaultGuardian;
    }

    function setSpace(address _newLogic) external override {
        require(msg.sender == owner);
        spaceLogic = _newLogic;
    }

    function getSpaceLogic() external view override returns (address) {
        return spaceLogic;
    }

    // Create Space, only owner
    function newSpace(bytes32 accountName, address _owner) internal returns (address) {
        //call Space contract
        bytes32 salt = keccak256(abi.encode(accountName));
        Space space = new Space{salt : salt}(_owner, address(this));
        return address(space);
    }

    function getSpaceByAccountName(bytes32 accountName) external view override returns (address) {
        return spaceTable[accountName];
    }

    function getSpaceByOwner(address _owner) external view override returns (address) {
        bytes32 accountName = ownerToName[_owner];
        return spaceTable[accountName];
    }
}
