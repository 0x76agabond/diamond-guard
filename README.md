# Diamond as Gnosis Safe Guard (Diamond Guard)

`Gnosis Safe Guard` built on top of the `Diamond Standard (EIP-2535)`.

---

## Abstract

`Diamond Guard` is a `Safe Smart Account Guard` implemented as a `Facet` within the `Diamond Standard architecture`.  

The goal is to create a `Safe Guard` that is not only secure but also **upgradable and adaptive** — capable of evolving alongside modern exploit patterns.  
Ultimately, it may become a **firewall-like layer** for smart accounts, receiving **security patches just like Windows updates**.  

---

## Motivation

I once researched semi-custodial wallet solutions and soon realized that `Gnosis Safe` was a very strong contender.  

It’s:
- **Cheaper** than traditional multisig setups.  
- **More secure** against internal threats than MPC solutions.  
- Practically **unhackable by pure technology alone** (if implemented correctly).  

However, on **February 21, 2025**, the **Bybit hack** happened — and it shattered that assumption.  
The exploit occurred in a way I never imagined possible.  

That incident made me realize something crucial:  
**Security should be `dynamic`, not `static`.**

In the current `Safe` model, once a `Guard` is deployed, **you need multisig approval to remove or replace it**, which slows down incident response.  
If an exploit happens, redeploying and re-approving a new `Guard` can take hours — time that attackers already have.

With **`Diamond Guard`**, the `Guard` itself becomes **modular and upgradeable**.  
You can patch, extend, or modify its logic **on the fly**, without replacing the entire `Guard` contract or going through a new multisig approval cycle.  

This architecture enables **fast reaction** to new vulnerabilities, turning the `Guard` into a **continuously-evolving firewall** for your `Safe`.

---

