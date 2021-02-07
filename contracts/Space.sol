// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./interfaces/IMySpace.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IBlackListAgent.sol";
import "./libraries/SafeMath256.sol";

contract SpaceLogic is IERC20, IMySpace {
    using SafeMath256 for uint;
    struct AdInfo {
        address coinType;
        uint64 endTime;
        uint numAudience;
        uint coinsPerAudience;
    }

    address private owner;
    address private chirp;
    address private voteCoin;
    uint private warmupTime;
    uint64 public nextThreadId;
    uint64 public nextVoteId;
    uint64 public nextAdId;
    address private blackListAgent;

    mapping(address => uint64/*timestamp*/) immatureFollowerTable;
    mapping(address => bool) followerTable;
    //accountName in blackList cannot be follower, if it already be, remove it
    mapping(bytes32 => bool) blackList;
    //voteConfig: 8bit, lsb represents if one vote only one ticket, silence vote coinAmount param;
    mapping(uint64/*vote id*/ => uint /*64bit end time | 8bit voteConfig | 8bit optionCount*/) voteTable;
    //no need hash
    mapping(bytes32 => uint) voteTallyTable;
    mapping(uint64/*ad id*/ => AdInfo) adTable;
    mapping(uint64 => mapping(address => bool)) adCoinReceivers;

    bool public coinLock;
    string private _name;
    uint8 private _decimal;
    string public _symbol;
    uint256 public _totalSupply;
    mapping(address => uint) public _balanceOf;
    mapping(address => mapping(address => uint)) public _allowance;

    function initCoin(string coinName, string coinSymbol, uint8 coinDecimal, uint initSupply) external {
        require(coinLock != true && msg.sender == owner);
        coinLock = true;
        _name = coinName;
        _symbol = coinSymbol;
        _decimal = coinDecimal;
        _totalSupply = initSupply;
        _balanceOf[owner] = initSupply;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimal;
    }

    function _mint(address to, uint value) internal {
        _totalSupply = _totalSupply.add(value);
        _balanceOf[to] = _balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        _balanceOf[from] = _balanceOf[from].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address _owner, address spender, uint value) private {
        _allowance[_owner][spender] = value;
        emit Approval(_owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        _balanceOf[from] = _balanceOf[from].sub(value);
        _balanceOf[to] = _balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (_allowance[from][msg.sender] != uint256(2 ^ 256 - 1)) {
            _allowance[from][msg.sender] = _allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function mint(uint amount) external {
        require(msg.sender == owner);
        _totalSupply += amount;
        _balanceOf[owner] += amount;
    }

    function totalSupply() external view override returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address _owner) external view override returns (uint) {
        return _balanceOf[_owner];
    }

    function allowance(address _owner, address spender) external view override returns (uint) {
        return _allowance[_owner][spender];
    }

    //todo: only call by register, when change owner
    function switchToNewOwner(address _owner) external override {
        require(msg.sender == chirp);
        owner = _owner;
    }
    // Get the owner of this contract
    function getOwner() external view override returns (address) {
        return owner;
    }
    // Add the accounts in badIdList into blacklist. operator-only.
    function addToBlacklist(bytes32[] calldata badIdList) external override {
        require(msg.sender == owner);
        for (uint i = 0; i < badIdList.length; i++) {
            bytes32 acc = badIdList[i];
            if (blackList[acc] != true) {
                blackList[acc] = true;
                address _owner = IRegistry(chirp).getOwnerByAccountName(acc);
                delete immatureFollowerTable[_owner];
                delete followerTable[_owner];
            }
        }
    }
    // Remove the accounts in goodIdList from blacklist. owner-only.
    function removeFromBlacklist(bytes32[] calldata goodIdList) external override {
        require(msg.sender == owner);
        for (uint i = 0; i < goodIdList.length; i++) {
            delete blackList[goodIdList[i]];
        }
    }
    // Add another contract as blacklist agent. owner-only.
    function addBlacklistAgent(address agent) external override {
        require(msg.sender == owner);
        blackListAgent = agent;
    }
    // Stop taking another contract as blacklist agent. owner-only.
    //todo: only support one agent now;
    function removeBlacklistAgent() external override {
        require(msg.sender == owner);
        blackListAgent = address(0);
    }
    // Query wether an acc is in the black list
    function isInBlacklist(bytes32 accountName) public override returns (bool) {
        return blackList[accountName] || (blackListAgent != address(0) && IBlackListAgent(blackListAgent).isInBlacklist(accountName));
    }

    // Create a new thread. Only the owner can call this function. Returns the new thread's id
    function createNewThread(bytes memory content, bytes32[] calldata notifyList) external override returns (uint64) {
        require(msg.sender == owner);
        uint64 threadId = nextThreadId;
        emit NewThread(threadId, content);
        uint length = notifyList.length;
        for (uint i = 0; i < (length + 1) / 2; i++) {
            if (2 * i + 1 == length) {
                emit Notify(threadId, notifyList[2 * i], bytes32(""));
            } else {
                emit Notify(threadId, notifyList[2 * i], notifyList[2 * i + 1]);
            }
        }
        nextThreadId++;
        return threadId;
    }
    // Add a comment under a thread. Only the owner and the followers can call this function
    function comment(uint64 threadId, bytes memory content, address rewardTo, uint rewardAmount, address rewardCoin) external override {
        require(msg.sender == owner || isFollower(msg.sender));
        if (threadId < nextThreadId) {
            //todo: not check transfer result
            IERC20(rewardCoin).transferFrom(msg.sender, rewardTo, rewardAmount);
            emit NewComment(threadId, msg.sender, content, rewardTo, rewardAmount, rewardCoin);
        }
    }
    // Returns the Id of the next thread
    function getNextThreadId() external view override returns (uint64) {
        return nextThreadId;
    }
    // Follow this contract's owner.
    function follow() external override {
        require(followerTable[msg.sender] != true);
        bytes32 acc = IRegistry(chirp).getAccountNameByOwner(msg.sender);
        require(!isInBlacklist(acc));
        immatureFollowerTable[msg.sender] = uint64(block.timestamp);
    }
    // Unfollow this contract's owner.
    function unfollow() external override {
        delete immatureFollowerTable[msg.sender];
        delete followerTable[msg.sender];
    }
    // Query all the followers, with paging support.
    // function getFollowers(uint start, uint count) external override returns (bytes32[] memory) {
    //     return bytes32[](0);
    // }
    // Set the warmup time for new followers: how many hours after becoming a follower can she comment? owner-only
    //change numHours to numSeconds
    function setWarmupTime(uint numSeconds) external override {
        require(msg.sender == owner && numSeconds != 0);
        warmupTime = numSeconds;
    }
    // Query the warmup time for new followers
    function getWarmupTime() external view override returns (uint) {
        return warmupTime;
    }
    // Start a new vote. owner-only. Can delete an old vote to save gas.
    function startVote(string memory detail, uint8 optionCount, uint8 voteConfig, uint endTime, uint64 deleteOldId) external override returns (uint64) {
        require(msg.sender == owner && endTime > block.timestamp);
        uint64 voteId = nextVoteId;
        if (deleteOldId < voteId) {
            //todo: deleteOldId may not end
            uint info = voteTable[deleteOldId];
            uint8 _optionCount = uint8(info);
            if (_optionCount != 0) {
                for (uint8 i = 0; i < _optionCount; i++) {
                    delete voteTallyTable[keccak256(abi.encode(deleteOldId << 8 | i))];
                }
            }
            delete voteTable[deleteOldId];
        }
        voteTable[voteId] = endTime << 16 | voteConfig << 8 | optionCount;
        emit StartVote(voteId, detail, optionCount, endTime);
        nextVoteId++;
        return voteId;
    }
    // Vote for an option. followers-only.
    //todo: optionId should be [0,optionCount)
    function vote(uint64 voteId, uint8 optionId, uint coinAmount) external override {
        require(isFollower(msg.sender));
        uint info = voteTable[voteId];
        uint64 endTime = uint64(info >> 16);
        uint8 config = uint8(info >> 8);
        uint8 optionCount = uint8(info);
        if (endTime != 0 && block.timestamp < endTime && optionId < optionCount) {
            //not like a on chain gov vote, pay coins is not refund to user, voteCoin may be address zero always;
            if ((config & 0x01 == 0x01) || voteCoin == address(0)) {
                voteTallyTable[keccak256(abi.encode(voteId << 8 | optionId))] += 1;
                emit Vote(msg.sender, voteId, optionId, 1);
            } else if (IERC20(voteCoin).transferFrom(msg.sender, owner, coinAmount)) {
                voteTallyTable[keccak256(abi.encode(voteId << 8 | optionId))] += coinAmount;
                emit Vote(msg.sender, voteId, optionId, coinAmount);
            }
        }
    }
    // Return the amounts of voted coins for each option.
    function getVoteResult(uint64 voteId) external view override returns (uint[] memory) {
        uint voteInfo = voteTable[voteId];
        //todo: not check if vote is end
        uint8 optionCount = uint8(voteInfo);
        require(optionCount != 0);
        uint[] memory tallyInfo = new uint[](optionCount);
        for (uint8 i = 0; i < optionCount; i++) {
            tallyInfo[i] = voteTallyTable[keccak256(abi.encode(voteId << 8 | i))];
        }
        return tallyInfo;
    }
    // Returns the Id of the next vote
    function getNextVoteId() external view override returns (uint64) {
        return nextVoteId;
    }

    // Publish a new Ad. owner-only. Can delete an old Ad to save gas and reclaim coins at the same time.
    function publishAd(string memory detail, uint numAudience, uint coinsPerAudience, address coinType, uint endTime, uint64 deleteOldId) external override returns (uint64) {
        //coinType should impl IERC20
        require(msg.sender == owner && endTime > block.timestamp && coinType != address(0));
        uint64 id = nextAdId;
        AdInfo memory info;
        info.coinType = coinType;
        info.numAudience = numAudience;
        info.coinsPerAudience = coinsPerAudience;
        info.endTime = uint64(endTime);
        adTable[id] = info;
        //todo: coinType == 0 => native coin
        require(IERC20(coinType).transferFrom(msg.sender, address(this), numAudience * coinsPerAudience));
        emit PublishAd(id, detail, numAudience, coinsPerAudience, coinType, endTime);
        if (deleteOldId < id) {
            AdInfo memory oldInfo = adTable[deleteOldId];
            if (oldInfo.endTime != 0) {
                //not check if old ad if end or not
                delete adTable[deleteOldId];
                //not check result
                IERC20(oldInfo.coinType).transfer(msg.sender, oldInfo.coinsPerAudience * oldInfo.numAudience);
            }
        }
        nextAdId++;
        return id;
    }
    // Click an Ad and express whether I am interested. followers-only
    function clickAd(uint id, bool interested) external override {
        require(isFollower(msg.sender));
        AdInfo memory info = adTable[uint64(id)];
        require(info.endTime > block.timestamp);
        if (!interested && info.numAudience > 0) {
            IERC20(info.coinType).transfer(msg.sender, info.coinsPerAudience);
            info.numAudience--;
            adTable[uint64(id)] = info;
        }
        emit ClickAd(uint64(id), msg.sender, interested);
    }
    // Delete an old Ad to save gas and reclaim coins
    function deleteAd(uint id) external override {
        require(msg.sender == owner);
        AdInfo memory oldInfo = adTable[uint64(id)];
        if (oldInfo.endTime != 0) {
            //not check if old ad if end or not
            delete adTable[uint64(id)];
            //not check result
            IERC20(oldInfo.coinType).transfer(msg.sender, oldInfo.coinsPerAudience * oldInfo.numAudience);
        }
    }
    // Returns the Id of the next Ad
    function getNextAdId() external view override returns (uint64) {
        return nextAdId;
    }

    function setVoteCoin(address coin) external {
        voteCoin = coin;
    }

    function getVoteCoin() external view returns (address) {
        return voteCoin;
    }

    function isFollower(address user) internal returns (bool) {
        bool _isFollower;
        if (followerTable[user] == true) {
            _isFollower = true;
        } else if (immatureFollowerTable[user] + warmupTime > block.timestamp) {
            _isFollower = true;
            followerTable[user] = true;
            delete immatureFollowerTable[user];
        }
        return _isFollower;
    }
}

contract Space {
    address private owner;
    address private chirp;

    constructor(address _owner, address _chirp){
        owner = _owner;
        chirp = _chirp;
    }

    receive() external payable {}

    fallback() payable external {
        address space = IRegistry(chirp).getSpaceLogic();
        assembly {
            let ptr := mload(0x40)
            let size := calldatasize()
            calldatacopy(ptr, 0, size)
            let result := delegatecall(gas(), space, ptr, size, 0, 0)
            size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
            case 0 {revert(ptr, size)}
            default {return (ptr, size)}
        }
    }
}
