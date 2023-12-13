// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { RateSourceMock } from "./mocks/RateSourceMock.sol";

import { IAaveOracle }            from "aave-v3-core/contracts/interfaces/IAaveOracle.sol";
import { IPoolAddressesProvider } from "aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";
import { IPool }                  from "aave-v3-core/contracts/interfaces/IPool.sol";
import { IPoolConfigurator }      from "aave-v3-core/contracts/interfaces/IPoolConfigurator.sol";
import { IERC20 }                 from "erc20-helpers/interfaces/IERC20.sol";

import { FixedPriceOracle }                   from "../src/FixedPriceOracle.sol";
import { PotRateSource }                      from "../src/PotRateSource.sol";
import { RateTargetBaseInterestRateStrategy } from "../src/RateTargetBaseInterestRateStrategy.sol";
import { RateTargetKinkInterestRateStrategy } from "../src/RateTargetKinkInterestRateStrategy.sol";

contract SparkLendMainnetIntegrationTest is Test {

    address AAVE_ORACLE             = 0x8105f69D9C41644c6A0803fDA7D03Aa70996cFD9;
    address POOL_ADDRESSES_PROVIDER = 0x02C3eA4e34C0cBd694D2adFa2c690EECbC1793eE;
    address POOL                    = 0xC13e21B648A5Ee794902342038FF3aDAB66BE987;
    address POOL_CONFIGURATOR       = 0x542DBa469bdE58FAeE189ffB60C6b49CE60E0738;
    address DAI                     = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address ETH                     = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address POT                     = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address ADMIN                   = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;  // SubDAO Proxy

    IAaveOracle            aaveOracle            = IAaveOracle(AAVE_ORACLE);
    IPoolAddressesProvider poolAddressesProvider = IPoolAddressesProvider(POOL_ADDRESSES_PROVIDER);
    IPool                  pool                  = IPool(POOL);
    IPoolConfigurator      configurator          = IPoolConfigurator(POOL_CONFIGURATOR);

    function setUp() public {
        vm.createSelectFork(getChain("mainnet").rpcUrl, 18_627_155);
    }

    function test_dai_market_oracle() public {
        FixedPriceOracle oracle = new FixedPriceOracle(1e8);
        
        // Nothing is special about this number, it just happens to be the price at this block
        assertEq(aaveOracle.getAssetPrice(DAI), 0.99959638e8);

        address[] memory assets = new address[](1);
        assets[0] = DAI;
        address[] memory sources = new address[](1);
        sources[0] = address(oracle);

        vm.prank(ADMIN);
        aaveOracle.setAssetSources(
            assets,
            sources
        );

        assertEq(aaveOracle.getAssetPrice(DAI), 1e8);
    }

    function test_dai_market_irm() public {
        RateTargetBaseInterestRateStrategy interestRateStrategy
            = new RateTargetBaseInterestRateStrategy({
                provider:                      poolAddressesProvider,
                rateSource:                    address(new PotRateSource(POT)),
                optimalUsageRatio:             1e27,
                baseVariableBorrowRateSpread:  0.005e27,
                variableRateSlope1:            0,
                variableRateSlope2:            0
            });

        uint256 currentBorrowRate = 0.053790164207174267760128000e27;

        // Previous borrow rate
        assertEq(_getBorrowRate(DAI), currentBorrowRate);

        vm.prank(ADMIN);
        configurator.setReserveInterestRateStrategyAddress(
            DAI,
            address(interestRateStrategy)
        );

        // Trigger an update from the new IRM
        _triggerUpdate(DAI);

        // Should be unchanged because the borrow spread is the same for both
        assertEq(_getBorrowRate(DAI), currentBorrowRate);

        // Change the borrow spread to 1%
        interestRateStrategy = new RateTargetBaseInterestRateStrategy({
            provider:                     poolAddressesProvider,
            rateSource:                   address(new PotRateSource(POT)),
            optimalUsageRatio:            1e27,
            baseVariableBorrowRateSpread: 0.01e27,
            variableRateSlope1:           0,
            variableRateSlope2:           0
        });
        vm.prank(ADMIN);
        configurator.setReserveInterestRateStrategyAddress(
            DAI,
            address(interestRateStrategy)
        );

        // Trigger an update from the new IRM
        _triggerUpdate(DAI);

        // Should be 0.5% higher than before
        assertEq(_getBorrowRate(DAI), currentBorrowRate + 0.005e27);
    }

    function test_eth_market_irm() public {
        // TODO replace with actual oracle when ready
        RateTargetKinkInterestRateStrategy interestRateStrategy
            = new RateTargetKinkInterestRateStrategy({
                provider:                 poolAddressesProvider,
                rateSource:               address(new RateSourceMock(0.038e27)),  // 3.8% (approx APR as of Dec 13, 2023)
                optimalUsageRatio:        0.9e27,
                baseVariableBorrowRate:   0,
                variableRateSlope1Spread: -0.008e27,  // 0.8% spread
                variableRateSlope2:       1.2e27
            });

        // Previous borrow rate
        assertEq(_getBorrowRate(ETH), 0.027395409271592459668138011e27);

        vm.prank(ADMIN);
        configurator.setReserveInterestRateStrategyAddress(
            ETH,
            address(interestRateStrategy)
        );

        // Trigger an update from the new IRM
        _triggerUpdate(ETH);

        // Should be unchanged because the borrow spread is the same for both
        assertEq(_getBorrowRate(ETH), 0.025683196253563698736573012e27);
    }

    function _getBorrowRate(address asset) internal view returns (uint256) {
        return pool.getReserveData(asset).currentVariableBorrowRate;
    }

    function _triggerUpdate(address asset) internal {
        deal(asset, address(this), 1);
        IERC20(asset).approve(address(pool), 1);
        pool.supply(asset, 1, address(this), 0);
    }

}
