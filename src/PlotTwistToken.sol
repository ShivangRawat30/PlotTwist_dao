// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PlotTwistToken is ERC20Burnable, Ownable {
    constructor() ERC20("PlotTwistToken", "PTT") Ownable(msg.sender) {}

    error PlotTwistToken__NotZeroAddress();
    error PlotTwistToken__MustBeMoreThenZero();
    error PlotTwistToken__BurnAmountExceedsBalance(address sender, uint256 balance);

    function mint(address account, uint256 amount) external returns (bool) {
        if (account == address(0)) {
            revert PlotTwistToken__NotZeroAddress();
        }
        if (amount <= 0) {
            revert PlotTwistToken__MustBeMoreThenZero();
        }
        _mint(account, amount);
        return true;
    }

    function burn(uint256 amount) public override {
        uint256 balance = balanceOf(msg.sender);
        if (amount <= 0) {
            revert PlotTwistToken__MustBeMoreThenZero();
        }
        if (balance < amount) {
            revert PlotTwistToken__BurnAmountExceedsBalance(msg.sender, balance);
        }
        super.burn(amount);
    }
}
