// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {PlotTwistToken} from "../src/PlotTwistToken.sol";
import {PlotTwistDAO} from "../src/PlotTwistDAO.sol";

contract DeployDAO is Script {
    function run() external returns(PlotTwistDAO, PlotTwistToken, HelperConfig) {
        HelperConfig  helperConfig = new HelperConfig();
        (address deployer) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployer);
        PlotTwistToken token = new PlotTwistToken();
        PlotTwistDAO dao = new PlotTwistDAO(address(token));
        token.transferOwnership(address(dao));
        vm.stopBroadcast();
        return (dao, token, helperConfig);
    }
}