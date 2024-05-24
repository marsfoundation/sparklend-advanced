// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { RateSourceMock } from "./mocks/RateSourceMock.sol";

import { CappedFallbackRateSource } from "../src/CappedFallbackRateSource.sol";

contract RevertingRateSource {
    function getAPR() external pure returns (uint256) {
        revert("RevertingRateSource/some-error");
    }
}

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

    function test_constructor_invalidBounds() public {
        vm.expectRevert("CappedFallbackRateSource/invalid-bounds");
        new CappedFallbackRateSource({
            _source:      address(originalSource),
            _lowerBound:  0.08e18,  // Lower bound is larger than upper bound
            _upperBound:  0.01e18,
            _defaultRate: 0.03e18
        });
    }

    function test_constructor_invalidDefaultRate() public {
        vm.expectRevert("CappedFallbackRateSource/invalid-default-rate");
        new CappedFallbackRateSource({
            _source:      address(originalSource),
            _lowerBound:  0.01e18,
            _upperBound:  0.08e18,
            _defaultRate: 0.09e18  // Default rate is outside lower and upper bounds
        });
    }

    function test_constructor() public {
        assertEq(address(rateSource.source()), address(originalSource));
        assertEq(rateSource.lowerBound(),      0.01e18);
        assertEq(rateSource.upperBound(),      0.08e18);
        assertEq(rateSource.defaultRate(),     0.03e18);
        assertEq(rateSource.decimals(),        18);
    }

    function test_rateWithinBounds() public {
        assertEq(rateSource.getAPR(), 0.037e18);
    }

    function test_rateBelowLowerBound() public {
        originalSource.setRate(0.005e18);
        
        assertEq(rateSource.getAPR(), 0.01e18);
    }

    function test_rateAboveUpperBound() public {
        originalSource.setRate(0.1e18);

        assertEq(rateSource.getAPR(), 0.08e18);
    }

    function test_rateReverts() public {
        rateSource = new CappedFallbackRateSource({
            _source:      address(new RevertingRateSource()),
            _lowerBound:  0.01e18,
            _upperBound:  0.08e18,
            _defaultRate: 0.03e18
        });

        assertEq(rateSource.getAPR(), 0.03e18);
    }

}
