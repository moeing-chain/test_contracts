// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract Chirp {

    address owner;
    address registerImpl;

    function Chirp(address _register){
        owner = msg.sender;
        registerImpl = _register;
    }

    function setRegister(address _register) external {
        require(msg.sender == owner);
        registerImpl = _register;
    }

    function getRegister() external view returns (address) {
        return registerImpl;
    }

    receive() external payable {}

    fallback() payable external {
        assembly {
            let ptr := mload(0x40)
            let size := calldatasize()
            calldatacopy(ptr, 0, size)
            let result := delegatecall(gas(), impl, ptr, size, 0, 0)
            size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}
