LeaseLock

A decentralized lease agreement and security deposit escrow smart contract built in **Clarity** for the **Stacks blockchain**.

---

 Overview

**LeaseLock** is a smart contract designed to securely manage rental lease agreements and security deposits on-chain. It enables landlords and tenants to create transparent, tamper-proof rental agreements where security deposits are locked in a smart contract until the lease conditions are satisfied.

By removing reliance on traditional escrow services, LeaseLock ensures that funds remain secure and can only be released according to predefined conditions. This provides both parties with trustless enforcement and verifiable proof of agreement.

LeaseLock introduces an automated and transparent infrastructure for managing rental deposits within the Stacks ecosystem.

---

 Problem Statement

Traditional rental agreements and deposit systems often suffer from:

- Disputes over deposit refunds
- Lack of transparency in agreement terms
- Dependence on centralized escrow services
- Delays in deposit return after lease completion
- Limited proof of contract terms

LeaseLock addresses these issues by:

- Locking deposits securely on-chain
- Enforcing lease terms programmatically
- Providing transparent agreement records
- Enabling deterministic fund release conditions
- Reducing the need for intermediaries

---

 Architecture

 Built With

- **Language:** Clarity  
- **Blockchain:** Stacks  
- **Framework:** Clarinet  

 Lease Model

Each lease agreement contains:

- Lease ID
- Landlord address
- Tenant address
- Security deposit amount
- Lease start timestamp
- Lease end timestamp
- Lease status
- Deposit release conditions

---

 Roles

1. Landlord

Responsible for creating lease agreements.

Capabilities:
- Create lease agreements
- Define deposit amount
- Confirm lease completion
- Trigger deposit settlement

---

2. Tenant

Participant who rents the property.

Capabilities:
- Deposit security funds
- Accept lease terms
- Retrieve deposit upon lease completion

---
3. Observers / Verifiers

Any blockchain user can verify:

- Lease agreement existence
- Lease duration
- Deposit amount
- Settlement status

---

 Lease Lifecycle

1. Landlord creates a lease agreement.
2. Tenant deposits security funds into the contract.
3. Lease enters active state.
4. Deposit remains locked for the lease duration.
5. At lease expiration:
   - Deposit is released according to settlement rules.
6. Lease status updates to completed.

---

 Core Features

- On-chain lease agreement registration  
- Time-locked security deposit escrow  
- Deterministic lease expiration logic  
- Conditional fund release mechanisms  
- Transparent lease verification  
- Landlord and tenant role enforcement  
- Immutable lease records  
- Clarinet-compatible contract architecture  

---

 Security Design Principles

- Deterministic deposit release conditions
- Explicit role-based permissions
- Immutable lease record storage
- Transparent escrow management
- Minimal and auditable contract logic

---

License

MIT License

---
 Development & Testing

1. Install Clarinet

Follow the official Stacks documentation to install **Clarinet**.

2. Initialize Project

```bash
clarinet new lease-lock
