// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { PriceSourceMock } from "./mocks/PriceSourceMock.sol";

import { CappedOracle } from "../src/CappedOracle.sol";

contract CappedOracleTest is Test {

    PriceSourceMock priceSource;

    CappedOracle oracle;

    function setUp() public {
        priceSource = new PriceSourceMock(0.8e8);
        oracle      = new CappedOracle(address(priceSource), 1e8);
    }

    function test_constructor() public {
        assertEq(oracle.latestAnswer(), 0.8e8);
        assertEq(oracle.decimals(), 8);
    }

    function test_price_at_max() public {
        assertEq(oracle.latestAnswer(), 0.8e8);
        priceSource.setLatestAnswer(1e8);
        assertEq(oracle.latestAnswer(), 1e8);
    }

    function test_price_above_max() public {
        assertEq(oracle.latestAnswer(), 0.8e8);
        priceSource.setLatestAnswer(1e8 + 1);
        assertEq(oracle.latestAnswer(), 1e8);
    }

    function test_price_below_zero() public {
        // This below zero behaviour will carry through
        assertEq(oracle.latestAnswer(), 0.8e8);
        priceSource.setLatestAnswer(-1e8);
        assertEq(oracle.latestAnswer(), -1e8);
    }

}
