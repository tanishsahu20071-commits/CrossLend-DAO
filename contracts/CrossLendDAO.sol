// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title CrossLend DAO
 * @notice A cross-chain-ready lending protocol with DAO governance
 *         - Deposit ERC20 collateral
 *         - Borrow stablecoins
 *         - Interest accrual
 *         - DAO voting for protocol parameters
 *         - Chain ID tracking for cross-chain expansion
 */

interface IERC20 {
    function transfer(address to, uint256 val) external returns (bool);
    function transferFrom(address from, address to, uint256 val) external returns (bool);
    function balanceOf(address user) external view returns (uint256);
}

contract CrossLendDAO {
    address public owner;
    uint256 public protocolInterestRate = 5; // 5% annual for simplicity

    struct Loan {
        address borrower;
        address collateralToken;
        uint256 collateralAmount;
        address borrowToken;
        uint256 borrowAmount;
        uint256 startBlock;
        bool active;
        uint256 chainId; // multi-chain extension
    }

    struct Proposal {
        uint256 id;
        string description;
        uint256 voteFor;
        uint256 voteAgainst;
        uint256 startBlock;
        uint256 endBlock;
        bool executed;
    }

    uint256 public loanCount;
    uint256 public proposalCount;

    mapping(uint256 => Loan) public loans;
    mapping(address => uint256[]) public userLoans;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public voted; // proposalID => voter => voted

    event LoanCreated(uint256 indexed id, address borrower, address collateralToken, uint256 collateralAmount, address borrowToken, uint256 borrowAmount);
    event LoanRepaid(uint256 indexed id, address borrower, uint256 repayAmount);
    event ProposalCreated(uint256 indexed id, string description, uint256 startBlock, uint256 endBlock);
    event Voted(uint256 indexed proposalId, address voter, bool support);
    event ProposalExecuted(uint256 indexed id, bool approved);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // ------------------------------------------------
    // LOAN FUNCTIONS
    // ------------------------------------------------
    function createLoan(
        address collateralToken,
        uint256 collateralAmount,
        address borrowToken,
        uint256 borrowAmount,
        uint256 chainId
    ) external returns (uint256) {
        require(collateralAmount > 0 && borrowAmount > 0, "Invalid amounts");
        IERC20(collateralToken).transferFrom(msg.sender, address(this), collateralAmount);

        loanCount++;
        loans[loanCount] = Loan({
            borrower: msg.sender,
            collateralToken: collateralToken,
            collateralAmount: collateralAmount,
            borrowToken: borrowToken,
            borrowAmount: borrowAmount,
            startBlock: block.number,
            active: true,
            chainId: chainId
        });

        userLoans[msg.sender].push(loanCount);

        IERC20(borrowToken).transfer(msg.sender, borrowAmount);

        emit LoanCreated(loanCount, msg.sender, collateralToken, collateralAmount, borrowToken, borrowAmount);
        return loanCount;
    }

    function repayLoan(uint256 loanId) external {
        Loan storage l = loans[loanId];
        require(l.active, "Loan inactive");
        require(l.borrower == msg.sender, "Not borrower");

        // simple interest: borrowAmount * interestRate * blocksPassed / 100 / blocksPerYear
        uint256 blocksPassed = block.number - l.startBlock;
        uint256 repayAmount = l.borrowAmount + (l.borrowAmount * protocolInterestRate * blocksPassed / (100 * 2102400)); // approx 2102400 blocks/year

        IERC20(l.borrowToken).transferFrom(msg.sender, address(this), repayAmount);
        IERC20(l.collateralToken).transfer(msg.sender, l.collateralAmount);

        l.active = false;
        emit LoanRepaid(loanId, msg.sender, repayAmount);
    }

    // ------------------------------------------------
    // DAO GOVERNANCE FUNCTIONS
    // ------------------------------------------------
    function createProposal(string memory description, uint256 durationBlocks) external returns (uint256) {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            description: description,
            voteFor: 0,
            voteAgainst: 0,
            startBlock: block.number,
            endBlock: block.number + durationBlocks,
            executed: false
        });

        emit ProposalCreated(proposalCount, description, block.number, block.number + durationBlocks);
        return proposalCount;
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage p = proposals[proposalId];
        require(block.number >= p.startBlock && block.number <= p.endBlock, "Voting closed");
        require(!voted[proposalId][msg.sender], "Already voted");

        voted[proposalId][msg.sender] = true;
        if (support) {
            p.voteFor += 1;
        } else {
            p.voteAgainst += 1;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(block.number > p.endBlock, "Voting not ended");
        require(!p.executed, "Already executed");

        bool approved = p.voteFor > p.voteAgainst;
        if (approved) {
            // Implement actual changes: interest rate update, new collateral type, etc.
        }

        p.executed = true;
        emit ProposalExecuted(proposalId, approved);
    }

    // ------------------------------------------------
    // VIEWERS
    // ------------------------------------------------
    function getUserLoans(address user) external view returns (uint256[] memory) {
        return userLoans[user];
    }

    function pendingInterest(uint256 loanId) external view returns (uint256) {
        Loan storage l = loans[loanId];
        if (!l.active) return 0;
        uint256 blocksPassed = block.number - l.startBlock;
        return (l.borrowAmount * protocolInterestRate * blocksPassed / (100 * 2102400));
    }
}
