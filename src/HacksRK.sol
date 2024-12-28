// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title HacksRK Token
 * @dev Implementation of the HacksRK Token with additional security features
 */
contract HacksRK is ERC20, Ownable, Pausable, ReentrancyGuard {
    // Events
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    event BlacklistUpdated(address indexed account, bool value);

    // State variables
    mapping(address => bool) public blacklisted;
    uint256 public constant MAX_SUPPLY = 1000000000 * 10**18; // 1 billion tokens
    uint256 public immutable initialSupply;

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     * @param _initVal The initial supply to mint to the contract creator
     */
    constructor(uint256 _initVal) ERC20("HacksRK", "HRK") Ownable(msg.sender) {
        require(_initVal <= MAX_SUPPLY, "Initial supply exceeds maximum supply");
        _mint(msg.sender, _initVal);
        initialSupply = _initVal;
    }

    /**
     * @dev Modifier to check if an address is not blacklisted
     */
    modifier notBlacklisted(address account) {
        require(!blacklisted[account], "Account is blacklisted");
        _;
    }

    /**
     * @dev Mints new tokens to the specified address
     * @param to The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) 
        public 
        onlyOwner 
        whenNotPaused 
        nonReentrant 
    {
        require(to != address(0), "Cannot mint to zero address");
        require(totalSupply() + amount <= MAX_SUPPLY, "Would exceed max supply");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /**
     * @dev Burns tokens from the caller's address
     * @param amount The amount of tokens to burn
     */
    function burn(uint256 amount) 
        public 
        whenNotPaused 
        nonReentrant 
    {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    /**
     * @dev Adds or removes an address from the blacklist
     * @param account The address to update
     * @param value True to blacklist, false to remove from blacklist
     */
    function updateBlacklist(address account, bool value) 
        external 
        onlyOwner 
    {
        require(account != address(0), "Cannot blacklist zero address");
        require(account != owner(), "Cannot blacklist owner");
        blacklisted[account] = value;
        emit BlacklistUpdated(account, value);
    }

    /**
     * @dev Pauses all token transfers
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Override of the transfer function to add blacklist check
     */
    function transfer(address to, uint256 amount)
        public
        override
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(to)
        returns (bool)
    {
        return super.transfer(to, amount);
    }

    /**
     * @dev Override of the transferFrom function to add blacklist check
     */
    function transferFrom(address from, address to, uint256 amount)
        public
        override
        whenNotPaused
        notBlacklisted(from)
        notBlacklisted(to)
        returns (bool)
    {
        return super.transferFrom(from, to, amount);
    }

    /**
     * @dev Override of the approve function to add blacklist check
     */
    function approve(address spender, uint256 amount)
        public
        override
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(spender)
        returns (bool)
    {
        return super.approve(spender, amount);
    }
}