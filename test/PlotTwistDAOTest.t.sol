// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Test, console } from "forge-std/Test.sol";
import {PlotTwistDAO} from "../src/PlotTwistDAO.sol";
import {PlotTwistToken} from "../src/PlotTwistToken.sol";

contract PlotTwistDAOTest is Test {
    error PlotTwistDAO__InsufficientAmount();
    PlotTwistDAO public dao;
    PlotTwistToken public token;

    uint256 public startingBalance = 2 ether;
    address public admin = makeAddr("admin");
    string public userOneName = "Shivang"; 
    address public userOne = makeAddr("One");
    string public userTwoName = "Ramneek"; 
    address public userTwo = makeAddr("Two");


    function setUp() external {
        vm.startBroadcast(admin);
        token = new PlotTwistToken();
        dao = new PlotTwistDAO(address(token));
        vm.stopBroadcast();

        vm.deal(userOne, startingBalance);
        vm.deal(userTwo, startingBalance);
        vm.deal(admin, startingBalance);
    }

    function testTheDAOTokenIsCorrect() public view {
        assertEq(dao.getTokenAddress(), address(token));
    }

    function testInSuffiecientTokenAmount() public {
        vm.prank(userOne);
        vm.expectRevert(PlotTwistDAO.PlotTwistDAO__InsufficientAmount.selector);
        dao.createOwner{value: 0.1 ether}(userOneName);
    }

}