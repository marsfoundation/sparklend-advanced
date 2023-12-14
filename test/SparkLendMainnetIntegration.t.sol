// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { RateSourceMock } from "./mocks/RateSourceMock.sol";

import { IAaveOracle }                  from "aave-v3-core/contracts/interfaces/IAaveOracle.sol";
import { IPoolAddressesProvider }       from "aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";
import { IPool }                        from "aave-v3-core/contracts/interfaces/IPool.sol";
import { IPoolConfigurator }            from "aave-v3-core/contracts/interfaces/IPoolConfigurator.sol";
import { IDefaultInterestRateStrategy } from "aave-v3-core/contracts/interfaces/IDefaultInterestRateStrategy.sol";
import { IERC20 }                       from "erc20-helpers/interfaces/IERC20.sol";
import { SafeERC20 }                    from "erc20-helpers/SafeERC20.sol";

import { FixedPriceOracle }                   from "../src/FixedPriceOracle.sol";
import { CappedOracle }                       from "../src/CappedOracle.sol";
import { PotRateSource }                      from "../src/PotRateSource.sol";
import { RateTargetBaseInterestRateStrategy } from "../src/RateTargetBaseInterestRateStrategy.sol";
import { RateTargetKinkInterestRateStrategy } from "../src/RateTargetKinkInterestRateStrategy.sol";

contract SparkLendMainnetIntegrationTest is Test {

    using SafeERC20 for IERC20;

    address AAVE_ORACLE             = 0x8105f69D9C41644c6A0803fDA7D03Aa70996cFD9;
    address POOL_ADDRESSES_PROVIDER = 0x02C3eA4e34C0cBd694D2adFa2c690EECbC1793eE;
    address POOL                    = 0xC13e21B648A5Ee794902342038FF3aDAB66BE987;
    address POOL_CONFIGURATOR       = 0x542DBa469bdE58FAeE189ffB60C6b49CE60E0738;
    address POT                     = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address ADMIN                   = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;  // SubDAO Proxy

    address DAI  = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address ETH  = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address USDC_ORACLE   = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    address USDT_ORACLE   = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
    address USDC_USDT_IRM = 0xbc8A68B0ab0617D7c90d15bb1601B25d795Dc4c8;  // Note: This is the same for both because the parameters are the same

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
        // TODO replace with actual ETH yield oracle when ready
        RateTargetKinkInterestRateStrategy interestRateStrategy
            = new RateTargetKinkInterestRateStrategy({
                provider:                 poolAddressesProvider,
                rateSource:               address(new RateSourceMock(0.038e27)),  // 3.8% (approx APR as of Dec 13, 2023)
                optimalUsageRatio:        0.9e27,
                baseVariableBorrowRate:   0,
                variableRateSlope1Spread: -0.008e27,  // 0.8% spread
                variableRateSlope2:       1.2e27
            });

        assertEq(_getBorrowRate(ETH), 0.027395409271592459668138011e27);

        vm.prank(ADMIN);
        configurator.setReserveInterestRateStrategyAddress(
            ETH,
            address(interestRateStrategy)
        );

        _triggerUpdate(ETH);

        assertEq(_getBorrowRate(ETH), 0.025683196253563698736573012e27);
    }

    function test_usdc_usdt_market_oracles() public {
        CappedOracle usdcOracle = new CappedOracle(USDC_ORACLE, 1e8);
        CappedOracle usdtOracle = new CappedOracle(USDT_ORACLE, 1e8);
        
        // Nothing is special about these numbers, they just happens to be the price at this block
        assertEq(aaveOracle.getAssetPrice(USDC), 1.00001291e8);
        assertEq(aaveOracle.getAssetPrice(USDT), 1.00047200e8);

        address[] memory assets = new address[](2);
        assets[0] = USDC;
        assets[1] = USDT;
        address[] memory sources = new address[](2);
        sources[0] = address(usdcOracle);
        sources[1] = address(usdtOracle);

        vm.prank(ADMIN);
        aaveOracle.setAssetSources(
            assets,
            sources
        );

        assertEq(aaveOracle.getAssetPrice(USDC), 1e8);
        assertEq(aaveOracle.getAssetPrice(USDT), 1e8);

        // TODO test if price of oracle drops below $1
    }

    function test_usdc_usdt_market_irms() public {
        RateTargetKinkInterestRateStrategy interestRateStrategy
            = new RateTargetKinkInterestRateStrategy({
                provider:                 poolAddressesProvider,
                rateSource:               address(new PotRateSource(POT)),
                optimalUsageRatio:        0.9e27,
                baseVariableBorrowRate:   0,
                variableRateSlope1Spread: -0.004e27,  // 0.4% spread
                variableRateSlope2:       0.2e27
            });
        IDefaultInterestRateStrategy previousInterestRateStrategy
            = IDefaultInterestRateStrategy(USDC_USDT_IRM);

        assertEq(interestRateStrategy.getBaseVariableBorrowRate(), previousInterestRateStrategy.getBaseVariableBorrowRate());
        assertEq(interestRateStrategy.getVariableRateSlope1(),     previousInterestRateStrategy.getVariableRateSlope1());
        assertEq(interestRateStrategy.getVariableRateSlope2(),     previousInterestRateStrategy.getVariableRateSlope2());
        assertEq(interestRateStrategy.getMaxVariableBorrowRate(),  previousInterestRateStrategy.getMaxVariableBorrowRate());

        assertEq(_getBorrowRate(USDC), 0.032465964040419624628115797e27);
        assertEq(_getBorrowRate(USDT), 0.043549288556262928206251427e27);

        vm.startPrank(ADMIN);
        configurator.setReserveInterestRateStrategyAddress(
            USDC,
            address(interestRateStrategy)
        );
        configurator.setReserveInterestRateStrategyAddress(
            USDT,
            address(interestRateStrategy)
        );
        vm.stopPrank();

        _triggerUpdate(USDC);
        _triggerUpdate(USDT);

        assertEq(_getBorrowRate(USDC), 0.032465964040419624628115797e27);
        assertEq(_getBorrowRate(USDT), 0.043549288556262928206251427e27);
    }

    // TODO add capped oracles for WBTC (need to import the combining contract first)

    function _getBorrowRate(address asset) internal view returns (uint256) {
        return pool.getReserveData(asset).currentVariableBorrowRate;
    }

    function _triggerUpdate(address asset) internal {
        // Flashloan small amount to force indicies update
        pool.flashLoanSimple(address(this), asset, 1, "", 0);
    }

    // Flashloan callback
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 fee,
        address,
        bytes calldata
    ) external returns (bool) {
        IERC20(asset).safeApprove(msg.sender, amount + fee);
        return true;
    }

}