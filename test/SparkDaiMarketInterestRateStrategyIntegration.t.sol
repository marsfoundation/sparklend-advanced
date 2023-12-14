// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { IPoolAddressesProvider } from "aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";
import { IPool }                  from "aave-v3-core/contracts/interfaces/IPool.sol";
import { IPoolConfigurator }      from "aave-v3-core/contracts/interfaces/IPoolConfigurator.sol";
import { IERC20 }                 from "erc20-helpers/interfaces/IERC20.sol";

import { PotRateSource }                      from "../src/PotRateSource.sol";
import { RateTargetBaseInterestRateStrategy } from "../src/RateTargetBaseInterestRateStrategy.sol";

contract SparkDaiMarketInterestRateStrategyIntegrationTest is Test {

    IPoolAddressesProvider poolAddressesProvider = IPoolAddressesProvider(0x02C3eA4e34C0cBd694D2adFa2c690EECbC1793eE);
    IPool                  pool                  = IPool(0xC13e21B648A5Ee794902342038FF3aDAB66BE987);
    IPoolConfigurator      configurator          = IPoolConfigurator(0x542DBa469bdE58FAeE189ffB60C6b49CE60E0738);

    address dai   = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address pot   = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address admin = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;  // SubDAO Proxy

    PotRateSource                      rateSource;
    RateTargetBaseInterestRateStrategy interestStrategy;

    function setUp() public {
        vm.createSelectFork(getChain("mainnet").rpcUrl, 18_627_155);

        rateSource = new PotRateSource(pot);

        interestStrategy = new RateTargetBaseInterestRateStrategy({
            provider:                      poolAddressesProvider,
            rateSource:                    address(rateSource),
            optimalUsageRatio:             1e27,
            baseVariableBorrowRateSpread:  0.005e27,
            variableRateSlope1:            0,
            variableRateSlope2:            0
        });
    }

    function test_update_dai_market_irm() public {
        uint256 currentBorrowRate = 0.053790164207174267760128000e27;

        // Previous borrow rate
        assertEq(_getBorrowRate(), currentBorrowRate);

        vm.prank(admin);
        configurator.setReserveInterestRateStrategyAddress(
            dai,
            address(interestStrategy)
        );

        // Trigger an update from the new IRM
        _triggerUpdate();

        // Should be unchanged because the borrow spread is the same for both
        assertEq(_getBorrowRate(), currentBorrowRate);

        // Change the borrow spread to 1%
        interestStrategy = new RateTargetBaseInterestRateStrategy({
            provider:                      poolAddressesProvider,
            rateSource:                    address(rateSource),
            optimalUsageRatio:             1e27,
            baseVariableBorrowRateSpread:  0.01e27,
            variableRateSlope1:            0,
            variableRateSlope2:            0
        });
        vm.prank(admin);
        configurator.setReserveInterestRateStrategyAddress(
            dai,
            address(interestStrategy)
        );

        // Trigger an update from the new IRM
        _triggerUpdate();

        // Should be 0.5% higher than before
        assertEq(_getBorrowRate(), currentBorrowRate + 0.005e27);
    }

    function _getBorrowRate() internal view returns (uint256) {
        return pool.getReserveData(dai).currentVariableBorrowRate;
    }

    function _triggerUpdate() internal {
        deal(dai, address(this), 1e18);
        IERC20(dai).approve(address(pool), type(uint256).max);
        pool.supply(dai, 1e18, address(this), 0);
    }

}
