// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {LendingPoolRouter} from "../src/LendingPoolRouter.sol";
import {LendingPoolFactory} from "../src/LendingPoolFactory.sol";
import {LendingPoolRouterDeployer} from "../src/LendingPoolRouterDeployer.sol";
import {Helper} from "../script/L0/Helper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Position} from "../src/Position.sol";
// import {HelperUtils} from "../src/HelperUtils.sol";
// RUN
// forge test -vvv --match-contract SenjaUpgradeTest --match-test test_upgrade_contract
contract SenjaUpgradeTest is Test, Helper {
    LendingPoolFactory public newImplementation;
    LendingPoolRouterDeployer public lendingPoolRouterDeployer;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
    }

    // RUN
    // forge test --match-contract SenjaUpgradeTest --match-test test_upgrade_contract -vvv
    function test_upgrade_contract() public {
        vm.startPrank(vm.envAddress("PUBLIC_KEY"));
        console.log("pool count", LendingPoolFactory(BASE_lendingPoolFactoryProxy).poolCount());
        {
            (address c, address b, address lp) = LendingPoolFactory(BASE_lendingPoolFactoryProxy).pools(0);
            console.log("pools[0] collateral", c);
            console.log("pools[0] borrow", b);
            console.log("pools[0] lp", lp);
        }
        console.log("ishealth", LendingPoolFactory(BASE_lendingPoolFactoryProxy).isHealthy());
        console.log("lendingPoolDeployer", LendingPoolFactory(BASE_lendingPoolFactoryProxy).lendingPoolDeployer());
        console.log("protocol", LendingPoolFactory(BASE_lendingPoolFactoryProxy).protocol());
        console.log("positionDeployer", LendingPoolFactory(BASE_lendingPoolFactoryProxy).positionDeployer());
        console.log("VERSION", LendingPoolFactory(BASE_lendingPoolFactoryProxy).VERSION());
        console.log(
            "lendingPoolRouterDeployer", LendingPoolFactory(BASE_lendingPoolFactoryProxy).lendingPoolRouterDeployer()
        );
        console.log("USDT", LendingPoolFactory(BASE_lendingPoolFactoryProxy).tokenDataStream(BASE_USDT));
        console.log("ETH", LendingPoolFactory(BASE_lendingPoolFactoryProxy).tokenDataStream(BASE_WETH));
        console.log("BTC", LendingPoolFactory(BASE_lendingPoolFactoryProxy).tokenDataStream(BASE_WBTC));
        console.log("****************************");
        newImplementation = new LendingPoolFactory();
        LendingPoolFactory(BASE_lendingPoolFactoryProxy).upgradeToAndCall(address(newImplementation), "");
        console.log("****************************");
        console.log("pool count", LendingPoolFactory(BASE_lendingPoolFactoryProxy).poolCount());
        {
            (address c0, address b0, address lp0) = LendingPoolFactory(BASE_lendingPoolFactoryProxy).pools(0);
            (address c1, address b1, address lp1) = LendingPoolFactory(BASE_lendingPoolFactoryProxy).pools(1);
            (address c2, address b2, address lp2) = LendingPoolFactory(BASE_lendingPoolFactoryProxy).pools(2);
            console.log("pools[0] collateral", c0);
            console.log("pools[0] borrow", b0);
            console.log("pools[0] lp", lp0);
            console.log("pools[1] collateral", c1);
            console.log("pools[1] borrow", b1);
            console.log("pools[1] lp", lp1);
            console.log("pools[2] collateral", c2);
            console.log("pools[2] borrow", b2);
            console.log("pools[2] lp", lp2);
        }
        console.log("ishealth", LendingPoolFactory(BASE_lendingPoolFactoryProxy).isHealthy());
        console.log("lendingPoolDeployer", LendingPoolFactory(BASE_lendingPoolFactoryProxy).lendingPoolDeployer());
        console.log("protocol", LendingPoolFactory(BASE_lendingPoolFactoryProxy).protocol());
        console.log("positionDeployer", LendingPoolFactory(BASE_lendingPoolFactoryProxy).positionDeployer());
        console.log("VERSION", LendingPoolFactory(BASE_lendingPoolFactoryProxy).VERSION());
        console.log(
            "lendingPoolRouterDeployer", LendingPoolFactory(BASE_lendingPoolFactoryProxy).lendingPoolRouterDeployer()
        );
        console.log("USDT", LendingPoolFactory(BASE_lendingPoolFactoryProxy).tokenDataStream(BASE_USDT));
        console.log("ETH", LendingPoolFactory(BASE_lendingPoolFactoryProxy).tokenDataStream(BASE_WETH));
        console.log("BTC", LendingPoolFactory(BASE_lendingPoolFactoryProxy).tokenDataStream(BASE_WBTC));

        console.log("****************************");
        lendingPoolRouterDeployer = new LendingPoolRouterDeployer();
        lendingPoolRouterDeployer.setFactory(BASE_lendingPoolFactoryProxy);
        LendingPoolFactory(BASE_lendingPoolFactoryProxy).setLendingPoolRouterDeployer(
            address(lendingPoolRouterDeployer)
        );
        console.log("****************************");

        (address c3, address b3, address lp3) = LendingPoolFactory(BASE_lendingPoolFactoryProxy).pools(3);
        console.log("pools[3] collateral", c3);
        console.log("pools[3] borrow", b3);
        console.log("pools[3] lp", lp3);
        console.log(
            "lendingPoolRouterDeployer", LendingPoolFactory(BASE_lendingPoolFactoryProxy).lendingPoolRouterDeployer()
        );
        console.log("****************************");
        console.log("****************************");
        (address c4, address b4, address lp4) = LendingPoolFactory(BASE_lendingPoolFactoryProxy).pools(4);
        console.log("pools[4] collateral", c4);
        console.log("pools[4] borrow", b4);
        console.log("pools[4] lp", lp4);
        vm.stopPrank();
    }

    // RUN
    // forge test --match-contract SenjaUpgradeTest --match-test test_swap_collateral -vvv
    // function test_swap_collateral() public {
    //     vm.startPrank(vm.envAddress("PUBLIC_KEY"));
    //     address user = vm.envAddress("PUBLIC_KEY");
    //     console.log("****************************");
    //     (address c4, address b4, address lp4) = LendingPoolFactory(BASE_lendingPoolFactoryProxy).pools(4);
    //     console.log("pools[4] collateral", c4);
    //     console.log("pools[4] borrow", b4);
    //     console.log("pools[4] lp", lp4);

    //     console.log("position deployer", LendingPoolFactory(BASE_lendingPoolFactoryProxy).positionDeployer());
    //     address router = LendingPool(payable(lp4)).router();
    //     address position = LendingPoolRouter(router).addressPositions(user);

    //     deal(c4, user, 100_000e18);
    //     IERC20(c4).approve(lp4, 100_000e18);
    //     LendingPool(payable(lp4)).supplyCollateral(100_000e18, user);
    //     position = LendingPoolRouter(router).addressPositions(user);
    //     console.log("position", position);
    //     Position(payable(position)).swapTokenByPosition(c4, b4, 100_000e18, 500);
    //     deal(b4, position, 100_000e18);

    //     // check balance
    //     console.log("balance of c4", IERC20(c4).balanceOf(position));
    //     console.log("balance of b4", IERC20(b4).balanceOf(position));
    //     console.log("balance of weth", IERC20(BASE_MOCK_WETH).balanceOf(position));

    //     vm.stopPrank();
    // }

    // RUN
    // forge test --match-contract SenjaUpgradeTest --match-test test_position_balance -vvv
    // function test_position_balance() public view {
    //     address user = vm.envAddress("PUBLIC_KEY");
    //     // console.log(
    //     // HelperUtils(BASE_HELPER_UTILS).getCollateralBalance(0xf3a9A94A4c7F37eBCeC38E3A665cd1D980287D4A, user)
    //     // );
    //     address lp = 0xf3a9A94A4c7F37eBCeC38E3A665cd1D980287D4A;
    //     address router = LendingPool(payable(lp)).router();
    //     address position = LendingPoolRouter(router).addressPositions(user);
    //     console.log(position);
    //     console.log("BASE_WETH: ", IERC20(BASE_WETH).balanceOf(position));
    //     console.log("BASE_WBTC", IERC20(BASE_WBTC).balanceOf(position));
    //     console.log("BASE_USDT", IERC20(BASE_USDT).balanceOf(position));
    // }
}
