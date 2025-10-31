// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {LendingPoolFactory} from "../src/LendingPoolFactory.sol";
import {ILendingPool} from "../src/interfaces/ILendingPool.sol";
import {ILPRouter} from "../src/interfaces/ILPRouter.sol";
import {IsHealthy} from "../src/IsHealthy.sol";
import {LendingPoolDeployer} from "../src/LendingPoolDeployer.sol";
import {Protocol} from "../src/Protocol.sol";
import {Oracle} from "../src/Oracle.sol";
import {Liquidator} from "../src/Liquidator.sol";
import {IOracle} from "../src/interfaces/IOracle.sol";
import {OFTETHadapter} from "../src/layerzero/OFTETHadapter.sol";
import {OFTWETHadapter} from "../src/layerzero/OFTWETHadapter.sol";
import {OFTWBTCadapter} from "../src/layerzero/OFTWBTCadapter.sol";
import {OFTUSDTadapter} from "../src/layerzero/OFTUSDTadapter.sol";
import {OFTWHBARadapter} from "../src/layerzero/OFTWHBARadapter.sol";
import {ElevatedMinterBurner} from "../src/layerzero/ElevatedMinterBurner.sol";
import {Helper} from "../script/L0/Helper.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";
import {ExecutorConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/SendLibBase.sol";
import {MyOApp} from "../src/layerzero/MyOApp.sol";
import {EnforcedOptionParam} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {HelperUtils} from "../src/HelperUtils.sol";
import {IFactory} from "../src/interfaces/IFactory.sol";
import {IPosition} from "../src/interfaces/IPosition.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {PositionDeployer} from "../src/PositionDeployer.sol";
import {LendingPoolRouterDeployer} from "../src/LendingPoolRouterDeployer.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {USDC as MOCKUSDC} from "../src/MockToken/USDC.sol";
import {USDT as MOCKUSDT} from "../src/MockToken/USDT.sol";
import {WETH as MOCKWETH} from "../src/MockToken/WETH.sol";
import {WHBAR as MOCKWHBAR} from "../src/MockToken/WHBAR.sol";
import {WBTC as MOCKWBTC} from "../src/MockToken/WBTC.sol";

interface IOrakl {
    function latestRoundData() external view returns (uint80, int256, uint256);
    function decimals() external view returns (uint8);
}

// RUN
// forge test --match-contract SenjaTest -vvv
contract SenjaTest is Test, Helper {
    using OptionsBuilder for bytes;

    IsHealthy public isHealthy;
    Liquidator public liquidator;
    LendingPoolRouterDeployer public lendingPoolRouterDeployer;
    LendingPoolDeployer public lendingPoolDeployer;
    Protocol public protocol;
    PositionDeployer public positionDeployer;
    LendingPoolFactory public lendingPoolFactory;
    LendingPoolFactory public newImplementation;
    Oracle public oracle;
    OFTUSDTadapter public oftusdtadapter;
    OFTETHadapter public oftethadapter;
    OFTWETHadapter public oftwethadapter;
    OFTWBTCadapter public oftbtcadapter;
    OFTWHBARadapter public oftwhbaradapter;

    ElevatedMinterBurner public elevatedminterburner;
    HelperUtils public helperUtils;
    ERC1967Proxy public proxy;

    MOCKUSDC public mockUSDC;
    MOCKUSDT public mockUSDT;
    MOCKWETH public mockWeth;
    MOCKWHBAR public mockWhbar;
    MOCKWBTC public mockWBTC;

    address public lendingPool;
    address public lendingPool2;
    address public lendingPool3;

    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");

    address public USDT;
    address public NATIVE = address(1);
    address public WNATIVE;
    address public WBTC;
    // Using WNATIVE instead of native token address(1) for better DeFi composability

    address public usdt_usd_adapter;
    address public eth_usd_adapter;
    address public btc_usd_adapter;

    address public ofteth_adapter;
    address public oftwhbar_adapter;
    address public oftweth_adapter;
    address public oftusdt_adapter;
    address public oftwbtc_adapter;
    // LayerZero
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

    function setUp() public {
        // vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        vm.createSelectFork(vm.rpcUrl("hedera_mainnet"));
        vm.startPrank(owner);
        _getUtils();
        _deployTokens();
        // *************** layerzero ***************
        _deployOFT();
        _setLibraries();
        _setSendConfig();
        _setReceiveConfig();
        _setPeers();
        _setEnforcedOptions();
        // *****************************************

        _deployOracleAdapter();
        _deployFactory();
        helperUtils = new HelperUtils(address(proxy));
        lendingPool = IFactory(address(proxy)).createLendingPool(WNATIVE, USDT, 8e17);
        lendingPool2 = IFactory(address(proxy)).createLendingPool(USDT, WNATIVE, 8e17);
        lendingPool3 = IFactory(address(proxy)).createLendingPool(NATIVE, USDT, 8e17);
        _setOFTAddress();
        deal(USDT, alice, 100_000e6);
        deal(WNATIVE, alice, 100_000 ether);
        vm.deal(alice, 100_000 ether);
        vm.stopPrank();
    }

    function _getUtils() internal {
        if (block.chainid == 295) {
            endpoint = HBAR_LZ_ENDPOINT;
            // oapp = HBAR_OAPP;
            sendLib = HBAR_SEND_LIB;
            receiveLib = HBAR_RECEIVE_LIB;
            srcEid = HBAR_EID;
            gracePeriod = uint32(0);
            dvn1 = HBAR_DVN1;
            dvn2 = HBAR_DVN2;
            executor = HBAR_EXECUTOR;
            eid0 = HBAR_EID;
            eid1 = BASE_EID;
        } else if (block.chainid == 8453) {
            endpoint = BASE_LZ_ENDPOINT;
            // oapp = BASE_OAPP;
            sendLib = BASE_SEND_LIB;
            receiveLib = BASE_RECEIVE_LIB;
            srcEid = BASE_EID;
            gracePeriod = uint32(0);
            dvn1 = BASE_DVN1;
            dvn2 = BASE_DVN2;
            executor = BASE_EXECUTOR;
            eid0 = BASE_EID;
            eid1 = ARB_EID;
            USDT = BASE_USDT;
            WNATIVE = BASE_WETH;
            WBTC = BASE_WBTC;
        } else if (block.chainid == 42161) {
            endpoint = ARB_LZ_ENDPOINT;
            // oapp = ARB_OAPP;
            sendLib = ARB_SEND_LIB;
            receiveLib = ARB_RECEIVE_LIB;
            srcEid = ARB_EID;
            gracePeriod = uint32(0);
            dvn1 = ARB_DVN1;
            dvn2 = ARB_DVN2;
            executor = ARB_EXECUTOR;
            eid0 = ARB_EID;
            eid1 = BASE_EID;
            USDT = ARB_USDT;
            WNATIVE = ARB_WETH;
            WBTC = ARB_WBTC;
        }
    }

    function _deployTokens() internal {
        mockUSDC = new MOCKUSDC();
        mockUSDT = new MOCKUSDT();
        mockWeth = new MOCKWETH();
        mockWBTC = new MOCKWBTC();
        if (block.chainid == 295) {
            mockWhbar = new MOCKWHBAR();

            console.log("address public HBAR_mockUSDC =", address(mockUSDC), ";");
            console.log("address public HBAR_mockUSDT =", address(mockUSDT), ";");
            console.log("address public HBAR_mockWeth =", address(mockWeth), ";");
            console.log("address public HBAR_mockWhbar =", address(mockWhbar), ";");
            USDT = address(mockUSDT);
            WNATIVE = address(mockWhbar);
            WBTC = address(mockWBTC);
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

    function _deployOFT() internal {
        if (block.chainid == 295) {
            oftusdtadapter = new OFTUSDTadapter(USDT, address(0), endpoint, owner);
            oftusdt_adapter = address(oftusdtadapter);
            oapp = address(oftusdtadapter);

            console.log("decimals", IERC20Metadata(WNATIVE).decimals());
            oftwhbaradapter = new OFTWHBARadapter(WNATIVE, address(0), endpoint, owner);
            oftwhbar_adapter = address(oftwhbaradapter);
            oapp2 = address(oftwhbaradapter);

            oftbtcadapter = new OFTWBTCadapter(WBTC, address(0), endpoint, owner);
            oftwbtc_adapter = address(oftbtcadapter);
            oapp3 = address(oftbtcadapter);
        } else if (block.chainid == 8453) {
            oftusdtadapter = new OFTUSDTadapter(USDT, address(0), BASE_LZ_ENDPOINT, owner);
            oftusdt_adapter = address(oftusdtadapter);
            oapp = address(oftusdtadapter);

            oftwethadapter = new OFTWETHadapter(WNATIVE, address(0), BASE_LZ_ENDPOINT, owner);
            oftweth_adapter = address(oftwethadapter);
            oapp2 = address(oftwethadapter);

            oftbtcadapter = new OFTWBTCadapter(WBTC, address(0), BASE_LZ_ENDPOINT, owner);
            oftwbtc_adapter = address(oftbtcadapter);
            oapp3 = address(oftbtcadapter);
        } else if (block.chainid == 42161) {
            elevatedminterburner = new ElevatedMinterBurner(USDT, owner);
            oftusdtadapter = new OFTUSDTadapter(USDT, address(elevatedminterburner), BASE_LZ_ENDPOINT, owner);
            oftusdt_adapter = address(oftusdtadapter);
            oapp = address(oftusdtadapter);

            elevatedminterburner = new ElevatedMinterBurner(WNATIVE, owner);
            oftwethadapter = new OFTWETHadapter(WNATIVE, address(elevatedminterburner), BASE_LZ_ENDPOINT, owner);
            oftweth_adapter = address(oftwethadapter);
            oapp2 = address(oftwethadapter);

            elevatedminterburner = new ElevatedMinterBurner(WBTC, owner);
            oftbtcadapter = new OFTWBTCadapter(WBTC, address(elevatedminterburner), BASE_LZ_ENDPOINT, owner);
            oftwbtc_adapter = address(oftbtcadapter);
            oapp3 = address(oftbtcadapter);
        }
    }

    function _setLibraries() internal {
        _getUtils();
        ILayerZeroEndpointV2(endpoint).setSendLibrary(oapp, dstEid0, sendLib);
        ILayerZeroEndpointV2(endpoint).setSendLibrary(oapp, dstEid1, sendLib);
        ILayerZeroEndpointV2(endpoint).setReceiveLibrary(oapp, srcEid, receiveLib, gracePeriod);

        ILayerZeroEndpointV2(endpoint).setSendLibrary(oapp2, dstEid0, sendLib);
        ILayerZeroEndpointV2(endpoint).setSendLibrary(oapp2, dstEid1, sendLib);
        ILayerZeroEndpointV2(endpoint).setReceiveLibrary(oapp2, srcEid, receiveLib, gracePeriod);

        ILayerZeroEndpointV2(endpoint).setSendLibrary(oapp3, dstEid0, sendLib);
        ILayerZeroEndpointV2(endpoint).setSendLibrary(oapp3, dstEid1, sendLib);
        ILayerZeroEndpointV2(endpoint).setReceiveLibrary(oapp3, srcEid, receiveLib, gracePeriod);
    }

    function _setSendConfig() internal {
        _getUtils();
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
        ILayerZeroEndpointV2(endpoint).setConfig(oapp, sendLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(oapp2, sendLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(oapp3, sendLib, params);
    }

    function _setReceiveConfig() internal {
        uint32 RECEIVE_CONFIG_TYPE = 2;
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

        ILayerZeroEndpointV2(endpoint).setConfig(oapp, receiveLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(oapp2, receiveLib, params);
        ILayerZeroEndpointV2(endpoint).setConfig(oapp3, receiveLib, params);
    }

    function _setPeers() internal {
        bytes32 oftPeer = bytes32(uint256(uint160(address(oapp)))); // oapp
        OFTUSDTadapter(oapp).setPeer(BASE_EID, oftPeer);
        OFTUSDTadapter(oapp).setPeer(ARB_EID, oftPeer);

        bytes32 oftPeer2 = bytes32(uint256(uint160(address(oapp2)))); // oapp2
        OFTETHadapter(oapp2).setPeer(BASE_EID, oftPeer2);
        OFTETHadapter(oapp2).setPeer(ARB_EID, oftPeer2);

        bytes32 oftPeer3 = bytes32(uint256(uint160(address(oapp3))));
        OFTWBTCadapter(oapp3).setPeer(BASE_EID, oftPeer3);
        OFTWBTCadapter(oapp3).setPeer(ARB_EID, oftPeer3);
    }

    function _setEnforcedOptions() internal {
        uint16 SEND = 1;
        bytes memory options1 = OptionsBuilder.newOptions().addExecutorLzReceiveOption(80000, 0);
        bytes memory options2 = OptionsBuilder.newOptions().addExecutorLzReceiveOption(100000, 0);

        EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](2);
        enforcedOptions[0] = EnforcedOptionParam({eid: dstEid0, msgType: SEND, options: options1});
        enforcedOptions[1] = EnforcedOptionParam({eid: dstEid1, msgType: SEND, options: options2});

        MyOApp(oapp).setEnforcedOptions(enforcedOptions);
        MyOApp(oapp2).setEnforcedOptions(enforcedOptions);
        MyOApp(oapp3).setEnforcedOptions(enforcedOptions);
    }

    function _deployOracleAdapter() internal {
        oracle = new Oracle(usdt_usd);
        usdt_usd_adapter = address(oracle);

        oracle = new Oracle(eth_usd);
        eth_usd_adapter = address(oracle);

        oracle = new Oracle(btc_usd);
        btc_usd_adapter = address(oracle);
    }

    function _deployFactory() internal {
        liquidator = new Liquidator();
        isHealthy = new IsHealthy(address(liquidator));
        lendingPoolDeployer = new LendingPoolDeployer();
        lendingPoolRouterDeployer = new LendingPoolRouterDeployer();
        protocol = new Protocol();
        positionDeployer = new PositionDeployer();

        lendingPoolFactory = new LendingPoolFactory();
        bytes memory data = abi.encodeWithSelector(
            lendingPoolFactory.initialize.selector,
            address(isHealthy),
            address(lendingPoolRouterDeployer),
            address(lendingPoolDeployer),
            address(protocol),
            address(positionDeployer)
        );
        proxy = new ERC1967Proxy(address(lendingPoolFactory), data);

        lendingPoolDeployer.setFactory(address(proxy));
        lendingPoolRouterDeployer.setFactory(address(proxy));

        IFactory(address(proxy)).addTokenDataStream(USDT, usdt_usd_adapter);
        IFactory(address(proxy)).addTokenDataStream(WNATIVE, eth_usd_adapter);
        IFactory(address(proxy)).addTokenDataStream(NATIVE, eth_usd_adapter);
        IFactory(address(proxy)).addTokenDataStream(WBTC, btc_usd_adapter);
    }

    function _setOFTAddress() internal {
        IFactory(address(proxy)).setOftAddress(NATIVE, oftweth_adapter);
        IFactory(address(proxy)).setOftAddress(WNATIVE, oftweth_adapter);
        IFactory(address(proxy)).setOftAddress(USDT, oftusdt_adapter);
        IFactory(address(proxy)).setOftAddress(WBTC, oftwbtc_adapter);
    }

    // RUN
    // forge test --match-test test_factory -vvv
    function test_factory() public view {
        // address router = ILendingPool(lendingPool).router();
        // assertEq(ILPRouter(router).lendingPool(), address(lendingPool));
        // assertEq(ILPRouter(router).factory(), address(proxy));
        // assertEq(ILPRouter(router).collateralToken(), WNATIVE);
        // assertEq(ILPRouter(router).borrowToken(), USDT);
        // assertEq(ILPRouter(router).ltv(), 8e17);
    }

    // RUN
    // forge test --match-test test_oftaddress -vvv
    function test_oftaddress() public view {
        assertEq(IFactory(address(proxy)).oftAddress(WNATIVE), oftweth_adapter);
        assertEq(IFactory(address(proxy)).oftAddress(USDT), oftusdt_adapter);
        assertEq(IFactory(address(proxy)).oftAddress(WBTC), oftwbtc_adapter);
    }

    // RUN
    // forge test --match-test test_checkorakl --match-contract SenjaTest -vvv
    function test_checkorakl() public view {
        console.log("blockchainid", block.chainid);
        (, uint256 price3,,,) = IOracle(usdt_usd_adapter).latestRoundData();
        console.log("usdt_usd_adapter price", price3);
        uint8 decimals3 = IOracle(usdt_usd_adapter).decimals();
        console.log("usdt_usd_adapter decimals", decimals3);
        (, uint256 price5,,,) = IOracle(eth_usd_adapter).latestRoundData();
        console.log("eth_usd_adapter price", price5);
        uint8 decimals5 = IOracle(eth_usd_adapter).decimals();
        console.log("eth_usd_adapter decimals", decimals5);
        (, uint256 price6,,,) = IOracle(btc_usd_adapter).latestRoundData();
        console.log("btc_usd_adapter price", price6);
        uint8 decimals6 = IOracle(btc_usd_adapter).decimals();
        console.log("btc_usd_adapter decimals", decimals6);
    }

    // RUN
    // forge test --match-test test_supply_liquidity -vvv
    function test_supply_liquidity() public {
        vm.startPrank(alice);

        // Supply 1000 USDT as liquidity
        IERC20(USDT).approve(lendingPool, 1_000e6);
        ILendingPool(lendingPool).supplyLiquidity(alice, 1_000e6);

        // Supply 1000 WNATIVE as liquidity
        IERC20(WNATIVE).approve(lendingPool2, 1_000 ether);
        ILendingPool(lendingPool2).supplyLiquidity(alice, 1_000 ether);

        // Supply 1000 USDT as liquidity (borrow token for lendingPool3)
        IERC20(USDT).approve(lendingPool3, 1_000e6);
        ILendingPool(lendingPool3).supplyLiquidity(alice, 1_000e6);
        vm.stopPrank();

        // Check balances
        assertEq(IERC20(USDT).balanceOf(lendingPool), 1_000e6);
        assertEq(IERC20(WNATIVE).balanceOf(lendingPool2), 1_000 ether);
        assertEq(IERC20(USDT).balanceOf(lendingPool3), 1_000e6);
    }

    // RUN
    // forge test --match-test test_withdraw_liquidity -vvv
    function test_withdraw_liquidity() public {
        test_supply_liquidity();
        vm.startPrank(alice);
        ILendingPool(lendingPool).withdrawLiquidity(1_000e6);
        ILendingPool(lendingPool2).withdrawLiquidity(1_000 ether);
        ILendingPool(lendingPool3).withdrawLiquidity(1_000e6);
        vm.stopPrank();

        assertEq(IERC20(USDT).balanceOf(lendingPool), 0);
        assertEq(IERC20(WNATIVE).balanceOf(lendingPool2), 0);
        assertEq(IERC20(USDT).balanceOf(lendingPool3), 0);
    }

    // RUN
    // forge test --match-test test_supply_collateral -vvv
    function test_supply_collateral() public {
        vm.startPrank(alice);

        IERC20(WNATIVE).approve(lendingPool, 1000 ether);
        ILendingPool(lendingPool).supplyCollateral(1000 ether, alice);

        IERC20(USDT).approve(lendingPool2, 1_000e6);
        ILendingPool(lendingPool2).supplyCollateral(1_000e6, alice);

        ILendingPool(lendingPool3).supplyCollateral{value: 1_000 ether}(1_000 ether, alice);
        vm.stopPrank();

        assertEq(IERC20(WNATIVE).balanceOf(_addressPosition(lendingPool, alice)), 1000 ether);
        assertEq(IERC20(USDT).balanceOf(_addressPosition(lendingPool2, alice)), 1_000e6);
        assertEq(IERC20(WNATIVE).balanceOf(_addressPosition(lendingPool3, alice)), 1000 ether);
    }

    // RUN
    // forge test --match-test test_withdraw_collateral -vvv
    function test_withdraw_collateral() public {
        test_supply_collateral();
        vm.startPrank(alice);
        ILendingPool(lendingPool).withdrawCollateral(1_000 ether);
        ILendingPool(lendingPool2).withdrawCollateral(1_000e6);
        ILendingPool(lendingPool3).withdrawCollateral(1_000 ether);
        vm.stopPrank();

        assertEq(IERC20(WNATIVE).balanceOf(_addressPosition(lendingPool, alice)), 0);
        assertEq(IERC20(USDT).balanceOf(_addressPosition(lendingPool2, alice)), 0);
        assertEq(IERC20(WNATIVE).balanceOf(_addressPosition(lendingPool3, alice)), 0);
    }

    // RUN
    // forge test --match-test test_borrow_debt -vvv
    function test_borrow_debt() public {
        test_supply_liquidity();
        test_supply_collateral();

        vm.startPrank(alice);
        ILendingPool(lendingPool).borrowDebt(10e6, block.chainid, BASE_EID, 65000);
        ILendingPool(lendingPool2).borrowDebt(0.01 ether, block.chainid, BASE_EID, 65000);
        ILendingPool(lendingPool3).borrowDebt(10e6, block.chainid, BASE_EID, 65000);
        ILendingPool(lendingPool).borrowDebt(10e6, block.chainid, BASE_EID, 65000);
        ILendingPool(lendingPool2).borrowDebt(0.01 ether, block.chainid, BASE_EID, 65000);
        ILendingPool(lendingPool3).borrowDebt(10e6, block.chainid, BASE_EID, 65000);
        vm.stopPrank();

        assertEq(ILPRouter(_router(lendingPool)).userBorrowShares(alice), 2 * 10e6);
        assertEq(ILPRouter(_router(lendingPool)).totalBorrowAssets(), 2 * 10e6);
        assertEq(ILPRouter(_router(lendingPool)).totalBorrowShares(), 2 * 10e6);
        assertEq(ILPRouter(_router(lendingPool2)).userBorrowShares(alice), 2 * 0.01 ether);
        assertEq(ILPRouter(_router(lendingPool2)).totalBorrowAssets(), 2 * 0.01 ether);
        assertEq(ILPRouter(_router(lendingPool2)).totalBorrowShares(), 2 * 0.01 ether);
        assertEq(ILPRouter(_router(lendingPool3)).userBorrowShares(alice), 2 * 10e6);
        assertEq(ILPRouter(_router(lendingPool3)).totalBorrowAssets(), 2 * 10e6);
        assertEq(ILPRouter(_router(lendingPool3)).totalBorrowShares(), 2 * 10e6);
    }

    // RUN
    // forge test --match-test test_repay_debt -vvv
    function test_repay_debt() public {
        test_borrow_debt();

        vm.startPrank(alice);
        IERC20(USDT).approve(lendingPool, 10e6);
        ILendingPool(lendingPool).repayWithSelectedToken(10e6, USDT, false, alice, 500);
        IERC20(USDT).approve(lendingPool, 10e6);
        ILendingPool(lendingPool).repayWithSelectedToken(10e6, USDT, false, alice, 500);
        IERC20(WNATIVE).approve(lendingPool2, 0.01 ether);
        ILendingPool(lendingPool2).repayWithSelectedToken(0.01 ether, WNATIVE, false, alice, 500);
        IERC20(WNATIVE).approve(lendingPool2, 0.01 ether);
        ILendingPool(lendingPool2).repayWithSelectedToken(0.01 ether, WNATIVE, false, alice, 500);

        IERC20(USDT).approve(lendingPool3, 10e6);
        ILendingPool(lendingPool3).repayWithSelectedToken(10e6, USDT, false, alice, 500);
        IERC20(USDT).approve(lendingPool3, 10e6);
        ILendingPool(lendingPool3).repayWithSelectedToken(10e6, USDT, false, alice, 500);
        vm.stopPrank();

        assertEq(ILPRouter(_router(lendingPool)).userBorrowShares(alice), 0);
        assertEq(ILPRouter(_router(lendingPool2)).userBorrowShares(alice), 0);
        assertEq(ILPRouter(_router(lendingPool3)).userBorrowShares(alice), 0);
        assertEq(ILPRouter(_router(lendingPool)).totalBorrowAssets(), 0);
        assertEq(ILPRouter(_router(lendingPool2)).totalBorrowAssets(), 0);
        assertEq(ILPRouter(_router(lendingPool3)).totalBorrowAssets(), 0);
        assertEq(ILPRouter(_router(lendingPool)).totalBorrowShares(), 0);
        assertEq(ILPRouter(_router(lendingPool2)).totalBorrowShares(), 0);
        assertEq(ILPRouter(_router(lendingPool3)).totalBorrowShares(), 0);
    }

    // RUN
    // forge test --match-test test_borrow_crosschain -vvv
    function test_borrow_crosschain() public {
        test_supply_liquidity();
        test_supply_collateral();

        // Provide enough NATIVE for LayerZero cross-chain fees
        vm.deal(alice, 10 ether);

        vm.startPrank(alice);

        uint256 fee = helperUtils.getFee(oftusdt_adapter, BASE_EID, alice, 10e6);
        ILendingPool(lendingPool).borrowDebt{value: fee}(10e6, 8453, BASE_EID, 65000);
        fee = helperUtils.getFee(oftusdt_adapter, BASE_EID, alice, 10e6);
        ILendingPool(lendingPool).borrowDebt{value: fee}(10e6, 8453, BASE_EID, 65000);

        fee = helperUtils.getFee(oftweth_adapter, BASE_EID, alice, 0.01 ether);
        ILendingPool(lendingPool2).borrowDebt{value: fee}(0.01 ether, 8453, BASE_EID, 65000);
        fee = helperUtils.getFee(oftweth_adapter, BASE_EID, alice, 0.01 ether);
        ILendingPool(lendingPool2).borrowDebt{value: fee}(0.01 ether, 8453, BASE_EID, 65000);

        fee = helperUtils.getFee(oftusdt_adapter, BASE_EID, alice, 10e6);
        ILendingPool(lendingPool3).borrowDebt{value: fee}(10e6, 8453, BASE_EID, 65000);
        fee = helperUtils.getFee(oftusdt_adapter, BASE_EID, alice, 10e6);
        ILendingPool(lendingPool3).borrowDebt{value: fee}(10e6, 8453, BASE_EID, 65000);

        vm.stopPrank();

        assertEq(ILPRouter(_router(lendingPool)).userBorrowShares(alice), 2 * 10e6);
        assertEq(ILPRouter(_router(lendingPool)).totalBorrowAssets(), 2 * 10e6);
        assertEq(ILPRouter(_router(lendingPool)).totalBorrowShares(), 2 * 10e6);
        assertEq(ILPRouter(_router(lendingPool2)).userBorrowShares(alice), 2 * 0.01 ether);
        assertEq(ILPRouter(_router(lendingPool2)).totalBorrowAssets(), 2 * 0.01 ether);
        assertEq(ILPRouter(_router(lendingPool2)).totalBorrowShares(), 2 * 0.01 ether);
        assertEq(ILPRouter(_router(lendingPool3)).userBorrowShares(alice), 2 * 10e6);
        assertEq(ILPRouter(_router(lendingPool3)).totalBorrowAssets(), 2 * 10e6);
        assertEq(ILPRouter(_router(lendingPool3)).totalBorrowShares(), 2 * 10e6);
    }

    // RUN
    // forge test --match-contract SenjaTest --match-test test_swap_collateral -vvv
    function test_swap_collateral() public {
        test_supply_collateral();
        vm.startPrank(alice);
        console.log("WNATIVE balance before", IERC20(WNATIVE).balanceOf(_addressPosition(lendingPool2, alice)));
        console.log("WNATIVE balance before", IERC20(WNATIVE).balanceOf(_addressPosition(lendingPool2, alice)));

        IPosition(_addressPosition(lendingPool2, alice)).swapTokenByPosition(USDT, WNATIVE, 100e6, 100); // 1% slippage tolerance
        vm.stopPrank();

        console.log("USDT balance after", IERC20(USDT).balanceOf(_addressPosition(lendingPool2, alice)));
        console.log("WNATIVE balance after", IERC20(WNATIVE).balanceOf(_addressPosition(lendingPool2, alice)));
    }

    function _addressPosition(address _lendingPool, address _user) internal view returns (address) {
        return ILPRouter(_router(_lendingPool)).addressPositions(_user);
    }

    function _router(address _lendingPool) internal view returns (address) {
        return ILendingPool(_lendingPool).router();
    }

    function _toDynamicArray(address[2] memory fixedArray) internal pure returns (address[] memory) {
        address[] memory dynamicArray = new address[](2);
        dynamicArray[0] = fixedArray[0];
        dynamicArray[1] = fixedArray[1];
        return dynamicArray;
    }

    // RUN
    // forge test --match-test test_comprehensive_collateral_swap_repay -vvv
    function test_comprehensive_collateral_swap_repay() public {
        // Step 1: Supply liquidity to enable borrowing
        test_supply_liquidity();

        // Step 2: Supply collateral
        test_supply_collateral();

        // Step 3: Borrow debt
        vm.startPrank(alice);
        ILendingPool(lendingPool).borrowDebt(50e6, block.chainid, BASE_EID, 65000);
        vm.stopPrank();

        // Verify initial state
        assertEq(ILPRouter(_router(lendingPool)).userBorrowShares(alice), 50e6);
        assertEq(ILPRouter(_router(lendingPool)).totalBorrowAssets(), 50e6);

        // Get position address
        address position = _addressPosition(lendingPool, alice);

        // Step 4: Test swapping collateral (WNATIVE) to borrow token (USDT) with high slippage
        vm.startPrank(alice);

        // Check initial balances
        console.log("Initial WNATIVE in position:", IERC20(WNATIVE).balanceOf(position));
        console.log("Initial USDT in position:", IERC20(USDT).balanceOf(position));

        // Swap WNATIVE to USDT with 10000 slippage tolerance (100%)
        IPosition(position).swapTokenByPosition(WNATIVE, USDT, 100 ether, 10000);

        // Check balances after swap
        console.log("Final WNATIVE in position:", IERC20(WNATIVE).balanceOf(position));
        console.log("Final USDT in position:", IERC20(USDT).balanceOf(position));

        vm.stopPrank();

        // Step 5: Test swapping collateral to WNATIVE (simulated with WNATIVE)
        vm.startPrank(alice);

        // Check balances before second swap
        console.log("Before second swap - WNATIVE:", IERC20(WNATIVE).balanceOf(position));
        console.log("Before second swap - USDT:", IERC20(USDT).balanceOf(position));

        // Swap USDT back to WNATIVE (simulating WNATIVE) with high slippage
        IPosition(position).swapTokenByPosition(USDT, WNATIVE, 10e6, 10000);

        // Check balances after second swap
        console.log("After second swap - WNATIVE:", IERC20(WNATIVE).balanceOf(position));
        console.log("After second swap - USDT:", IERC20(USDT).balanceOf(position));

        vm.stopPrank();

        // Step 6: Test repaying using collateral with high slippage tolerance
        vm.startPrank(alice);

        // Check balances before repayment
        console.log("Before repayment - WNATIVE:", IERC20(WNATIVE).balanceOf(position));
        console.log("Before repayment - USDT:", IERC20(USDT).balanceOf(position));

        // Repay using USDT directly
        IERC20(USDT).approve(lendingPool, 5e6);
        ILendingPool(lendingPool).repayWithSelectedToken(5e6, USDT, false, alice, 500);

        // Check balances after repayment
        console.log("After repayment - WNATIVE:", IERC20(WNATIVE).balanceOf(position));
        console.log("After repayment - USDT:", IERC20(USDT).balanceOf(position));

        vm.stopPrank();

        // Verify repayment worked
        assertLt(ILPRouter(_router(lendingPool)).userBorrowShares(alice), 50e6);
        assertLt(ILPRouter(_router(lendingPool)).totalBorrowAssets(), 50e6);

        console.log("Remaining borrow shares:", ILPRouter(_router(lendingPool)).userBorrowShares(alice));
        console.log("Remaining total borrow assets:", ILPRouter(_router(lendingPool)).totalBorrowAssets());
    }

    // RUN
    // forge test --match-test test_repay_with_high_slippage -vvv
    function test_repay_with_high_slippage() public {
        // Setup: Supply liquidity, collateral, and borrow
        test_supply_liquidity();
        test_supply_collateral();

        vm.startPrank(alice);
        ILendingPool(lendingPool).borrowDebt(20e6, block.chainid, BASE_EID, 65000);
        vm.stopPrank();

        address position = _addressPosition(lendingPool, alice);

        // Test repaying with USDT directly (no swap needed)
        vm.startPrank(alice);

        // Check initial state
        console.log("Initial WNATIVE in position:", IERC20(WNATIVE).balanceOf(position));
        console.log("Initial USDT in position:", IERC20(USDT).balanceOf(position));
        console.log("Initial borrow shares:", ILPRouter(_router(lendingPool)).userBorrowShares(alice));

        // Repay using USDT directly (this should work without swapping)
        IERC20(USDT).approve(lendingPool, 10e6);
        ILendingPool(lendingPool).repayWithSelectedToken(10e6, USDT, false, alice, 500);

        // Check final state
        console.log("Final WNATIVE in position:", IERC20(WNATIVE).balanceOf(position));
        console.log("Final USDT in position:", IERC20(USDT).balanceOf(position));
        console.log("Final borrow shares:", ILPRouter(_router(lendingPool)).userBorrowShares(alice));

        vm.stopPrank();

        // Verify some repayment occurred
        assertLt(ILPRouter(_router(lendingPool)).userBorrowShares(alice), 20e6);
    }

    // RUN
    // forge test --match-test test_swap_with_extreme_slippage -vvv
    function test_swap_with_extreme_slippage() public {
        test_supply_collateral();

        address position = _addressPosition(lendingPool, alice);

        vm.startPrank(alice);

        // Test with maximum slippage tolerance (10000 = 100%)
        uint256 swapAmount = 50 ether;

        console.log("Testing swap with 10000 slippage tolerance (100%)");
        console.log("Initial WNATIVE:", IERC20(WNATIVE).balanceOf(position));
        console.log("Initial USDT:", IERC20(USDT).balanceOf(position));

        // This should work even with extreme slippage
        IPosition(position).swapTokenByPosition(WNATIVE, USDT, swapAmount, 10000);

        console.log("After swap WNATIVE:", IERC20(WNATIVE).balanceOf(position));
        console.log("After swap USDT:", IERC20(USDT).balanceOf(position));

        // Test swapping back (use a smaller amount that's available)
        uint256 usdtAmount = 5e6; // Use 5 USDT instead of 10
        IPosition(position).swapTokenByPosition(USDT, WNATIVE, usdtAmount, 10000);

        console.log("After swap back WNATIVE:", IERC20(WNATIVE).balanceOf(position));
        console.log("After swap back USDT:", IERC20(USDT).balanceOf(position));

        vm.stopPrank();
    }

    // RUN
    // forge test --match-test test_position_repay_with_swap -vvv
    function test_position_repay_with_swap() public {
        // Setup: Supply liquidity, collateral, and borrow
        test_supply_liquidity();
        test_supply_collateral();

        vm.startPrank(alice);
        ILendingPool(lendingPool).borrowDebt(20e6, block.chainid, BASE_EID, 65000);
        vm.stopPrank();

        address position = _addressPosition(lendingPool, alice);

        // First, swap some WNATIVE to USDT in the position
        vm.startPrank(alice);

        console.log("Before swap - WNATIVE:", IERC20(WNATIVE).balanceOf(position));
        console.log("Before swap - USDT:", IERC20(USDT).balanceOf(position));
        console.log("Before swap - borrow shares:", ILPRouter(_router(lendingPool)).userBorrowShares(alice));

        // Swap WNATIVE to USDT with high slippage tolerance
        IPosition(position).swapTokenByPosition(WNATIVE, USDT, 100 ether, 10000);

        console.log("After swap - WNATIVE:", IERC20(WNATIVE).balanceOf(position));
        console.log("After swap - USDT:", IERC20(USDT).balanceOf(position));

        vm.stopPrank();

        // Now test repayment using the position's repayWithSelectedToken function
        // This should work because the position has USDT and can repay directly
        vm.startPrank(alice);

        // The position should have USDT now, so we can repay directly
        // But we need to call this through the lending pool, not directly on position
        IERC20(USDT).approve(lendingPool, 10e6);
        ILendingPool(lendingPool).repayWithSelectedToken(10e6, USDT, false, alice, 500);

        console.log("After repayment - WNATIVE:", IERC20(WNATIVE).balanceOf(position));
        console.log("After repayment - USDT:", IERC20(USDT).balanceOf(position));
        console.log("After repayment - borrow shares:", ILPRouter(_router(lendingPool)).userBorrowShares(alice));

        vm.stopPrank();

        // Verify repayment occurred
        assertLt(ILPRouter(_router(lendingPool)).userBorrowShares(alice), 20e6);
    }

    // RUN
    // forge test --match-test test_position_repay_with_collateral_swap -vvv --TODO:
    function test_position_repay_with_collateral_swap() public {
        // Setup: Supply liquidity, collateral, and borrow
        test_supply_liquidity();
        test_supply_collateral();

        vm.startPrank(alice);
        ILendingPool(lendingPool).borrowDebt(20e6, block.chainid, BASE_EID, 65000);
        vm.stopPrank();

        address position = _addressPosition(lendingPool, alice);

        // Test repaying using WNATIVE collateral through lending pool
        // The lending pool should call the position's repayWithSelectedToken function
        vm.startPrank(alice);

        console.log("Before repayment - WNATIVE:", IERC20(WNATIVE).balanceOf(position));
        console.log("Before repayment - USDT:", IERC20(USDT).balanceOf(position));
        console.log("Before repayment - borrow shares:", ILPRouter(_router(lendingPool)).userBorrowShares(alice));

        // Call repayWithSelectedToken through lending pool with WNATIVE
        // This should trigger internal swap from WNATIVE to USDT in the position
        ILendingPool(lendingPool).repayWithSelectedToken(10e6, WNATIVE, false, alice, 10000);

        console.log("After repayment - WNATIVE:", IERC20(WNATIVE).balanceOf(position));
        console.log("After repayment - USDT:", IERC20(USDT).balanceOf(position));
        console.log("After repayment - borrow shares:", ILPRouter(_router(lendingPool)).userBorrowShares(alice));

        vm.stopPrank();

        // Verify repayment occurred
        assertLt(ILPRouter(_router(lendingPool)).userBorrowShares(alice), 20e6);
    }

    // RUN
    // forge test --match-test test_position_swap_authorization_issue -vvv
    function test_position_swap_authorization_issue() public {
        // This test demonstrates the authorization issue in Position.sol
        // The repayWithSelectedToken function calls swapTokenByPosition internally
        // but swapTokenByPosition has _onlyAuthorizedSwap() modifier that doesn't allow
        // the Position contract itself to call it

        test_supply_liquidity();
        test_supply_collateral();

        vm.startPrank(alice);
        ILendingPool(lendingPool).borrowDebt(20e6, block.chainid, BASE_EID, 65000);
        vm.stopPrank();

        address position = _addressPosition(lendingPool, alice);

        console.log("Position address:", position);
        console.log("WNATIVE in position:", IERC20(WNATIVE).balanceOf(position));
        console.log("USDT in position:", IERC20(USDT).balanceOf(position));

        // Try to call swapTokenByPosition directly from the position (this should fail)
        vm.startPrank(alice);

        // This will fail with NotForSwap() because the position contract is not authorized
        // to call its own swapTokenByPosition function
        try IPosition(position).swapTokenByPosition(WNATIVE, USDT, 100 ether, 10000) {
            console.log("Direct swap succeeded (unexpected)");
        } catch Error(string memory reason) {
            console.log("Direct swap failed as expected:", reason);
        }

        vm.stopPrank();

        // The issue is that repayWithSelectedToken calls swapTokenByPosition internally
        // but swapTokenByPosition has _onlyAuthorizedSwap() modifier that only allows
        // calls from lending pool, IsHealthy, or Liquidator contracts
        // The Position contract itself is not authorized to call swapTokenByPosition
    }

    // RUN
    // forge test --match-test test_position_repay_collateral_direct -vvv --TODO:
    function test_position_repay_collateral_direct() public {
        // Setup: Supply liquidity, collateral, and borrow
        test_supply_liquidity();
        test_supply_collateral();

        vm.startPrank(alice);
        ILendingPool(lendingPool).borrowDebt(15e6, block.chainid, BASE_EID, 65000);
        vm.stopPrank();

        address position = _addressPosition(lendingPool, alice);

        // Test repaying using WNATIVE collateral with high slippage tolerance
        vm.startPrank(alice);

        console.log("Initial state:");
        console.log("WNATIVE in position:", IERC20(WNATIVE).balanceOf(position));
        console.log("USDT in position:", IERC20(USDT).balanceOf(position));
        console.log("Borrow shares:", ILPRouter(_router(lendingPool)).userBorrowShares(alice));
        console.log("Total borrow assets:", ILPRouter(_router(lendingPool)).totalBorrowAssets());

        // Repay using WNATIVE collateral through lending pool - this should swap internally
        // The position contract should handle the swap from WNATIVE to USDT
        ILendingPool(lendingPool).repayWithSelectedToken(5e6, WNATIVE, false, alice, 10000);

        console.log("After first repayment:");
        console.log("WNATIVE in position:", IERC20(WNATIVE).balanceOf(position));
        console.log("USDT in position:", IERC20(USDT).balanceOf(position));
        console.log("Borrow shares:", ILPRouter(_router(lendingPool)).userBorrowShares(alice));
        console.log("Total borrow assets:", ILPRouter(_router(lendingPool)).totalBorrowAssets());

        // Try another repayment with WNATIVE
        ILendingPool(lendingPool).repayWithSelectedToken(5e6, WNATIVE, false, alice, 10000);

        console.log("After second repayment:");
        console.log("WNATIVE in position:", IERC20(WNATIVE).balanceOf(position));
        console.log("USDT in position:", IERC20(USDT).balanceOf(position));
        console.log("Borrow shares:", ILPRouter(_router(lendingPool)).userBorrowShares(alice));
        console.log("Total borrow assets:", ILPRouter(_router(lendingPool)).totalBorrowAssets());

        vm.stopPrank();

        // Verify repayments occurred
        assertLt(ILPRouter(_router(lendingPool)).userBorrowShares(alice), 15e6);
        assertLt(ILPRouter(_router(lendingPool)).totalBorrowAssets(), 15e6);
    }

    // RUN
    // forge test --match-test test_get_fee -vvvv
    function test_get_fee() public {
        address helperGetFee = 0x8a0AB3999e64942E3A0A3227a5914319A7788253;

        uint256 fee = HelperUtils(helperGetFee).getFee(BASE_OFT_MOCK_USDT_ADAPTER, ARB_EID, address(alice), 10e6);

        console.log("Fee:", fee);
    }
}
