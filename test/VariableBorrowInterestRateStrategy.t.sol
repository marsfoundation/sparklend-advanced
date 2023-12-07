// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./InterestRateStrategyBase.t.sol";

import { RateSourceMock } from "./mocks/RateSourceMock.sol";

import {
    VariableBorrowInterestRateStrategy,
    IPoolAddressesProvider
} from "../src/VariableBorrowInterestRateStrategy.sol";

contract VariableBorrowInterestRateStrategyTest is InterestRateStrategyBaseTest {

    VariableBorrowInterestRateStrategy interestStrategy;

    function setUp() public {
        interestStrategy = new VariableBorrowInterestRateStrategy({
            provider: IPoolAddressesProvider(address(123)),
            optimalUsageRatio:      0.8e27,
            baseVariableBorrowRate: 0.005e27,
            variableRateSlope1:     0.01e27,
            variableRateSlope2:     0.45e27
        });

        initBase(interestStrategy);
    }

    function test_constructor() public {
        assertEq(address(interestStrategy.ADDRESSES_PROVIDER()), address(123));

        assertEq(interestStrategy.OPTIMAL_USAGE_RATIO(),                   0.8e27);
        assertEq(interestStrategy.OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO(),    0);
        assertEq(interestStrategy.MAX_EXCESS_USAGE_RATIO(),                0.2e27);
        assertEq(interestStrategy.MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO(), 1e27);

        assertEq(interestStrategy.getVariableRateSlope1(),     0.01e27);
        assertEq(interestStrategy.getVariableRateSlope2(),     0.45e27);
        assertEq(interestStrategy.getStableRateSlope1(),       0);
        assertEq(interestStrategy.getStableRateSlope2(),       0);
        assertEq(interestStrategy.getStableRateExcessOffset(), 0);
        assertEq(interestStrategy.getBaseStableBorrowRate(),   0.01e27);
        assertEq(interestStrategy.getBaseVariableBorrowRate(), 0.005e27);
        assertEq(interestStrategy.getMaxVariableBorrowRate(),  0.465e27);
    }

}
