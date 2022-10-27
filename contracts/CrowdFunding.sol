// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Project.sol";

/**
 * Propose a project (name, website, logo, prject description, prospects, fund amount, formula: numOfTokens to issue in exchange for 1ETH, dao details)
 * Fund a project (projectId, amount) - become a member of the project's DAO if enough num of tokens
 * Funding complete - DAO created, members added
 */
contract CrowdFunding is Ownable {
    Project[] private s_projects;

    event ProjectCreated(
        address indexed contractAddress,
        address indexed creator,
        string projectTitle,
        string projectDesc,
        uint256 deadline,
        uint256 goalAmount
    );

    /**
     * @dev This is called by the CrowdFundingDAO, once the voters have agreed to add this project into active list
     */
    function createProject(
        string memory title,
        string memory description,
        uint durationInDays
    ) public onlyOwner {
        uint fundRaisingDeadline = block.timestamp.add(
            durationInDays.mul(1 days)
        );

        Project project = new Project(
            msg.sender,
            title,
            description,
            fundRaisingDeadline
        );
        emit ProjectCreated(
            address(project),
            msg.sender,
            title,
            description,
            goalAmount,
            fundRaisingDeadline
        );
    }

    function getActiveProjects() public view returns (Project[] memory) {
        return s_projects;
    }
}
