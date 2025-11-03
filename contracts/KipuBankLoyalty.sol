// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title KipuBankLoyalty
 * @dev Extensión del contrato KipuBank con un sistema de puntos de fidelidad.
 */
contract KipuBankLoyalty {
    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public loyaltyPoints;
    uint256 public minDeposit;
    uint256 public maxDeposit;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event LoyaltyPointsEarned(address indexed user, uint256 points);

    constructor(uint256 _minDeposit, uint256 _maxDeposit) {
        owner = msg.sender;
        minDeposit = _minDeposit;
        maxDeposit = _maxDeposit;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Función para depositar ETH
    function deposit() external payable {
        require(msg.value >= minDeposit, "Deposit below minimum");
        require(msg.value <= maxDeposit, "Deposit above maximum");
        balances[msg.sender] += msg.value;

        // Gana 1 punto de fidelidad por cada 0.01 ETH depositado
        uint256 points = msg.value / 0.01 ether;
        loyaltyPoints[msg.sender] += points;

        emit Deposit(msg.sender, msg.value);
        emit LoyaltyPointsEarned(msg.sender, points);
    }

    // Función para retirar ETH
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

    // Consulta los puntos de un usuario
    function getLoyaltyPoints(address user) external view returns (uint256) {
        return loyaltyPoints[user];
    }

    // Función para canjear puntos (solo de ejemplo)
    function redeemPoints(uint256 points) external {
        require(loyaltyPoints[msg.sender] >= points, "Not enough points");
        loyaltyPoints[msg.sender] -= points;
        // Aquí podríamos dar recompensas en ETH o tokens en el futuro
    }
}
