# ⛓️ VehicleChain — Blockchain Vehicle Registry DApp

> A decentralized application (DApp) that mints each registered vehicle as an ERC-721 token and records ownership transfers on Ethereum.

---

## 📁 Project Structure

```
Vehicle-Registry-DApp/
├── contracts/
│   └── VehicleRegistry.sol     ← Solidity smart contract
├── frontend/
│   ├── index.html              ← Active DApp UI, styles, and Web3.js logic
│   ├── app.js                  ← Legacy frontend script (not loaded by index.html)
│   └── style.css               ← Legacy stylesheet (index.html uses inline styles)
└── README.md
```

---

## 🚀 Deployment & Setup

### Step 1 — Open Remix IDE
Go to [remix.ethereum.org](https://remix.ethereum.org)

### Step 2 — Compile the Smart Contract
1. Create a new file: `VehicleRegistry.sol`
2. Paste the code from `contracts/VehicleRegistry.sol`
3. Go to **Solidity Compiler** tab
4. Select compiler version **0.8.19** (or any 0.8.x)
5. Click **Compile VehicleRegistry.sol**

### Step 3 — Deploy to Sepolia Testnet
1. Switch MetaMask to **Sepolia Testnet**
2. Get test ETH from [sepoliafaucet.com](https://sepoliafaucet.com)
3. In Remix → **Deploy & Run Transactions** tab
4. Environment: **Injected Provider - MetaMask**
5. Click **Deploy** and confirm in MetaMask
6. Copy the deployed **contract address**. This version must be freshly deployed; an earlier VehicleRegistry deployment does not support ERC-721 tokens or ETH sales.

### Step 4 — Configure the Frontend
Open `frontend/index.html` and replace the zero address in the inline configuration near the bottom:
```javascript
const CONTRACT_ADDRESS = "0xYOUR_DEPLOYED_CONTRACT_ADDRESS_HERE";
```

### Step 5 — Launch the DApp
Open `frontend/index.html` in your browser (or use Live Server in VS Code).

---

## 📋 Smart Contract: VehicleRegistry.sol

| Feature | Description |
|---------|-------------|
| **Register Vehicle** | Admin-only. Creates an immutable record and mints one ERC-721 token |
| **Transfer Ownership** | Owner-only. Transfers the token and appends the recipient to history |
| **ETH Sale Listing** | Owner sets a fixed price in ETH or removes the listing with 0 |
| **Buy Vehicle** | Buyer pays the exact listed ETH amount; payment and token transfer are atomic |
| **Query Details** | Public read. Returns model, year, token ID, owner, date, listing price, and history |
| **Ownership History** | Public read. Returns all previous owners |
| **Events** | `VehicleRegistered` & `OwnershipTransferred` emitted |

### Key Modifiers
- `onlyAdmin` — restricts to contract deployer
- `onlyOwner(vehicleId)` — restricts to current vehicle owner  
- `vehicleExists(vehicleId)` — ensures vehicle is registered

---

## 🌐 Frontend Features

| Feature | Description |
|---------|-------------|
| MetaMask Connect | One-click wallet connection with auto-detect |
| Sepolia Auto-Switch | Automatically prompts to switch network |
| Register Form | Admin form to register new vehicles |
| Transfer Form | Owner form to transfer the token or list/remove an ETH sale |
| Vehicle Tokens | ERC-721 token IDs minted at registration and shown in the fleet/details |
| ETH Purchases | MetaMask confirms exact-value payments directly to the seller |
| Query Panel | Search any vehicle + full history table |
| Event Log | Live feed of blockchain events |
| Toast Notifications | Real-time tx success/error feedback |
| Etherscan Links | Direct links to transactions and addresses |

---

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| Smart Contract | Solidity 0.8.x |
| Blockchain | Ethereum (Sepolia Testnet) |
| Wallet | MetaMask |
| Frontend | HTML5 + Vanilla CSS + JavaScript |
| Web3 Library | Web3.js v4.3.0 |
| IDE | Remix IDE |

---

## 🧪 Testing in Remix (Without Frontend)

After deployment, in Remix's **Deployed Contracts** panel you can:
1. Call `registerVehicle("MH12AB1234", "Toyota Camry", 2024, <your-address>)`
2. Call `transferOwnership("MH12AB1234", <new-address>)` for a free owner-authorized transfer
3. Call `getVehicleDetails("MH12AB1234")` — read vehicle info
4. Call `getOwnershipHistory("MH12AB1234")` — read full history
5. Call `setVehiclePrice("MH12AB1234", <price-in-wei>)`, then `buyVehicle("MH12AB1234")` with the exact amount in Remix's **Value** field

---

## ⚠️ Notes

- Admin address is set at deployment (the deployer's wallet address)
- Only admin can register; only the current ERC-721 owner can transfer or list a vehicle
- Free transfers cancel an existing sale listing; purchases transfer the listed ETH to the seller and update ownership in one transaction
- Wallet addresses and transactions are public on Ethereum. Personal names or contact details are not stored on-chain.
- Registration and ownership history are permanent on-chain; active sale listings can be changed or removed by the current owner
- Use Sepolia testnet (free test ETH via faucet)

---

*Built for Blockchain Mini Project — Vehicle Registration & Ownership Transfer System*
