// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {Helper} from "../L0/Helper.sol";
import {IFactory} from "../../src/interfaces/IFactory.sol";

contract AddTokenDataStream is Script, Helper {
    function run() external {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        IFactory(BASE_lendingPoolFactoryProxy).addTokenDataStream(BASE_MOCK_USDC, BASE_usdc_usd_adapter);
        IFactory(BASE_lendingPoolFactoryProxy).addTokenDataStream(BASE_MOCK_USDT, BASE_usdt_usd_adapter);
        IFactory(BASE_lendingPoolFactoryProxy).addTokenDataStream(BASE_MOCK_WETH, BASE_eth_usd_adapter);
        vm.stopBroadcast();
    }
}

// RUN
// forge script AddTokenDataStream --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script AddTokenDataStream --broadcast -vvv
// forge script AddTokenDataStream -vvv
