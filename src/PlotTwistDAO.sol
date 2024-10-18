// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {PlotTwistToken} from "./PlotTwistToken.sol";

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

contract PlotTwistDAO {
    error PlotTwistDAO__InsufficientAmount();
    error PlotTwistDAO__Mintfailed();

    enum SubTier {
        None,
        Silver,
        Gold,
        Diamond
    }

    struct buyerStruct {
        string name;
        SubTier tier;
        uint256 endingTime;
        uint256 TokenAmount;
    }

    PlotTwistToken private i_btt;
    uint256 private constant SILVER_AMOUNT = 0.003 ether;
    uint256 private constant GOLD_AMOUNT = 0.007 ether;
    uint256 private constant DIAMOND_AMOUNT = 0.01 ether;
    uint256 private constant USER_SUB_DURATION = 60 * 60 * 24 * 30; // 30 days
    mapping(address owner => buyerStruct) private s_buyInfo;

    //////////////////
    /// FUNCTIONS ///
    /////////////////
    constructor(address pttAddress) {
        i_btt = PlotTwistToken(pttAddress);
    }

    modifier notSubscriptionAmount(uint256 amount) {
        if (amount != SILVER_AMOUNT || amount != GOLD_AMOUNT || amount != DIAMOND_AMOUNT) {
            revert PlotTwistDAO__InsufficientAmount();
        }
        _;
    }

    function createOwner(string memory name) external payable notSubscriptionAmount(msg.value) {
        if (msg.value == DIAMOND_AMOUNT) {
            uint256 mintAmount = 100;
            s_buyInfo[msg.sender] = buyerStruct({
                name: name,
                tier: SubTier.Diamond,
                endingTime: currentTime() + USER_SUB_DURATION,
                TokenAmount: 0
            });
            _mintPtt(msg.sender, mintAmount);
        } else if (msg.value == GOLD_AMOUNT) {
            uint256 mintAmount = 50;
            s_buyInfo[msg.sender] = buyerStruct({
                name: name,
                tier: SubTier.Gold,
                endingTime: currentTime() + USER_SUB_DURATION,
                TokenAmount: 0
            });
            _mintPtt(msg.sender, mintAmount);
        } else {
            uint256 mintAmount = 20;
            s_buyInfo[msg.sender] = buyerStruct({
                name: name,
                tier: SubTier.Silver,
                endingTime: currentTime() + USER_SUB_DURATION,
                TokenAmount: 0
            });
            _mintPtt(msg.sender, mintAmount);
        }
    }

    function _mintPtt(address to, uint256 mintAmount) internal {
        s_buyInfo[to].TokenAmount += mintAmount;
        bool minted = i_btt.mint(to, mintAmount);

        if (!minted) {
            revert PlotTwistDAO__Mintfailed();
        }
    }

    function currentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function getTokenAddress() public view returns (address) {
        return address(i_btt);
    }
}
