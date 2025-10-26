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
If an exploit happens, redeploying and re-approving a new `Guard` can take hours — time that attackers don’t need.  

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
