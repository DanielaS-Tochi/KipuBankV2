// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title KipuBank
 * @author Daniela Silvana Tochi
 * @notice Smart contract / Contrato educativo para depósitos y retiros de ETH con límites y buenas prácticas.
 * @dev Built for Module 2 final. Designed for Remix + MetaMask deployment on Sepolia.
 */
contract KipuBank {
    /// @notice Límite máximo global de depósito / Global deposit cap
    uint256 public immutable bankCap;

    /// @notice Límite máximo de retiro por transacción / Withdraw limit per tx
    uint256 public immutable withdrawLimit;

    /// @notice Propietario del contrato
    address public immutable owner;

    /// @notice Saldo por usuario (mapping)
    mapping(address => uint256) private balances;

    /// @notice Total depositado en el contrato
    uint256 public totalDeposited;

    /// @notice Contadores de operaciones
    uint256 public depositCount;
    uint256 public withdrawalCount;

    /// @notice Eventos para depósitos y retiros
    event Deposit(address indexed user, uint256 amount, uint256 newBalance);
    event Withdrawal(address indexed user, uint256 amount, uint256 newBalance);

    /// @notice Errores personalizados
    error ExceedsBankCap(uint256 requested, uint256 available);
    error ExceedsWithdrawLimit(uint256 requested, uint256 limit);
    error InsufficientBalance(uint256 requested, uint256 balance);
    error OnlyOwner();
    error ZeroDeposit();

    /// @notice Modificadores
    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier nonZero() {
        if (msg.value == 0) revert ZeroDeposit();
        _;
    }

    /// @notice Constructor: define bankCap y withdrawLimit
    /// @param _bankCap Límite global de depósito (en wei)
    /// @param _withdrawLimit Límite por retiro por tx (en wei)
    constructor(uint256 _bankCap, uint256 _withdrawLimit) {
        owner = msg.sender;
        bankCap = _bankCap;
        withdrawLimit = _withdrawLimit;
    }

    /// @notice Deposita ETH en la bóveda del remitente (payable)
    function deposit() external payable nonZero {
        uint256 newTotal = totalDeposited + msg.value;
        if (newTotal > bankCap) revert ExceedsBankCap(msg.value, bankCap - totalDeposited);

        // effects
        balances[msg.sender] += msg.value;
        totalDeposited = newTotal;
        depositCount++;

        // interactions (emit)
        emit Deposit(msg.sender, msg.value, balances[msg.sender]);
    }

    /// @notice Retira ETH de la bóveda del remitente, respetando withdrawLimit
    /// @param amount Cantidad a retirar (wei)
    function withdraw(uint256 amount) external {
        if (amount > withdrawLimit) revert ExceedsWithdrawLimit(amount, withdrawLimit);
        if (amount > balances[msg.sender]) revert InsufficientBalance(amount, balances[msg.sender]);

        // effects
        balances[msg.sender] -= amount;
        totalDeposited -= amount;
        withdrawalCount++;

        // interactions: transferencia segura
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawal(msg.sender, amount, balances[msg.sender]);
    }

    /// @notice Consulta saldo de cualquier usuario (view)
    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    /// @dev Función privada que devuelve cuánto queda del bankCap
    function _availableCap() private view returns (uint256) {
        return bankCap - totalDeposited;
    }

    /// @notice Ejemplo de función solo-owner para demostrar modifier (opcional)
    function increaseBankCapForDemo(uint256 /*newCap*/) external onlyOwner {
        // Intencionalmente vacío: no cambia la variable immutable (solo demostración).
        // Si se quisiera que bankCap sea actualizable, habría que remover `immutable`.
    }
}
