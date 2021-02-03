// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./interfaces/IChirp.sol";

contract Chirp is IChirp {

    address private owner;
    address private registerLogic;
    address private defaultGuardian;
    address private spaceLogic;
    uint64 latencyTime;

    constructor(address _register, address _spaceLogic, address _defaultGuardian){
        owner = msg.sender;
        registerLogic = _register;
        defaultGuardian = _defaultGuardian;
        spaceLogic = _spaceLogic;
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner);
        owner = _owner;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function setRegister(address _register) external override {
        require(msg.sender == owner);
        registerLogic = _register;
    }

    function getRegister() external view override returns (address) {
        return registerLogic;
    }

    receive() external payable {}

    fallback() payable external {
        assembly {
            let ptr := mload(0x40)
            let size := calldatasize()
            calldatacopy(ptr, 0, size)
            let result := delegatecall
    (gas(), sload(registerLogic.slot), ptr, size, 0, 0)
    size := returndatasize()
    returndatacopy(ptr, 0, size)
    switch result
    case 0 {revert(ptr, size)}
    default {return (ptr, size)}
    }
}
}
