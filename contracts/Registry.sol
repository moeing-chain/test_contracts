// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/IRegistry.sol";
import "./Space.sol";

contract RegistryLogic is IRegistry {

    struct bakAddressInfo {
        address bakAddress;
        uint64 startTime;
    }

    address private owner;
    address private register; //placeholder
    uint64 latencyTime;
    address private spaceLogic;
    address private defaultGuardian;
    mapping(address => bytes32) private ownerToName;
    mapping(bytes32 => address) private nameToOwner;
    mapping(address => address) private ownerToSuccessor;
    mapping(address => bakAddressInfo) private ownerToSuccessorBak;
    mapping(address => address) private ownerToGuardian;
    mapping(address => bakAddressInfo) private ownerToGuardianBak;
    mapping(bytes32 => address) public spaceTable;

    function Registry(){}

    //todo: support change name
    function register(bytes32 accountName, address successor, address guardian) external returns (bool) {
        if (nameToOwner[accountName] == address(0)) {
            nameToOwner[accountName] = msg.sender;
            ownerToName[msg.sender] = accountName;
            ownerToSuccessor[msg.sender] = successor;
            ownerToGuardian[msg.sender] = guardian;
            address spaceAddr = newSpace(msg.sender, accountName);
            spaceTable[accountName] = spaceAddr;
            emit Register(accountName, msg.sender, successor, guardian);
            return true;
        }
        return false;
    }

    //by owner, guardian
    function switchOwner(bytes32 accountName) external {
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
        require(_owner != address(0) && (_owner == msg.sender || _guardian == msg.sender || (_guardian == 0 && defaultGuardian == msg.sender)));
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

    function setSuccessor(address _successor) external {
        bakAddressInfo memory info;
        info.bakAddress = _successor;
        info.startTime = block.timestamp;
        ownerToSuccessorBak[msg.sender] = info;
    }

    function setGuardian(address _guardian) external {
        bakAddressInfo memory info;
        info.bakAddress = _guardian;
        info.startTime = block.timestamp;
        ownerToGuardianBak[msg.sender] = info;
    }

    // Given the owner's address, query the corresponding accountName
    function getAccountNameByOwner(address owner) external view returns (bytes32) {
        return ownerToName[owner];
    }

    // Given the accountName, query the addresses of the owner and operator
    function getOwnerByAccountName(bytes32 accountName) external view returns (address) {
        return nameToOwner[accountName];
    }

    // Given the accountName, query the newly-appointed operator
    function getSuccessor(address owner) external view returns (address) {
        return ownerToSuccessor[owner];
    }

    function getGuardian(address owner) external view returns (address) {
        return ownerToGuardian[owner];
    }

    function getDefaultGuardian() external view returns (address) {
        return defaultGuardian;
    }

    function setSpace(address _newLogic) external {
        require(msg.sender == owner);
        spaceLogic = _newLogic;
    }

    function getSpaceLogic() external view returns (address) {
        return spaceImpl;
    }

    // Create Space, only owner
    function newSpace(byte32 accountName, address _owner) internal returns (address) {
        //call Space contract
        byte32 salt = keccak256(bytes32(accountName));
        return new Space{salt : salt}(_owner, address(this));
    }

    function getSpaceByAccountName(byte32 accountName) external view returns (address) {
        return spaceTable[accountName];
    }

    function getSpaceByOwner(address owner) external view returns (address) {
        return spaceTable[accountName];
    }
}
