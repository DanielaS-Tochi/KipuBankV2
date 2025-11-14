# Informe de Análisis de Amenazas - KipuBankV3
**Trabajo Final Módulo 5 - Ethereum Developer Pack**
**Autora:** Daniela Silvana Tochi
**Fecha:** 14 de Noviembre, 2025

---

## 1. Descripción General de KipuBankV3

### ¿Qué hace el protocolo?

KipuBankV3 es un contrato bancario DeFi que permite a los usuarios depositar cualquier token soportado por Uniswap V2 y automáticamente convertirlo a USDC. El contrato mantiene los balances de los usuarios en USDC y permite retiros en cualquier momento.

### Componentes Principales

**Entradas del sistema:**
- **ETH**: Se deposita directamente y se convierte a USDC
- **Tokens ERC20**: Cualquier token con liquidez en Uniswap V2

**Salidas del sistema:**
- **USDC**: Los usuarios siempre retiran en USDC

**Flujo básico de operación:**

1. **Usuario deposita ETH o tokens** → El contrato recibe los fondos
2. **Conversión automática** → Si no es USDC, se hace swap en Uniswap V2
3. **Acreditación** → El balance del usuario aumenta en USDC
4. **Retiro** → El usuario puede retirar su USDC cuando quiera

### Integraciones Externas

- **Uniswap V2 Router**: Para ejecutar los swaps de tokens
- **Uniswap V2 Factory**: Para verificar que existan pares de liquidez
- **OpenZeppelin**: Para seguridad (ReentrancyGuard, AccessControl, SafeERC20)

### Mecanismo de Bank Cap

El protocolo tiene un límite máximo de USDC que puede manejar (`bankCapUSDC`). Esto funciona como un mecanismo de control de riesgo: si se alcanza el cap, no se permiten más depósitos hasta que haya retiros.

**Ejemplo práctico:**
```
Bank Cap: 1,000,000 USDC
Total Depositado: 800,000 USDC
Espacio disponible: 200,000 USDC
```

Si un usuario intenta depositar más de 200,000 USDC equivalentes, la transacción revierte con `BankCapExceeded()`.

### Roles y Permisos

- **DEFAULT_ADMIN_ROLE**: Control total del contrato (asignado al deployer)
- **BANK_MANAGER_ROLE**: Puede actualizar el bank cap
- **Usuarios normales**: Pueden depositar y retirar libremente

---

## 2. Evaluación de Madurez del Protocolo

### 2.1 Cobertura de Pruebas

**Tests actuales implementados: 11**

Los tests cubren:
- ✅ Depósito de ETH
- ✅ Depósito de USDC directo
- ✅ Depósito de otros tokens (DAI)
- ✅ Retiros normales
- ✅ Verificación del bank cap
- ✅ Múltiples usuarios depositando
- ✅ Errores esperados (balance insuficiente, monto cero)
- ✅ Actualización del bank cap
- ✅ Función receive()
- ✅ Cálculo de capacidad disponible

**Análisis de cobertura:**

*Nota: Para obtener métricas precisas de cobertura, ejecutar `forge coverage` en el directorio del proyecto.*

**Áreas bien cubiertas:**
- Flujos principales de depósito y retiro
- Validaciones básicas
- Control de acceso para bank cap

**Áreas con cobertura limitada o ausente:**

1. **Slippage extremo**: No hay tests que simulen condiciones de slippage cercano al 5%
2. **Paths de swap complejos**: Solo se testea el path directo token→USDC y token→WETH→USDC, no se testean escenarios donde ambos paths fallan
3. **Condiciones de competencia**: No hay tests que simulen múltiples usuarios depositando simultáneamente cerca del bank cap
4. **Ataques económicos**: No hay tests de sandwich attacks o manipulación de precio
5. **Edge cases de Uniswap**: No se testea qué pasa si un pool tiene liquidez extremadamente baja
6. **Actualización de bank cap a un valor menor**: No se testea qué pasa si el manager reduce el cap por debajo del total depositado actual

### 2.2 Métodos de Prueba

**Tipos de tests implementados:**

