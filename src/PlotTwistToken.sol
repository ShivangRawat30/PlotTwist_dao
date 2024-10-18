// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PlotTwistToken is ERC20, Ownable {
    constructor() ERC20("PlotTwistToken", "PTT") Ownable(msg.sender) {}

    error PlotTwistToken__NotZeroAddress();
    error PlotTwistToken__MustBeMoreThenZero();

    function mint(address account, uint256 amount) external onlyOwner returns (bool) {
        if (account == address(0)) {
            revert PlotTwistToken__NotZeroAddress();
        }
        if (amount <= 0) {
            revert PlotTwistToken__MustBeMoreThenZero();
        }
        _mint(account, amount);
        return true;
    }
}