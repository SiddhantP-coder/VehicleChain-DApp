# ⛓️ VehicleChain — Blockchain Vehicle Registry DApp

> A decentralized application (DApp) for secure vehicle registration and transparent ownership transfer using Ethereum smart contracts.

---

## 📁 Project Structure

```
Vehicle-Registry-DApp/
├── contracts/
│   └── VehicleRegistry.sol     ← Solidity smart contract
├── frontend/
│   ├── index.html              ← Main DApp UI
│   ├── app.js                  ← Web3.js logic + contract calls
│   └── style.css               ← Premium dark glassmorphism styles
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
6. Copy the deployed **contract address**

### Step 4 — Configure the Frontend
Open `frontend/app.js` and update line 13:
```javascript
const CONTRACT_ADDRESS = "0xYOUR_DEPLOYED_CONTRACT_ADDRESS_HERE";
```

### Step 5 — Launch the DApp
Open `frontend/index.html` in your browser (or use Live Server in VS Code).

---

## 📋 Smart Contract: VehicleRegistry.sol

| Feature | Description |
|---------|-------------|
| **Register Vehicle** | Admin-only. Creates immutable record on-chain |
| **Transfer Ownership** | Owner-only. Updates current owner, appends to history |
| **Query Details** | Public read. Returns model, year, owner, date |
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
| Transfer Form | Owner form to transfer to new address |
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
2. Call `transferOwnership("MH12AB1234", <new-address>)`
3. Call `getVehicleDetails("MH12AB1234")` — read vehicle info
4. Call `getOwnershipHistory("MH12AB1234")` — read full history

---

## ⚠️ Notes

- Admin address is set at deployment (the deployer's wallet address)
- Only admin can register; only current owner can transfer
- All records are permanent and immutable on-chain
- Use Sepolia testnet (free test ETH via faucet)

---

*Built for Blockchain Mini Project — Vehicle Registration & Ownership Transfer System*