| Tipo de Test | Implementado | Descripción |
|--------------|--------------|-------------|
| **Unit Tests** | ✅ Sí | Tests de funciones individuales con mocks |
| **Integration Tests** | ✅ Sí | Tests de múltiples funciones trabajando juntas |
| **Fuzz Tests** | ❌ No | Tests con entradas aleatorias para encontrar edge cases |
| **Invariant Tests** | ❌ No | Tests de propiedades que siempre deben cumplirse |
| **Fork Tests** | ❌ No | Tests contra datos reales de mainnet/testnet |

**Análisis:**

El protocolo usa **mocks de Uniswap** (MockUniswapV2Router02, MockUniswapV2Factory) en lugar de interactuar con contratos reales. Esto es bueno para tests rápidos y determinísticos, pero tiene limitaciones:

**Ventajas de los mocks:**
- Tests más rápidos (no hay llamadas a red)
- Comportamiento predecible y controlado
- No depende de estado externo

**Desventajas:**
- No capturan el comportamiento real de Uniswap
- Pueden ocultar problemas de integración
- Los exchange rates son hardcodeados, no reflejan mercados reales

**Recomendación:** Agregar fork tests que usen Uniswap real en Sepolia para validar el comportamiento en condiciones más realistas.

### 2.3 Documentación

**Archivos de documentación existentes:**

1. **README.md**: Descripción general, características, deployment
2. **TECHNICAL.md**: Documentación técnica detallada, arquitectura, gas costs
3. **SECURITY.md**: Políticas de seguridad, limitaciones conocidas
4. **DEPLOYMENT_GUIDE.md**: Guía paso a paso para deployment
5. **QUICKSTART.md**: Guía rápida para desarrolladores
6. **PROJECT_SUMMARY.md**: Resumen del proyecto y comparación con versiones anteriores

**Calidad de la documentación: ALTA**

La documentación es extensa y cubre múltiples aspectos del protocolo. Cada función está comentada con NatSpec, lo cual es excelente para generar documentación automática.

**Áreas de mejora:**

1. **Diagramas de flujo**: No hay diagramas visuales de los flujos de depósito/retiro
2. **Ejemplos de uso real**: Faltan ejemplos de cómo integrar el contrato desde un frontend
3. **Threat model formal**: No existe un documento que liste sistemáticamente todos los vectores de ataque (este informe cubre esa brecha)
4. **Runbook de emergencia**: No hay un documento de qué hacer si se encuentra un bug crítico post-deployment

### 2.4 Roles y Poderes de los Actores

**Roles definidos en el protocolo:**

#### DEFAULT_ADMIN_ROLE
**Quién lo tiene:** El deployer del contrato (msg.sender en el constructor)

**Poderes:**
- Otorgar y revocar CUALQUIER rol (incluyendo BANK_MANAGER_ROLE)
- Puede asignarse a sí mismo el BANK_MANAGER_ROLE
- Control total sobre el sistema de roles

**Riesgos:**
- Si la clave privada del admin se compromete, el atacante tiene control total
- Puede otorgar BANK_MANAGER_ROLE a una dirección maliciosa
- Es un single point of failure (punto único de fallo)

**Recomendación:** Este rol debería ser un multisig (ej: Gnosis Safe) con al menos 3-5 firmantes

#### BANK_MANAGER_ROLE
**Quién lo tiene:** También el deployer inicialmente (línea 58)

**Poderes:**
- Actualizar el bank cap a cualquier valor
- Puede reducir el cap por debajo del total depositado (no hay validación)

**Riesgos:**
- Puede reducir el cap a 0, efectivamente pausando depósitos
- Puede aumentarlo a valores extremadamente altos, eliminando la protección
- No hay timelock ni límites en los cambios

**Caso problemático:**
```solidity
// Situación actual
totalDepositedUSDC = 1,000,000 USDC
bankCapUSDC = 1,500,000 USDC

// Manager reduce el cap
updateBankCap(500,000) // ⚠️ Esto es permitido pero crea inconsistencia
```

#### Usuario Normal
**Poderes:**
- Depositar ETH o tokens hasta el bank cap
- Retirar su propio balance en cualquier momento
- Ver su balance y la capacidad disponible

**Limitaciones:**
- No puede retirar más de lo que tiene
- No puede depositar si se excede el bank cap
- Está sujeto al slippage del 5% en swaps

### 2.5 Evaluación de Debilidades

**Resumen de debilidades encontradas:**

