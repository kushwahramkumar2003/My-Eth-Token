// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/HacksRK.sol";

contract HacksRKTest is Test {
    HacksRK public token;
    address public owner;
    address public user1;
    address public user2;
    
    uint256 public constant INITIAL_SUPPLY = 1000000 * 10**18;
    
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    event BlacklistUpdated(address indexed account, bool value);

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        
     
        token = new HacksRK(INITIAL_SUPPLY);
        
    
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }


    function testInitialSupply() public {
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
    }

    function testMinting() public {
        uint256 mintAmount = 1000 * 10**18;
        
        vm.expectEmit(true, false, false, true);
        emit TokensMinted(user1, mintAmount);
        
        token.mint(user1, mintAmount);
        assertEq(token.balanceOf(user1), mintAmount);
    }

    function testBurning() public {
        uint256 burnAmount = 1000 * 10**18;
        
        vm.expectEmit(true, false, false, true);
        emit TokensBurned(owner, burnAmount);
        
        token.burn(burnAmount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - burnAmount);
    }


    function testTransfer() public {
        uint256 transferAmount = 1000 * 10**18;
        
        token.transfer(user1, transferAmount);
        assertEq(token.balanceOf(user1), transferAmount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
    }

    function testTransferFrom() public {
        uint256 approveAmount = 1000 * 10**18;
        uint256 transferAmount = 500 * 10**18;
        
        token.approve(user1, approveAmount);
        
        vm.prank(user1);
        token.transferFrom(owner, user2, transferAmount);
        
        assertEq(token.balanceOf(user2), transferAmount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.allowance(owner, user1), approveAmount - transferAmount);
    }

   
    function testBlacklist() public {
        token.updateBlacklist(user1, true);
        assertTrue(token.blacklisted(user1));
        
        vm.expectRevert("Account is blacklisted");
        token.transfer(user1, 100);
        
        vm.expectRevert("Account is blacklisted");
        vm.prank(user1);
        token.transfer(user2, 100);
    }

    function testRemoveFromBlacklist() public {
        token.updateBlacklist(user1, true);
        token.updateBlacklist(user1, false);
        
        assertTrue(!token.blacklisted(user1));
        
       
        uint256 transferAmount = 100 * 10**18;
        token.transfer(user1, transferAmount);
        assertEq(token.balanceOf(user1), transferAmount);
    }

 
    function testPause() public {
        token.pause();
        
        vm.expectRevert("Pausable: paused");
        token.transfer(user1, 100);
        
        token.unpause();
        
       
        uint256 transferAmount = 100 * 10**18;
        token.transfer(user1, transferAmount);
        assertEq(token.balanceOf(user1), transferAmount);
    }


    function testFailMintToZeroAddress() public {
        token.mint(address(0), 100);
    }

    function testFailExceedMaxSupply() public {
        token.mint(user1, token.MAX_SUPPLY());
    }

    function testFailBlacklistOwner() public {
        token.updateBlacklist(owner, true);
    }

    function testFailTransferWhenPaused() public {
        token.pause();
        token.transfer(user1, 100);
    }

    function testFailInsufficientBalance() public {
        vm.prank(user1);
        token.transfer(user2, 1000000 * 10**18);
    }

    function testFailTransferFromWithoutApproval() public {
        vm.prank(user1);
        token.transferFrom(owner, user2, 100);
    }

 
    function testApproveAndAllowance() public {
        uint256 approveAmount = 1000 * 10**18;
        
        token.approve(user1, approveAmount);
        assertEq(token.allowance(owner, user1), approveAmount);
        
        vm.prank(user1);
        token.transferFrom(owner, user2, approveAmount / 2);
        assertEq(token.allowance(owner, user1), approveAmount / 2);
    }
}