// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {PlotTwistDAO} from "../src/PlotTwistDAO.sol";
import {PlotTwistToken} from "../src/PlotTwistToken.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {DeployDAO} from "../script/DeployDAO.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract PlotTwistDAOTest is Test {
    error PlotTwistDAO__InsufficientAmount();
    error PlotTwistDAO__NotSubscribed();

    PlotTwistDAO public dao;
    PlotTwistToken public token;
    DeployDAO public deployer;
    HelperConfig public helperConfig;

    uint256 public startingBalance = 2 ether;
    address public admin = makeAddr("admin");
    string public userOneName = "Shivang";
    address public userOne = makeAddr("One");
    string public userTwoName = "Ramneek";
    address public userTwo = makeAddr("Two");

    uint256 public constant USER_SUB_DURATION = 60 * 60 * 24 * 30;
    uint256 private constant VOTING_START_TIME = 24 * 60 * 60; // 1 day
    uint256 private constant VOTING_ENDING_TIME = 24 * 60 * 60 * 3; // 3 days

    function setUp() external {
        deployer = new DeployDAO();
        (dao, token, helperConfig) = deployer.run();

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

    function testUserGetsDiamondSub() public {
        vm.prank(userOne);
        uint256 expectedTime = block.timestamp + USER_SUB_DURATION;
        dao.createOwner{value: 0.01 * 1e18}(userOneName);
        string memory expectedName = "Shivang";
        string memory actualName = dao.getBuyerName(address(userOne));
        uint256 subTier = uint256(dao.getBuyerTier(address(userOne)));
        uint256 actualTokenAmount = dao.getBuyerTokenAmount(address(userOne));
        uint256 actualTime = dao.getBuyerEndingTime(address(userOne));

        assertEq(expectedName, actualName);
        assertEq(subTier, 3);
        assertEq(actualTokenAmount, 100 ether);
        assertEq(expectedTime, actualTime);
    }

    function testRetunsWhenUserDoesNotHaveSub() public {
        vm.prank(address(1));
        vm.expectRevert(PlotTwistDAO.PlotTwistDAO__NotSubscribed.selector);
        dao.createProposal("hello", "everyone");
    }

    function testProposalInfo() public {
        vm.startPrank(userOne);
        dao.createOwner{value: 0.01 * 1e18}(userOneName);
        token.approve(address(dao), 5 ether);
        uint256 expectedExecTime = block.timestamp;
        uint256 expectedVT = block.timestamp + VOTING_START_TIME;
        uint256 expectedET = block.timestamp + VOTING_ENDING_TIME;
        dao.createProposal("hello", "everyone");
        vm.stopPrank();
        assertEq(userOne, dao.getPropsalOwner(1));
        assertEq(1, dao.getProposalId(1));
        assertEq("hello", dao.getProposalTitle(1));
        assertEq("everyone", dao.getProposalDescription(1));
        assertEq(expectedExecTime, dao.getProposalExecutionTime(1));
        assertEq(expectedVT, dao.getProposalVotingStartTime(1));
        assertEq(expectedET, dao.getProposalVotingEndTime(1));
        assertEq(0, dao.getProposalVotesFor(1));
        assertEq(0, dao.getProposalVotesAgainst(1));
        assertEq(1, uint256(dao.getProposalStatus(1)));
        assertEq(95 ether, dao.getBuyerTokenAmount(userOne));
    }

    function testUserUpvotesProposal() public {
        vm.startPrank(userOne);
        dao.createOwner{value: 0.01 * 1e18}(userOneName);
        token.approve(address(dao), 5 ether);
        dao.createProposal("hello", "everyone");
        vm.warp(block.timestamp + VOTING_START_TIME + 1);
        vm.roll(block.number + 1);
        token.approve(address(dao), 3 ether);
        dao.upvote(1);
        uint256 actualAmount = dao.getBuyerTokenAmount(userOne);
        vm.stopPrank();
        uint256 expectedAmount = 92 ether;
        assertEq(1, uint256(dao.getVote(1, userOne)));
        assertEq(3, dao.getProposalVotesFor(1));
        assertEq(3, dao.getProposalTotalVotes(1));
        assertEq(actualAmount, expectedAmount);
    }

    function testUserDownvotesProposal() public {
        vm.startPrank(userOne);
        dao.createOwner{value: 0.01 * 1e18}(userOneName);
        token.approve(address(dao), 5 ether);
        dao.createProposal("hello", "everyone");
        vm.warp(block.timestamp + VOTING_START_TIME + 1);
        vm.roll(block.number + 1);
        token.approve(address(dao), 3 ether);
        dao.downvote(1);
        uint256 actualAmount = dao.getBuyerTokenAmount(userOne);
        vm.stopPrank();
        uint256 expectedAmount = 92 ether;
        assertEq(2, uint256(dao.getVote(1, userOne)));
        assertEq(3, dao.getProposalVotesAgainst(1));
        assertEq(3, dao.getProposalTotalVotes(1));
        assertEq(actualAmount, expectedAmount);
    }

    function testEndingTheProposal() public {
        console.log("deployer: ", address(deployer));
        vm.startPrank(userOne);
        dao.createOwner{value: 0.01 * 1e18}(userOneName);
        token.approve(address(dao), 5 ether);
        dao.createProposal("hello", "everyone");
        vm.warp(block.timestamp + VOTING_START_TIME + 1);
        vm.roll(block.number + 1);
        vm.stopPrank();
        for (uint256 i = 1; i < 11; i++) {
            vm.deal(address(uint160(i)), startingBalance);
            vm.startPrank(address(uint160(i)));
            string memory name = Strings.toString(i);
            dao.createOwner{value: 0.01 ether}(name);
            token.approve(address(dao), 3 ether);
            dao.upvote(1);
            vm.stopPrank();
        }
        vm.warp(block.timestamp + VOTING_ENDING_TIME + 1);
        vm.roll(block.number + 1);
        vm.startPrank(userOne);
        dao.endProposal(1);
        assertEq(2, uint256(dao.getProposalStatus(1)));
        assertEq(30, dao.getProposalTotalVotes(1));
        dao.actProposal(1);
        assertEq(3, uint256(dao.getProposalStatus(1)));
    }

    function testFaiedProposal() public {
        vm.startPrank(userOne);
        dao.createOwner{value: 0.01 * 1e18}(userOneName);
        token.approve(address(dao), 5 ether);
        dao.createProposal("hello", "everyone");
        vm.warp(block.timestamp + VOTING_START_TIME + 1);
        vm.roll(block.number + 1);
        vm.stopPrank();
        for (uint256 i = 1; i < 11; i++) {
            vm.deal(address(uint160(i)), startingBalance);
            vm.startPrank(address(uint160(i)));
            string memory name = Strings.toString(i);
            dao.createOwner{value: 0.01 ether}(name);
            token.approve(address(dao), 3 ether);
            dao.downvote(1);
            vm.stopPrank();
        }
        vm.warp(block.timestamp + VOTING_ENDING_TIME + 1);
        vm.roll(block.number + 1);
        vm.startPrank(userOne);
        dao.endProposal(1);
        assertEq(4, uint256(dao.getProposalStatus(1)));
        assertEq(30, dao.getProposalTotalVotes(1));
    }

    function testCancelledProposal() public {
        vm.startPrank(userOne);
        dao.createOwner{value: 0.01 * 1e18}(userOneName);
        token.approve(address(dao), 5 ether);
        dao.createProposal("hello", "everyone");
        vm.warp(block.timestamp + VOTING_START_TIME + 1);
        vm.roll(block.number + 1);
        vm.stopPrank();
        for (uint256 i = 1; i < 2; i++) {
            vm.deal(address(uint160(i)), startingBalance);
            vm.startPrank(address(uint160(i)));
            string memory name = Strings.toString(i);
            dao.createOwner{value: 0.01 ether}(name);
            token.approve(address(dao), 3 ether);
            dao.downvote(1);
            vm.stopPrank();
        }
        vm.warp(block.timestamp + VOTING_ENDING_TIME + 1);
        vm.roll(block.number + 1);
        vm.startPrank(userOne);
        dao.endProposal(1);
        assertEq(5, uint256(dao.getProposalStatus(1)));
        assertEq(3, dao.getProposalTotalVotes(1));
    }
}
