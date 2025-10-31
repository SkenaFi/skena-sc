// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {Helper} from "../L0/Helper.sol";
import {MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {OFTUSDTadapter} from "../../src/layerzero/OFTUSDTAdapter.sol";
import {SendParam} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {OAppSupplyLiquidityUSDT} from "../../src/layerzero/messages/OAppSupplyLiquidityUSDT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OAppAdapter} from "../../src/layerzero/messages/OAppAdapter.sol";
import {ElevatedMinterBurner} from "../../src/layerzero/ElevatedMinterBurner.sol";

contract SendMessage is Script, Helper {
    using OptionsBuilder for bytes;

    address owner = vm.envAddress("PUBLIC_KEY");
    OAppSupplyLiquidityUSDT public oappSupplyLiquidityUSDT;
    address token;
    address BASE_lendingPool = 0x3571b96b1418910FD03831d35730172e4d011B06;
    uint256 amount = 100e6;
    address oappAdapter;
    

    function run() external {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        // vm.createSelectFork(vm.rpcUrl("arb_mainnet"));
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        _getUtils();
        _sendMessageSupplyLiquidity();
        // _checkTokenOFT();
        vm.stopBroadcast();
    }

    function _sendMessageSupplyLiquidity() internal {
        bytes memory extraOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(65000, 0);
        SendParam memory sendParam = SendParam({
            dstEid: BASE_EID,
            to: _addressToBytes32(address(BASE_oappSupplyLiquidityUSDT)), //OAPP DST
            amountLD: amount,
            minAmountLD: amount, // 0% slippage tolerance
            extraOptions: extraOptions,
            composeMsg: "",
            oftCmd: ""
        });
        MessagingFee memory feeBridge = OFTUSDTadapter(BASE_OFT_MOCK_USDT_ADAPTER).quoteSend(sendParam, false);

        MessagingFee memory feeMessage = OAppSupplyLiquidityUSDT(BASE_oappSupplyLiquidityUSDT).quoteSendString(
            BASE_EID, BASE_lendingPool, owner, BASE_MOCK_USDT, amount, "", false
        );

        IERC20(BASE_MOCK_USDT).approve(oappAdapter, amount);
        OAppAdapter(oappAdapter).sendBridge{value: feeBridge.nativeFee + feeMessage.nativeFee}(
            address(BASE_oappSupplyLiquidityUSDT),
            BASE_OFT_MOCK_USDT_ADAPTER,
            BASE_lendingPool,
            BASE_MOCK_USDT,
            ARB_MOCK_USDTK,
            address(BASE_oappSupplyLiquidityUSDT),
            BASE_EID,
            amount,
            feeBridge.nativeFee,
            feeMessage.nativeFee
        );

        console.log("SupplyLiquidityCrosschain");
    }

    function _checkTokenOFT() internal view {
        if (block.chainid == 10) {
            console.log("tokenOFT", OFTUSDTadapter(ARB_OFT_MOCK_USDTK_ADAPTER).tokenOFT());
            console.log("elevated", OFTUSDTadapter(ARB_OFT_MOCK_USDTK_ADAPTER).elevatedMinterBurner());
            console.log(
                "elevated operator",
                ElevatedMinterBurner(ARB_MOCK_USDTK_ELEVATED_MINTER_BURNER).operators(ARB_OFT_MOCK_USDTK_ADAPTER)
            );
        } else if (block.chainid == 8453) {
            console.log("tokenOFT", OFTUSDTadapter(BASE_OFT_USDT_ADAPTER).tokenOFT());
            console.log("elevated", OFTUSDTadapter(BASE_OFT_USDT_ADAPTER).elevatedMinterBurner());
            console.log("tokenOFT", OFTUSDTadapter(BASE_OFT_MOCK_USDT_ADAPTER).tokenOFT());
            console.log("elevated", OFTUSDTadapter(BASE_OFT_MOCK_USDT_ADAPTER).elevatedMinterBurner());
        }
    }

    function _getUtils() internal {
        if (block.chainid == 10) {
            token = ARB_USDTK;
            oappAdapter = ARB_oappAdapter;
        } else if (block.chainid == 8453) {
            token = ARB_MOCK_USDTK;
        }
    }

    function _addressToBytes32(address _address) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }
}

// RUN
//  forge script SendMessage --broadcast -vvv
//  forge script SendMessage -vvv
