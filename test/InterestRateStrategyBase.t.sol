// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { IDefaultInterestRateStrategy }       from "aave-v3-core/contracts/interfaces/IDefaultInterestRateStrategy.sol";
import { DataTypes }                          from "aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol";
import { DefaultReserveInterestRateStrategy } from "aave-v3-core/contracts/protocol/pool/DefaultReserveInterestRateStrategy.sol";

import { MockERC20 } from "erc20-helpers/MockERC20.sol";

abstract contract InterestRateStrategyBaseTest is Test {

    uint256 constant MAX_TOKEN_AMOUNT = 1e27;  // 1 billion tokens at 18 decimals

    MockERC20 asset;

    IDefaultInterestRateStrategy private interestStrategy;
    DefaultReserveInterestRateStrategy private defaultInterestStrategy;

    function initBase(IDefaultInterestRateStrategy _interestStrategy) internal {
        asset = new MockERC20("Token", "TKN", 18);
        interestStrategy = _interestStrategy;

        // Mirror the values to the default strategy
        defaultInterestStrategy = new DefaultReserveInterestRateStrategy({
            provider: interestStrategy.ADDRESSES_PROVIDER(),
            optimalUsageRatio: interestStrategy.OPTIMAL_USAGE_RATIO(),
            baseVariableBorrowRate: interestStrategy.getBaseVariableBorrowRate(),
            variableRateSlope1: interestStrategy.getVariableRateSlope1(),
            variableRateSlope2: interestStrategy.getVariableRateSlope2(),
            stableRateSlope1: interestStrategy.getStableRateSlope1(),
            stableRateSlope2: interestStrategy.getStableRateSlope2(),
            baseStableRateOffset: interestStrategy.getBaseStableBorrowRate() - interestStrategy.getStableRateSlope1(),
            stableRateExcessOffset: interestStrategy.getStableRateExcessOffset(),
            optimalStableToTotalDebtRatio: interestStrategy.OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO()
        });
    }

    function test_calculateInterestRates(
        uint256 liquidityAvailable,
        DataTypes.CalculateInterestRatesParams memory params
    ) public {
        // Bound everything to reasonable values
        // Disable stable borrow stuff
        liquidityAvailable       = bound(liquidityAvailable,    0, MAX_TOKEN_AMOUNT);
        params.unbacked          = bound(params.unbacked,       0, MAX_TOKEN_AMOUNT);
        params.liquidityAdded    = bound(params.liquidityAdded, 0, MAX_TOKEN_AMOUNT);
        params.liquidityTaken    = bound(params.liquidityTaken, 0, liquidityAvailable + params.liquidityAdded);
        params.totalStableDebt   = 0;
        params.totalVariableDebt = bound(params.totalVariableDebt, 0, MAX_TOKEN_AMOUNT);
        params.reserveFactor     = bound(params.reserveFactor,     0, 100_00);
        params.reserve           = address(asset);
        params.aToken            = makeAddr("aToken");

        asset.mint(params.aToken, liquidityAvailable);

        (
            uint256 expectedLiquidityRate,
            ,
            uint256 expectedVariableBorrowRate
        ) = defaultInterestStrategy.calculateInterestRates(params);
        (
            uint256 actualLiquidityRate,
            ,
            uint256 actualVariableBorrowRate
        ) = interestStrategy.calculateInterestRates(params);

        // Small diff from simplifying the stable borrow stuff which removes rounding errors from integer division
        assertApproxEqRel(expectedLiquidityRate, actualLiquidityRate, 0.000001e18, "liquidity rate mismatch");
        assertEq(expectedVariableBorrowRate, actualVariableBorrowRate, "variable borrow rate mismatch");
    }

}
