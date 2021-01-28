// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IBlackListAgent {
    function isInBlacklist(bytes32 id) external returns (bool);
    // Query the content of the black list, with paging support.
    function getBlacklist(uint start, uint count) external returns (bytes32[] memory);
}
