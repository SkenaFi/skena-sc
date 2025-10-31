// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {Helper} from "../L0/Helper.sol";
import {ElevatedMinterBurner} from "../../src/layerzero/ElevatedMinterBurner.sol";
import {OFTUSDCadapter} from "../../src/layerzero/OFTUSDCadapter.sol";
import {OFTUSDTadapter} from "../../src/layerzero/OFTUSDTadapter.sol";
import {OFTETHadapter} from "../../src/layerzero/OFTETHadapter.sol";
import {OFTWETHadapter} from "../../src/layerzero/OFTWETHadapter.sol";
import {OFTWBTCadapter} from "../../src/layerzero/OFTWBTCadapter.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";
import {ExecutorConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/SendLibBase.sol";
import {EnforcedOptionParam} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {MyOApp} from "../../src/layerzero/MyOApp.sol";
import {USDCk} from "../../src/BridgeToken/USDCk.sol";
import {USDTk} from "../../src/BridgeToken/USDTk.sol";
import {WETHk} from "../../src/BridgeToken/WETHk.sol";
import {WBTCk} from "../../src/BridgeToken/WBTCk.sol";
import {ElevatedMinterBurner} from "../../src/layerzero/ElevatedMinterBurner.sol";

contract OFTDeployment is Script, Helper {
    using OptionsBuilder for bytes;

    OFTUSDTadapter public oftusdtadapter;
    OFTUSDCadapter public oftusdcadapter;
    OFTWETHadapter public oftwethadapter;
    OFTUSDTadapter public oftmockusdtadapter;
    OFTUSDCadapter public oftmockusdcadapter;
    OFTWETHadapter public oftmockwethadapter;
    OFTETHadapter public oftETHadapter;
    OFTWBTCadapter public oftwbtcadapter;
    USDCk public usdck;
    USDTk public usdtk;
    WBTCk public wbtck;
    WETHk public wethk;
    ElevatedMinterBurner public elevatedminterburner;

    address owner = vm.envAddress("PUBLIC_KEY");
    uint256 privateKey = vm.envUint("PRIVATE_KEY");

    address endpoint;
    address oapp;
    address oapp2;
    address oapp3;
    address sendLib;
    address receiveLib;
    uint32 srcEid;
    uint32 gracePeriod;

    address dvn1;
    address dvn2;
    address executor;

    uint32 eid0;
    uint32 eid1;

    uint32 constant EXECUTOR_CONFIG_TYPE = 1;
    uint32 constant ULN_CONFIG_TYPE = 2;
    uint32 constant RECEIVE_CONFIG_TYPE = 2;
    uint16 constant SEND = 1; // Message type for sendString function

    bool isDeployed = true;

    function run() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        // vm.createSelectFork(vm.rpcUrl("arb_mainnet"));
        vm.startBroadcast(privateKey);
        console.log("deployed on ChainId: ", block.chainid);
        // _deployRepresentativeToken();
        _getUtils();
        _deployOFT();
        // _setLibraries();
        // _setSendConfig();
        // _setReceiveConfig();
        // _setPeers();
        _setEnforcedOptions();
        vm.stopBroadcast();
    }

    function _getUtils() internal {
        if (block.chainid == 8453) {
            endpoint = BASE_LZ_ENDPOINT;
            sendLib = BASE_SEND_LIB;
            receiveLib = BASE_RECEIVE_LIB;
            srcEid = BASE_EID;
            gracePeriod = uint32(0);
            dvn1 = BASE_DVN1;
            dvn2 = BASE_DVN2;
            executor = BASE_EXECUTOR;
            eid0 = BASE_EID;
            eid1 = ARB_EID;
        } else if (block.chainid == 42161) {
            endpoint = ARB_LZ_ENDPOINT;
            sendLib = ARB_SEND_LIB;
            receiveLib = ARB_RECEIVE_LIB;
            srcEid = ARB_EID;
            gracePeriod = uint32(0);
            dvn1 = ARB_DVN1;
            dvn2 = ARB_DVN2;
            executor = ARB_EXECUTOR;
            eid0 = ARB_EID;
            eid1 = BASE_EID;
        }
    }

    function _deployRepresentativeToken() internal {
        usdtk = new USDTk();
        ARB_USDTK = address(usdtk);
        console.log("address public ARB_USDTK =", address(usdtk), ";");
        elevatedminterburner = new ElevatedMinterBurner(address(ARB_USDTK), owner);
        console.log("address public ARB_USDTK_ELEVATED_MINTER_BURNER =", address(elevatedminterburner), ";");
        oftusdtadapter = new OFTUSDTadapter(address(ARB_USDTK), address(elevatedminterburner), ARB_LZ_ENDPOINT, owner);
        console.log("address public ARB_OFT_USDTK_ADAPTER =", address(oftusdtadapter), ";");
        elevatedminterburner.setOperator(address(oftusdtadapter), true);
        usdtk.setOperator(address(elevatedminterburner), true);

        usdck = new USDCk();
        ARB_USDCK = address(usdck);
        console.log("address public ARB_USDCK =", address(usdck), ";");
        elevatedminterburner = new ElevatedMinterBurner(address(ARB_USDCK), owner);
        console.log("address public ARB_USDCK_ELEVATED_MINTER_BURNER =", address(elevatedminterburner), ";");
        oftusdcadapter = new OFTUSDCadapter(address(ARB_USDCK), address(elevatedminterburner), ARB_LZ_ENDPOINT, owner);
        console.log("address public ARB_OFT_USDCK_ADAPTER =", address(oftusdcadapter), ";");
        elevatedminterburner.setOperator(address(oftusdcadapter), true);
        usdck.setOperator(address(elevatedminterburner), true);

        wbtck = new WBTCk();
        ARB_WBTCK = address(wbtck);
        console.log("address public ARB_WBTCK =", address(ARB_WBTCK), ";");
        elevatedminterburner = new ElevatedMinterBurner(address(ARB_WBTCK), owner);
        console.log("address public ARB_WBTCK_ELEVATED_MINTER_BURNER =", address(elevatedminterburner), ";");
        oftwbtcadapter = new OFTWBTCadapter(address(ARB_WBTCK), address(elevatedminterburner), ARB_LZ_ENDPOINT, owner);
        console.log("address public ARB_OFT_WBTCK_ADAPTER =", address(oftwbtcadapter), ";");
        elevatedminterburner.setOperator(address(oftwbtcadapter), true);
        wbtck.setOperator(address(elevatedminterburner), true);

        wethk = new WETHk();
        ARB_WETHK = address(wethk);
        console.log("address public ARB_WETHK =", address(ARB_WETHK), ";");
        elevatedminterburner = new ElevatedMinterBurner(address(ARB_WETHK), owner);
        console.log("address public ARB_WETHK_ELEVATED_MINTER_BURNER =", address(elevatedminterburner), ";");
        oftwethadapter = new OFTWETHadapter(address(ARB_WETHK), address(elevatedminterburner), ARB_LZ_ENDPOINT, owner);
        console.log("address public ARB_OFT_WETHK_ADAPTER =", address(oftwethadapter), ";");
        elevatedminterburner.setOperator(address(oftwethadapter), true);
        wethk.setOperator(address(elevatedminterburner), true);
    }

    function _deployOFT() internal {
        if (!isDeployed) {
            oftusdtadapter =
                new OFTUSDTadapter(block.chainid == 8453 ? BASE_USDT : ARB_USDTK, address(0), endpoint, owner);
            block.chainid == 8453
                ? console.log("address public BASE_OFT_USDT_ADAPTER = %s;", address(oftusdtadapter))
                : console.log("address public ARB_OFT_USDT_ADAPTER = %s;", address(oftusdtadapter));

            oftusdcadapter =
                new OFTUSDCadapter(block.chainid == 8453 ? BASE_USDC : ARB_USDCK, address(0), endpoint, owner);
            block.chainid == 8453
                ? console.log("address public BASE_OFT_USDC_ADAPTER = %s;", address(oftusdcadapter))
                : console.log("address public ARB_OFT_USDC_ADAPTER = %s;", address(oftusdcadapter));

            oftwbtcadapter =
                new OFTWBTCadapter(block.chainid == 8453 ? BASE_WBTC : ARB_WBTCK, address(0), endpoint, owner);
            block.chainid == 8453
                ? console.log("address public BASE_OFT_WBTC_ADAPTER = %s;", address(oftwbtcadapter))
                : console.log("address public ARB_OFT_WBTC_ADAPTER = %s;", address(oftwbtcadapter));

            oftwethadapter =
                new OFTWETHadapter(block.chainid == 8453 ? BASE_WETH : ARB_WETHK, address(0), endpoint, owner);
            block.chainid == 8453
                ? console.log("address public BASE_OFT_WETH_ADAPTER = %s;", address(oftwethadapter))
                : console.log("address public ARB_OFT_WETH_ADAPTER = %s;", address(oftwethadapter));

            oftmockusdtadapter =
                new OFTUSDTadapter(block.chainid == 8453 ? BASE_MOCK_USDT : ARB_MOCK_USDTK, address(0), endpoint, owner);
            block.chainid == 8453
                ? console.log("address public BASE_OFT_MOCK_USDT_ADAPTER = %s;", address(oftmockusdtadapter))
                : console.log("address public ARB_OFT_MOCK_USDT_ADAPTER = %s;", address(oftmockusdtadapter));

            oftmockusdcadapter =
                new OFTUSDCadapter(block.chainid == 8453 ? BASE_MOCK_USDC : ARB_MOCK_USDCK, address(0), endpoint, owner);
            block.chainid == 8453
                ? console.log("address public BASE_OFT_MOCK_USDC_ADAPTER = %s;", address(oftmockusdcadapter))
                : console.log("address public ARB_OFT_MOCK_USDC_ADAPTER = %s;", address(oftmockusdcadapter));

            oftmockwethadapter =
                new OFTWETHadapter(block.chainid == 8453 ? BASE_MOCK_WETH : ARB_MOCK_WETHK, address(0), endpoint, owner);
            block.chainid == 8453
                ? console.log("address public BASE_OFT_MOCK_WETH_ADAPTER = %s;", address(oftmockwethadapter))
                : console.log("address public ARB_OFT_MOCK_WETH_ADAPTER = %s;", address(oftmockwethadapter));
        } else {
            oftusdtadapter = OFTUSDTadapter(block.chainid == 8453 ? BASE_OFT_USDT_ADAPTER : ARB_OFT_USDTK_ADAPTER);
            oftusdcadapter = OFTUSDCadapter(block.chainid == 8453 ? BASE_OFT_USDC_ADAPTER : ARB_OFT_USDCK_ADAPTER);
            oftwbtcadapter = OFTWBTCadapter(block.chainid == 8453 ? BASE_OFT_WBTC_ADAPTER : ARB_OFT_WBTCK_ADAPTER);
            oftwethadapter = OFTWETHadapter(block.chainid == 8453 ? BASE_OFT_WETH_ADAPTER : ARB_OFT_WETHK_ADAPTER);
            oftmockusdtadapter =
                OFTUSDTadapter(block.chainid == 8453 ? BASE_OFT_MOCK_USDT_ADAPTER : ARB_OFT_MOCK_USDTK_ADAPTER);
            oftmockusdcadapter =
                OFTUSDCadapter(block.chainid == 8453 ? BASE_OFT_MOCK_USDC_ADAPTER : ARB_OFT_MOCK_USDCK_ADAPTER);
            oftmockwethadapter =
                OFTWETHadapter(block.chainid == 8453 ? BASE_OFT_MOCK_WETH_ADAPTER : ARB_OFT_MOCK_WETHK_ADAPTER);
        }
    }

    function _setLibraries() internal {
        // Set delegate to the script runner for each OFT adapter

        // Now configure libraries using the delegate permissions
        ILayerZeroEndpointV2(endpoint).setSendLibrary(address(oftusdtadapter), eid1, sendLib);
        ILayerZeroEndpointV2(endpoint).setSendLibrary(address(oftusdcadapter), eid1, sendLib);
        ILayerZeroEndpointV2(endpoint).setSendLibrary(address(oftwbtcadapter), eid1, sendLib);
        ILayerZeroEndpointV2(endpoint).setSendLibrary(address(oftwethadapter), eid1, sendLib);
        ILayerZeroEndpointV2(endpoint).setSendLibrary(address(oftmockusdtadapter), eid1, sendLib);
        ILayerZeroEndpointV2(endpoint).setSendLibrary(address(oftmockusdcadapter), eid1, sendLib);
        ILayerZeroEndpointV2(endpoint).setSendLibrary(address(oftmockwethadapter), eid1, sendLib);

        ILayerZeroEndpointV2(endpoint).setReceiveLibrary(address(oftusdtadapter), srcEid, receiveLib, gracePeriod);
        ILayerZeroEndpointV2(endpoint).setReceiveLibrary(address(oftusdcadapter), srcEid, receiveLib, gracePeriod);
        ILayerZeroEndpointV2(endpoint).setReceiveLibrary(address(oftwbtcadapter), srcEid, receiveLib, gracePeriod);
        ILayerZeroEndpointV2(endpoint).setReceiveLibrary(address(oftwethadapter), srcEid, receiveLib, gracePeriod);
        ILayerZeroEndpointV2(endpoint).setReceiveLibrary(address(oftmockusdtadapter), srcEid, receiveLib, gracePeriod);
        ILayerZeroEndpointV2(endpoint).setReceiveLibrary(address(oftmockusdcadapter), srcEid, receiveLib, gracePeriod);
        ILayerZeroEndpointV2(endpoint).setReceiveLibrary(address(oftmockwethadapter), srcEid, receiveLib, gracePeriod);
    }

    function _setSendConfig() internal {
        UlnConfig memory uln = UlnConfig({
            confirmations: 15,
            requiredDVNCount: 2,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: _toDynamicArray([dvn1, dvn2]),
            optionalDVNs: new address[](0)
        });
        ExecutorConfig memory exec = ExecutorConfig({maxMessageSize: 10000, executor: executor});
        bytes memory encodedUln = abi.encode(uln);
        bytes memory encodedExec = abi.encode(exec);
        SetConfigParam[] memory params = new SetConfigParam[](4);
        params[0] = SetConfigParam(eid0, EXECUTOR_CONFIG_TYPE, encodedExec);
        params[1] = SetConfigParam(eid0, ULN_CONFIG_TYPE, encodedUln);
        params[2] = SetConfigParam(eid1, EXECUTOR_CONFIG_TYPE, encodedExec);
        params[3] = SetConfigParam(eid1, ULN_CONFIG_TYPE, encodedUln);

        // Configure send settings using delegate permissions
        ILayerZeroEndpointV2(endpoint).setConfig(address(oftusdcadapter), sendLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(address(oftusdtadapter), sendLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(address(oftwbtcadapter), sendLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(address(oftwethadapter), sendLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(address(oftmockusdtadapter), sendLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(address(oftmockusdcadapter), sendLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(address(oftmockwethadapter), sendLib, params);
    }

    function _setReceiveConfig() internal {
        UlnConfig memory uln;
        uln = UlnConfig({
            confirmations: 15, // min block confirmations from source (A)
            requiredDVNCount: 2, // required DVNs for message acceptance
            optionalDVNCount: type(uint8).max, // optional DVNs count
            optionalDVNThreshold: 0, // optional DVN threshold
            requiredDVNs: _toDynamicArray([dvn1, dvn2]), // sorted required DVNs
            optionalDVNs: new address[](0) // no optional DVNs
        });
        bytes memory encodedUln = abi.encode(uln);
        SetConfigParam[] memory params;
        params = new SetConfigParam[](2);
        params[0] = SetConfigParam(eid0, RECEIVE_CONFIG_TYPE, encodedUln);
        params[1] = SetConfigParam(eid1, RECEIVE_CONFIG_TYPE, encodedUln);

        // Configure receive settings using delegate permissions
        ILayerZeroEndpointV2(endpoint).setConfig(address(oftusdcadapter), receiveLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(address(oftusdtadapter), receiveLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(address(oftwbtcadapter), receiveLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(address(oftwethadapter), receiveLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(address(oftmockusdtadapter), receiveLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(address(oftmockusdcadapter), receiveLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(address(oftmockwethadapter), receiveLib, params);
    }

    function _setPeers() internal {
        bytes32 oftPeer1 = bytes32(uint256(uint160(address(oftusdcadapter))));
        bytes32 oftPeer2 = bytes32(uint256(uint160(address(oftusdtadapter))));
        bytes32 oftPeer3 = bytes32(uint256(uint160(address(oftwbtcadapter))));
        bytes32 oftPeer4 = bytes32(uint256(uint160(address(oftwethadapter))));
        bytes32 oftPeer5 = bytes32(uint256(uint160(address(oftmockusdtadapter))));
        bytes32 oftPeer6 = bytes32(uint256(uint160(address(oftmockusdcadapter))));
        bytes32 oftPeer7 = bytes32(uint256(uint160(address(oftmockwethadapter))));

        bytes32 oftPeer8 =
            bytes32(uint256(uint160(block.chainid == 8453 ? ARB_OFT_USDCK_ADAPTER : BASE_OFT_USDC_ADAPTER)));
        bytes32 oftPeer9 =
            bytes32(uint256(uint160(block.chainid == 8453 ? ARB_OFT_USDTK_ADAPTER : BASE_OFT_USDT_ADAPTER)));
        bytes32 oftPeer10 =
            bytes32(uint256(uint160(block.chainid == 8453 ? ARB_OFT_WBTCK_ADAPTER : BASE_OFT_WBTC_ADAPTER)));
        bytes32 oftPeer11 =
            bytes32(uint256(uint160(block.chainid == 8453 ? ARB_OFT_WETHK_ADAPTER : BASE_OFT_WETH_ADAPTER)));
        bytes32 oftPeer12 =
            bytes32(uint256(uint160(block.chainid == 8453 ? ARB_OFT_MOCK_USDTK_ADAPTER : BASE_OFT_MOCK_USDT_ADAPTER)));
        bytes32 oftPeer13 =
            bytes32(uint256(uint160(block.chainid == 8453 ? ARB_OFT_MOCK_USDCK_ADAPTER : BASE_OFT_MOCK_USDC_ADAPTER)));
        bytes32 oftPeer14 =
            bytes32(uint256(uint160(block.chainid == 8453 ? ARB_OFT_MOCK_WETHK_ADAPTER : BASE_OFT_MOCK_WETH_ADAPTER)));

        // OFTUSDCadapter(oftusdcadapter).setPeer(eid0, oftPeer1);
        // OFTUSDTadapter(oftusdtadapter).setPeer(eid0, oftPeer2);
        // OFTWBTCadapter(oftwbtcadapter).setPeer(eid0, oftPeer3);
        // OFTWETHadapter(oftwethadapter).setPeer(eid0, oftPeer4);
        // OFTUSDTadapter(oftmockusdtadapter).setPeer(eid0, oftPeer5);
        // OFTUSDCadapter(oftmockusdcadapter).setPeer(eid0, oftPeer6);
        // OFTWETHadapter(oftmockwethadapter).setPeer(eid0, oftPeer7);

        OFTUSDCadapter(oftusdcadapter).setPeer(eid1, oftPeer8);
        OFTUSDTadapter(oftusdtadapter).setPeer(eid1, oftPeer9);
        OFTWBTCadapter(oftwbtcadapter).setPeer(eid1, oftPeer10);
        OFTWETHadapter(oftwethadapter).setPeer(eid1, oftPeer11);
        OFTUSDTadapter(oftmockusdtadapter).setPeer(eid1, oftPeer12);
        OFTUSDCadapter(oftmockusdcadapter).setPeer(eid1, oftPeer13);
        OFTWETHadapter(oftmockwethadapter).setPeer(eid1, oftPeer14);
    }

    function _setEnforcedOptions() internal {
        bytes memory options1 = OptionsBuilder.newOptions().addExecutorLzReceiveOption(80000, 0);
        bytes memory options2 = OptionsBuilder.newOptions().addExecutorLzReceiveOption(100000, 0);

        EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](2);
        enforcedOptions[0] = EnforcedOptionParam({eid: eid0, msgType: SEND, options: options1});
        enforcedOptions[1] = EnforcedOptionParam({eid: eid1, msgType: SEND, options: options2});

        MyOApp(address(oftusdcadapter)).setEnforcedOptions(enforcedOptions);
        MyOApp(address(oftusdtadapter)).setEnforcedOptions(enforcedOptions);
        MyOApp(address(oftwbtcadapter)).setEnforcedOptions(enforcedOptions);
        MyOApp(address(oftwethadapter)).setEnforcedOptions(enforcedOptions);
        MyOApp(address(oftmockusdtadapter)).setEnforcedOptions(enforcedOptions);
        MyOApp(address(oftmockusdcadapter)).setEnforcedOptions(enforcedOptions);
        MyOApp(address(oftmockwethadapter)).setEnforcedOptions(enforcedOptions);
    }

    function _toDynamicArray(address[2] memory fixedArray) internal pure returns (address[] memory) {
        address[] memory dynamicArray = new address[](2);
        dynamicArray[0] = fixedArray[0];
        dynamicArray[1] = fixedArray[1];
        return dynamicArray;
    }

    function _toDynamicArray1(address[1] memory fixedArray) internal pure returns (address[] memory) {
        address[] memory dynamicArray = new address[](1);
        dynamicArray[0] = fixedArray[0];
        return dynamicArray;
    }
}

// RUN
//
// forge script OFTDeployment --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script OFTDeployment --broadcast -vvv
// forge script OFTDeployment -vvv
