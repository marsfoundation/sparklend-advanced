// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { RateSourceMock } from "./mocks/RateSourceMock.sol";

import { CappedFallbackRateSource } from "../src/CappedFallbackRateSource.sol";

contract CappedFallbackRateSourceTest is Test {

    RateSourceMock originalSource;

    CappedFallbackRateSource rateSource;

    function setUp() public {
        originalSource = new RateSourceMock(0.037e18, 18);

        rateSource = new CappedFallbackRateSource({
            _source:      address(originalSource),
            _lowerBound:  0.01e18,
            _upperBound:  0.08e18,
            _defaultRate: 0.03e18
        });
    }

    function test_constructor() public {
        assertEq(address(rateSource.source()), address(originalSource));
        assertEq(rateSource.lowerBound(),      0.01e18);
        assertEq(rateSource.upperBound(),      0.08e18);
        assertEq(rateSource.defaultRate(),     0.03e18);
    }

}
