// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "./IERC20.sol";

interface IMySpace {
    // A new thread was created.
    event NewThread(uint64 indexed threadId, bytes content);
    // In a new thread with 'threadId', accountA and accountB were mentioned (@)
    event Notify(uint64 indexed threadId, bytes32 indexed accountA, bytes32 indexed accountB);
    // Someone commented in a thread with 'threadId', at the same time, she also rewards some coins to 'rewardTo'
    event NewComment(uint64 indexed threadId, address indexed commenter, bytes content, address indexed rewardTo, uint rewardAmount, address rewardCoin);

    // A new Vote was started. It has 'optionCount' options. It will finished at 'endTime'.
    event StartVote(uint64 indexed id, string detail, uint optionCount, uint endTime);
    // The 'voter' votes for a option with 'optionId', by paying some coins
    event Vote(address indexed voter, uint voteId, uint optionId, uint coinAmount);

    // A new Advertisement was published. Totally numAudience*coinsPerAudience of coins were reserved for the audiences who may be not interested with this Ad. The followers selected by 'bloomfilter' can click this Ad. This Ad keeps effective until 'endTime'
    event PublishAd(uint64 indexed id, string detail, uint numAudience, uint coinsPerAudience, address coinType, uint endTime);
    // An 'audience' clicked at an Ad with 'id' and expressed whether she is interested. If she is not interested, she gets some coins for compensation.
    event ClickAd(uint64 indexed id, address indexed audience, bool interested);

    function switchToNewOwner(address _owner) external;
    // Get the owner of this contract
    function getOwner() external view returns (address);


    // Create a new thread. Only the owner can call this function. Returns the new thread's id
    function createNewThread(bytes memory content, bytes32[] calldata notifyList) external returns (uint64);
    // Add a comment under a thread. Only the owner and the followers can call this function
    function comment(uint64 threadId, bytes memory content, address rewardTo, uint rewardAmount, address rewardCoin) external;
    // Returns the Id of the next thread
    function getNextThreadId() external view returns (uint64);

    // Add the accounts in badIdList into blacklist. operator-only.
    function addToBlacklist(bytes32[] calldata badIdList) external;
    // Remove the accounts in goodIdList from blacklist. operator-only.
    function removeFromBlacklist(bytes32[] calldata goodIdList) external;
    // Add another contract as blacklist agent. operator-only.
    function addBlacklistAgent(address agent) external;
    // Stop taking another contract as blacklist agent. operator-only.
    //function removeBlacklistAgent(address agent) external;
    function removeBlacklistAgent() external;
    // Query wether an id is in the black list
    function isInBlacklist(bytes32 id) external returns (bool);
    // Query the content of the black list, with paging support.
    //function getBlacklist(uint start, uint count) external returns (bytes32[] memory);

    // Follow this contract's owner.
    function follow() external;
    // Unfollow this contract's owner.
    function unfollow() external;
    // Query all the followers, with paging support.
    //function getFollowers(uint start, uint count) external returns (bytes32[] memory);
    // Set the warmup time for new followers: how many hours after becoming a follower can she comment? operator-only
    function setWarmupTime(uint numSeconds) external;
    // Query the warmup time for new followers
    function getWarmupTime() external view returns (uint);

    // Start a new vote. operator-only. Can delete an old vote to save gas.
    function startVote(string memory detail, uint8 optionCount, uint8 voteConfig, uint endTime, uint64 deleteOldId) external returns (uint64);
    // Vote for an option. followers-only.
    function vote(uint64 voteId, uint8 optionId, uint coinAmount) external;
    // Return the amounts of voted coins for each option.
    function getVoteResult(uint64 voteId) external view returns (uint[] memory);
    // Returns the Id of the next vote
    function getNextVoteId() external view returns (uint64);

    // Publish a new Ad. owner-only. Can delete an old Ad to save gas and reclaim coins at the same time.
    function publishAd(string memory detail, uint numAudience, uint coinsPerAudience, address coinType, uint endTime, uint64 deleteOldId) external returns (uint64);
    // Click an Ad and express whether I am interested. followers-only
    function clickAd(uint id, bool interested) external;
    // Delete an old Ad to save gas and reclaim coins
    function deleteAd(uint id) external;
    // Returns the Id of the next Ad
    function getNextAdId() external view returns (uint64);
}

