// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract Chirp {

    address private owner;
    address private registerLogic;

    function Chirp(address _register){
        owner = msg.sender;
        registerLogic = _register;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner);
        owner = _owner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function setRegister(address _register) external {
        require(msg.sender == owner);
        registerLogic = _register;
    }

    function getRegister() external view returns (address) {
        return registerLogic;
    }

    receive() external payable {}

    fallback() payable external {
        assembly {
            let ptr := mload(0x40)
            let size := calldatasize()
            calldatacopy(ptr, 0, size)
            let result := delegatecall(gas(), registerLogic, ptr, size, 0, 0)
            size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
            case 0 {revert(ptr, size)}
            default {return (ptr, size)}
        }
    }
}
