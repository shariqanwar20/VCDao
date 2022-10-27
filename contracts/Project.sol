// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

error Project__IncorrectState();
error Project__CreatorCannotFundHisProject();
error Project__FundingNotExpired();
error Project__FundsNotGiven();
error Project__FailedToSendFunds();
error Project__AmountExceedsLimit();

contract Project {
    enum State {
        FUNDRAISING,
        SUCCESS,
        EXPIRED,
        CLOSED
    }

    // For testing pruposes. Will be changed to a higher number
    uint constant MIN_FUNDERS = 2;
    address payable private immutable i_creator;
    address private immutable i_token;
    uint private immutable i_id;
    uint private immutable i_tokensToIssue;
    string private s_title;
    string private s_description;
    uint private s_fundingRound;
    uint private s_goalAmount;
    uint private s_rasieBy;
    uint private s_currentBalance;
    uint private s_maxAmountToInvest;
    State private s_state = State.CLOSED;

    mapping(address => uint) contributedFunds;

    event ClaimTokens(address indexed to, uint amount);

    event FundsContributed(
        address indexed sender,
        address indexed contractAddress,
        uint amount
    );

    event AmountRefunded(address indexed to, uint amount);

    event FundingSuccess(
        uint indexed projectId,
        address indexed projectToken,
        uint round
    );

    modifier isState(State _state) {
        if (s_state != _state) {
            revert Project__IncorrectState();
        }
        _;
    }

    constructor(
        address creator,
        address token,
        uint id,
        uint tokenToIssue,
        string memory title,
        string memory description,
        uint fundRaisingDeadline
    ) {
        i_creator = payable(creator);
        i_token = token;
        i_tokensToIssue = tokenToIssue;
        s_title = title;
        i_id = id;
        s_description = description;
        s_rasieBy = fundRaisingDeadline;
        s_state = State.FUNDRAISING;
        s_fundingRound = 1;
        s_goalAmount = s_fundingRound * 1000;
        s_currentBalance = 0;
        s_maxAmountToInvest = Math.ceilDiv(s_goalAmount, MIN_FUNDERS);
    }

    /**
     * @dev gather funds to meet the goal before deadline. Creator is not allowed to fund his project. For intial rounds, funders can only give a certain max
     * amount which would be changed to any amount after certain number of rounds
     */
    function contribute() public payable isState(State.FUNDRAISING) {
        if (msg.sender != i_creator)
            revert Project__CreatorCannotFundHisProject();
        if (contributedFunds[msg.sender] + msg.value > s_maxAmountToInvest)
            revert Project__AmountExceedsLimit();

        contributedFunds[msg.sender] += msg.value;
        s_currentBalance += msg.value;
        emit FundsContributed(msg.sender, address(this), msg.value);
        checkIfFundingCompletedOrExpired();
    }

    function checkIfFundingCompletedOrExpired() public {
        if (s_currentBalance >= s_goalAmount) {
            s_state = State.SUCCESS;
            emit FundingSuccess(i_id, i_token, s_fundingRound);
        } else if (block.timestamp > s_rasieBy) {
            s_state = State.EXPIRED;
        }
    }

    /**
     * @dev start successive funding rounds after majority funders agree to it
     */
    function initiateFundingRound() public isState(State.CLOSED) {}

    function payOut() internal isState(State.SUCCESS) returns (bool) {
        (bool callSuccess, ) = i_creator.call{value: s_currentBalance}("");
        if (!callSuccess) revert Project__FailedToSendFunds();

        s_currentBalance = 0;
        s_state = State.CLOSED;
        return true;
    }

    /**
     * @dev investor recieves a proportion of Project's tokens based on amount funded
     * @notice assume the Project token is already deployed
     *
     * SUGGESTION: We can mint the relevant project tokens here and issue it to investor
     */
    function claimTokens() public isState(State.SUCCESS) returns (bool) {
        if (contributedFunds[msg.sender] == 0) revert Project__FundsNotGiven();

        uint tokens = (contributedFunds[msg.sender] / s_goalAmount) *
            i_tokensToIssue;
        contributedFunds[msg.sender] = 0;

        IERC20(i_token).transfer(msg.sender, tokens);
        emit ClaimTokens(msg.sender, tokens);
        return true;
    }

    function getRefund() public isState(State.EXPIRED) returns (bool) {
        if (block.timestamp < s_rasieBy) revert Project__FundingNotExpired();
        if (contributedFunds[msg.sender] == 0) revert Project__FundsNotGiven();

        uint amountToRefund = contributedFunds[msg.sender];
        (bool callSuccess, ) = msg.sender.call{value: amountToRefund}("");
        if (!callSuccess) revert Project__FailedToSendFunds();

        contributedFunds[msg.sender] = 0;
        s_currentBalance -= amountToRefund;
        emit AmountRefunded(msg.sender, amountToRefund);
        return true;
    }

    function getDetails()
        public
        view
        returns (
            address payable projectStarter,
            string memory projectTitle,
            string memory projectDescription,
            uint projectId,
            uint goalAmount,
            uint deadline,
            uint amountRaised,
            uint fundingRound,
            State currentState
        )
    {
        projectStarter = i_creator;
        projectTitle = s_title;
        projectDescription = s_description;
        projectId = i_id;
        goalAmount = s_goalAmount;
        deadline = s_rasieBy;
        amountRaised = s_currentBalance;
        fundingRound = s_fundingRound;
        currentState = s_state;
    }
}
