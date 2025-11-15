![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue)
![License: MIT](https://img.shields.io/badge/License-MIT-green)
![Network: Sepolia](https://img.shields.io/badge/Network-Sepolia-orange)

# 💰 KipuBank V2 Smart Contract

## 🇪🇸 Español

### 📖 Descripción

**KipuBankV2** es una versión mejorada del contrato original **KipuBank**, desarrollada para el trabajo práctico del **Módulo 3 – Aplicaciones Descentralizadas**.  
Esta nueva versión incorpora **control de acceso, soporte multi-token, integración con Chainlink, y mejoras de seguridad y arquitectura**, siguiendo buenas prácticas de Solidity y estándares de la industria Web3.

El objetivo es simular un banco descentralizado con soporte tanto para **ETH** como para **tokens ERC‑20**, añadiendo además una **contabilidad interna basada en USD** a través de un **oráculo de precios Chainlink**.

---

### ⚙️ Principales mejoras implementadas

| Categoría                         | Mejora                                      | Descripción                                                                 |
|----------------------------------|---------------------------------------------|-----------------------------------------------------------------------------|
| 🧩 **Control de acceso**          | `AccessControl` de OpenZeppelin             | Permite funciones administrativas seguras mediante roles (`BANK_MANAGER_ROLE`). |
| 💰 **Soporte multi-token**        | ETH + ERC‑20                                | Usuarios pueden depositar y retirar tanto ETH como tokens ERC‑20.         |
| 🧮 **Contabilidad interna**       | Mappings anidados                            | `balances[user][token]` para manejar múltiples activos.                    |
| 🔗 **Oráculo Chainlink ETH/USD**  | Precio en tiempo real                        | Conversión del valor en ETH a USD para controlar el límite del banco.     |
| 🧠 **Variables inmutables y constantes** | Eficiencia y seguridad                   | Uso de `immutable` y `constant` para datos clave.                          |
| 🪙 **Conversión de decimales**    | Estandarización                              | Conversión a formato USDC (6 decimales) para todas las operaciones internas. |
| 🛡️ **Seguridad**                  | Patrón Checks‑Effects‑Interactions + ReentrancyGuard | Prevención de reentradas y vulnerabilidades comunes.             |
| 📢 **Eventos y errores personalizados** | Transparencia y debugging             | Emite eventos `Deposited`, `Withdrawn` y `BankCapUpdated`.                  |
| 🧾 **Documentación NatSpec**      | Código profesional                            | Comentarios claros y estructura limpia.                                     |

---

### 🧱 Variables principales

| Tipo                                            | Nombre                 | Descripción                                  |
|-------------------------------------------------|------------------------|----------------------------------------------|
| `bytes32`                                       | `BANK_MANAGER_ROLE`    | Rol administrativo del banco.                |
| `AggregatorV3Interface`                          | `priceFeed`            | Oráculo ETH/USD de Chainlink.                |
| `uint256`                                       | `bankCapUSD`           | Límite máximo del banco (en USD, 6 decimales). |
| `mapping(address => mapping(address => uint256))` | `balances`             | Contabilidad multi‑token por usuario.        |

---

### 🚀 Despliegue

- **Red:** Sepolia Testnet  
- **Herramienta:** Remix IDE  
- **Wallet:** MetaMask  
- **Versión Solidity:** 0.8.19  
- **Oráculo Chainlink ETH/USD (Sepolia):**  
  `0x694AA1769357215DE4FAC081bf1f309aDC325306`

#### **Constructor parameters**
| Parámetro        | Descripción                            | Ejemplo            |
|------------------|----------------------------------------|---------------------|
| `_priceFeed`     | Dirección del oráculo Chainlink        | `0x694AA1769357215DE4FAC081bf1f309aDC325306` |
| `_bankCapUSD`    | Límite máximo en USD (6 decimales)    | `100000000` (100 USD) |

---

### 🧪 Cómo interactuar

1. Abrir **Remix IDE** y conectar **MetaMask** a la red **Sepolia**.  
2. Compilar el contrato `KipuBankV2.sol` con versión **0.8.19**.  
3. Desplegarlo ingresando:
   - `_priceFeed`: dirección del oráculo ETH/USD  
   - `_bankCapUSD`: por ejemplo, `100000000`  
4. Probar funciones:
   - `depositETH()` → enviar ETH mediante el campo **Value** (en wei).  
   - `depositToken(address token, uint256 amount)` → aprobar token ERC‑20 y luego depositar.  
   - `withdrawETH(uint256 amount)` → retirar ETH.  
   - `withdrawToken(address token, uint256 amount)` → retirar tokens ERC‑20.  
   - `updateBankCap(uint256 newCap)` → sólo para el rol `BANK_MANAGER_ROLE`.  
   - `balances(user, token)` → consultar saldos por usuario y token.  

---

### 🧠 Decisiones de diseño

- **Uso de `AccessControl`** permite escalar el sistema con roles adicionales (ej.: auditor, liquidez).  
- **Contabilidad en USD** facilita incorporar en el futuro préstamos, liquidaciones o yield.  
- **Oráculo Chainlink integrado** asegura datos descentralizados y fiables.  
- **Patrón CEI + ReentrancyGuard** garantiza un flujo seguro en depósitos y retiros.  

---

### 👩‍💻 Autoría

Desarrollado por **Daniela Silvana Tochi**  
**Módulo 3 – Aplicaciones Descentralizadas**  
**Año:** 2025  
**Licencia:** MIT  

---

## 🇬🇧 English

### 📖 Description

**KipuBankV2** is an upgraded version of the original **KipuBank** smart contract, developed as the **Final Project for Module 3 – Decentralized Applications**.  
This version introduces **access control, multi‑token support, Chainlink oracle integration, and improved security and accounting**, following Solidity and Web3 best practices.

The goal is to simulate a decentralized bank that supports both **ETH** and **ERC‑20 tokens**, with internal accounting based on **USD values** using the **Chainlink ETH/USD price feed**.

---

### ⚙️ Main Improvements

| Category                                | Feature                                | Description                                         |
|----------------------------------------|----------------------------------------|-----------------------------------------------------|
| 🧩 **Access Control**                   | OpenZeppelin `AccessControl`          | Adds secure admin operations via `BANK_MANAGER_ROLE`. |
| 💰 **Multi‑token Support**              | ETH + ERC20                            | Users can deposit and withdraw both native ETH and ERC‑20 tokens. |
| 🧮 **Internal Accounting**              | Nested mappings                        | Tracks balances as `balances[user][token]`.         |
| 🔗 **Chainlink Oracle Integration**     | ETH/USD Feed                           | Converts ETH value to USD to enforce the bank cap. |
| 🧠 **Constants & Immutables**           | Gas‑efficient                          | Defines immutable and constant values for key parameters. |
| 🪙 **Decimal Conversion**               | USDC standard (6 decimals)             | Normalizes values across tokens.                    |
| 🛡️ **Security**                         | CEI pattern + ReentrancyGuard          | Protects against reentrancy and unsafe interactions. |
| 📢 **Custom Events & Errors**           | Debug‑friendly                         | Emits `Deposited`, `Withdrawn`, `BankCapUpdated`.   |
| 🧾 **NatSpec Documentation**            | Clarity                                | Clean, documented and readable Solidity code.       |

---

### 🧱 Key Variables

| Type                                               | Name             | Description                          |
|----------------------------------------------------|------------------|--------------------------------------|
| `bytes32`                                         | `BANK_MANAGER_ROLE` | Admin role identifier.              |
| `AggregatorV3Interface`                           | `priceFeed`        | Chainlink ETH/USD oracle address.   |
| `uint256`                                         | `bankCapUSD`       | Maximum allowed total (in USD, 6 decimals). |
| `mapping(address => mapping(address => uint256))`| `balances`         | Tracks user balances for multiple tokens. |

---

### 🚀 Deployment

- **Network:** Sepolia Testnet  
- **Tool:** Remix IDE  
- **Wallet:** MetaMask  
- **Solidity version:** 0.8.19  
- **Chainlink ETH/USD feed (Sepolia):**  
  `0x694AA1769357215DE4FAC081bf1f309aDC325306`

#### **Constructor parameters**
| Parameter        | Description                          | Example             |
|------------------|--------------------------------------|----------------------|
| `_priceFeed`     | Chainlink ETH/USD feed address       | `0x694AA1769357215DE4FAC081bf1f309aDC325306` |
| `_bankCapUSD`    | Bank cap in USD (6 decimals)         | `100000000` (100 USD) |

---

### 🧪 How to Interact

1. Open **Remix IDE** and connect **MetaMask** to **Sepolia testnet**.  
2. Compile `KipuBankV2.sol` using **0.8.19**.  
3. Deploy the contract entering:
   - `_priceFeed`: Chainlink ETH/USD address  
   - `_bankCapUSD`: e.g. `100000000`  
4. Test functions:
   - `depositETH()` → send ETH via the **Value** field (in wei).  
   - `depositToken(address token, uint256 amount)` → approve token first, then deposit.  
   - `withdrawETH(uint256 amount)` → withdraw ETH.  
   - `withdrawToken(address token, uint256 amount)` → withdraw ERC20 tokens.  
   - `updateBankCap(uint256 newCap)` → only callable by `BANK_MANAGER_ROLE`.  
   - `balances(user, token)` → check balances by address and token.  

---

### 🧠 Design Decisions

- Using `AccessControl` enables scalability with more roles (e.g., auditor, liquidity provider).  
- USD‑based accounting simplifies future features like lending or yield.  
- Chainlink oracle integration provides reliable decentralized price data.  
- CEI pattern and `ReentrancyGuard` enforce secure transaction workflows.  

---

### 🏷 License

This project is licensed under the [MIT License](./LICENSE).

---

### ✍️ Author

Developed by **Daniela Silvana Tochi**  
**Module 3 – Decentralized Applications**  
**Year:** 2025  
**License:** MIT  
