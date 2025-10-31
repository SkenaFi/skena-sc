// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";
import {Helper} from "./Helper.sol";

/// @title LayerZero Receive Configuration Script (B ← A)
/// @notice Defines and applies ULN (DVN) config for inbound message verification on Chain B for messages received from Chain A via LayerZero Endpoint V2.
contract SetReceiveConfig is Script, Helper {
    uint32 constant RECEIVE_CONFIG_TYPE = 2;

    // destination
    uint32 eid0 = BASE_EID;
    uint32 eid1 = ARB_EID;

    address endpoint;
    address oapp;
    address receiveLib;
    address dvn1;
    address dvn2;

    /// @notice Helper function to convert fixed-size array to dynamic array
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

    function _getUtils() internal {
        if (block.chainid == 8453) {
            endpoint = BASE_LZ_ENDPOINT;
            receiveLib = BASE_RECEIVE_LIB;
            dvn1 = BASE_DVN1;
            dvn2 = BASE_DVN2;
        } else if (block.chainid == 10) {
            endpoint = ARB_LZ_ENDPOINT;
            receiveLib = ARB_RECEIVE_LIB;
            dvn1 = ARB_DVN1;
            dvn2 = ARB_DVN2;
        }
    }

    function run() external {
        deployBASE();
        deployOP();
        // hyperevm
    }

    function deployBASE() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        _getUtils();
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

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        ILayerZeroEndpointV2(endpoint).setConfig(BASE_OFT_USDC_ADAPTER, receiveLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(BASE_OFT_USDT_ADAPTER, receiveLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(BASE_OFT_WBTC_ADAPTER, receiveLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(BASE_OFT_WETH_ADAPTER, receiveLib, params);
        vm.stopBroadcast();
    }

    function deployOP() public {
        vm.createSelectFork(vm.rpcUrl("arb_mainnet"));
        _getUtils();
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

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        ILayerZeroEndpointV2(endpoint).setConfig(ARB_OFT_USDCK_ADAPTER, receiveLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(ARB_OFT_USDTK_ADAPTER, receiveLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(ARB_OFT_WBTCK_ADAPTER, receiveLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(ARB_OFT_WETHK_ADAPTER, receiveLib, params);
        vm.stopBroadcast();
    }
}

// RUN
// forge script SetReceiveConfig --broadcast -vvv
// forge script SetReceiveConfig -vvv
