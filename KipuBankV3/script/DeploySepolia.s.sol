// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/KipuBankV3.sol";

contract DeploySepoliaKipuBankV3 is Script {
    address constant SEPOLIA_UNISWAP_ROUTER = 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008;
    address constant SEPOLIA_USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    uint256 constant BANK_CAP = 1000000 * 10**6;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        KipuBankV3 bank = new KipuBankV3(
            SEPOLIA_UNISWAP_ROUTER,
            SEPOLIA_USDC,
            BANK_CAP
        );

        console.log("KipuBankV3 deployed on Sepolia at:", address(bank));
        console.log("Bank Cap (USDC):", BANK_CAP);
        console.log("Uniswap Router:", SEPOLIA_UNISWAP_ROUTER);
        console.log("USDC Address:", SEPOLIA_USDC);

        vm.stopBroadcast();
    }
}
