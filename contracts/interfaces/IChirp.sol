// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IChirp {
    function setOwner(address _owner) external;
    function getOwner() external view returns (address);
    function setRegister(address _register) external;
    function getRegister() external view returns (address);
}