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

contract ZeroLengthRevertingRateSource {
    function getAPR() external pure returns (uint256) {
        revert();
    }
}

contract LargeGasUsageRateSource {
    function getAPR() external pure returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < 10000; i++) {
            result += i;
        }
        return result;
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

    function test_constructor_lowerBoundGtUpperBoundBoundary() public {
        vm.expectRevert("CappedFallbackRateSource/invalid-bounds");
        new CappedFallbackRateSource({
            _source:      address(originalSource),
            _lowerBound:  0.01e18 + 1,  // Lower bound is larger than upper bound
            _upperBound:  0.01e18,
            _defaultRate: 0.01e18
        });

        new CappedFallbackRateSource({
            _source:      address(originalSource),
            _lowerBound:  0.01e18,
            _upperBound:  0.01e18,
            _defaultRate: 0.01e18
        });
    }

    function test_constructor_defaultRateLtLowerBoundBoundary() public {
        vm.expectRevert("CappedFallbackRateSource/invalid-default-rate");
        new CappedFallbackRateSource({
            _source:      address(originalSource),
            _lowerBound:  0.01e18,
            _upperBound:  0.08e18,
            _defaultRate: 0.01e18 - 1  // Default rate is below lower bound
        });

        new CappedFallbackRateSource({
            _source:      address(originalSource),
            _lowerBound:  0.01e18,
            _upperBound:  0.08e18,
            _defaultRate: 0.01e18
        });
    }

    function test_constructor_defaultRateGtUpperBoundBoundary() public {
        vm.expectRevert("CappedFallbackRateSource/invalid-default-rate");
        new CappedFallbackRateSource({
            _source:      address(originalSource),
            _lowerBound:  0.01e18,
            _upperBound:  0.08e18,
            _defaultRate: 0.08e18 + 1  // Default rate is above upper bound
        });

        new CappedFallbackRateSource({
            _source:      address(originalSource),
            _lowerBound:  0.01e18,
            _upperBound:  0.08e18,
            _defaultRate: 0.08e18
        });
    }

    function test_constructor() public {
        assertEq(address(rateSource.source()), address(originalSource));
        assertEq(rateSource.lowerBound(),      0.01e18);
        assertEq(rateSource.upperBound(),      0.08e18);
        assertEq(rateSource.defaultRate(),     0.03e18);
    }

    function test_decimals() public {
        assertEq(rateSource.decimals(), 18);

        originalSource.setDecimals(27);

        assertEq(rateSource.decimals(), 27);
    }

    function test_getAPR_rateWithinBounds() public {
        assertEq(rateSource.getAPR(), 0.037e18);
    }

    function test_getAPR_rateBelowLowerBoundBoundary() public {
        originalSource.setRate(0.01e18 - 1);
        
        assertEq(rateSource.getAPR(), 0.01e18);  // Use lowerBound

        originalSource.setRate(0.01e18);

        assertEq(rateSource.getAPR(), 0.01e18);  // Use sourceRate

        originalSource.setRate(0.01e18 + 1);

        assertEq(rateSource.getAPR(), 0.01e18 + 1);  // Use sourceRate
    }

    function test_getAPR_rateAboveUpperBoundBoundary() public {
        originalSource.setRate(0.08e18 + 1);

        assertEq(rateSource.getAPR(), 0.08e18);  // Use upperBound

        originalSource.setRate(0.08e18);

        assertEq(rateSource.getAPR(), 0.08e18);  // Use sourceRate

        originalSource.setRate(0.08e18 - 1);

        assertEq(rateSource.getAPR(), 0.08e18 - 1);  // Use sourceRate
    }

    function test_getAPR_rateReverts() public {
        rateSource = new CappedFallbackRateSource({
            _source:      address(new RevertingRateSource()),
            _lowerBound:  0.01e18,
            _upperBound:  0.08e18,
            _defaultRate: 0.03e18
        });

        assertEq(rateSource.getAPR(), 0.03e18);
    }

    // Example of inner zero-length revert due to explicit revert()
    // Must ensure the inner contract does not revert with zero-length error
    function test_getAPR_rateRevertsZeroLength() public {
        rateSource = new CappedFallbackRateSource({
            _source:      address(new ZeroLengthRevertingRateSource()),
            _lowerBound:  0.01e18,
            _upperBound:  0.08e18,
            _defaultRate: 0.03e18
        });

        vm.expectRevert("CappedFallbackRateSource/zero-length-error");
        rateSource.getAPR();
    }

    // Example of inner zero-length revert due to OOG
    function test_getAPR_rateRevertsOutOfGas() public {
        rateSource = new CappedFallbackRateSource({
            _source:      address(new LargeGasUsageRateSource()),
            _lowerBound:  0.01e18,
            _upperBound:  0.08e18,
            _defaultRate: 0.03e18
        });

        vm.expectRevert("CappedFallbackRateSource/zero-length-error");
        rateSource.getAPR{gas:20000}();
    }

}
