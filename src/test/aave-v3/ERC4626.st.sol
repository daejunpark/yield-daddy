// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "erc4626-tests/ERC4626.test.sol";

import {PoolMock} from "./mocks/PoolMock.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {IPool} from "../../aave-v3/external/IPool.sol";
import {AaveV3ERC4626} from "../../aave-v3/AaveV3ERC4626.sol";
import {RewardsControllerMock} from "./mocks/RewardsControllerMock.sol";
import {AaveV3ERC4626Factory} from "../../aave-v3/AaveV3ERC4626Factory.sol";
import {IRewardsController} from "../../aave-v3/external/IRewardsController.sol";

contract ERC4626StdTest is ERC4626Test {
    address public constant rewardRecipient = address(0x01);

    // copied from AaveV3ERC4626.t.sol
    ERC20Mock public aave;
    ERC20Mock public aToken;
    AaveV3ERC4626 public vault;
    ERC20Mock public underlying;
    PoolMock public lendingPool;
    AaveV3ERC4626Factory public factory;
    IRewardsController public rewardsController;

    function setUp() public override {
        // copied from AaveV3ERC4626.t.sol
        aave = new ERC20Mock();
        aToken = new ERC20Mock();
        underlying = new ERC20Mock();
        lendingPool = new PoolMock();
        rewardsController = new RewardsControllerMock(address(aave));
        factory = new AaveV3ERC4626Factory(lendingPool, rewardRecipient, rewardsController);
        lendingPool.setReserveAToken(address(underlying), address(aToken));
        vault = AaveV3ERC4626(address(factory.createERC4626(underlying)));

        // for ERC4626Test setup
        __underlying__ = address(underlying);
        __vault__ = address(vault);
        __delta__ = 0;
    }

    // custom setup for yield
    function setupYield(Init memory init) public override {
        // setup initial yield
        if (init.yield >= 0) {
            uint gain = uint(init.yield);
            try underlying.mint(address(lendingPool), gain) {} catch { vm.assume(false); }
            try aToken.mint(address(vault), gain) {} catch { vm.assume(false); }
        } else {
            vm.assume(false); // TODO: test negative yield scenario
        }
    }
}
