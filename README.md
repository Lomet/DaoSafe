# MultiLockSafe

## Overview
MultiLockSafe is a decentralized and self-custodial smart contract designed for secure token storage and retrieval. It uses a multi-signature mechanism where multiple lockers approve withdrawals, ensuring enhanced security. The system supports modular locker participation, allowing external services to integrate and act as lockers.

## Features
- **Secure token deposits and withdrawals**
- **Multi-locker authorization system**
- **Configurable fees** ({BuyFee} and {UpKeepFee})
- **Supports external locker integrations**
- **Password-based security mechanism**

---

## Fees
MultiLockSafe operates with two types of fees:

1. **{BuyFee}**: This is the fee required to open a new safe. It ensures commitment from users and helps maintain the ecosystem.
2. **{UpKeepFee}**: A fee required for each withdrawal to prevent abuse and ensure the security and operational sustainability of the smart contract.

These fees are configurable and subject to governance decisions.

---

## Lockers
A **Locker** is an entity that participates in the authorization process for withdrawals. To withdraw tokens, the safe owner must obtain signatures from a set of lockers. This ensures additional security and mitigates risks related to compromised private keys.

- **Backend as a Locker**: Users can assign a backend system to act as a locker, allowing for automated security checks and approvals.
- **Third-Party Locker Integration**: Developers and service providers can offer their backends as lockers, enabling third-party applications to integrate with MultiLockSafe and provide enhanced security services.

This flexible architecture allows external services to build on top of MultiLockSafe, expanding its use cases and security model.

---

## Password-Based Security
MultiLockSafe enhances security with a **hashedPassword mechanism**:
- When opening a safe, users provide `hashedPassword = sign(sign(password))`.
- To withdraw, they must provide `sign(password)`, which the contract verifies.
- This ensures that only someone who knows the password can withdraw, even if the private key is compromised.

---

## Security Benefits & Use Cases
MultiLockSafe provides strong security guarantees against various attacks:

### 1. **Seed Phrase Exposure Protection**
If a user's seed phrase (private key) is leaked, an attacker **cannot immediately withdraw** the assets stored in the safe. The original owner can:
- Use `sign(password)` to withdraw assets to a new, secure contract or wallet.
- Block the attacker's access by updating the lockers.

### 2. **Prevention of Malicious Approve Attack**
A common attack in DeFi is when users unknowingly approve malicious contracts to transfer their funds. With MultiLockSafe:
- Tokens are stored inside the safe and **cannot be transferred using an external approve call**.
- Even if a malicious dApp tricks a user into approving a transfer, the attacker cannot withdraw from the safe without locker authorization.

### 3. **Multi-Party Custody & Recovery**
- A user can assign multiple lockers (e.g., family members, DAOs, or security services) to approve transactions.
- If the user loses access to their primary wallet, they can recover funds using pre-approved lockers.

---

## How It Works
1. **Opening a Safe**: The user pays the {BuyFee}, specifies locker addresses, and provides `hashedPassword`.
2. **Depositing Tokens**: The user deposits tokens into their safe.
3. **Withdrawing Tokens**: The user submits a withdrawal request with:
   - `sign(password)`
   - Locker approvals
   - {UpKeepFee}
4. **Swapping Lockers**: Users can update their lockers by providing authorization signatures.

---

## Developer Integration
- **Third-party developers** can register their services as lockers.
- **Backend implementations** can act as automated security validators.
- **Governance mechanisms** can be added to adjust fees and security parameters dynamically.

For additional integration details, check the contract implementation in `SafeCore.sol` and `SafeOperations.sol`.

