// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/KipuBankV3.sol";

contract VerifyKipuBankV3 is Script {
    function run() external view {
        address contractAddress = vm.envAddress("CONTRACT_ADDRESS");

        KipuBankV3 bank = KipuBankV3(payable(contractAddress));

        console.log("=== KipuBankV3 Verification ===");
        console.log("Contract Address:", contractAddress);
        console.log("");

        console.log("--- Configuration ---");
        console.log("Bank Cap (USDC):", bank.bankCapUSDC());
        console.log("Total Deposited:", bank.totalDepositedUSDC());
        console.log("Available Cap:", bank.getAvailableCap());
        console.log("");

        console.log("--- Addresses ---");
        console.log("Uniswap Router:", address(bank.uniswapRouter()));
        console.log("USDC:", bank.USDC());
        console.log("WETH:", bank.WETH());
        console.log("");

        console.log("--- Roles ---");
        bytes32 adminRole = bank.DEFAULT_ADMIN_ROLE();
        bytes32 managerRole = bank.BANK_MANAGER_ROLE();

        console.log("DEFAULT_ADMIN_ROLE:");
        console.logBytes32(adminRole);
        console.log("BANK_MANAGER_ROLE:");
        console.logBytes32(managerRole);
        console.log("");

        console.log("=== Verification Complete ===");
    }
}
