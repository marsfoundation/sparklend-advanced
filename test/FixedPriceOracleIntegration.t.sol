// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { IAaveOracle } from "aave-v3-core/contracts/interfaces/IAaveOracle.sol";

import { FixedPriceOracle } from "../src/FixedPriceOracle.sol";

contract FixedPriceOracleIntegrationTest is Test {

    IAaveOracle aaveOracle = IAaveOracle(0x8105f69D9C41644c6A0803fDA7D03Aa70996cFD9);

    address dai   = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address admin = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;     // SubDAO Proxy

    FixedPriceOracle oracle;

    function setUp() public {
        vm.createSelectFork(getChain("mainnet").rpcUrl, 18_492_860);

        oracle = new FixedPriceOracle(1e8);
    }

    function test_replace_dai_oracle() public {
        // Nothing is special about this number, it just happens to be the price at this block
        assertEq(aaveOracle.getAssetPrice(dai), 1.00001809e8);

        address[] memory assets = new address[](1);
        assets[0] = dai;
        address[] memory sources = new address[](1);
        sources[0] = address(oracle);

        vm.prank(admin);
        aaveOracle.setAssetSources(
            assets,
            sources
        );

        assertEq(aaveOracle.getAssetPrice(dai), 1e8);
    }

}
