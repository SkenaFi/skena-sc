// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {Helper} from "../L0/Helper.sol";
import {HelperUtils} from "../../src/HelperUtils.sol";

contract DeployHelperUtils is Script, Helper {
    HelperUtils public helperUtils;

    function run() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        helperUtils = new HelperUtils(address(BASE_lendingPoolFactoryProxy));
        console.log("address public BASE_HELPER_UTILS =", address(helperUtils), ";");
        vm.stopBroadcast();

        console.log("HelperUtils deployed successfully!");
    }
}

// RUN
// forge script DeployHelperUtils --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
