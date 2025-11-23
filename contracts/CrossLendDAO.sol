// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CrossLend DAO
 * @dev Decentralized Autonomous Organization for cross-chain lending governance
 */
contract CrossLendDAO {
    
    // Structs
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        mapping(address => bool) hasVoted;
    }
    
    struct Member {
        uint256 votingPower;
        uint256 joinedAt;
        bool isActive;
    }
    
    struct LendingPool {
        uint256 totalLiquidity;
        uint256 availableLiquidity;
        uint256 interestRate;
        bool isActive;
    }
    
    // State variables
    address public owner;
    uint256 public proposalCount;
    uint256 public memberCount;
    uint256 public totalVotingPower;
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public constant MIN_VOTING_POWER = 100;
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => Member) public members;
    mapping(uint256 => LendingPool) public lendingPools;
    
    // Events
    event MemberJoined(address indexed member, uint256 votingPower);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCasted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event LiquidityAdded(uint256 indexed poolId, address indexed provider, uint256 amount);
    event LiquidityRemoved(uint256 indexed poolId, address indexed provider, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyMember() {
        require(members[msg.sender].isActive, "Only active members can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        members[msg.sender] = Member({
            votingPower: 1000,
            joinedAt: block.timestamp,
            isActive: true
        });
        memberCount = 1;
        totalVotingPower = 1000;
    }
    
    /**
     * @dev Function 1: Join the DAO as a member
     * @param _votingPower Initial voting power for the member
     */
    function joinDAO(uint256 _votingPower) external {
        require(!members[msg.sender].isActive, "Already a member");
        require(_votingPower >= MIN_VOTING_POWER, "Voting power too low");
        
        members[msg.sender] = Member({
            votingPower: _votingPower,
            joinedAt: block.timestamp,
            isActive: true
        });
        
        memberCount++;
        totalVotingPower += _votingPower;
        
        emit MemberJoined(msg.sender, _votingPower);
    }
    
    /**
     * @dev Function 2: Create a new proposal
     * @param _description Description of the proposal
     */
    function createProposal(string memory _description) external onlyMember returns (uint256) {
        proposalCount++;
        
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + VOTING_PERIOD;
        newProposal.executed = false;
        
        emit ProposalCreated(proposalCount, msg.sender, _description);
        
        return proposalCount;
    }
    
    /**
     * @dev Function 3: Vote on a proposal
     * @param _proposalId ID of the proposal
     * @param _support True for yes, false for no
     */
    function vote(uint256 _proposalId, bool _support) external onlyMember {
        Proposal storage proposal = proposals[_proposalId];
        
        require(block.timestamp >= proposal.startTime, "Voting has not started");
        require(block.timestamp <= proposal.endTime, "Voting has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(!proposal.executed, "Proposal already executed");
        
        uint256 votingPower = members[msg.sender].votingPower;
        
        if (_support) {
            proposal.forVotes += votingPower;
        } else {
            proposal.againstVotes += votingPower;
        }
        
        proposal.hasVoted[msg.sender] = true;
        
        emit VoteCasted(_proposalId, msg.sender, _support, votingPower);
    }
    
    /**
     * @dev Function 4: Execute a proposal after voting period
     * @param _proposalId ID of the proposal
     */
    function executeProposal(uint256 _proposalId) external onlyMember {
        Proposal storage proposal = proposals[_proposalId];
        
        require(block.timestamp > proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");
        
        bool passed = proposal.forVotes > proposal.againstVotes;
        proposal.executed = true;
        
        emit ProposalExecuted(_proposalId, passed);
    }
    
    /**
     * @dev Function 5: Add liquidity to a lending pool
     * @param _poolId ID of the lending pool
     */
    function addLiquidity(uint256 _poolId) external payable {
        require(msg.value > 0, "Must send ETH");
        
        LendingPool storage pool = lendingPools[_poolId];
        
        if (!pool.isActive) {
            pool.isActive = true;
            pool.interestRate = 5; // 5% default interest rate
        }
        
        pool.totalLiquidity += msg.value;
        pool.availableLiquidity += msg.value;
        
        emit LiquidityAdded(_poolId, msg.sender, msg.value);
    }
    
    /**
     * @dev Function 6: Remove liquidity from a lending pool
     * @param _poolId ID of the lending pool
     * @param _amount Amount to withdraw
     */
    function removeLiquidity(uint256 _poolId, uint256 _amount) external onlyMember {
        LendingPool storage pool = lendingPools[_poolId];
        
        require(pool.isActive, "Pool not active");
        require(_amount <= pool.availableLiquidity, "Insufficient liquidity");
        
        pool.availableLiquidity -= _amount;
        pool.totalLiquidity -= _amount;
        
        payable(msg.sender).transfer(_amount);
        
        emit LiquidityRemoved(_poolId, msg.sender, _amount);
    }
    
    /**
     * @dev Function 7: Update member voting power
     * @param _member Address of the member
     * @param _newVotingPower New voting power
     */
    function updateVotingPower(address _member, uint256 _newVotingPower) external onlyOwner {
        require(members[_member].isActive, "Member not active");
        
        uint256 oldPower = members[_member].votingPower;
        members[_member].votingPower = _newVotingPower;
        
        totalVotingPower = totalVotingPower - oldPower + _newVotingPower;
    }
    
    /**
     * @dev Function 8: Get proposal details
     * @param _proposalId ID of the proposal
     */
    function getProposal(uint256 _proposalId) external view returns (
        uint256 id,
        address proposer,
        string memory description,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 startTime,
        uint256 endTime,
        bool executed
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.startTime,
            proposal.endTime,
            proposal.executed
        );
    }
    
    /**
     * @dev Function 9: Get member details
     * @param _member Address of the member
     */
    function getMember(address _member) external view returns (
        uint256 votingPower,
        uint256 joinedAt,
        bool isActive
    ) {
        Member storage member = members[_member];
        return (member.votingPower, member.joinedAt, member.isActive);
    }
    
    /**
     * @dev Function 10: Get lending pool details
     * @param _poolId ID of the lending pool
     */
    function getLendingPool(uint256 _poolId) external view returns (
        uint256 totalLiquidity,
        uint256 availableLiquidity,
        uint256 interestRate,
        bool isActive
    ) {
        LendingPool storage pool = lendingPools[_poolId];
        return (
            pool.totalLiquidity,
            pool.availableLiquidity,
            pool.interestRate,
            pool.isActive
        );
    }
}