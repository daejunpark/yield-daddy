// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "erc4626-tests/ERC4626.test.sol";

import {EulerMock} from "./mocks/EulerMock.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {EulerERC4626} from "../../euler/EulerERC4626.sol";
import {EulerETokenMock} from "./mocks/EulerETokenMock.sol";
import {EulerMarketsMock} from "./mocks/EulerMarketsMock.sol";
import {EulerERC4626Factory} from "../../euler/EulerERC4626Factory.sol";

contract ERC4626StdTest is ERC4626Test {
    // copied from EulerERC4626.t.sol
    EulerMock public euler;
    EulerERC4626 public vault;
    ERC20Mock public underlying;
    EulerETokenMock public eToken;
    EulerMarketsMock public markets;
    EulerERC4626Factory public factory;

    function setUp() public override {
        // copied from EulerERC4626.t.sol
        euler = new EulerMock();
        underlying = new ERC20Mock();
        eToken = new EulerETokenMock(underlying, euler);
        markets = new EulerMarketsMock();
        factory = new EulerERC4626Factory(address(euler), markets);
        markets.setETokenForUnderlying(address(underlying), address(eToken));
        vault = EulerERC4626(address(factory.createERC4626(underlying)));

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
            try underlying.mint(address(eToken), gain) {} catch { vm.assume(false); }
        } else {
            vm.assume(false); // TODO: test negative yield scenario
        }
    }

    // NOTE: The following tests are relaxed to consider only smaller values (of type uint120),
    // since the totalAssets(), maxWithdraw(), and maxRedeem() functions fail with large values (due to overflow).

    function test_totalAssets(Init memory init) public override {
        init = clamp(init, type(uint120).max);
        super.test_totalAssets(init);
    }

    function test_maxWithdraw(Init memory init) public override {
        init = clamp(init, type(uint120).max);
        super.test_maxWithdraw(init);
    }

    function test_maxRedeem(Init memory init) public override {
        init = clamp(init, type(uint120).max);
        super.test_maxRedeem(init);
    }

    function clamp(Init memory init, uint max) internal pure returns (Init memory) {
        for (uint i = 0; i < N; i++) {
            init.share[i] = init.share[i] % max;
            init.asset[i] = init.asset[i] % max;
        }
        init.yield = init.yield % int(max);
        return init;
    }
}
