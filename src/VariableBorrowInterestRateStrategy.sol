// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { IERC20 } from 'aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

import { IDefaultInterestRateStrategy } from 'aave-v3-core/contracts/interfaces/IDefaultInterestRateStrategy.sol';
import { IPoolAddressesProvider }       from 'aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol';
import { IReserveInterestRateStrategy } from 'aave-v3-core/contracts/interfaces/IReserveInterestRateStrategy.sol';

import { DataTypes }      from 'aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol';
import { Errors }         from 'aave-v3-core/contracts/protocol/libraries/helpers/Errors.sol';
import { PercentageMath } from 'aave-v3-core/contracts/protocol/libraries/math/PercentageMath.sol';
import { WadRayMath }     from 'aave-v3-core/contracts/protocol/libraries/math/WadRayMath.sol';

/**
 * @title  VariableBorrowInterestRateStrategy contract
 * @author Aave
 * @notice Implements the calculation of the interest rates depending on the reserve state.
 * @dev    The model of interest rate is based on 2 slopes, one before the `OPTIMAL_USAGE_RATIO`
 *         point of usage and another from that one to 100%.
 *         - An instance of this same contract, can't be used across different Aave markets,
 *           due to the caching of the PoolAddressesProvider.
 *         - NOTE: This is a modified version of DefaultReserveInterestRateStrategy with
 *                 the stable borrow feature disabled.
 */