| Categoría | Severidad | Descripción |
|-----------|-----------|-------------|
| Centralización | ALTA | Admin y Manager son single points of failure |
| Oracle | ALTA | Usa precios spot de Uniswap sin protección contra manipulación |
| Front-running | MEDIA | Transacciones públicas pueden ser front-runeadas |
| Slippage fijo | MEDIA | 5% puede ser demasiado en mercados estables |
| Sin pausa | MEDIA | No hay mecanismo de pausa en emergencias |
| Testing | MEDIA | Falta cobertura de fuzz y invariant tests |

---

## 3. Vectores de Ataque y Modelo de Amenazas

### Vector de Ataque #1: Manipulación de Precio con Flash Loans

**Categoría:** Uso indebido de supuestos del protocolo (precio oracle confiable)

**Descripción:**

El contrato usa `uniswapRouter.getAmountsOut()` para obtener el precio esperado de un swap. Este precio se basa en el estado actual del pool de Uniswap, que puede ser manipulado dentro de una sola transacción usando flash loans.

**Escenario de ataque:**

1. Atacante obtiene un flash loan de 1,000,000 DAI
2. Vende todo el DAI por USDC en el pool DAI/USDC de Uniswap (mueve el precio)
3. Deposita 1 DAI en KipuBankV3
4. KipuBankV3 ve que el precio DAI/USDC es artificialmente bajo
5. El swap devuelve menos USDC de lo que debería
6. Atacante recompra DAI barato después
7. Devuelve el flash loan y se queda con la ganancia

**¿Por qué es posible?**

En `_swapTokenToUSDC()` línea 166-167:
```solidity
uint256[] memory amounts = uniswapRouter.getAmountsOut(amount, path);
uint256 minAmountOut = (amounts[amounts.length - 1] * (SLIPPAGE_DENOMINATOR - MAX_SLIPPAGE)) / SLIPPAGE_DENOMINATOR;
```

Este código asume que el precio de `getAmountsOut()` es confiable, pero ese precio puede estar manipulado en el mismo bloque.

**Impacto:**
- **Usuarios**: Reciben menos USDC del que deberían por sus depósitos
- **Protocolo**: Pierde valor porque acredita menos USDC del que realmente vale el token depositado

**Severidad: ALTA** (en mainnet con grandes volúmenes)

**Mitigaciones posibles:**

1. **Usar TWAP (Time-Weighted Average Price)**: Promediar el precio en múltiples bloques
2. **Integrar Chainlink**: Usar un oracle descentralizado como fuente de verdad
3. **Límites por transacción**: Rechazar depósitos muy grandes que puedan afectar el precio
4. **Verificación post-swap**: Comparar el precio obtenido con un oracle externo

**Nota importante:** Este ataque es más viable en mainnet donde hay liquidez para flash loans grandes. En testnets como Sepolia es menos probable pero técnicamente posible.

### Vector de Ataque #2: Front-Running de Depósitos

**Categoría:** Estrategias económicas/exploitativas

**Descripción:**

Las transacciones en Ethereum son públicas en el mempool antes de ser incluidas en un bloque. Un bot puede ver una transacción de depósito pendiente y ejecutar su propia transacción con mayor gas price para que se ejecute primero.

**Escenario de ataque:**

1. Usuario envía transacción: `depositToken(DAI, 10000)`
2. Bot MEV ve la transacción en el mempool
3. Bot ejecuta dos transacciones con mayor gas:
   - **Transacción 1 (front-run)**: Vende USDC por DAI en Uniswap, subiendo el precio de DAI
   - **Transacción original del usuario**: Se ejecuta con un precio peor de DAI
   - **Transacción 2 (back-run)**: Bot recompra USDC, obteniendo ganancia

**Código vulnerable:**

En `depositToken()` línea 80-100, no hay protección contra front-running. El slippage del 5% protege parcialmente pero no previene el ataque.

```solidity
function depositToken(address token, uint256 amount) external nonReentrant {
    // ... sin protección contra front-running
    usdcAmount = _swapTokenToUSDC(token, amount);
    // ...
}
```

**Impacto:**
- **Usuarios**: Reciben menos USDC que lo esperado (aunque dentro del slippage tolerado)
- **Atacante**: Obtiene ganancias libres de riesgo (MEV - Maximal Extractable Value)

**Severidad: MEDIA**

**Mitigaciones posibles:**

1. **Permitir que el usuario especifique minAmountOut**: En lugar de calcularlo automáticamente
```solidity
function depositToken(address token, uint256 amount, uint256 minUSDCOut) external
```

