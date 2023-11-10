// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { FixedPriceOracle } from "../src/FixedPriceOracle.sol";

contract FixedPriceOracleTest is Test {

    FixedPriceOracle oracle;

    function setUp() public {
        oracle = new FixedPriceOracle(123e8);
    }

    function test_constructor() public {
        assertEq(oracle.price(),    123e8);
        assertEq(oracle.decimals(), 8);
    }

    function test_bad_price_values() public {
        vm.expectRevert("FixedPriceOracle/invalid-price");
        new FixedPriceOracle(0);

        vm.expectRevert("FixedPriceOracle/invalid-price");
        new FixedPriceOracle(-1);
    }

    function test_latestAnswer() public {
        assertEq(oracle.latestAnswer(), 123e8);
    }

}