contract VariableBorrowInterestRateStrategy is IDefaultInterestRateStrategy {

    using WadRayMath     for uint256;
    using PercentageMath for uint256;

    /**********************************************************************************************/
    /*** Declarations and Constructor                                                           ***/
    /**********************************************************************************************/

    // Unused functionality, so initialized to 100% and 0% respectively.
    uint256 public override constant MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO = WadRayMath.RAY;
    uint256 public override constant OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO    = 0;

    uint256 public override immutable MAX_EXCESS_USAGE_RATIO;
    uint256 public override immutable OPTIMAL_USAGE_RATIO;

    IPoolAddressesProvider public override immutable ADDRESSES_PROVIDER;

    // Base variable borrow rate when usage rate = 0.
    // Expressed in ray.
    uint256 internal immutable _baseVariableBorrowRate;

    // Slope of the variable interest curve when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO.
    // Expressed in ray.
    uint256 internal immutable _variableRateSlope1;

    // Slope of the variable interest curve when usage ratio > OPTIMAL_USAGE_RATIO.
    // Expressed in ray.
    uint256 internal immutable _variableRateSlope2;

    /**
     * @dev   Constructor.
     * @param provider               The address of the PoolAddressesProvider contract.
     * @param optimalUsageRatio      The optimal usage ratio.
     * @param baseVariableBorrowRate The base variable borrow rate.
     * @param variableRateSlope1     The variable rate slope below optimal usage ratio.
     * @param variableRateSlope2     The variable rate slope above optimal usage ratio.
     */
    constructor(
        IPoolAddressesProvider provider,
        uint256 optimalUsageRatio,
        uint256 baseVariableBorrowRate,
        uint256 variableRateSlope1,
        uint256 variableRateSlope2
    ) {
        require(WadRayMath.RAY >= optimalUsageRatio, Errors.INVALID_OPTIMAL_USAGE_RATIO);

        OPTIMAL_USAGE_RATIO    = optimalUsageRatio;
        MAX_EXCESS_USAGE_RATIO = WadRayMath.RAY - optimalUsageRatio;
        ADDRESSES_PROVIDER     = provider;

        _baseVariableBorrowRate = baseVariableBorrowRate;
        _variableRateSlope1     = variableRateSlope1;
        _variableRateSlope2     = variableRateSlope2;
    }

    /**********************************************************************************************/
    /*** Internal Virtual Functions (Override for different functionality)                      ***/
    /**********************************************************************************************/

    function _getBaseVariableBorrowRate() internal virtual view returns (uint256) {
        return _baseVariableBorrowRate;
    }

    function _getVariableRateSlope1() internal virtual view returns (uint256) {
        return _variableRateSlope1;
    }

    function _getVariableRateSlope2() internal virtual view returns (uint256) {
        return _variableRateSlope2;
    }

    /**********************************************************************************************/
    /*** Standard Interface Getter Functions                                                    ***/
    /**********************************************************************************************/

    function getBaseStableBorrowRate() external override view returns (uint256) {
        return _getVariableRateSlope1();
    }

    function getBaseVariableBorrowRate() external override view returns (uint256) {
        return _getBaseVariableBorrowRate();
    }

    function getVariableRateSlope1() external override view returns (uint256) {
        return _getVariableRateSlope1();
    }

    function getVariableRateSlope2() external override view returns (uint256) {
        return _getVariableRateSlope2();
    }

    function getStableRateSlope1() external override pure returns (uint256) {
        return 0;
    }

    function getStableRateSlope2() external override pure returns (uint256) {
        return 0;
    }

    function getStableRateExcessOffset() external override pure returns (uint256) {
        return 0;
    }

    function getMaxVariableBorrowRate() external view override returns (uint256) {
        return _getBaseVariableBorrowRate() + _getVariableRateSlope1() + _getVariableRateSlope2();
    }

    /**********************************************************************************************/
    /*** Interest Calculation Function                                                          ***/
    /**********************************************************************************************/

    struct CalcInterestRatesLocalVars {
        uint256 availableLiquidity;
        uint256 currentVariableBorrowRate;
        uint256 currentLiquidityRate;
        uint256 borrowUsageRatio;
        uint256 supplyUsageRatio;
        uint256 availableLiquidityPlusDebt;
    }

    function calculateInterestRates(
        DataTypes.CalculateInterestRatesParams memory params
    )
        external view override
        returns (uint256 liquidityRate, uint256 stableBorrowRate, uint256 variableBorrowRate)
    {
        CalcInterestRatesLocalVars memory vars;

        // 1. Set the current variable borrow rate to the base rate.

        vars.currentLiquidityRate      = 0;
        vars.currentVariableBorrowRate = _getBaseVariableBorrowRate();

        // 2. Calculate the borrow and supply usage ratios.

        if (params.totalVariableDebt != 0) {
            // Calculate the total resulting cash in the reserve after the call is complete.
            vars.availableLiquidity =
                IERC20(params.reserve).balanceOf(params.aToken) +
                params.liquidityAdded -
                params.liquidityTaken;

            // Calculate the total value of the asset in the reserve (cash + debt).
            vars.availableLiquidityPlusDebt = vars.availableLiquidity + params.totalVariableDebt;

            // Calculate the borrowUsageRatio (debt / total value).
            vars.borrowUsageRatio = params.totalVariableDebt.rayDiv(vars.availableLiquidityPlusDebt);

            // Calculate the supplyUsageRatio (debt / total value + unbacked).
            // NOTE: The supplyUsageRatio will almost always equal the borrowUsageRatio, except
            //       when unbacked aTokens are minted.
            vars.supplyUsageRatio
                = params.totalVariableDebt.rayDiv(vars.availableLiquidityPlusDebt + params.unbacked);
        }

        // 3. Calculate the variable borrow rate, using the 2-slope model.

        if (vars.borrowUsageRatio > OPTIMAL_USAGE_RATIO) {
            // excessBorrowUsageRatio = (borrowRatio - optimalRatio) / (1 - optimalRatio)
            uint256 excessBorrowUsageRatio
                = (vars.borrowUsageRatio - OPTIMAL_USAGE_RATIO).rayDiv(MAX_EXCESS_USAGE_RATIO);

            vars.currentVariableBorrowRate +=
                _getVariableRateSlope1() +
                _getVariableRateSlope2().rayMul(excessBorrowUsageRatio);
        } else {
            vars.currentVariableBorrowRate +=
                _getVariableRateSlope1().rayMul(vars.borrowUsageRatio).rayDiv(OPTIMAL_USAGE_RATIO);
        }

        // 4. Calculate the liquidity rate by multiplying the current variable borrow rate by
        //    the supply usage ratio and multiplying by (100% - the protocol's reserve factor).
        //    This yields the amount that the lenders are earning based on the interest paid by
        //    the borrowers, before the protocol's cut, taking into account idle capital.

        if (params.totalVariableDebt != 0) {
            vars.currentLiquidityRate =
                vars.currentVariableBorrowRate
                .rayMul(vars.supplyUsageRatio)
                .percentMul(PercentageMath.PERCENTAGE_FACTOR - params.reserveFactor);
        }

        return (
            vars.currentLiquidityRate,
            0,
            vars.currentVariableBorrowRate
        );
    }

}
