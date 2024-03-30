// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { IERC20 }    from "erc20-helpers/interfaces/IERC20.sol";
import { SafeERC20 } from "erc20-helpers/SafeERC20.sol";

import { IAaveOracle }                  from "sparklend-v1-core/interfaces/IAaveOracle.sol";
import { IPoolAddressesProvider }       from "sparklend-v1-core/interfaces/IPoolAddressesProvider.sol";
import { IPool }                        from "sparklend-v1-core/interfaces/IPool.sol";
import { IPoolConfigurator }            from "sparklend-v1-core/interfaces/IPoolConfigurator.sol";
import { IDefaultInterestRateStrategy } from "sparklend-v1-core/interfaces/IDefaultInterestRateStrategy.sol";

import { FixedPriceOracle }                   from "src/FixedPriceOracle.sol";
import { CappedOracle }                       from "src/CappedOracle.sol";
import { PotRateSource }                      from "src/PotRateSource.sol";
import { RateTargetBaseInterestRateStrategy } from "src/RateTargetBaseInterestRateStrategy.sol";
import { RateTargetKinkInterestRateStrategy } from "src/RateTargetKinkInterestRateStrategy.sol";
import { RETHExchangeRateOracle }             from "src/RETHExchangeRateOracle.sol";
import { WSTETHExchangeRateOracle }           from "src/WSTETHExchangeRateOracle.sol";

import { RateSourceMock } from "./mocks/RateSourceMock.sol";

