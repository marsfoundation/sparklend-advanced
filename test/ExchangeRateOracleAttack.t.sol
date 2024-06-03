// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { IAaveOracle } from "sparklend-v1-core/interfaces/IAaveOracle.sol";

import { Ethereum } from "lib/sparklend-address-registry/src/Ethereum.sol";

import { WEETHExchangeRateOracle } from "src/WEETHExchangeRateOracle.sol";

contract ExchangeRateOracleAttackBase is Test {

    WEETHExchangeRateOracle oracle;

    address WEETH         = 0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;
    address ETHUSD_ORACLE = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    IAaveOracle aaveOracle = IAaveOracle(Ethereum.AAVE_ORACLE);

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

        assertEq(aaveOracle.getAssetPrice(WEETH),    price);
        assertEq(aaveOracle.getSourceOfAsset(WEETH), address(oracle));
    }
}
