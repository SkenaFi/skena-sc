// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {OFTadapter} from "../../src/layerzero/OFTadapter.sol";
import {SendParam} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {Helper} from "./Helper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract SendOFT is Script, Helper {
    using OptionsBuilder for bytes;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        vm.createSelectFork(vm.rpcUrl("arb_mainnet"));
        console.log("hello world");
        
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function run() external {
        // Load environment variables
        address toAddress = vm.envAddress("PUBLIC_KEY");
        // *********FILL THIS*********
        address oftAddress = BASE_OFT_USDT_ADAPTER; // src
        address TOKEN = BASE_USDT;
        uint256 amount = 1_000; // amount to send
        uint256 tokensToSend = amount * 10 ** IERC20Metadata(TOKEN).decimals(); // src
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        //*******
        //** DESTINATION
        // uint32 dstEid = BASE_EID; // dst
        uint32 dstEid = ARB_EID; // dst
        //*******
        //***************************

        vm.startBroadcast(privateKey);
        OFTadapter oft = OFTadapter(oftAddress);
        // Build send parameters
        bytes memory extraOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(65000, 0);
        SendParam memory sendParam = SendParam({
            dstEid: dstEid,
            to: addressToBytes32(toAddress),
            amountLD: tokensToSend,
            minAmountLD: tokensToSend,
            extraOptions: extraOptions,
            composeMsg: "",
            oftCmd: ""
        });

        // Get fee quote
        MessagingFee memory fee = oft.quoteSend(sendParam, false);

        console.log("Sending tokens...");
        console.log("Fee amount:", fee.nativeFee);
        console.log("eth before", address(toAddress).balance);
        console.log("TOKEN Balance before", IERC20(TOKEN).balanceOf(toAddress));
        // Send tokens
        IERC20(TOKEN).approve(oftAddress, tokensToSend);
        oft.send{value: fee.nativeFee}(sendParam, fee, msg.sender);
        console.log("eth after", address(toAddress).balance);
        console.log("TOKEN Balance after", IERC20(TOKEN).balanceOf(toAddress));

        vm.stopBroadcast();
    }
}

// RUN
// forge script SendOFT --broadcast -vvv
