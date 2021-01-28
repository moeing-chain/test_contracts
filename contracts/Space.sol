// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/IMySpace.sol";

contract Space is IMySpace {

    address public owner;
    uint64 public nextThreadId;
    uint private warmupTime;
    mapping(address => uint64/*timestamp*/) followerTable;

    function Space(){
        owner = msg.sender;
    }

    // Someone commented in a thread with 'threadId', at the same time, she also rewards some coins to 'rewardTo'
    event NewComment(uint64 indexed threadId, address indexed commenter, bytes content, address indexed rewardTo, uint rewardAmount, address rewardCoin);

    // Create a new thread. Only the owner can call this function. Returns the new thread's id
    function createNewThread(bytes memory content, bytes32[] calldata notifyList) external returns (uint64) {
        require(msg.sender == owner);
        uint64 threadId = nextThreadId;
        emit NewThread(threadId, content);
        uint length = notifyList.length;
        for (uint i = 0; i < (length + 1) / 2; i++) {
            if (2 * i + 1 == length) {
                emit Notify(threadId, notifyList[2 * i], address(0));
            } else {
                emit Notify(threadId, notifyList[2 * i], notifyList[2 * i + 1]);
            }
        }
        nextThreadId++;
        return threadId;
    }

    // Add a comment under a thread. Only the owner and the followers can call this function
    function comment(uint64 threadId, bytes memory content, address rewardTo, uint rewardAmount, address rewardCoin) external {

    }
    
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

    // Start a new vote. operator-only. Can delete an old vote to save gas.
    function startVote(string memory detail, uint optionCount, uint endTime, uint64 deleteOldId) external returns (uint64);
    // Vote for an option. followers-only.
    function vote(uint voteId, uint optionId, uint coinAmount) external;
    // Return the amounts of voted coins for each option.
    function getVoteResult(uint voteId) external view returns (uint[] memory);
    // Returns the Id of the next vote
    function getNextVoteId() external view returns (uint64);

    // Publish a new Ad. operator-only. Can delete an old Ad to save gas and reclaim coins at the same time.
    function publishAd(string memory detail, uint numAudience, uint numRejector, uint coinsPerAudience, address coinType, uint[] calldata bloomfilter, uint endTime, uint64 deleteOldId) external returns (uint64);
    // Click an Ad and express whether I am interested. followers-only
    function clickAd(uint id, bool interested) external;
    // Delete an old Ad to save gas and reclaim coins
    function deleteAd(uint id) external;
    // Returns the Id of the next Ad
    function getNextAdId() external view returns (uint64);
}
