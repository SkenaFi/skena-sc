// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Helper} from "../script/L0/Helper.sol";
import {OAppSupplyLiquidityUSDT} from "../src/layerzero/messages/OAppSupplyLiquidityUSDT.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {EnforcedOptionParam} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";
import {ExecutorConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/SendLibBase.sol";
import {MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {OFTUSDTadapter} from "../src/layerzero/OFTUSDTAdapter.sol";
import {SendParam} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OAppAdapter} from "../src/layerzero/messages/OAppAdapter.sol";
// RUN
// forge test -vvv --match-contract DstToOriginTest --match-test test_all_set
contract DstToOriginTest is Test, Helper {
    using OptionsBuilder for bytes;

    OAppAdapter public oappAdapter;
    OAppSupplyLiquidityUSDT public oappSupplyLiquidityUSDT;

    address public owner = vm.envAddress("PUBLIC_KEY");

    // LayerZero
    uint32 dstEid0 = BASE_EID; // Destination chain EID
    uint32 dstEid1 = ARB_EID; // Destination chain EID

    address endpoint;
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

    address BASE_lendingPool = 0xf9C899692C42B2f5fC598615dD529360D533E6Ce;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        console.log("sel", vm.createSelectFork(vm.rpcUrl("base_mainnet")));
        deal(BASE_USDT, owner, 1000000000000000000000000000000000000000);
        vm.startPrank(owner);
        _getUtils();
        _deployOApp();
        _setLibraries();
        _setSendConfig();
        _setReceiveConfig();
        _setPeers();
        _setEnforcedOptions();
        vm.stopPrank();
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
            eid0 = BASE_EID;
            eid1 = ARB_EID;
        }
    }

    function _deployOApp() internal {
        oappAdapter = new OAppAdapter();
        if (block.chainid == 10) {
            oappSupplyLiquidityUSDT = new OAppSupplyLiquidityUSDT(ARB_LZ_ENDPOINT, owner);
        } else if (block.chainid == 8453) {
            oappSupplyLiquidityUSDT = new OAppSupplyLiquidityUSDT(BASE_LZ_ENDPOINT, owner);
        }
    }

    function _setLibraries() internal {
        ILayerZeroEndpointV2(endpoint).setSendLibrary(address(oappSupplyLiquidityUSDT), dstEid0, sendLib);
        ILayerZeroEndpointV2(endpoint).setSendLibrary(address(oappSupplyLiquidityUSDT), dstEid1, sendLib);
        ILayerZeroEndpointV2(endpoint).setReceiveLibrary(
            address(oappSupplyLiquidityUSDT), srcEid, receiveLib, gracePeriod
        );
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
        ILayerZeroEndpointV2(endpoint).setConfig(address(oappSupplyLiquidityUSDT), sendLib, params);
    }

    function _setReceiveConfig() internal {
        uint32 RECEIVE_CONFIG_TYPE = 2;

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

        ILayerZeroEndpointV2(endpoint).setConfig(address(oappSupplyLiquidityUSDT), receiveLib, params);
    }

    function _setPeers() internal {
        bytes32 oftPeer = bytes32(uint256(uint160(address(oappSupplyLiquidityUSDT))));
        OAppSupplyLiquidityUSDT(address(oappSupplyLiquidityUSDT)).setPeer(BASE_EID, oftPeer);
        OAppSupplyLiquidityUSDT(address(oappSupplyLiquidityUSDT)).setPeer(ARB_EID, oftPeer);
    }

    function _setEnforcedOptions() internal {
        uint16 SEND = 1;
        bytes memory options1 = OptionsBuilder.newOptions().addExecutorLzReceiveOption(80000, 0);
        bytes memory options2 = OptionsBuilder.newOptions().addExecutorLzReceiveOption(100000, 0);

        EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](2);
        enforcedOptions[0] = EnforcedOptionParam({eid: dstEid0, msgType: SEND, options: options1});
        enforcedOptions[1] = EnforcedOptionParam({eid: dstEid1, msgType: SEND, options: options2});

        OAppSupplyLiquidityUSDT(address(oappSupplyLiquidityUSDT)).setEnforcedOptions(enforcedOptions);
    }

    // RUN
    // forge test -vvvv --match-test test_SupplyLiquidityCrosschain
    // function test_SupplyLiquidityCrosschain() public {
    //     vm.startPrank(owner);
    //     oappSupplyLiquidityUSDT.setOFTaddress(BASE_OFT_USDT_ADAPTER);

    //     bytes memory extraOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(65000, 0);
    //     SendParam memory sendParam = SendParam({
    //         dstEid: ARB_EID,
    //         to: _addressToBytes32(address(ARB_oappSupplyLiquidityUSDT)), //OAPP DST
    //         amountLD: 1e6,
    //         minAmountLD: 1e6, // 0% slippage tolerance
    //         extraOptions: extraOptions,
    //         composeMsg: "",
    //         oftCmd: ""
    //     });
    //     MessagingFee memory feeBridge = OFTUSDTadapter(BASE_OFT_USDT_ADAPTER).quoteSend(sendParam, false);

    //     MessagingFee memory feeMessage =
    //         oappSupplyLiquidityUSDT.quoteSendString(ARB_EID, BASE_lendingPool, owner, BASE_MOCK_USDT, 1e6, "", false);

    //     IERC20(ARB_USDT).approve(ARB_oappAdapter, 1e6);
    //     OAppAdapter(ARB_oappAdapter).sendBridge{value: feeBridge.nativeFee + feeMessage.nativeFee}(
    //         address(oappSupplyLiquidityUSDT),
    //         ARB_OFT_USDTK_ADAPTER,
    //         BASE_lendingPool,
    //         ARB_MOCK_USDT,// TODO:
    //         ARB_MOCK_USDT,// TODO:
    //         address(oappSupplyLiquidityUSDT),
    //         ARB_EID,
    //         1e6,
    //         feeBridge.nativeFee,
    //         feeMessage.nativeFee
    //     );
    //     vm.stopPrank();
    // }

    function test_all_set() public {
        _getUtils();
        console.log("success");
    }

    function _toDynamicArray(address[2] memory fixedArray) internal pure returns (address[] memory) {
        address[] memory dynamicArray = new address[](2);
        dynamicArray[0] = fixedArray[0];
        dynamicArray[1] = fixedArray[1];
        return dynamicArray;
    }

    function _addressToBytes32(address _address) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }
}
