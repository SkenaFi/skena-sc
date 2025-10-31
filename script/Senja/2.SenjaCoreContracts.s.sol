// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {Helper} from "../L0/Helper.sol";
import {Liquidator} from "../../src/Liquidator.sol";
import {IsHealthy} from "../../src/IsHealthy.sol";
import {LendingPoolDeployer} from "../../src/LendingPoolDeployer.sol";
import {Protocol} from "../../src/Protocol.sol";
import {PositionDeployer} from "../../src/PositionDeployer.sol";
import {LendingPoolFactory} from "../../src/LendingPoolFactory.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IFactory} from "../../src/interfaces/IFactory.sol";
import {LendingPoolRouterDeployer} from "../../src/LendingPoolRouterDeployer.sol";

contract SenjaCoreContracts is Script, Helper {
    Liquidator public liquidator;
    IsHealthy public isHealthy;
    LendingPoolDeployer public lendingPoolDeployer;
    LendingPoolRouterDeployer public lendingPoolRouterDeployer;
    Protocol public protocol;
    PositionDeployer public positionDeployer;
    LendingPoolFactory public lendingPoolFactory;
    ERC1967Proxy public proxy;
    bool isDeployed = false;

    function run() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        if (!isDeployed) {
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
        } else {
            liquidator = Liquidator(payable(BASE_liquidator));
            isHealthy = IsHealthy(BASE_isHealthy);
            lendingPoolDeployer = LendingPoolDeployer(BASE_lendingPoolDeployer);
            lendingPoolRouterDeployer = LendingPoolRouterDeployer(BASE_lendingPoolRouterDeployer);
            protocol = Protocol(payable(BASE_protocol));
            positionDeployer = PositionDeployer(BASE_positionDeployer);
            lendingPoolFactory = LendingPoolFactory(BASE_lendingPoolFactoryProxy);
        }
        lendingPoolDeployer.setFactory(address(proxy));
        lendingPoolRouterDeployer.setFactory(address(proxy));

        IFactory(address(proxy)).addTokenDataStream(BASE_USDC, BASE_usdc_usd_adapter);
        IFactory(address(proxy)).addTokenDataStream(BASE_USDT, BASE_usdt_usd_adapter);
        IFactory(address(proxy)).addTokenDataStream(BASE_ETH, BASE_eth_usd_adapter);
        IFactory(address(proxy)).addTokenDataStream(BASE_WETH, BASE_eth_usd_adapter);
        IFactory(address(proxy)).addTokenDataStream(BASE_WBTC, BASE_btc_usd_adapter);
        IFactory(address(proxy)).addTokenDataStream(BASE_MOCK_USDC, BASE_usdc_usd_adapter);
        IFactory(address(proxy)).addTokenDataStream(BASE_MOCK_USDT, BASE_usdt_usd_adapter);
        IFactory(address(proxy)).addTokenDataStream(BASE_MOCK_WETH, BASE_eth_usd_adapter);

        IFactory(address(proxy)).setPositionDeployer(address(positionDeployer));
        IFactory(address(proxy)).setLendingPoolDeployer(address(lendingPoolDeployer));
        IFactory(address(proxy)).setLendingPoolRouterDeployer(address(lendingPoolRouterDeployer));
        IFactory(address(proxy)).setProtocol(address(protocol));
        IFactory(address(proxy)).setIsHealthy(address(isHealthy));

        vm.stopBroadcast();
        if (block.chainid == 8453) {
            console.log("address public BASE_liquidator = %s;", address(liquidator));
            console.log("address public BASE_isHealthy = %s;", address(isHealthy));
            console.log("address public BASE_lendingPoolDeployer = %s;", address(lendingPoolDeployer));
            console.log("address public BASE_protocol = %s;", address(protocol));
            console.log("address public BASE_positionDeployer = %s;", address(positionDeployer));
            console.log("address public BASE_lendingPoolFactoryImplementation = %s;", address(lendingPoolFactory));
            console.log("address public BASE_lendingPoolFactoryProxy = %s;", address(proxy));
        } else if (block.chainid == 42161) {
            console.log("address public ARB_liquidator = %s;", address(liquidator));
            console.log("address public ARB_isHealthy = %s;", address(isHealthy));
            console.log("address public ARB_lendingPoolDeployer = %s;", address(lendingPoolDeployer));
            console.log("address public ARB_protocol = %s;", address(protocol));
            console.log("address public ARB_positionDeployer = %s;", address(positionDeployer));
            console.log("address public ARB_lendingPoolFactoryImplementation = %s;", address(lendingPoolFactory));
            console.log("address public ARB_lendingPoolFactoryProxy = %s;", address(proxy));
        }
    }
}

// RUN
// forge script SenjaCoreContracts --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script SenjaCoreContracts --broadcast -vvv
// forge script SenjaCoreContracts -vvv
