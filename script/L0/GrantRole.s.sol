// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {Helper} from "./Helper.sol";
import {USDTk} from "../../src/BridgeToken/USDTk.sol";
import {WETHk} from "../../src/BridgeToken/WETHk.sol";
import {WBTCk} from "../../src/BridgeToken/WBTCk.sol";
import {WETHk} from "../../src/BridgeToken/WETHk.sol";

contract GrantRole is Script, Helper {
    function run() public {
        vm.createSelectFork(vm.rpcUrl("arb_mainnet"));
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        USDTk(ARB_USDTK).setOperator(ARB_USDTK_ELEVATED_MINTER_BURNER, true);
        console.log("USDTk operator set");
        WBTCk(ARB_WBTCK).setOperator(ARB_WBTCK_ELEVATED_MINTER_BURNER, true);
        console.log("WBTCk operator set");
        WETHk(ARB_WETHK).setOperator(ARB_WETHK_ELEVATED_MINTER_BURNER, true);
        console.log("WETHk operator set");
        vm.stopBroadcast();
    }
}

// RUN
// forge script GrantRole --broadcast -vvv
