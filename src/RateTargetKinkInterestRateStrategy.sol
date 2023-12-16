// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IRateSource } from './interfaces/IRateSource.sol';

import {
    VariableBorrowInterestRateStrategy,
    IPoolAddressesProvider
} from './VariableBorrowInterestRateStrategy.sol';

/**
 * @title  RateTargetKinkInterestRateStrategy
 * @notice Sets the kink interest rate as a fixed spread from a rate source.
 */
contract RateTargetKinkInterestRateStrategy is VariableBorrowInterestRateStrategy {

    IRateSource public immutable RATE_SOURCE;

    // Slope spread of the variable interest curve when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO. Expressed in ray.
    int256 internal immutable _variableRateSlope1Spread;

    /**
     * @dev   Constructor.
     * @param provider                 The address of the PoolAddressesProvider contract.
     * @param rateSource               The address of the rate source contract.
     * @param optimalUsageRatio        The optimal usage ratio.
     * @param baseVariableBorrowRate   The base variable borrow rate.
     * @param variableRateSlope1Spread The spread between the rate source and the desired target kink rate.
     *                                 Note: This discounts the base variable borrow rate.
     * @param variableRateSlope2       The variable rate slope above optimal usage ratio.
     */
    constructor(
        IPoolAddressesProvider provider,
        address rateSource,
        uint256 optimalUsageRatio,
        uint256 baseVariableBorrowRate,
        int256  variableRateSlope1Spread,
        uint256 variableRateSlope2
    ) VariableBorrowInterestRateStrategy(
        provider,
        optimalUsageRatio,
        baseVariableBorrowRate,
        0,
        variableRateSlope2
    ) {
        RATE_SOURCE = IRateSource(rateSource);

        _variableRateSlope1Spread = variableRateSlope1Spread;
    }

    function _getVariableRateSlope1() internal override view returns (uint256) {
        // We assume all rates are below max int. This is a reasonable assumption because
        // otherwise the rates will be so high that the protocol will stop working
        int256 rate = int256(RATE_SOURCE.getAPR()) + _variableRateSlope1Spread - int256(_baseVariableBorrowRate);
        return rate > 0 ? uint256(rate) : 0;
    }

}
