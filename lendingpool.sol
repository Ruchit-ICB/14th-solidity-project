// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LendingPool {
    address public owner;
    uint public interestRate = 5; // 5% interest (flat)

    struct Loan {
        address borrower;
        uint collateral;
        uint loanAmount;
        uint dueTime;
        bool repaid;
    }

    mapping(address => Loan) public loans;

    constructor() {
        owner = msg.sender;
    }

    // Users can lend ETH to the pool
    receive() external payable {}

    /// Borrow ETH by locking 2x collateral
    function borrow() external payable {
        require(loans[msg.sender].loanAmount == 0, "Loan already exists");
        require(msg.value > 0, "Collateral required");

        uint borrowAmount = msg.value / 2;
        require(address(this).balance >= borrowAmount, "Insufficient liquidity");

        loans[msg.sender] = Loan({
            borrower: msg.sender,
            collateral: msg.value,
            loanAmount: borrowAmount,
            dueTime: block.timestamp + 3 days,
            repaid: false
        });

        payable(msg.sender).transfer(borrowAmount);
    }

    /// Repay the loan with interest
    function repay() external payable {
        Loan storage loan = loans[msg.sender];
        require(!loan.repaid, "Already repaid");
        require(block.timestamp <= loan.dueTime, "Loan overdue");
        require(loan.loanAmount > 0, "No active loan");

        uint interest = (loan.loanAmount * interestRate) / 100;
        uint totalDue = loan.loanAmount + interest;
        require(msg.value == totalDue, "Incorrect repayment amount");

        loan.repaid = true;
        payable(msg.sender).transfer(loan.collateral); // Return collateral
    }

    /// Liquidate loan if not repaid in time
    function liquidate(address user) external {
        Loan storage loan = loans[user];
        require(!loan.repaid, "Already repaid");
        require(block.timestamp > loan.dueTime, "Loan not overdue");

        loan.repaid = true;
        // Collateral is kept by contract as penalty
    }

    /// Withdraw protocol profits (interest + liquidated collateral)
    function withdraw(uint amount) external {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(amount);
    }

    function getLoan(address user) external view returns (
        uint collateral, uint loanAmount, uint dueTime, bool repaid
    ) {
        Loan storage l = loans[user];
        return (l.collateral, l.loanAmount, l.dueTime, l.repaid);
    }
}
