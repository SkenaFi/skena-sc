// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {Helper} from "./Helper.sol";
import {IWETH} from "../../src/interfaces/IWETH.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ConvertToWrappedToken is Script, Helper {
    function run() public {
        deployBASE();
    }

    function deployBASE() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        console.log("balance before deposit: ", vm.envAddress("PUBLIC_KEY"));
        console.log("balance token before deposit: ", IERC20(BASE_WETH).balanceOf(vm.envAddress("PUBLIC_KEY")));
        IWETH(BASE_WETH).deposit{value: 1e18}();
        console.log("balance after deposit: ", vm.envAddress("PUBLIC_KEY"));
        console.log("balance token after deposit: ", IERC20(BASE_WETH).balanceOf(vm.envAddress("PUBLIC_KEY")));
        vm.stopBroadcast();
    }
}

// RUN
// forge script ConvertToWrappedToken --broadcast -vvv
