// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {MyOApp} from "../../src/layerzero/MyOApp.sol";
import {Helper} from "./Helper.sol";

/// @title LayerZero OApp Peer Configuration Script
/// @notice Sets up peer connections between OApp deployments on different chains
contract SetPeers is Script, Helper {
    function run() external {
        deployBASE();
        deployOP();
        // hyperevm
    }

    function deployBASE() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        MyOApp(BASE_OFT_USDC_ADAPTER).setPeer(BASE_EID, bytes32(uint256(uint160(BASE_OFT_USDC_ADAPTER))));
        MyOApp(BASE_OFT_USDC_ADAPTER).setPeer(ARB_EID, bytes32(uint256(uint160(ARB_OFT_USDCK_ADAPTER))));

        // USDT Adapter peers
        MyOApp(BASE_OFT_USDT_ADAPTER).setPeer(BASE_EID, bytes32(uint256(uint160(BASE_OFT_USDT_ADAPTER))));
        MyOApp(BASE_OFT_USDT_ADAPTER).setPeer(ARB_EID, bytes32(uint256(uint160(ARB_OFT_USDTK_ADAPTER))));

        // WETH Adapter peers
        MyOApp(BASE_OFT_WETH_ADAPTER).setPeer(BASE_EID, bytes32(uint256(uint160(BASE_OFT_WETH_ADAPTER))));
        MyOApp(BASE_OFT_WETH_ADAPTER).setPeer(ARB_EID, bytes32(uint256(uint160(ARB_OFT_WETHK_ADAPTER))));

        // WBTC Adapter peers
        MyOApp(BASE_OFT_WBTC_ADAPTER).setPeer(BASE_EID, bytes32(uint256(uint160(BASE_OFT_WBTC_ADAPTER))));
        MyOApp(BASE_OFT_WBTC_ADAPTER).setPeer(ARB_EID, bytes32(uint256(uint160(ARB_OFT_WBTCK_ADAPTER))));

        vm.stopBroadcast();
    }

    function deployOP() public {
        vm.createSelectFork(vm.rpcUrl("arb_mainnet"));
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        MyOApp(ARB_OFT_USDCK_ADAPTER).setPeer(BASE_EID, bytes32(uint256(uint160(BASE_OFT_USDC_ADAPTER))));
        MyOApp(ARB_OFT_USDCK_ADAPTER).setPeer(ARB_EID, bytes32(uint256(uint160(ARB_OFT_USDCK_ADAPTER))));

        // USDT Adapter peers
        MyOApp(ARB_OFT_USDTK_ADAPTER).setPeer(BASE_EID, bytes32(uint256(uint160(BASE_OFT_USDT_ADAPTER))));
        MyOApp(ARB_OFT_USDTK_ADAPTER).setPeer(ARB_EID, bytes32(uint256(uint160(ARB_OFT_USDTK_ADAPTER))));

        // WETH Adapter peers
        MyOApp(ARB_OFT_WETHK_ADAPTER).setPeer(BASE_EID, bytes32(uint256(uint160(BASE_OFT_WETH_ADAPTER))));
        MyOApp(ARB_OFT_WETHK_ADAPTER).setPeer(ARB_EID, bytes32(uint256(uint160(ARB_OFT_WETHK_ADAPTER))));

        // WBTC Adapter peers
        MyOApp(ARB_OFT_WBTCK_ADAPTER).setPeer(BASE_EID, bytes32(uint256(uint160(BASE_OFT_WBTC_ADAPTER))));
        MyOApp(ARB_OFT_WBTCK_ADAPTER).setPeer(ARB_EID, bytes32(uint256(uint160(ARB_OFT_WBTCK_ADAPTER))));

        vm.stopBroadcast();
    }
}

// RUN
// forge script SetPeers --broadcast -vvv
