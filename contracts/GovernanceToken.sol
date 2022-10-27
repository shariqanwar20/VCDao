// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/**
 * @dev Token for CrowdFundingDAO.
 * @notice For testing purposes, these can be minted at faucets.vcdao.netlify.app but later on you have to swap them in exchange for ETH.
 */

contract GovernanceToken is ERC20, ERC20Permit, ERC20Votes {
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint _maxSupply
    ) ERC20(_tokenname, _tokenSymbol) ERC20Permit(_tokenName) {
        _mint(msg.sender, _maxSupply);
    }

    function getMaxSupply() public view returns (uint256) {
        return s_maxSupply;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}
