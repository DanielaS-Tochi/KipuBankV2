# KipuBankV3

**Autor:** Daniela Silvana Tochi

## Descripción General

KipuBankV3 es una aplicación DeFi avanzada que representa la evolución del sistema bancario KipuBank. Esta versión integra Uniswap V2 para permitir depósitos de cualquier token ERC20 soportado por el protocolo, realizando swaps automáticos a USDC y acreditando el balance del usuario, todo mientras respeta el límite máximo del banco (bank cap).

## Características Principales

### 1. Depósitos Multi-Token
- **ETH Nativo**: Los usuarios pueden depositar ETH directamente
- **USDC Directo**: Depósitos de USDC sin necesidad de swap
- **Cualquier Token ERC20**: Soporte para tokens con pares en Uniswap V2

### 2. Integración con Uniswap V2
- Swaps automáticos de tokens a USDC
- Rutas inteligentes (directa o a través de WETH)
- Protección contra slippage (5% máximo)
- Validación de liquidez antes del swap

### 3. Seguridad y Mejores Prácticas
- **ReentrancyGuard**: Protección contra ataques de reentrada
- **AccessControl**: Sistema de roles para administración
- **SafeERC20**: Manejo seguro de transferencias ERC20
- **Custom Errors**: Optimización de gas y mensajes claros

### 4. Preservación de Funcionalidad KipuBankV2
- Control de ownership mediante roles
- Sistema de depósitos y retiros
- Límite del banco (bank cap) respetado
- Contabilidad precisa en USDC

## Arquitectura Técnica

### Componentes Clave

```
KipuBankV3
├── src/
│   ├── KipuBankV3.sol          # Contrato principal
│   └── interfaces/
│       ├── IUniswapV2Router02.sol
│       └── IUniswapV2Factory.sol
├── test/
│   └── KipuBankV3.t.sol        # Tests completos
└── script/
    ├── Deploy.s.sol             # Script de despliegue general
    └── DeploySepolia.s.sol      # Script para Sepolia
```

### Flujo de Depósito

1. **Usuario deposita token X**
2. **Validación**:
   - Verificar que el monto > 0
   - Verificar que el token sea válido
3. **Swap a USDC**:
   - Si token == USDC → No swap
   - Si existe par Token/USDC → Swap directo
   - Si no → Ruta Token → WETH → USDC
4. **Validación Bank Cap**:
   - Verificar que `totalDepositedUSDC + usdcAmount <= bankCapUSDC`
5. **Actualización de Estado**:
   - Incrementar `balances[usuario]`
   - Incrementar `totalDepositedUSDC`
6. **Emitir Evento**: `Deposited`

### Decisiones de Diseño

#### 1. USDC como Token Base
**Razón**: USDC es un stablecoin ampliamente adoptado, lo que proporciona:
- Estabilidad de precio
- Alta liquidez en DEXs
- Facilita cálculos del bank cap

#### 2. Protección contra Slippage
**Implementación**: Máximo 5% de slippage permitido
```solidity
uint256 minAmountOut = (expectedAmount * 9500) / 10000;
```
**Razón**: Protege a los usuarios contra movimientos adversos de precio durante el swap.

#### 3. Rutas Inteligentes de Swap
**Lógica**:
```solidity
if (pairExists(token, USDC)) {
    // Ruta directa: Token → USDC
} else {
    // Ruta indirecta: Token → WETH → USDC
}
```
**Razón**: Optimiza costos de gas y garantiza mejor ejecución de precio.

#### 4. Validación de Liquidez
**Implementación**: Verificación antes del swap
```solidity
function _pairExists(address tokenA, address tokenB) internal view returns (bool)
```
**Razón**: Previene fallos de transacción y proporciona errores claros.

#### 5. Inmutabilidad de Direcciones Críticas
**Implementación**: `immutable` para router, USDC, WETH
**Razón**:
- Ahorro de gas en accesos
- Mayor seguridad (no pueden ser cambiadas)

#### 6. SafeERC20
**Razón**: Maneja tokens ERC20 no estándar que no retornan `bool` en transferencias.

## Instalación y Setup

### Prerrequisitos
```bash
# Instalar Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Instalación de Dependencias
```bash
cd KipuBankV3
forge install OpenZeppelin/openzeppelin-contracts
forge install foundry-rs/forge-std
```

### Configuración de Variables de Entorno
Crear archivo `.env`:
```env
PRIVATE_KEY=your_private_key
SEPOLIA_RPC_URL=your_sepolia_rpc_url
ETHERSCAN_API_KEY=your_etherscan_api_key

# Para deployment personalizado
UNISWAP_ROUTER=0x...
USDC_ADDRESS=0x...
BANK_CAP_USDC=1000000000000  # 1M USDC (6 decimales)
```

## Testing

### Ejecutar Tests
```bash
# Todos los tests
forge test

# Tests con verbosidad
forge test -vvv

# Test específico
forge test --match-test testDepositETH

# Cobertura
forge coverage
```

### Tests Implementados
- ✅ `testDepositETH`: Depósito de ETH y swap a USDC
- ✅ `testDepositUSDC`: Depósito directo de USDC
- ✅ `testDepositDAI`: Depósito de token ERC20 con swap
- ✅ `testWithdraw`: Retiro de fondos
- ✅ `testBankCapRespected`: Validación del límite del banco
- ✅ `testMultipleUsersDeposit`: Múltiples usuarios
- ✅ `testRevertInsufficientBalance`: Error de balance insuficiente
- ✅ `testRevertZeroAmount`: Error de monto cero
- ✅ `testUpdateBankCap`: Actualización del bank cap
- ✅ `testGetAvailableCap`: Consulta de capacidad disponible
- ✅ `testReceiveFunction`: Función receive()

## Deployment

### Despliegue en Sepolia
```bash
# Cargar variables de entorno
source .env