2. **Integrar Flashbots/MEV-Boost**: Permitir transacciones privadas que no pasan por el mempool público

3. **Límite de tiempo**: El usuario puede especificar un deadline más corto
```solidity
block.timestamp + 60 // Solo 60 segundos en lugar de 300
```

4. **Commit-Reveal Pattern**: Usuario hace commit de su intención en un bloque, y reveal en otro (más complejo)

### Vector de Ataque #3: Explotación del Bank Cap en Condiciones de Competencia

**Categoría:** Errores en la lógica de negocio del contrato

**Descripción:**

El check del bank cap ocurre DESPUÉS del swap, no antes. Esto significa que el contrato puede terminar con más USDC del esperado si múltiples transacciones se procesan cerca del límite.

**Código problemático:**

En `depositToken()` líneas 91-94:
```solidity
usdcAmount = _swapTokenToUSDC(token, amount); // Swap primero

if (totalDepositedUSDC + usdcAmount > bankCapUSDC) revert BankCapExceeded(); // Check después
```

**Escenario problemático:**

```
Estado inicial:
- bankCapUSDC = 1,000,000 USDC
- totalDepositedUSDC = 999,000 USDC
- Espacio disponible = 1,000 USDC

Dos transacciones en el mismo bloque:
- User A deposita tokens que darán ~600 USDC
- User B deposita tokens que darán ~600 USDC

Ambas transacciones ven que tienen espacio disponible (999,000 < 1,000,000)
Ambas ejecutan el swap
Cuando se hace el check, las dos ya tienen el USDC

Resultado:
- Total depositado = 999,000 + 600 + 600 = 1,000,200 USDC
- Se excedió el bank cap por 200 USDC
```

**¿Por qué no falla?**

Porque cada transacción ve el estado ANTES de que la otra se ejecute. Cuando llega el check, el swap ya ocurrió y el USDC ya está en el contrato.

**Impacto:**
- **Protocolo**: El bank cap no es un límite estricto, puede ser excedido
- **Propósito del cap**: Se pierde el control de riesgo que se buscaba

**Severidad: MEDIA-BAJA** (es más un problema de diseño que un exploit grave)

**Mitigaciones posibles:**

1. **Check antes del swap**:
```solidity
// Estimar el USDC que se recibirá
uint256 estimatedUSDC = _estimateSwapOutput(token, amount);
if (totalDepositedUSDC + estimatedUSDC > bankCapUSDC) revert BankCapExceeded();

// Luego hacer el swap
usdcAmount = _swapTokenToUSDC(token, amount);
```

2. **Reservar espacio**: Implementar un sistema de "slots" que se reservan antes del swap

3. **Aceptar el edge case**: Documentar que el cap es "aproximado" con un margen de error pequeño

### Vector de Ataque #4: Compromiso del Admin/Manager

**Categoría:** Problemas de permisos o de configuración de control de acceso

**Descripción:**

El `DEFAULT_ADMIN_ROLE` y `BANK_MANAGER_ROLE` son asignados a una sola dirección (el deployer) en el constructor. Si esa clave privada se compromete, un atacante tiene control total sobre el sistema.

**Código vulnerable:**

En `constructor()` líneas 57-58:
```solidity
_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
_grantRole(BANK_MANAGER_ROLE, msg.sender);
```

**Escenarios de compromiso:**

1. **Phishing**: El admin cae en un ataque de phishing y firma una transacción maliciosa
2. **Key exposure**: La clave privada se expone en código, logs, o backups no seguros
3. **Malware**: El dispositivo del admin es comprometido
4. **Inside job**: Un empleado malicioso con acceso a la clave

**Acciones maliciosas posibles:**

1. **Reducir bank cap a 0**: Efectivamente pausar el protocolo
```solidity
updateBankCap(0); // Nadie puede depositar más
```

2. **Aumentar bank cap a infinito**: Eliminar cualquier protección de riesgo
```solidity
updateBankCap(type(uint256).max); // Sin límites
```

3. **Otorgar roles a atacantes**:
```solidity
grantRole(BANK_MANAGER_ROLE, attackerAddress);
```

4. **Revocar roles de addresses legítimas**:
```solidity
revokeRole(BANK_MANAGER_ROLE, legitimateManager);
```

