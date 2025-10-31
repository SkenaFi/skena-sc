// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {USDCk} from "../../src/BridgeToken/USDCk.sol";
import {USDTk} from "../../src/BridgeToken/USDTk.sol";
import {WETHk} from "../../src/BridgeToken/WETHk.sol";
import {WBTCk} from "../../src/BridgeToken/WBTCk.sol";
import {ElevatedMinterBurner} from "../../src/layerzero/ElevatedMinterBurner.sol";
import {Helper} from "./Helper.sol";
import {OFTUSDTadapter} from "../../src/layerzero/OFTUSDTadapter.sol";
import {OFTWBTCadapter} from "../../src/layerzero/OFTWBTCadapter.sol";
import {OFTWETHadapter} from "../../src/layerzero/OFTWETHadapter.sol";

contract DeployOFT is Script, Helper {
    address owner = vm.envAddress("PUBLIC_KEY");
    uint256 privateKey = vm.envUint("PRIVATE_KEY");

    USDCk public usdck;
    USDTk public usdtk;
    WBTCk public wbtck;
    WETHk public wethk;
    ElevatedMinterBurner public elevatedminterburner;
    OFTUSDTadapter public oftusdtadapter;
    OFTWBTCadapter public oftwbtcadapter;
    OFTWETHadapter public oftwethadapter;

    function run() public {
        deployBASE();
        // deployOP();
        // deployUSDCBASE();
        // deployUSDCOP();
        // hyperevm
    }

    function deployOP() public {
        vm.createSelectFork(vm.rpcUrl("arb_mainnet"));
        vm.startBroadcast(privateKey);
        console.log("deployed on ChainId: ", block.chainid);

        usdtk = new USDTk();
        ARB_USDTK = address(usdtk);
        console.log("address public ARB_USDTK =", address(usdtk), ";");
        elevatedminterburner = new ElevatedMinterBurner(address(ARB_USDTK), owner);
        console.log("address public ARB_ELEVATED_MINTER_BURNER =", address(elevatedminterburner), ";");
        oftusdtadapter = new OFTUSDTadapter(address(ARB_USDTK), address(elevatedminterburner), ARB_LZ_ENDPOINT, owner);
        console.log("address public ARB_OFT_USDTK_ADAPTER =", address(oftusdtadapter), ";");
        elevatedminterburner.setOperator(address(oftusdtadapter), true);

        wbtck = new WBTCk();
        ARB_WBTCK = address(wbtck);
        console.log("address public ARB_WBTCK =", address(ARB_WBTCK), ";");
        elevatedminterburner = new ElevatedMinterBurner(address(ARB_WBTCK), owner);
        console.log("address public ARB_ELEVATED_MINTER_BURNER =", address(elevatedminterburner), ";");
        oftwbtcadapter = new OFTWBTCadapter(address(ARB_WBTCK), address(elevatedminterburner), ARB_LZ_ENDPOINT, owner);
        console.log("address public ARB_OFT_WBTCK_ADAPTER =", address(oftwbtcadapter), ";");
        elevatedminterburner.setOperator(address(oftwbtcadapter), true);

        wethk = new WETHk();
        ARB_WETHK = address(wethk);
        console.log("address public ARB_WETHK =", address(ARB_WETHK), ";");
        elevatedminterburner = new ElevatedMinterBurner(address(ARB_WETHK), owner);
        console.log("address public ARB_ELEVATED_MINTER_BURNER =", address(elevatedminterburner), ";");
        oftwethadapter = new OFTWETHadapter(address(ARB_WETHK), address(elevatedminterburner), ARB_LZ_ENDPOINT, owner);
        console.log("address public ARB_OFT_WETHK_ADAPTER =", address(oftwethadapter), ";");
        elevatedminterburner.setOperator(address(oftwethadapter), true);

        vm.stopBroadcast();
    }

    function deployBASE() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        vm.startBroadcast(privateKey);
        console.log("deployed on ChainId: ", block.chainid);

        oftusdtadapter = new OFTUSDTadapter(BASE_USDT, address(0), BASE_LZ_ENDPOINT, owner);
        console.log("address public BASE_OFT_USDT_ADAPTER =", address(oftusdtadapter), ";");

        oftwbtcadapter = new OFTWBTCadapter(BASE_WBTC, address(0), BASE_LZ_ENDPOINT, owner);
        console.log("address public BASE_OFT_WBTC_ADAPTER =", address(oftwbtcadapter), ";");

        oftwethadapter = new OFTWETHadapter(BASE_WETH, address(0), BASE_LZ_ENDPOINT, owner);
        console.log("address public BASE_OFT_WETH_ADAPTER =", address(oftwethadapter), ";");
        vm.stopBroadcast();
    }

    function deployUSDCBASE() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        vm.startBroadcast(privateKey);
        oftusdtadapter = new OFTUSDTadapter(BASE_USDC, address(0), BASE_LZ_ENDPOINT, owner);
        console.log("address public BASE_OFT_USDC_ADAPTER =", address(oftusdtadapter), ";");
        vm.stopBroadcast();
    }

    function deployUSDCOP() public {
        vm.createSelectFork(vm.rpcUrl("arb_mainnet"));
        vm.startBroadcast(privateKey);
        usdck = new USDCk();
        ARB_USDCK = address(usdck);
        console.log("address public ARB_USDCK =", address(ARB_USDCK), ";");
        elevatedminterburner = new ElevatedMinterBurner(address(ARB_USDCK), owner);
        console.log("address public ARB_USDCK_ELEVATED_MINTER_BURNER =", address(elevatedminterburner), ";");
        oftusdtadapter = new OFTUSDTadapter(address(ARB_USDCK), address(elevatedminterburner), ARB_LZ_ENDPOINT, owner);
        console.log("address public ARB_OFT_USDCK_ADAPTER =", address(oftusdtadapter), ";");
        elevatedminterburner.setOperator(address(oftusdtadapter), true);
        vm.stopBroadcast();
    }
}
// RUN
// forge script DeployOFT --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script DeployOFT --broadcast -vvv
// forge script DeployOFT -vvv