# Deploy
forge script script/DeploySepolia.s.sol:DeploySepoliaKipuBankV3 \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --verify

# Verificar manualmente si es necesario
forge verify-contract <CONTRACT_ADDRESS> \
    src/KipuBankV3.sol:KipuBankV3 \
    --chain-id 11155111 \
    --constructor-args $(cast abi-encode "constructor(address,address,uint256)" <ROUTER> <USDC> <CAP>)
```

### Despliegue en Otras Redes
```bash
forge script script/Deploy.s.sol:DeployKipuBankV3 \
    --rpc-url $YOUR_RPC_URL \
    --broadcast \
    --verify
```

## Interacción con el Contrato

### Usando Cast (Foundry)

#### 1. Depositar ETH
```bash
cast send <CONTRACT_ADDRESS> "depositETH()" \
    --value 0.1ether \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY
```

#### 2. Depositar USDC
```bash
# Aprobar USDC primero
cast send <USDC_ADDRESS> "approve(address,uint256)" \
    <CONTRACT_ADDRESS> 1000000000 \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY

# Depositar
cast send <CONTRACT_ADDRESS> "depositToken(address,uint256)" \
    <USDC_ADDRESS> 1000000000 \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY
```

#### 3. Consultar Balance
```bash
cast call <CONTRACT_ADDRESS> "balanceOf(address)(uint256)" \
    <USER_ADDRESS> \
    --rpc-url $SEPOLIA_RPC_URL
```

#### 4. Retirar Fondos
```bash
cast send <CONTRACT_ADDRESS> "withdraw(uint256)" \
    1000000000 \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY
```

### Usando Web3.js/Ethers.js

```javascript
// Depositar ETH
await kipuBank.depositETH({ value: ethers.parseEther("0.1") });

// Depositar Token
await token.approve(kipuBankAddress, amount);
await kipuBank.depositToken(tokenAddress, amount);

// Retirar
await kipuBank.withdraw(amount);

// Consultar balance
const balance = await kipuBank.balanceOf(userAddress);
```

## Direcciones de Contratos

### Sepolia Testnet
- **Uniswap V2 Router**: `0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008`
- **USDC**: `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238`
- **WETH**: `0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14`

### Mainnet
- **Uniswap V2 Router**: `0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D`
- **USDC**: `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48`
- **WETH**: `0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2`

## Seguridad

### Auditoría y Mejores Prácticas

1. **Checks-Effects-Interactions Pattern**: Todas las funciones siguen este patrón
2. **ReentrancyGuard**: Protección en todas las funciones públicas que manejan fondos
3. **SafeERC20**: Manejo seguro de tokens ERC20
4. **Access Control**: Funciones administrativas protegidas con roles
5. **Custom Errors**: Ahorro de gas y mensajes claros
6. **Validaciones**: Múltiples validaciones antes de operaciones críticas

### Consideraciones de Seguridad

- ⚠️ **Slippage**: El contrato tiene un slippage máximo del 5%. En condiciones de alta volatilidad, considerar ajustar.
- ⚠️ **Front-running**: Los swaps públicos pueden ser vulnerables a front-running. Considerar implementar MEV protection.
- ⚠️ **Oracle**: No se usa oracle de precios. Se confía en los precios de Uniswap.
- ✅ **Reentrancy**: Protegido con ReentrancyGuard
- ✅ **Integer Overflow**: Solidity 0.8.19 tiene protección nativa

## Gas Optimization

### Optimizaciones Implementadas

1. **Immutable Variables**: Router, USDC, WETH son inmutables
2. **Custom Errors**: En lugar de strings de error
3. **Unchecked Blocks**: Donde es seguro (no implementado actualmente pero recomendado)
4. **Packing de Variables**: Organización eficiente de storage

### Costos Estimados de Gas

- Deposit ETH: ~150,000 gas
- Deposit USDC: ~80,000 gas
- Deposit Token (swap): ~200,000 gas
- Withdraw: ~60,000 gas

## Roadmap y Mejoras Futuras

### Versión 3.1
- [ ] Soporte para Uniswap V3 (mayor eficiencia de capital)
- [ ] Límites de retiro por usuario
- [ ] Sistema de tarifas (fees)

### Versión 3.2
- [ ] Integración con Chainlink Price Feeds
- [ ] Multi-collateral (múltiples stablecoins)
- [ ] Flash loans protection

### Versión 4.0
- [ ] Yield farming automático
- [ ] Staking de tokens del banco
- [ ] Gobernanza descentralizada

## Contribuciones

Este proyecto es parte de un examen final del curso de desarrollo Web3. Las contribuciones son bienvenidas siguiendo estas pautas:

1. Fork del repositorio
2. Crear branch con feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit de cambios (`git commit -m 'Add nueva funcionalidad'`)
4. Push al branch (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request

## Licencia

MIT License - ver archivo LICENSE para detalles

## Contacto y Recursos

- **GitHub**: [Link al repositorio]
- **Documentación Uniswap V2**: https://docs.uniswap.org/contracts/v2/overview
- **OpenZeppelin Contracts**: https://docs.openzeppelin.com/contracts/
- **Foundry Book**: https://book.getfoundry.sh/

## Agradecimientos

- Equipo de Kipu por la educación en desarrollo Web3
- Comunidad de OpenZeppelin por los contratos seguros
- Uniswap por el protocolo de intercambio descentralizado
- Foundry por las herramientas de desarrollo

---

**Desarrollado con ❤️ para el ecosistema Ethereum**
