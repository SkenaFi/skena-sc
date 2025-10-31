// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {Helper} from "./Helper.sol";
import {ElevatedMinterBurner} from "../../src/layerzero/ElevatedMinterBurner.sol";
import {OFTUSDTadapter} from "../../src/layerzero/OFTUSDTAdapter.sol";
import {USDTk} from "../../src/BridgeToken/USDTk.sol";
import {USDCk} from "../../src/BridgeToken/USDCk.sol";
import {WBTCk} from "../../src/BridgeToken/WBTCk.sol";
import {WETHk} from "../../src/BridgeToken/WETHk.sol";

contract SetElevated is Script, Helper {
    address public owner = vm.envAddress("PUBLIC_KEY");
    ElevatedMinterBurner public elevatedminterburner;

    function run() external {
        vm.createSelectFork(vm.rpcUrl("arb_mainnet"));
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // _setElevated();
        _setOperator();

        vm.stopBroadcast();
    }

    function _setElevated() internal {
        elevatedminterburner = new ElevatedMinterBurner(address(ARB_USDTK), owner);
        elevatedminterburner.setOperator(address(ARB_OFT_USDTK_ADAPTER), true);
        OFTUSDTadapter(ARB_OFT_USDTK_ADAPTER).setElevatedMinterBurner(address(elevatedminterburner));
        console.log("address public ARB_USDTK_ELEVATED_MINTER_BURNER =", address(elevatedminterburner), ";");
    }

    function _setOperator() internal {
        USDTk(ARB_USDTK).setOperator(ARB_USDTK_ELEVATED_MINTER_BURNER, true);
        USDTk(ARB_USDTK).setOperator(ARB_OFT_USDTK_ADAPTER, true);

        USDCk(ARB_USDCK).setOperator(ARB_USDCK_ELEVATED_MINTER_BURNER, true);
        USDCk(ARB_USDCK).setOperator(ARB_OFT_USDCK_ADAPTER, true);

        WBTCk(ARB_WBTCK).setOperator(ARB_WBTCK_ELEVATED_MINTER_BURNER, true);
        WBTCk(ARB_WBTCK).setOperator(ARB_OFT_WBTCK_ADAPTER, true);

        WETHk(ARB_WETHK).setOperator(ARB_WETHK_ELEVATED_MINTER_BURNER, true);
        WETHk(ARB_WETHK).setOperator(ARB_OFT_WETHK_ADAPTER, true);

        USDCk(ARB_MOCK_USDCK).setOperator(ARB_MOCK_USDCK_ELEVATED_MINTER_BURNER, true);
        USDCk(ARB_MOCK_USDCK).setOperator(ARB_OFT_MOCK_USDCK_ADAPTER, true);

        USDTk(ARB_MOCK_USDTK).setOperator(ARB_MOCK_USDTK_ELEVATED_MINTER_BURNER, true);
        USDTk(ARB_MOCK_USDTK).setOperator(ARB_OFT_MOCK_USDTK_ADAPTER, true);

        WETHk(ARB_MOCK_WETHK).setOperator(ARB_MOCK_WETHK_ELEVATED_MINTER_BURNER, true);
        WETHk(ARB_MOCK_WETHK).setOperator(ARB_OFT_MOCK_WETHK_ADAPTER, true);

        ElevatedMinterBurner(ARB_USDTK_ELEVATED_MINTER_BURNER).setOperator(ARB_OFT_USDTK_ADAPTER, true);
        ElevatedMinterBurner(ARB_WBTCK_ELEVATED_MINTER_BURNER).setOperator(ARB_OFT_WBTCK_ADAPTER, true);
        ElevatedMinterBurner(ARB_WETHK_ELEVATED_MINTER_BURNER).setOperator(ARB_OFT_WETHK_ADAPTER, true);
        ElevatedMinterBurner(ARB_USDCK_ELEVATED_MINTER_BURNER).setOperator(ARB_OFT_USDCK_ADAPTER, true);
        ElevatedMinterBurner(ARB_MOCK_USDCK_ELEVATED_MINTER_BURNER).setOperator(ARB_OFT_MOCK_USDCK_ADAPTER, true);
        ElevatedMinterBurner(ARB_MOCK_USDTK_ELEVATED_MINTER_BURNER).setOperator(ARB_OFT_MOCK_USDTK_ADAPTER, true);
        ElevatedMinterBurner(ARB_MOCK_WETHK_ELEVATED_MINTER_BURNER).setOperator(ARB_OFT_MOCK_WETHK_ADAPTER, true);
    }
}

// RUN
// forge script SetElevated --broadcast -vvv