**Impacto:**
- **Usuarios**: No pueden depositar (si cap = 0) o están en riesgo (si cap = infinito)
- **Protocolo**: Pérdida de confianza, posible abandono masivo de usuarios
- **Reputación**: Daño irreparable

**Severidad: CRÍTICA**

**Mitigaciones implementadas:**

Actualmente: **NINGUNA**. El protocolo confía 100% en que el admin es seguro.

**Mitigaciones recomendadas:**

1. **Multisig Wallet** (Gnosis Safe):
```solidity
// Cambiar el admin a un multisig después del deployment
grantRole(DEFAULT_ADMIN_ROLE, gnosisSafeAddress);
revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
```

2. **Timelock para cambios críticos**:
```solidity
// Cambios de bank cap requieren espera de 24-48 horas
function updateBankCap(uint256 newCap) external onlyRole(BANK_MANAGER_ROLE) {
    require(block.timestamp >= proposedCapTimestamp + TIMELOCK_DURATION);
    bankCapUSDC = newCap;
}
```

3. **Límites en cambios**:
```solidity
// No permitir que el cap baje más del 50% o suba más del 200% de una vez
require(newCap >= bankCapUSDC / 2 && newCap <= bankCapUSDC * 2);
```

4. **Emergency Pause** (con múltiples firmantes):
```solidity
bool public paused;
function emergencyPause() external onlyRole(EMERGENCY_ROLE) {
    paused = true;
}
```

### Vector de Ataque #5: Slippage Abuse

**Categoría:** Uso indebido de supuestos del protocolo

**Descripción:**

El slippage fijo del 5% es generoso y puede ser explotado en ciertas condiciones. Un usuario malicioso puede depositar tokens en momentos de alta volatilidad sabiendo que el protocolo aceptará hasta 5% de pérdida.

**Código relevante:**

Líneas 34-35:
```solidity
uint256 public constant MAX_SLIPPAGE = 500; // 5%
uint256 public constant SLIPPAGE_DENOMINATOR = 10000;
```

**Escenario de explotación:**

1. Mercado está volátil, precio de ETH oscila rápidamente
2. Usuario espera a que el precio de ETH esté "alto" en Uniswap
3. Deposita ETH justo antes de que el precio caiga
4. El swap se ejecuta con el precio alto, pero acepta hasta 5% menos
5. Usuario obtuvo más USDC del que debería en condiciones normales

**Problema inverso:**

En mercados estables (ej: DAI ↔ USDC), un 5% de slippage es excesivo:
- El precio real DAI/USDC fluctúa ~0.001%
- Permitir 5% significa que un atacante podría manipular el pool significativamente y aún así el swap pasaría

**Impacto:**
- **Protocolo**: Acepta swaps subóptimos
- **Usuarios**: No tienen control sobre su propia tolerancia al slippage

**Severidad: MEDIA-BAJA**

**Mitigaciones recomendadas:**

1. **Slippage dinámico** basado en el par:
```solidity
mapping(address => uint256) public tokenSlippageLimit;

// Stablecoins: 0.5%
tokenSlippageLimit[DAI] = 50;
// Volatile assets: 5%
tokenSlippageLimit[WETH] = 500;
```

2. **Permitir que el usuario especifique**:
```solidity
function depositToken(
    address token,
    uint256 amount,
    uint256 maxSlippageBps // basis points
) external
```

---

## 4. Recomendaciones de Testing y Validación

### 4.1 Tests Faltantes Críticos

#### A. Fuzz Testing

**¿Qué es?** Ejecutar las funciones con miles de inputs aleatorios para encontrar edge cases.

**Tests recomendados:**

```solidity
// Test 1: Fuzz deposit amounts
function testFuzz_DepositToken(uint256 amount) public {
    // Asumir rangos razonables
    vm.assume(amount > 1000 && amount < 1000000 * 10**18);
    vm.assume(amount < BANK_CAP);

    vm.startPrank(user1);
    dai.mint(user1, amount);
    dai.approve(address(bank), amount);

    uint256 balanceBefore = bank.balanceOf(user1);
    bank.depositToken(address(dai), amount);
    uint256 balanceAfter = bank.balanceOf(user1);

    // Verificar que el balance siempre aumenta
    assertGt(balanceAfter, balanceBefore);
    vm.stopPrank();
}

// Test 2: Fuzz multiple users depositing
function testFuzz_MultipleDeposits(
    uint256 amount1,
    uint256 amount2,
    uint256 amount3
) public {
    // Múltiples usuarios con múltiples cantidades aleatorias
    // Verificar que los balances se mantienen correctos
}

// Test 3: Fuzz withdraw amounts
function testFuzz_Withdraw(uint256 depositAmount, uint256 withdrawAmount) public {
    vm.assume(depositAmount > 0 && depositAmount < BANK_CAP);
    vm.assume(withdrawAmount > 0 && withdrawAmount <= depositAmount);

    // Depositar cantidad random
    // Retirar cantidad random (menor o igual)
    // Verificar que nunca se puede retirar más de lo depositado
}
```

