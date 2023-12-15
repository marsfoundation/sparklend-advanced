// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IRateSource } from './interfaces/IRateSource.sol';

import {
    VariableBorrowInterestRateStrategy,
    IPoolAddressesProvider
} from './VariableBorrowInterestRateStrategy.sol';

/**
 * @title  RateTargetBaseInterestRateStrategy
 * @notice Sets the base interest rate as a fixed spread from a rate source.
 */
contract RateTargetBaseInterestRateStrategy is VariableBorrowInterestRateStrategy {

    IRateSource public immutable RATE_SOURCE;

    // Base variable borrow rate spread when usage rate = 0. Expressed in ray.
    uint256 internal immutable _baseVariableBorrowRateSpread;

    /**
     * @dev   Constructor.
     * @param provider                     The address of the PoolAddressesProvider contract.
     * @param rateSource                   The address of the rate source contract.
     * @param optimalUsageRatio            The optimal usage ratio.
     * @param baseVariableBorrowRateSpread The base variable borrow rate spread.
     * @param variableRateSlope1           The variable rate slope below optimal usage ratio.
     * @param variableRateSlope2           The variable rate slope above optimal usage ratio.
     */
    constructor(
        IPoolAddressesProvider provider,
        address rateSource,
        uint256 optimalUsageRatio,
        uint256 baseVariableBorrowRateSpread,
        uint256 variableRateSlope1,
        uint256 variableRateSlope2
    ) VariableBorrowInterestRateStrategy(
        provider,
        optimalUsageRatio,
        0,
        variableRateSlope1,
        variableRateSlope2
    ) {
        RATE_SOURCE = IRateSource(rateSource);

        _baseVariableBorrowRateSpread = baseVariableBorrowRateSpread;
    }

    function _getBaseVariableBorrowRate() internal override view returns (uint256) {
        uint256 apr = RATE_SOURCE.getAPR();
        return apr + _baseVariableBorrowRateSpread;
    }

}
