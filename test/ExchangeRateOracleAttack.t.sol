// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { IAaveOracle } from "sparklend-v1-core/interfaces/IAaveOracle.sol";

import { Ethereum } from "lib/sparklend-address-registry/src/Ethereum.sol";

import { WEETHExchangeRateOracle } from "src/WEETHExchangeRateOracle.sol";

interface IWEETH {
    function getEETHByWeETH(uint256 amount) external view returns (uint256);
}

interface IEETH {
    function burnShares(address user, uint256 shares) external;
}

contract ExchangeRateOracleAttackBase is Test {

    WEETHExchangeRateOracle oracle;

    address EETH          = 0x35fA164735182de50811E8e2E824cFb9B6118ac2;
    address EETH_WHALE    = 0x1de713F78aA5f29874bBcc95e125721F002Da7f2;
    address ETHUSD_ORACLE = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address WEETH         = 0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;

    IAaveOracle aaveOracle = IAaveOracle(Ethereum.AAVE_ORACLE);
    IEETH       eeth       = IEETH(EETH);
    IWEETH      weeth      = IWEETH(WEETH);

    function test_attack() public {
        vm.createSelectFork(getChain("mainnet").rpcUrl, 19895484);  // May 18, 2024

        oracle = new WEETHExchangeRateOracle(WEETH, ETHUSD_ORACLE);

        address[] memory assets = new address[](1);
        assets[0] = WEETH;
        address[] memory sources = new address[](1);
        sources[0] = address(oracle);

        vm.prank(Ethereum.SPARK_PROXY);
        aaveOracle.setAssetSources(
            assets,
            sources
        );

        uint256 price = 3225.32665359e8;

        assertEq(weeth.getEETHByWeETH((1e18)), 1.038650846493764559e18);

        assertEq(aaveOracle.getAssetPrice(WEETH),    price);
        assertEq(aaveOracle.getSourceOfAsset(WEETH), address(oracle));

        // Have to burn 10k shares to change exchange rate by 1%
        vm.prank(EETH_WHALE);
        eeth.burnShares(EETH_WHALE, 10_000e18);

        assertEq(weeth.getEETHByWeETH((1e18)), 1.046247736567006321e18);
    }
}
