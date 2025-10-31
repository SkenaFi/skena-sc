// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {LendingPoolFactory} from "../../src/LendingPoolFactory.sol";
import {Helper} from "../L0/Helper.sol";
import {LendingPoolRouterDeployer} from "../../src/LendingPoolRouterDeployer.sol";
import {LendingPoolDeployer} from "../../src/LendingPoolDeployer.sol";
import {IsHealthy} from "../../src/IsHealthy.sol";
import {Liquidator} from "../../src/Liquidator.sol";
import {PositionDeployer} from "../../src/PositionDeployer.sol";
import {Protocol} from "../../src/Protocol.sol";

contract UpgradeContract is Script, Helper {
    LendingPoolFactory public newImplementation;
    LendingPoolRouterDeployer public lendingPoolRouterDeployer;
    LendingPoolDeployer public lendingPoolDeployer;
    IsHealthy public isHealthy;
    Liquidator public liquidator;
    PositionDeployer public positionDeployer;
    Protocol public protocol;

    address owner = vm.envAddress("PUBLIC_KEY");
    uint256 privateKey = vm.envUint("PRIVATE_KEY");

    function run() external {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        vm.startBroadcast(privateKey);

        // _upgrade();

        _setContract();

        vm.stopBroadcast();
    }

    function _upgrade() internal {
        newImplementation = new LendingPoolFactory();
        LendingPoolFactory(BASE_lendingPoolFactoryProxy).upgradeToAndCall(address(newImplementation), "");

        console.log("address public BASE_lendingPoolImplementation =", address(newImplementation), ";");
    }

    function _setContract() internal {
        _setupLendingPoolRouterDeployer();
        _setupLiquidatorAndIsHealthy();
        _setupPositionDeployer();
        _setupProtocol();
        _setupLendingPoolDeployer();
        _createLendingPool();
    }

    function _setupLendingPoolRouterDeployer() internal {
        lendingPoolRouterDeployer = new LendingPoolRouterDeployer();
        lendingPoolRouterDeployer.setFactory(BASE_lendingPoolFactoryProxy);
        LendingPoolFactory(BASE_lendingPoolFactoryProxy).setLendingPoolRouterDeployer(
            address(lendingPoolRouterDeployer)
        );
        console.log("address public BASE_lendingPoolRouterDeployer =", address(lendingPoolRouterDeployer), ";");
    }

    function _setupLiquidatorAndIsHealthy() internal {
        liquidator = new Liquidator();
        liquidator.setFactory(BASE_lendingPoolFactoryProxy);
        isHealthy = new IsHealthy(address(liquidator));
        LendingPoolFactory(BASE_lendingPoolFactoryProxy).setIsHealthy(address(isHealthy));
        console.log("address public BASE_liquidator =", address(liquidator), ";");
        console.log("address public BASE_isHealthy =", address(isHealthy), ";");
    }

    function _setupPositionDeployer() internal {
        positionDeployer = new PositionDeployer();
        LendingPoolFactory(BASE_lendingPoolFactoryProxy).setPositionDeployer(address(positionDeployer));
        console.log("address public BASE_positionDeployer =", address(positionDeployer), ";");
    }

    function _setupProtocol() internal {
        protocol = new Protocol();
        LendingPoolFactory(BASE_lendingPoolFactoryProxy).setProtocol(address(protocol));
        console.log("address public BASE_protocol =", address(protocol), ";");
    }

    function _setupLendingPoolDeployer() internal {
        lendingPoolDeployer = new LendingPoolDeployer();
        lendingPoolDeployer.setFactory(BASE_lendingPoolFactoryProxy);
        LendingPoolFactory(BASE_lendingPoolFactoryProxy).setLendingPoolDeployer(address(lendingPoolDeployer));
        console.log("address public BASE_lendingPoolDeployer =", address(lendingPoolDeployer), ";");
    }

    function _createLendingPool() internal {
        LendingPoolFactory(BASE_lendingPoolFactoryProxy).createLendingPool(BASE_MOCK_WETH, BASE_MOCK_USDT, 886e15);
    }
}

// RUN
//  forge script UpgradeContract --broadcast -vvv
//  forge script UpgradeContract -vvv