**Por qué es importante:** Los fuzz tests pueden encontrar combinaciones de inputs que los humanos no consideraríamos, como números muy grandes, muy pequeños, o en límites específicos.

#### B. Invariant Testing

**¿Qué son los invariantes?** Propiedades matemáticas que SIEMPRE deben ser verdaderas, sin importar qué acciones se ejecuten.

**Invariantes de KipuBankV3:**

```solidity
// Invariante 1: La suma de todos los balances debe ser igual al total depositado
function invariant_SumOfBalancesEqualsTotal() public {
    uint256 sumOfBalances = 0;
    for (uint256 i = 0; i < users.length; i++) {
        sumOfBalances += bank.balanceOf(users[i]);
    }
    assertEq(sumOfBalances, bank.totalDepositedUSDC());
}

// Invariante 2: El total depositado nunca debe exceder el bank cap
function invariant_TotalNeverExceedsCap() public {
    assertLe(bank.totalDepositedUSDC(), bank.bankCapUSDC());
}

// Invariante 3: El balance de USDC del contrato debe ser >= total depositado
function invariant_ContractHasEnoughUSDC() public {
    assertGe(
        IERC20(USDC).balanceOf(address(bank)),
        bank.totalDepositedUSDC()
    );
}

// Invariante 4: Ningún usuario puede tener balance negativo
function invariant_NoNegativeBalances() public {
    for (uint256 i = 0; i < users.length; i++) {
        assertGe(bank.balanceOf(users[i]), 0);
    }
}
```

**Configuración de invariant testing en Foundry:**

```solidity
// En el test file
contract KipuBankInvariantTest is Test {
    KipuBankV3 public bank;
    Handler public handler;

    function setUp() public {
        // Setup del contrato
        handler = new Handler(bank);

        // Decirle a Foundry qué funciones llamar
        targetContract(address(handler));
    }
}

// Handler que ejecuta acciones aleatorias
contract Handler {
    KipuBankV3 public bank;
    address[] public users;

    function depositRandom(uint256 userIndex, uint256 amount) public {
        // Depósito aleatorio
    }

    function withdrawRandom(uint256 userIndex, uint256 amount) public {
        // Retiro aleatorio
    }
}
```

#### C. Fork Testing

**¿Qué es?** Ejecutar tests contra el estado real de una blockchain (mainnet o testnet).

**Setup:**

```bash
# En foundry.toml
[rpc_endpoints]
sepolia = "${SEPOLIA_RPC_URL}"

# Correr tests
forge test --fork-url sepolia --match-contract ForkTest
```

**Tests recomendados:**

```solidity
contract KipuBankForkTest is Test {
    KipuBankV3 public bank;

    // Direcciones reales de Sepolia
    address constant UNISWAP_ROUTER = 0x...; // Router real
    address constant USDC = 0x...;           // USDC real

    function setUp() public {
        // Usar contratos reales
        bank = new KipuBankV3(UNISWAP_ROUTER, USDC, 1000000e6);
    }

    function testFork_RealUniswapSwap() public {
        // Test con Uniswap real, no mocks
        // Verificar que los swaps funcionen con liquidez real
    }

    function testFork_ActualSlippage() public {
        // Verificar el slippage real en mercado real
    }
}
```

**Por qué es importante:** Los mocks no capturan el comportamiento real de Uniswap. Fork tests validan que todo funciona en el mundo real.

### 4.2 Escenarios de Prueba Adicionales

**Test de estrés:**
```solidity
function test_MaxBankCapDeposit() public {
    // Intentar depositar exactamente el bank cap
    // Verificar que funciona

    // Intentar depositar bank cap + 1
    // Verificar que falla
}

function test_ManySmallDeposits() public {
    // 100 usuarios depositando cantidades pequeñas
    // Verificar que el gas no explota
    // Verificar que los balances son correctos
}
```

