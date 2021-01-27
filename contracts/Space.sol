// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/IMySpace.sol";

contract Space is IMySpace {

    function Space(){

    }

    // Create a new thread. Only the owner can call this function. Returns the new thread's id
    function createNewThread(bytes memory content, bytes32[] calldata notifyList) external returns (uint64);
    // Add a comment under a thread. Only the owner and the followers can call this function
    function comment(uint64 threadId, bytes memory content, address rewardTo, uint rewardAmount, address rewardCoin) external;
    // Returns the Id of the next thread
    function getNextThreadId() external returns (uint64);

    // Follow this contract's owner.
    function follow() external;
    // Unfollow this contract's owner.
    function unfollow() external;
    // Query all the followers, with paging support.
    function getFollowers(uint start, uint count) external returns (bytes32[] memory);
    // Set the warmup time for new followers: how many hours after becoming a follower can she comment? operator-only
    function setWarmupTime(uint numHours) external;
    // Query the warmup time for new followers
    function getWarmupTime() external view returns (uint);
}