// TODO: Add capped oracles for WBTC (need to import the combining contract first)
contract SparkLendMainnetIntegrationTest is Test {

    using SafeERC20 for IERC20;

    address AAVE_ORACLE             = 0x8105f69D9C41644c6A0803fDA7D03Aa70996cFD9;
    address POOL_ADDRESSES_PROVIDER = 0x02C3eA4e34C0cBd694D2adFa2c690EECbC1793eE;
    address POOL                    = 0xC13e21B648A5Ee794902342038FF3aDAB66BE987;
    address POOL_CONFIGURATOR       = 0x542DBa469bdE58FAeE189ffB60C6b49CE60E0738;
    address POT                     = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address ADMIN                   = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;  // SubDAO Proxy

    address DAI    = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address ETH    = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDC   = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address USDT   = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address STETH  = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address RETH   = 0xae78736Cd615f374D3085123A210448E74Fc6393;

    address ETH_IRM       = 0xeCe550fB709C85CE9FC999A033447Ee2DF3ce55c;
    address USDC_ORACLE   = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    address USDT_ORACLE   = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
    address USDC_USDT_IRM = 0xbc8A68B0ab0617D7c90d15bb1601B25d795Dc4c8;  // Note: This is the same for both because the parameters are the same
    address ETHUSD_ORACLE = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address RETH_ORACLE   = 0x05225Cd708bCa9253789C1374e4337a019e99D56;
    address WSTETH_ORACLE = 0x8B6851156023f4f5A66F68BEA80851c3D905Ac93;

    IAaveOracle            aaveOracle            = IAaveOracle(AAVE_ORACLE);
    IPoolAddressesProvider poolAddressesProvider = IPoolAddressesProvider(POOL_ADDRESSES_PROVIDER);
    IPool                  pool                  = IPool(POOL);
    IPoolConfigurator      configurator          = IPoolConfigurator(POOL_CONFIGURATOR);

    function setUp() public {
        vm.createSelectFork(getChain("mainnet").rpcUrl, 19015252);  // Jan 15, 2024
    }

    function test_dai_market_oracle() public {
        // Set fork state to before this was introduced
        vm.createSelectFork(getChain("mainnet").rpcUrl, 18784436);  // Dec 14, 2023

        FixedPriceOracle oracle = new FixedPriceOracle(1e8);

        // Nothing is special about this number, it just happens to be the price at this block
        assertEq(aaveOracle.getAssetPrice(DAI), 0.99982058e8);

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
        RateTargetBaseInterestRateStrategy strategy
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
            address(strategy)
        );

        // Trigger an update from the new IRM
        _triggerUpdate(DAI);

        // Should be unchanged because the borrow spread is the same for both
        assertEq(_getBorrowRate(DAI), currentBorrowRate);

        // Change the borrow spread to 1%
        strategy = new RateTargetBaseInterestRateStrategy({
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
            address(strategy)
        );

        // Trigger an update from the new IRM
        _triggerUpdate(DAI);

        // Should be 0.5% higher than before
        assertEq(_getBorrowRate(DAI), currentBorrowRate + 0.005e27);
    }

    function test_eth_market_irm() public {
        // TODO: Replace with actual ETH yield oracle when ready
        uint256 mockETHYield = 0.03823984723902383709e27;  // 3.8% (approx APR as of Dec 14, 2023)
        RateTargetKinkInterestRateStrategy strategy
            = new RateTargetKinkInterestRateStrategy({
                provider:                 poolAddressesProvider,
                rateSource:               address(new RateSourceMock(mockETHYield)),
                optimalUsageRatio:        0.9e27,
                baseVariableBorrowRate:   0,
                variableRateSlope1Spread: -0.008e27,  // -0.8% spread
                variableRateSlope2:       1.2e27
            });
        IDefaultInterestRateStrategy prevStrategy
            = IDefaultInterestRateStrategy(ETH_IRM);

        _triggerUpdate(ETH);

        assertEq(strategy.getBaseVariableBorrowRate(),    prevStrategy.getBaseVariableBorrowRate());
        assertEq(prevStrategy.getVariableRateSlope1(),    0.032e27);
        assertEq(strategy.getVariableRateSlope1(),        mockETHYield - 0.008e27);
        assertEq(strategy.getVariableRateSlope2(),        prevStrategy.getVariableRateSlope2());
        assertEq(prevStrategy.getMaxVariableBorrowRate(), 1.232e27);
        assertEq(strategy.getMaxVariableBorrowRate(),     1.2e27 + mockETHYield - 0.008e27);

        _triggerUpdate(ETH);

        assertEq(_getBorrowRate(ETH), 0.023148514322509339980467652e27);

        vm.prank(ADMIN);
        configurator.setReserveInterestRateStrategyAddress(
            ETH,
            address(strategy)
        );

        _triggerUpdate(ETH);

        // slope1 has adjusted down a bit so the borrow rate is slightly lower at same utilization
        assertEq(_getBorrowRate(ETH), 0.021875235528844931668104031e27);
    }

    function test_usdc_usdt_market_oracles() public {
        // Set fork state to before this was introduced
        vm.createSelectFork(getChain("mainnet").rpcUrl, 18784436);  // Dec 14, 2023

        CappedOracle usdcOracle = new CappedOracle(USDC_ORACLE, 1e8);
        CappedOracle usdtOracle = new CappedOracle(USDT_ORACLE, 1e8);

        // Nothing is special about these numbers, they just happen to be the price at this block
        assertEq(aaveOracle.getAssetPrice(USDC), 1.00005299e8);
        assertEq(aaveOracle.getAssetPrice(USDT), 0.99961441e8);

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
        assertEq(aaveOracle.getAssetPrice(USDT), 0.99961441e8);
    }

    function test_usdc_usdt_market_irms() public {
        RateTargetKinkInterestRateStrategy strategy
            = new RateTargetKinkInterestRateStrategy({
                provider:                 poolAddressesProvider,
                rateSource:               address(new PotRateSource(POT)),
                optimalUsageRatio:        0.95e27,
                baseVariableBorrowRate:   0,
                variableRateSlope1Spread: -0.004e27,  // -0.4% spread
                variableRateSlope2:       0.2e27
            });
        IDefaultInterestRateStrategy prevStrategy
            = IDefaultInterestRateStrategy(USDC_USDT_IRM);

        assertEq(strategy.OPTIMAL_USAGE_RATIO(),       prevStrategy.OPTIMAL_USAGE_RATIO());
        assertEq(strategy.MAX_EXCESS_USAGE_RATIO(),    prevStrategy.MAX_EXCESS_USAGE_RATIO());
        assertEq(strategy.getBaseVariableBorrowRate(), prevStrategy.getBaseVariableBorrowRate());
        assertEq(strategy.getVariableRateSlope1(),     prevStrategy.getVariableRateSlope1());
        assertEq(strategy.getVariableRateSlope2(),     prevStrategy.getVariableRateSlope2());
        assertEq(strategy.getMaxVariableBorrowRate(),  prevStrategy.getMaxVariableBorrowRate());

        _triggerUpdate(USDC);
        _triggerUpdate(USDT);

        uint256 currentRateUSDC = 0.046649006348770788951303144e27;
        uint256 currentRateUSDT = 0.035889274935287857936106840e27;

        assertEq(_getBorrowRate(USDC), currentRateUSDC, "before: USDC mismatch");
        assertEq(_getBorrowRate(USDT), currentRateUSDT, "before: USDT mismatch");

        vm.startPrank(ADMIN);
        configurator.setReserveInterestRateStrategyAddress(
            USDC,
            address(strategy)
        );
        configurator.setReserveInterestRateStrategyAddress(
            USDT,
            address(strategy)
        );
        vm.stopPrank();

        _triggerUpdate(USDC);
        _triggerUpdate(USDT);

        // Should be no change
        assertEq(_getBorrowRate(USDC), currentRateUSDC, "after1: USDC mismatch");
        assertEq(_getBorrowRate(USDT), currentRateUSDT, "after1: USDT mismatch");

        // Test with different parameters
        strategy = new RateTargetKinkInterestRateStrategy({
            provider:                 poolAddressesProvider,
            rateSource:               address(new PotRateSource(POT)),
            optimalUsageRatio:        0.95e27,
            baseVariableBorrowRate:   0,
            variableRateSlope1Spread: -0.002e27,  // -0.2% spread
            variableRateSlope2:       0.2e27
        });

        vm.startPrank(ADMIN);
        configurator.setReserveInterestRateStrategyAddress(
            USDC,
            address(strategy)
        );
        configurator.setReserveInterestRateStrategyAddress(
            USDT,
            address(strategy)
        );
        vm.stopPrank();

        _triggerUpdate(USDC);
        _triggerUpdate(USDT);

        assertEq(_getBorrowRate(USDC), currentRateUSDC + 0.002000000000000000000000000e27, "after2: USDC mismatch");
        // Almost +0.2%, but utilization is slightly below the kink point
        assertEq(_getBorrowRate(USDT), currentRateUSDT + 0.001602551612415803144238481e27, "after2: USDT mismatch");
    }

    function test_reth_market_oracle() public {
        RETHExchangeRateOracle oracle = new RETHExchangeRateOracle(RETH, ETHUSD_ORACLE);

        // Nothing is special about this number, it just happens to be the price at this block
        uint256 beforePrice = 2747.09479896e8;
        assertEq(aaveOracle.getAssetPrice(RETH),    beforePrice);
        assertEq(aaveOracle.getSourceOfAsset(RETH), RETH_ORACLE);

        address[] memory assets = new address[](1);
        assets[0] = RETH;
        address[] memory sources = new address[](1);
        sources[0] = address(oracle);

        vm.prank(ADMIN);
        aaveOracle.setAssetSources(
            assets,
            sources
        );

        assertEq(aaveOracle.getAssetPrice(RETH),    beforePrice);
        assertEq(aaveOracle.getSourceOfAsset(RETH), address(oracle));
    }

    function test_wsteth_market_oracle() public {
        WSTETHExchangeRateOracle oracle = new WSTETHExchangeRateOracle(STETH, ETHUSD_ORACLE);

        // Nothing is special about this number, it just happens to be the price at this block
        uint256 beforePrice = 2893.26746079e8;
        assertEq(aaveOracle.getAssetPrice(WSTETH),    beforePrice);
        assertEq(aaveOracle.getSourceOfAsset(WSTETH), WSTETH_ORACLE);

        address[] memory assets = new address[](1);
        assets[0] = WSTETH;
        address[] memory sources = new address[](1);
        sources[0] = address(oracle);

        vm.prank(ADMIN);
        aaveOracle.setAssetSources(
            assets,
            sources
        );

        assertEq(aaveOracle.getAssetPrice(WSTETH),    beforePrice);
        assertEq(aaveOracle.getSourceOfAsset(WSTETH), address(oracle));
    }

    /**********************************************************************************************/
    /*** Helper Functions                                                                       ***/
    /**********************************************************************************************/

    function _getBorrowRate(address asset) internal view returns (uint256) {
        return pool.getReserveData(asset).currentVariableBorrowRate;
    }

    function _triggerUpdate(address asset) internal {
        // Flashloan small amount to force indices update
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
