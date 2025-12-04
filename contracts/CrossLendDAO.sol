// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title CrossLend DAO
 * @notice A decentralized lending DAO where members can submit lending proposals,
 *         vote, and approve funds for borrowers in a democratic, trustless manner.
 */

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract CrossLendDAO {
    address public owner;
    IERC20 public lendingToken;

    struct Member {
        bool isMember;
    }

    struct Proposal {
        uint256 id;
        address proposer;
        address borrower;
        uint256 amount;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool executed;
    }

    uint256 public proposalCount;
    mapping(address => Member) public members;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event MemberAdded(address indexed member);
    event ProposalCreated(uint256 indexed proposalId, address proposer, address borrower, uint256 amount);
    event Voted(uint256 indexed proposalId, address voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isMember, "Not a DAO member");
        _;
    }

    constructor(address _lendingToken) {
        owner = msg.sender;
        lendingToken = IERC20(_lendingToken);
    }

    /** Add a new DAO member */
    function addMember(address newMember) external onlyOwner {
        require(newMember != address(0), "Invalid address");
        members[newMember].isMember = true;
        emit MemberAdded(newMember);
    }

    /** Create a lending proposal */
    function createProposal(address borrower, uint256 amount, uint256 votingDuration) external onlyMember {
        require(borrower != address(0), "Invalid borrower");
        require(amount > 0, "Amount > 0");

        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            borrower: borrower,
            amount: amount,
            votesFor: 0,
            votesAgainst: 0,
            deadline: block.timestamp + votingDuration,
            executed: false
        });

        emit ProposalCreated(proposalCount, msg.sender, borrower, amount);
    }

    /** Vote on a proposal */
    function vote(uint256 proposalId, bool support) external onlyMember {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp <= proposal.deadline, "Voting ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    /** Execute proposal if majority votes in favor */
    function executeProposal(uint256 proposalId) external onlyMember {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.deadline, "Voting not ended");
        require(!proposal.executed, "Already executed");

        proposal.executed = true;

        bool approved = proposal.votesFor > proposal.votesAgainst;

        if (approved && lendingToken.transfer(proposal.borrower, proposal.amount)) {
            emit ProposalExecuted(proposalId, true);
        } else {
            emit ProposalExecuted(proposalId, false);
        }
    }

    /** View DAO member status */
    function isMember(address addr) external view returns (bool) {
        return members[addr].isMember;
    }

    /** Get proposal details */
    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        return proposals[proposalId];
    }
}
