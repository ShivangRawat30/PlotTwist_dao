// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address deployerKey;
    }
    NetworkConfig public activeNetworkConfig;
    address public FOUNDRY_DEFAULT_SENDER =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    constructor() {
        if(block.chainid == 84532) {
            activeNetworkConfig = baseEthSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function baseEthSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            deployerKey: 0x13a1C8eC74cb67AD1b828AAcC326a0031b5147cD
        });
    }

    function getOrCreateAnvilEthConfig() public view returns (NetworkConfig memory anvilNetworkConfig) {
        if(activeNetworkConfig.deployerKey != address(0)) {
            return activeNetworkConfig;
        }
        anvilNetworkConfig = NetworkConfig({
            deployerKey: FOUNDRY_DEFAULT_SENDER
        });
    }



}
