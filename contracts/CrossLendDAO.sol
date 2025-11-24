Structs
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
    
    Events
    event MemberJoined(address indexed member, uint256 votingPower);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCasted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event LiquidityAdded(uint256 indexed poolId, address indexed provider, uint256 amount);
    event LiquidityRemoved(uint256 indexed poolId, address indexed provider, uint256 amount);
    
    5% default interest rate
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
// 
End
// 
