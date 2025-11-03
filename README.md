![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue)
![License: MIT](https://img.shields.io/badge/License-MIT-green)
![Network: Sepolia](https://img.shields.io/badge/Network-Sepolia-orange)

# 🪙 KipuBankV2 Smart Contract

## 🇬🇧 English

### 📖 Overview
**KipuBankV2** is an upgraded version of the original *KipuBank* smart contract.  
It introduces **multi-token deposits**, **access control**, and a base for **Chainlink oracle integration**.  
This version simulates a decentralized bank that supports both **ETH and ERC20 tokens**, with secure withdrawal limits and modular expansion capacity.

### ✨ Key Improvements
- ✅ Access control via `AccessControl` (admin and manager roles).  
- ✅ Multi-token accounting (supports ETH and ERC20 tokens).  
- ✅ Immutable and constant variables for safer configuration.  
- ✅ Custom errors and events for observability and debugging.  
- 🔜 Chainlink oracle integration to handle USD conversion.  
- 🔜 Decimal conversion utilities for cross-token accounting.  
- 🌟 Planned: *KipuPoints* — a loyalty program for long-term depositors.

### ⚙️ Deployment Instructions
1. Open [Remix IDE](https://remix.ethereum.org/)
2. Create folder `/src` and upload `KipuBankV2.sol`
3. Compile with **Solidity 0.8.20**
4. Deploy on **Sepolia Testnet**
   - Enter a `_bankCapUSD` (e.g. `100000`)
   - Click **Deploy**
5. Verify the contract in **Routescan** or **Sourcify**
6. Save the deployed address and verification link in this README

### 🧩 Interaction
You can interact directly from Remix:
- `deposit(address token, uint256 amount)` — deposit ETH or ERC20 tokens  
  *(use `address(0)` for ETH and specify `value` in Remix)*  
- `withdraw(address token, uint256 amount)` — withdraw your funds  
- `balanceOf(address user, address token)` — check balances  

### 🔐 Roles
- **DEFAULT_ADMIN_ROLE:** Full control over contract management.  
- **BANK_MANAGER_ROLE:** Permissioned role for future operations (e.g. Chainlink settings or cap updates).

### 📬 Deployed Contract (example)
> 🧱 Address: *to be added*  
> 🔗 Verification: *to be added*

---

## 🇪🇸 Español

### 📖 Descripción
**KipuBankV2** es una versión mejorada del contrato *KipuBank*, que incorpora **control de acceso**, **soporte multi-token** y base para integración con **oráculos de Chainlink**.  
Simula un banco descentralizado donde los usuarios pueden **depositar y retirar ETH o tokens ERC20** de forma segura, dentro de límites predefinidos.

### ✨ Mejoras Clave
- ✅ Control de acceso con `AccessControl` (roles de admin y manager).  
- ✅ Soporte multi-token (ETH y ERC20).  
- ✅ Variables `immutable` y `constant` para mayor seguridad.  
- ✅ Errores personalizados y eventos para mejorar el seguimiento.  
- 🔜 Integración con Chainlink para convertir valores a USD.  
- 🔜 Funciones para conversión de decimales entre tokens.  
- 🌟 Próximamente: *KipuPoints*, un sistema de fidelidad para usuarios activos.

### ⚙️ Instrucciones de Despliegue
1. Abrir [Remix IDE](https://remix.ethereum.org/)
2. Crear la carpeta `/src` y subir `KipuBankV2.sol`
3. Compilar con **Solidity 0.8.20**
4. Desplegar en **Sepolia Testnet**
   - Ingresar `_bankCapUSD` (ejemplo: `100000`)
   - Click en **Deploy**
5. Verificar el contrato en **Routescan** o **Sourcify**
6. Agregar aquí la dirección desplegada y enlace de verificación.

### 🧩 Interacción
Desde Remix podés:
- `deposit(address token, uint256 amount)` — depositar ETH o tokens ERC20  
  *(usar `address(0)` para ETH y especificar `value` en Remix)*  
- `withdraw(address token, uint256 amount)` — retirar tus fondos  
- `balanceOf(address user, address token)` — consultar tu saldo  

### 🔐 Roles
- **DEFAULT_ADMIN_ROLE:** Control total del contrato.  
- **BANK_MANAGER_ROLE:** Rol con permisos limitados para futuras funciones (ej. actualización de oráculo o límites).

### 📬 Contrato Desplegado (ejemplo)
> 🧱 Dirección: *por completar*  
> 🔗 Verificación: *por completar*

---

### 📘 License
MIT License © 2025 — Daniela Silvana Tochi
