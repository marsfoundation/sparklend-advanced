// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { IDefaultInterestRateStrategy } from 'aave-v3-core/contracts/interfaces/IDefaultInterestRateStrategy.sol';
import { DataTypes } from 'aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol';

abstract contract InterestRateStrategyBaseTest is Test {

    uint256 constant MAX_TOKEN_AMOUNT = 1e27;  // 1 billion tokens at 18 decimals

    IDefaultInterestRateStrategy private interestStrategy;

    function initBase(IDefaultInterestRateStrategy _interestStrategy) internal {
        interestStrategy = _interestStrategy;
    }

    function test_calculateInterestRates(
        uint256 liquidityAvailable,
        DataTypes.CalculateInterestRatesParams memory params
    ) public {
        // Bound everything to reasonable values
        // Disable stable borrow stuff
        liquidityAvailable       = bound(liquidityAvailable, 0, MAX_TOKEN_AMOUNT);
        params.unbacked          = bound(params.unbacked, 0, MAX_TOKEN_AMOUNT);
        params.liquidityAdded    = bound(params.liquidityAdded, 0, MAX_TOKEN_AMOUNT);
        params.liquidityTaken    = bound(params.liquidityTaken, 0, liquidityAvailable + liquidityAdded);
        params.totalStableDebt   = 0;
        params.totalVariableDebt = bound(params.totalVariableDebt, 0, MAX_TOKEN_AMOUNT);
        params.reserveFactor     = bound(params.reserveFactor, 0, 100_00);

        deal(params.reserve, params.aToken, liquidityAvailable);
    }

}