**Test de seguridad:**
```solidity
function test_CannotWithdrawOthersBalance() public {
    // Usuario A deposita
    // Usuario B intenta retirar el balance de A
    // Debe fallar
}

function test_CannotUpdateCapWithoutRole() public {
    // Usuario sin BANK_MANAGER_ROLE intenta cambiar el cap
    // Debe revertir con AccessControl error
}
```

**Test de integración:**
```solidity
function test_FullCycle() public {
    // 1. Depositar ETH
    // 2. Verificar balance
    // 3. Depositar tokens
    // 4. Verificar balance acumulado
    // 5. Retirar parcialmente
    // 6. Verificar balance restante
    // 7. Retirar todo
    // 8. Verificar balance = 0
}
```

### 4.3 Herramientas Recomendadas

1. **Slither** (análisis estático):
```bash
pip install slither-analyzer
slither . --detect all
```

2. **Echidna** (fuzzing avanzado):
```bash
# Instalar echidna
# Escribir properties en Solidity
# Correr fuzzing por horas/días
echidna . --contract KipuBankV3 --config echidna.yaml
```

3. **Mythril** (análisis simbólico):
```bash
pip install mythril
myth analyze src/KipuBankV3.sol
```

4. **Foundry Coverage**:
```bash
forge coverage
# Buscar funciones con <80% de cobertura
```

---

## 5. Conclusión y Próximos Pasos para Auditoría

### 5.1 Estado Actual de Madurez

**Calificación general: 6.5/10**

**Fortalezas:**
- ✅ Código limpio y bien estructurado
- ✅ Documentación extensa
- ✅ Tests básicos funcionando
- ✅ Uso de librerías auditadas (OpenZeppelin)
- ✅ Deployment exitoso en testnet

**Debilidades:**
- ⚠️ Falta cobertura de tests avanzados (fuzz, invariant, fork)
- ⚠️ Sin protección contra manipulación de oracle
- ⚠️ Roles centralizados sin multisig
- ⚠️ Sin mecanismo de pausa de emergencia
- ⚠️ No auditado por firma profesional

### 5.2 Checklist Pre-Auditoría

**Antes de contratar una auditoría, completar:**

- [ ] Ejecutar `forge coverage` y alcanzar >80% de cobertura
- [ ] Implementar fuzz tests para funciones principales
- [ ] Implementar invariant tests para propiedades críticas
- [ ] Agregar fork tests con Uniswap real
- [ ] Ejecutar Slither y resolver hallazgos de severidad alta/media
- [ ] Transferir roles a multisig (mínimo 3/5)
- [ ] Implementar timelock para cambios de bank cap
- [ ] Documentar decision log (por qué se tomaron ciertas decisiones de diseño)
- [ ] Crear runbook de emergencia
- [ ] Definir plan de response para hallazgos de auditoría

### 5.3 Recomendaciones por Prioridad

#### Prioridad CRÍTICA (hacer antes de mainnet):

1. **Migrar admin a multisig**
   - Usar Gnosis Safe con 3-5 firmantes
   - Nunca tener una sola EOA con control total

2. **Agregar protección de oracle**
   - Integrar Chainlink para precios
   - O implementar verificación TWAP de Uniswap V3

3. **Auditoría profesional**
   - Contratar firma reconocida (OpenZeppelin, Trail of Bits, etc.)
   - Presupuesto: $15k-$40k USD dependiendo de scope

4. **Mecanismo de pausa**
   - Agregar función `pause()` y `unpause()`
   - Modificador `whenNotPaused` en funciones críticas

#### Prioridad ALTA (hacer en las próximas semanas):

5. **Tests avanzados**
   - Implementar fuzz testing suite
   - Implementar invariant testing suite
   - Fork tests contra Sepolia

6. **Límites en cambios de bank cap**
   - No permitir cambios drásticos (>50% de una vez)
   - Requiere tiempo de espera (timelock)

7. **Validación del bank cap antes del swap**
   - Estimar el output esperado
   - Verificar bank cap antes de ejecutar el swap

8. **Bug bounty program**
   - Publicar en Immunefi o Code4rena
   - Recompensas proporcionales a severidad