## Architecture
![Architecture](https://drive.usercontent.google.com/download?id=1W7YuP_fMvzMu8hiyhnUNGo4wUjXWJel1&export=view&authuser=0)

I built this template based on the `Diamond Standard`, `Separation of Concerns`, and `Domain-Driven Design (DDD) principles`.

Each **business domain** has **3 contracts**:
- `Implement Facet` – Implements **business logic** of the specific domain, using state from the `Library`.  

- `Library` – Defines **const**, **struct**, **internal function** and implements **ERC-8042** to manage the **identifier** of the business domain.  

- `Setting Facet` – Implements **CRUD operations** to manage the **state of the Library**.  
  This `Facet` works as a **gateway** to communicate with **off-chain components**.

👉 With this setup, your codebase **explains itself** — each part is clearly defined yet **interlocks with others like LEGO bricks**, forming a cohesive and understandable architecture.

---

## Benefits

- **Flexible security model**  
  Easily adapts to different operational needs — from static `Safe Guards` to dynamic, upgradable defense layers.

- **Supports sophisticated protection logic**  
  No more 24 KB contract size limit; complex security rules, risk scoring, or modular verifications can all fit inside the `Guard Facet`.

- **No “Safe-bricked” nightmare**  
  If a `Guard` becomes corrupted or misconfigured, simply detach it and plug in another `Guard` — no redeployment or migration of the entire `Safe` required.

---

## Consideration

- Yes, the `Safe team` decided **not to implement Safe v2 using the Diamond Standard** to maintain consistency across all proxy implementations.  
  However, since **`Diamond Guard`** is a `Safe Guard`, not the `Safe` itself, **I don’t think I’m a heretic** — this design simply extends the ecosystem without altering the `Safe` core.

- This implementation **could be abused by the `Guard` owner** to manipulate the `Safe`.  
  To mitigate this risk, it should be implemented with an additional **governance layer** — for example, an **ERC-2767 governance contract** or **another Safe Proxy** to work as owner that take responsible for managing `Guard` authorization and upgrades.

---

Guard Settings Overview
------------------------------------------------------------
| Variable                     | Type    | Description |
|-------------------------------|---------|--------------|
| `isLocked`                    | bool    | Completely locks the Safe — all transactions are blocked regardless of other settings. |
| `isModuleLocked`              | bool    | Blocks any transaction executed through a module, regardless of configuration. |
| `isActivated`                 | bool    | Enables or disables Guard checks for standard (non-module) transactions. |
| `isModuleCheckActivated`      | bool    | Enables or disables Guard checks for module-based transactions. |
| `isWhitelistEnabled`          | bool    | Requires every transaction target (`to`) address to be explicitly whitelisted before execution. |
| `isEnforceExecutor`           | bool    | Enforces that the designated executor must have signed the transaction. |
| `isDelegateCallAllowed`       | bool    | Allows or blocks `DELEGATECALL` operations for standard transactions. |
| `isModuleDelegateCallAllowed` | bool    | Allows or blocks `DELEGATECALL` operations for module-based transactions. |
------------------------------------------------------------
## Idea

- Each flag operates independently but can stack in effect.  
- `isLocked` overrides all others (global block).  
- `isWhitelistEnabled` and `isEnforceExecutor` act as conditional checks layered on top of normal verification flow.  
---
## Note
- This is a **PoC** for architecture showcase.
  **You may need to refine** it before using it in production.
  See the **top comment** in `src/guardFacet/implementFacet/GuardFacet.sol` for details.

- To enable the **Diamond** to operate as a full **Safe Guard**, you must **cut in both**  
  `GuardFacet` **and** `GuardSettingFacet`.  
  Omitting either facet will disable critical **Guard functionality**.

- Ensure that **all four Guard entry functions** are implemented inside `GuardFacet`:  
  `checkTransaction`, `checkAfterExecution`, `checkModuleTransaction`, and `checkAfterModuleExecution`.  
  Missing any of these may cause the **Safe** to become **unstable** or **bricked** depending on which hook is absent.

- This project relies on shared **helper modules** from other repositories.

- **`tContract`**  
  Source: [**diamond-testing-framework**](https://github.com/0x76agabond/diamond-testing-framework)  
  Purpose: Provides the **Diamond Testing OOP framework** (`tPrototype`, `tFacet`, and `CutUtil`)  
  used for **modular facet deployment** and **simulation** in tests.

- **`NotSafe`**  
  Source: [**mock-safe**](https://github.com/0x76agabond/mock-safe)  
  Purpose: A **lightweight Gnosis Safe mock** used to **simulate Safe transactions**  
  and **verify Guard behavior** under controlled **test environments**.
---
## Requirements
- Foundry 
- Solidity 
- foundry.toml with `rpc_endpoints`
---
## Getting Started
1. Clone repo  
2. Run `forge install` (if needed)  
3. Add `rpc_endpoints`
4. forge build 
5. forge test TestSafeWithGuard.t -vvv
---
## Example
``` solidity

// ===================================
// Init 
// ===================================
{
  

    // Create mock token
    BEP20Token token = new BEP20Token();

    DiamondCutFacet cutFacet = new DiamondCutFacet();
    diamond = new Diamond(address(ks.addrs[4]), address(cutFacet));
    // Attach loupe facet for introspection
    CutUtil.cutHelper(diamond, new tDiamondLoupe(), "");
    // Attach GuardFacet
    CutUtil.cutHelper(diamond, new tGuardFacet(), "");
    // Attach GuardSettingFacet and run init()
    CutUtil.cutHelper(
        diamond, new tGuardSettingFacet(), abi.encodeWithSelector(IGuardSettingFacet.init.selector)
    );
}

// ===================================
// Enable whitelist requirement
// ===================================
{
  IGuardSettingFacet setting = IGuardSettingFacet(address(diamond));
  setting.setWhitelistEnabled(true);
  setting.setWhitelist(address(safeWallet), address(token), true);

  // Register Diamond as Safe Guard
  safeWallet.setGuard(address(diamond));
}

// ===================================
// Build multisig transaction and Execute
// ===================================
{
  // Generate Safe transaction and valid signatures
  vm.startPrank(ks.addrs[0]);
  bytes32 txHash = Transaction.getTransactionHash(
      address(safeWallet),
      address(token),
      0,
      abi.encodeWithSelector(token.transfer.selector, ks.addrs[4], 1e18),
      Enum.Operation.Call,
      0,
      0,
      0,
      address(0),
      address(0),
      safeWallet.nonce()
  );

  bytes memory sig1 = generateSignature(txHash, ks.keys[1]);
  bytes memory sig2 = generateSignature(txHash, ks.keys[2]);
  bytes memory sigs = bytes.concat(sig1, sig2);

  // Execute Safe transaction and expect success
  try safeWallet.execTransaction(
      address(token),
      0,
      abi.encodeWithSelector(token.transfer.selector, ks.addrs[4], 1e18),
      Enum.Operation.Call,
      0,
      0,
      0,
      address(0),
      payable(address(0)),
      sigs
  ) returns (bool success) {
      console.log("Transaction success as expected:", success);
  } catch Error(string memory reason) {
      console.log("Transaction failed:", reason);
  }
}
        
```