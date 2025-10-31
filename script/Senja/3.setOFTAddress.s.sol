// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {Helper} from "../L0/Helper.sol";
import {IFactory} from "../../src/interfaces/IFactory.sol";

contract SetOFTAddress is Script, Helper {
    function run() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        IFactory(address(BASE_lendingPoolFactoryProxy)).setOftAddress(BASE_USDT, BASE_OFT_USDT_ADAPTER);
        IFactory(address(BASE_lendingPoolFactoryProxy)).setOftAddress(BASE_USDC, BASE_OFT_USDC_ADAPTER);
        IFactory(address(BASE_lendingPoolFactoryProxy)).setOftAddress(BASE_WETH, BASE_OFT_WETH_ADAPTER);
        IFactory(address(BASE_lendingPoolFactoryProxy)).setOftAddress(BASE_WBTC, BASE_OFT_WBTC_ADAPTER);

        IFactory(address(BASE_lendingPoolFactoryProxy)).setOftAddress(BASE_MOCK_USDT, BASE_OFT_MOCK_USDT_ADAPTER);
        IFactory(address(BASE_lendingPoolFactoryProxy)).setOftAddress(BASE_MOCK_USDC, BASE_OFT_MOCK_USDC_ADAPTER);
        IFactory(address(BASE_lendingPoolFactoryProxy)).setOftAddress(BASE_MOCK_WETH, BASE_OFT_MOCK_WETH_ADAPTER);
        vm.stopBroadcast();
        console.log("OFT address set successfully!");
    }
}
// RUN
// forge script SetOFTAddress --broadcast -vvv