#### Prioridad MEDIA (mejoras futuras):

9. **Slippage configurable por usuario**
   - Permitir que cada usuario especifique su tolerancia

10. **Upgrade a Uniswap V3**
    - Mejor eficiencia de capital
    - TWAP integrado

11. **Eventos más descriptivos**
    - Agregar más información en eventos
    - Facilitar monitoring y analytics

12. **Optimizaciones de gas**
    - Revisar uso de `unchecked` donde sea seguro
    - Batch operations para múltiples acciones

### 5.4 Roadmap Recomendado

**Semana 1-2:**
- [ ] Completar suite de tests (fuzz + invariant + fork)
- [ ] Ejecutar herramientas de análisis estático (Slither, Mythril)
- [ ] Resolver todos los issues encontrados

**Semana 3-4:**
- [ ] Deploy a testnet con multisig como admin
- [ ] Testing extensivo con usuarios reales en testnet
- [ ] Recolectar feedback y ajustar parámetros

**Semana 5-6:**
- [ ] Preparar documentación para auditores
- [ ] Contratar firma de auditoría
- [ ] Auditoría en progreso (2-4 semanas típicamente)

**Semana 7-8:**
- [ ] Recibir reporte de auditoría
- [ ] Implementar fixes para hallazgos
- [ ] Re-test todas las modificaciones

**Semana 9:**
- [ ] Segundo review de auditoría (si es necesario)
- [ ] Publicar reporte de auditoría
- [ ] Preparar deployment a mainnet

**Semana 10:**
- [ ] Deploy a mainnet
- [ ] Verificar contrato en Etherscan
- [ ] Anuncio público y lanzamiento

### 5.5 Métricas de Éxito

**Antes de considerar el protocolo "listo para producción":**

- ✅ Cobertura de tests >85%
- ✅ 0 hallazgos críticos en auditoría
- ✅ Todos los hallazgos altos resueltos
- ✅ Multisig configurado y testeado
- ✅ Documentación completa y actualizada
- ✅ Bug bounty program activo
- ✅ Plan de response de emergencia documentado
- ✅ Monitoring y alertas configurados
- ✅ Team capaz de responder 24/7

### 5.6 Consideraciones Finales

**Filosofía DevSecOps:**

Este análisis refleja el enfoque DevSecOps que se enseñó durante todo el bootcamp: la seguridad no es algo que se agrega al final, sino que debe estar integrada desde el diseño hasta el deployment y más allá.

**Mentalidad correcta:**

Un protocolo nunca está "100% seguro". Lo que buscamos es:
1. Minimizar la superficie de ataque
2. Tener mecanismos de respuesta ante incidentes
3. Transparencia con los usuarios sobre riesgos
4. Mejora continua basada en feedback y nuevos hallazgos

**Siguiente paso inmediato:**

El siguiente paso más valioso es implementar los tests avanzados (fuzz e invariant). Estos pueden descubrir bugs que ningún humano encontraría revisando el código manualmente.

---

## Anexo: Glosario de Términos

**Flash Loan:** Préstamo que se pide y devuelve en la misma transacción, sin colateral.

**Front-running:** Ejecutar una transacción antes que otra al ver su contenido en el mempool.

**MEV (Maximal Extractable Value):** Ganancia que se puede extraer reordenando, incluyendo o excluyendo transacciones.

**Slippage:** Diferencia entre el precio esperado y el precio real de ejecución de un swap.

**TWAP (Time-Weighted Average Price):** Precio promedio ponderado en el tiempo, más difícil de manipular.

**Invariante:** Propiedad matemática que siempre debe ser verdadera.

**Fuzz testing:** Testing con inputs aleatorios para encontrar edge cases.

**Multisig:** Wallet que requiere múltiples firmas para ejecutar transacciones.

**Timelock:** Delay obligatorio entre proponer y ejecutar un cambio.

---

**Fin del Informe**

Este análisis fue realizado como parte del Trabajo Final del Módulo 5 del Ethereum Developer Pack, demostrando comprensión de:
- Análisis de seguridad de protocolos DeFi
- Identificación de vectores de ataque
- Evaluación de madurez de código
- Recomendaciones prácticas para auditoría
- Mentalidad DevSecOps aplicada a Web3

**Preparado por:** Daniela Silvana Tochi
**Fecha:** 14 de Noviembre, 2025
