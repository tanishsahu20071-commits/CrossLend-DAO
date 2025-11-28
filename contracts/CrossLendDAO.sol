5% annual for simplicity

    struct Loan {
        address borrower;
        address collateralToken;
        uint256 collateralAmount;
        address borrowToken;
        uint256 borrowAmount;
        uint256 startBlock;
        bool active;
        uint256 chainId; proposalID => voter => voted

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

    LOAN FUNCTIONS
    simple interest: borrowAmount * interestRate * blocksPassed / 100 / blocksPerYear
        uint256 blocksPassed = block.number - l.startBlock;
        uint256 repayAmount = l.borrowAmount + (l.borrowAmount * protocolInterestRate * blocksPassed / (100 * 2102400)); ------------------------------------------------
    ------------------------------------------------
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
            ------------------------------------------------
    ------------------------------------------------
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
// 
Contract End
// 
