// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {Helper} from "../L0/Helper.sol";
import {USDC} from "../../src/MockToken/USDC.sol";
import {USDT} from "../../src/MockToken/USDT.sol";
import {WETH} from "../../src/MockToken/WETH.sol";
import {IFactory} from "../../src/interfaces/IFactory.sol";
import {ElevatedMinterBurner} from "../../src/layerzero/ElevatedMinterBurner.sol";
import {OFTUSDTadapter} from "../../src/layerzero/OFTUSDTadapter.sol";
import {OFTETHadapter} from "../../src/layerzero/OFTETHadapter.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";
import {ExecutorConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/SendLibBase.sol";
import {EnforcedOptionParam} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {MyOApp} from "../../src/layerzero/MyOApp.sol";
import {WHBAR} from "../../src/MockToken/WHBAR.sol";

contract DevSkena is Script, Helper {
    using OptionsBuilder for bytes;

    USDC public mockUSDC;
    USDT public mockUSDT;
    WETH public mockWeth;
    WHBAR public mockWhbar;

    ElevatedMinterBurner public elevatedminterburner;
    OFTUSDTadapter public oftusdtadapter;
    OFTETHadapter public oftETHadapter;

    address public oftusdc;
    address public oftusdt;
    address public oftweth;

    address public owner = vm.envAddress("PUBLIC_KEY");

    uint32 dstEid0 = BASE_EID; // Destination chain EID
    uint32 dstEid1 = ARB_EID; // Destination chain EID

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
    uint16 SEND = 1; // Message type for sendString function

    function run() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        // vm.createSelectFork(vm.rpcUrl("aRB_mainnet"));
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        _deployTokens();

        // _getUtils();
        // _deployOFT();
        // _setLibraries();
        // _setSendConfig();
        // _setReceiveConfig();

        // _setPeers();
        // _setEnforcedOFT();
        // _setOFTAddress();
        vm.stopBroadcast();
    }

    function _deployTokens() internal {
        mockUSDC = new USDC();
        mockUSDT = new USDT();
        mockWeth = new WETH();
        if (block.chainid == 295) {
            mockWhbar = new WHBAR();

            console.log("address public HBAR_mockUSDC =", address(mockUSDC), ";");
            console.log("address public HBAR_mockUSDT =", address(mockUSDT), ";");
            console.log("address public HBAR_mockWeth =", address(mockWeth), ";");
            console.log("address public HBAR_mockWhbar =", address(mockWhbar), ";");
        } else if (block.chainid == 8453) {
            console.log("address public BASE_mockUSDC =", address(mockUSDC), ";");
            console.log("address public BASE_mockUSDT =", address(mockUSDT), ";");
            console.log("address public BASE_mockWeth =", address(mockWeth), ";");
        } else if (block.chainid == 42161) {
            console.log("address public ARB_mockUSDC =", address(mockUSDC), ";");
            console.log("address public ARB_mockUSDT =", address(mockUSDT), ";");
            console.log("address public ARB_mockWeth =", address(mockWeth), ";");
        }
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
        } else if (block.chainid == 10) {
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

    function _deployOFT() internal {
        if (block.chainid == 8453) {
            elevatedminterburner = new ElevatedMinterBurner(address(BASE_MOCK_USDC), owner);
            console.log("address public BASE_MOCK_USDC_ELEVATED_MINTER_BURNER =", address(elevatedminterburner), ";");
            oftusdtadapter =
                new OFTUSDTadapter(address(BASE_MOCK_USDC), address(elevatedminterburner), BASE_LZ_ENDPOINT, owner);
            console.log("address public BASE_OFT_MOCK_USDC_ADAPTER =", address(oftusdtadapter), ";");
            elevatedminterburner.setOperator(address(oftusdtadapter), true);
            oftusdc = address(oftusdtadapter);

            elevatedminterburner = new ElevatedMinterBurner(address(BASE_MOCK_USDT), owner);
            console.log("address public BASE_MOCK_USDT_ELEVATED_MINTER_BURNER =", address(elevatedminterburner), ";");
            oftusdtadapter =
                new OFTUSDTadapter(address(BASE_MOCK_USDT), address(elevatedminterburner), BASE_LZ_ENDPOINT, owner);
            console.log("address public BASE_OFT_MOCK_USDT_ADAPTER =", address(oftusdtadapter), ";");
            elevatedminterburner.setOperator(address(oftusdtadapter), true);
            oftusdt = address(oftusdtadapter);

            elevatedminterburner = new ElevatedMinterBurner(BASE_MOCK_WETH, owner);
            console.log("address public BASE_MOCK_WETH_ELEVATED_MINTER_BURNER =", address(elevatedminterburner), ";");
            oftETHadapter = new OFTETHadapter(BASE_MOCK_WETH, address(elevatedminterburner), BASE_LZ_ENDPOINT, owner);
            console.log("address public BASE_OFT_MOCK_WETH_ADAPTER =", address(oftETHadapter), ";");
            elevatedminterburner.setOperator(address(oftETHadapter), true);
            oftweth = address(oftETHadapter);
        } else {
            elevatedminterburner = new ElevatedMinterBurner(address(ARB_MOCK_USDCK), owner);
            console.log("address public ARB_MOCK_USDC_ELEVATED_MINTER_BURNER =", address(elevatedminterburner), ";");
            oftusdtadapter =
                new OFTUSDTadapter(address(ARB_MOCK_USDCK), address(elevatedminterburner), ARB_LZ_ENDPOINT, owner);
            console.log("address public ARB_OFT_MOCK_USDC_ADAPTER =", address(oftusdtadapter), ";");
            elevatedminterburner.setOperator(address(oftusdtadapter), true);
            oftusdc = address(oftusdtadapter);

            elevatedminterburner = new ElevatedMinterBurner(address(ARB_MOCK_USDTK), owner);
            console.log("address public ARB_MOCK_USDT_ELEVATED_MINTER_BURNER =", address(elevatedminterburner), ";");
            oftusdtadapter =
                new OFTUSDTadapter(address(ARB_MOCK_USDTK), address(elevatedminterburner), ARB_LZ_ENDPOINT, owner);
            console.log("address public ARB_OFT_MOCK_USDT_ADAPTER =", address(oftusdtadapter), ";");
            elevatedminterburner.setOperator(address(oftusdtadapter), true);
            oftusdt = address(oftusdtadapter);

            elevatedminterburner = new ElevatedMinterBurner(ARB_MOCK_WETHK, owner);
            console.log("address public ARB_MOCK_WETH_ELEVATED_MINTER_BURNER =", address(elevatedminterburner), ";");
            oftETHadapter = new OFTETHadapter(ARB_MOCK_WETHK, address(elevatedminterburner), ARB_LZ_ENDPOINT, owner);
            console.log("address public ARB_OFT_MOCK_WETH_ADAPTER =", address(oftETHadapter), ";");
            elevatedminterburner.setOperator(address(oftETHadapter), true);
            oftweth = address(oftETHadapter);
        }
    }

    function _setLibraries() internal {
        ILayerZeroEndpointV2(endpoint).setSendLibrary(oftusdc, eid0, sendLib);
        ILayerZeroEndpointV2(endpoint).setSendLibrary(oftusdt, eid0, sendLib);
        ILayerZeroEndpointV2(endpoint).setSendLibrary(oftweth, eid0, sendLib);
        ILayerZeroEndpointV2(endpoint).setReceiveLibrary(oftusdc, srcEid, receiveLib, gracePeriod);
        ILayerZeroEndpointV2(endpoint).setReceiveLibrary(oftusdt, srcEid, receiveLib, gracePeriod);
        ILayerZeroEndpointV2(endpoint).setReceiveLibrary(oftweth, srcEid, receiveLib, gracePeriod);
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

        ILayerZeroEndpointV2(endpoint).setConfig(oftusdc, sendLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(oftusdt, sendLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(oftweth, sendLib, params);
    }

    function _setReceiveConfig() internal {
        UlnConfig memory uln = UlnConfig({
            confirmations: 15,
            requiredDVNCount: 2,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: _toDynamicArray([dvn1, dvn2]),
            optionalDVNs: new address[](0)
        });
        bytes memory encodedUln = abi.encode(uln);
        SetConfigParam[] memory params = new SetConfigParam[](2);
        params[0] = SetConfigParam(eid0, RECEIVE_CONFIG_TYPE, encodedUln);
        params[1] = SetConfigParam(eid1, RECEIVE_CONFIG_TYPE, encodedUln);

        ILayerZeroEndpointV2(endpoint).setConfig(oftusdc, receiveLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(oftusdt, receiveLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(oftweth, receiveLib, params);
    }

    function _setPeers() internal {
        if (block.chainid == 8453) {
            MyOApp(BASE_OFT_MOCK_USDC_ADAPTER).setPeer(BASE_EID, bytes32(uint256(uint160(BASE_OFT_MOCK_USDC_ADAPTER))));
            MyOApp(BASE_OFT_MOCK_USDT_ADAPTER).setPeer(BASE_EID, bytes32(uint256(uint160(BASE_OFT_MOCK_USDT_ADAPTER))));
            MyOApp(BASE_OFT_MOCK_WETH_ADAPTER).setPeer(BASE_EID, bytes32(uint256(uint160(BASE_OFT_MOCK_WETH_ADAPTER))));

            MyOApp(BASE_OFT_MOCK_USDC_ADAPTER).setPeer(ARB_EID, bytes32(uint256(uint160(ARB_OFT_MOCK_USDCK_ADAPTER))));
            MyOApp(BASE_OFT_MOCK_USDT_ADAPTER).setPeer(ARB_EID, bytes32(uint256(uint160(ARB_OFT_MOCK_USDTK_ADAPTER))));
            MyOApp(BASE_OFT_MOCK_WETH_ADAPTER).setPeer(ARB_EID, bytes32(uint256(uint160(ARB_OFT_MOCK_WETHK_ADAPTER))));
        } else if (block.chainid == 42161) {
            MyOApp(ARB_OFT_MOCK_USDCK_ADAPTER).setPeer(ARB_EID, bytes32(uint256(uint160(ARB_OFT_MOCK_USDCK_ADAPTER))));
            MyOApp(ARB_OFT_MOCK_USDTK_ADAPTER).setPeer(ARB_EID, bytes32(uint256(uint160(ARB_OFT_MOCK_USDTK_ADAPTER))));
            MyOApp(ARB_OFT_MOCK_WETHK_ADAPTER).setPeer(ARB_EID, bytes32(uint256(uint160(ARB_OFT_MOCK_WETHK_ADAPTER))));

            MyOApp(ARB_OFT_MOCK_USDCK_ADAPTER).setPeer(BASE_EID, bytes32(uint256(uint160(BASE_OFT_MOCK_USDC_ADAPTER))));
            MyOApp(ARB_OFT_MOCK_USDTK_ADAPTER).setPeer(BASE_EID, bytes32(uint256(uint160(BASE_OFT_MOCK_USDT_ADAPTER))));
            MyOApp(ARB_OFT_MOCK_WETHK_ADAPTER).setPeer(BASE_EID, bytes32(uint256(uint160(BASE_OFT_MOCK_WETH_ADAPTER))));
        }
    }

    function _setEnforcedOFT() internal {
        bytes memory options1 = OptionsBuilder.newOptions().addExecutorLzReceiveOption(80000, 0);
        bytes memory options2 = OptionsBuilder.newOptions().addExecutorLzReceiveOption(100000, 0);

        EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](2);
        enforcedOptions[0] = EnforcedOptionParam({eid: eid0, msgType: SEND, options: options1});
        enforcedOptions[1] = EnforcedOptionParam({eid: eid1, msgType: SEND, options: options2});
        if (block.chainid == 8453) {
            MyOApp(BASE_OFT_MOCK_USDC_ADAPTER).setEnforcedOptions(enforcedOptions);
            MyOApp(BASE_OFT_MOCK_USDT_ADAPTER).setEnforcedOptions(enforcedOptions);
            MyOApp(BASE_OFT_MOCK_WETH_ADAPTER).setEnforcedOptions(enforcedOptions);
        } else if (block.chainid == 42161) {
            MyOApp(ARB_OFT_MOCK_USDCK_ADAPTER).setEnforcedOptions(enforcedOptions);
            MyOApp(ARB_OFT_MOCK_USDTK_ADAPTER).setEnforcedOptions(enforcedOptions);
            MyOApp(ARB_OFT_MOCK_WETHK_ADAPTER).setEnforcedOptions(enforcedOptions);
        }
    }

    function _setOFTAddress() internal {
        if (block.chainid == 8453) {
            IFactory(BASE_lendingPoolFactoryProxy).setOftAddress(BASE_MOCK_USDC, oftusdt);
            IFactory(BASE_lendingPoolFactoryProxy).setOftAddress(BASE_MOCK_USDT, oftusdt);
            IFactory(BASE_lendingPoolFactoryProxy).setOftAddress(BASE_MOCK_WETH, oftweth);
        } else if (block.chainid == 42161) {
            // IFactory(ARB_lendingPoolFactoryProxy).setOftAddress(ARB_MOCK_USDT, oftusdt);
            // IFactory(ARB_lendingPoolFactoryProxy).setOftAddress(ARB_MOCK_WETH, oftweth);
        }
    }

    function _toDynamicArray(address[2] memory fixedArray) internal pure returns (address[] memory) {
        address[] memory dynamicArray = new address[](2);
        dynamicArray[0] = fixedArray[0];
        dynamicArray[1] = fixedArray[1];
        return dynamicArray;
    }
}

// RUN
// forge script DevSkena --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script DevSkena --broadcast -vvv --verify --verifier sourcify --verifier-url https://server-verify.hashscan.io
// forge script DevSkena --broadcast -vvv
// forge script DevSkena -vvv
