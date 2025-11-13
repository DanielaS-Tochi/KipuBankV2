// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/KipuBankV3.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InteractKipuBankV3 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address contractAddress = vm.envAddress("CONTRACT_ADDRESS");

        KipuBankV3 bank = KipuBankV3(payable(contractAddress));

        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Interacting with KipuBankV3 ===");
        console.log("Contract:", contractAddress);
        console.log("User:", vm.addr(deployerPrivateKey));
        console.log("");

        address user = vm.addr(deployerPrivateKey);
        uint256 initialBalance = bank.balanceOf(user);
        console.log("Initial Balance:", initialBalance);

        console.log("");
        console.log("=== Interaction Complete ===");

        vm.stopBroadcast();
    }

    function depositETH(address contractAddress, uint256 amount) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        KipuBankV3 bank = KipuBankV3(payable(contractAddress));

        vm.startBroadcast(deployerPrivateKey);

        console.log("Depositing ETH:", amount);
        bank.depositETH{value: amount}();

        address user = vm.addr(deployerPrivateKey);
        console.log("New Balance:", bank.balanceOf(user));

        vm.stopBroadcast();
    }

    function depositUSDC(address contractAddress, address usdcAddress, uint256 amount) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        KipuBankV3 bank = KipuBankV3(payable(contractAddress));
        IERC20 usdc = IERC20(usdcAddress);

        vm.startBroadcast(deployerPrivateKey);

        console.log("Approving USDC:", amount);
        usdc.approve(contractAddress, amount);

        console.log("Depositing USDC:", amount);
        bank.depositToken(usdcAddress, amount);

        address user = vm.addr(deployerPrivateKey);
        console.log("New Balance:", bank.balanceOf(user));

        vm.stopBroadcast();
    }

    function withdraw(address contractAddress, uint256 amount) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        KipuBankV3 bank = KipuBankV3(payable(contractAddress));

        vm.startBroadcast(deployerPrivateKey);

        console.log("Withdrawing:", amount);
        bank.withdraw(amount);

        address user = vm.addr(deployerPrivateKey);
        console.log("New Balance:", bank.balanceOf(user));

        vm.stopBroadcast();
    }

    function checkBalance(address contractAddress, address user) external view {
        KipuBankV3 bank = KipuBankV3(payable(contractAddress));

        console.log("User:", user);
        console.log("Balance:", bank.balanceOf(user));
    }
}
