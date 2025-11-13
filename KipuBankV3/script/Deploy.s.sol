// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/KipuBankV3.sol";

contract DeployKipuBankV3 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address uniswapRouter = vm.envAddress("UNISWAP_ROUTER");
        address usdc = vm.envAddress("USDC_ADDRESS");
        uint256 bankCap = vm.envUint("BANK_CAP_USDC");

        vm.startBroadcast(deployerPrivateKey);

        KipuBankV3 bank = new KipuBankV3(
            uniswapRouter,
            usdc,
            bankCap
        );

        console.log("KipuBankV3 deployed at:", address(bank));
        console.log("Bank Cap (USDC):", bankCap);
        console.log("Uniswap Router:", uniswapRouter);
        console.log("USDC Address:", usdc);

        vm.stopBroadcast();
    }
}
