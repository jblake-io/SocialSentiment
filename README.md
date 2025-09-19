# SocialSentiment

A sophisticated synthetic assets smart contract built on the Stacks blockchain that tracks social media sentiment and creates market-responsive synthetic assets based on sentiment data.

## 🎯 Overview

SocialSentiment enables the creation and management of synthetic assets whose value fluctuates based on aggregated social media sentiment scores. The contract provides a decentralized oracle system for sentiment data submission and automatically adjusts asset prices based on weighted sentiment averages.

## ✨ Features

### Core Functionality
- **Sentiment Data Aggregation**: Collect and aggregate sentiment scores (0-100) for various topics
- **Synthetic Asset Creation**: Generate synthetic assets tied to sentiment data
- **Dynamic Price Adjustment**: Asset prices automatically adjust based on sentiment changes
- **Oracle Authorization System**: Manage authorized oracles for sentiment data submission
- **Weighted Averaging**: Calculate sentiment using weighted averages across submissions
- **Market Impact Calculation**: Determine market impact based on sentiment scores

### Advanced Features
- **Emergency Controls**: Contract owner can pause/unpause contract operations
- **User Submission Tracking**: Track individual user sentiment submissions
- **Balance Management**: Monitor user balances for synthetic assets
- **Precision Handling**: 6-decimal place precision for asset calculations

## 🔧 Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity v2
- **Epoch**: 2.5
- **Precision**: 6 decimal places (1,000,000 base units)
- **Sentiment Range**: 0-100
- **Price Multipliers**: 0.5x to 1.5x based on sentiment

### Contract Architecture

#### Data Structures
- `sentiment-data`: Stores sentiment information per topic
- `synthetic-assets`: Manages synthetic asset properties
- `user-submissions`: Tracks individual user sentiment submissions
- `authorized-oracles`: Manages oracle authorization
- `user-asset-balances`: Tracks user asset holdings

#### Token Standard
- Implements Clarity fungible token standard
- Token name: `synthetic-asset`

## 🚀 Installation

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity development environment
- Node.js (for optional tooling)
- Stacks CLI

### Setup
1. Clone the repository:
```bash
git clone <repository-url>
cd SocialSentiment
```

2. Install dependencies:
```bash
cd SocialSentiment_contract
npm install
```

3. Test the contract:
```bash
clarinet test
```

4. Start local development environment:
```bash
clarinet integrate
```

## 📖 Usage Examples

### Submitting Sentiment Data
```clarity
;; Submit sentiment score for topic ID 1 with score 75 (positive sentiment)
(contract-call? .SocialSentiment submit-sentiment u1 u75)
```

### Creating a Synthetic Asset
```clarity
;; Create synthetic asset for topic ID 1 with base price of 100 STX (in microSTX)
(contract-call? .SocialSentiment create-synthetic-asset u1 u100000000)
```

### Minting Synthetic Assets
```clarity
;; Mint 1000 units of asset ID 1 to specified recipient
(contract-call? .SocialSentiment mint-synthetic-asset u1 u1000 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
```

### Querying Sentiment Data
```clarity
;; Get sentiment data for topic ID 1
(contract-call? .SocialSentiment get-sentiment-data u1)
```

### Checking Asset Price
```clarity
;; Get current price for asset ID 1
(contract-call? .SocialSentiment get-current-asset-price u1)
```

## 📋 Contract Functions Documentation

### Public Functions

#### `submit-sentiment (topic-id uint) (sentiment-score uint)`
Submit sentiment data for a specific topic.
- **Parameters**:
  - `topic-id`: Unique identifier for the topic
  - `sentiment-score`: Sentiment value (0-100)
- **Returns**: `(response bool uint)`
- **Access**: Any user when contract is active

#### `create-synthetic-asset (topic-id uint) (base-price uint)`
Create a new synthetic asset based on existing sentiment data.
- **Parameters**:
  - `topic-id`: Topic with existing sentiment data
  - `base-price`: Base price in microSTX
- **Returns**: `(response uint uint)` - Returns new asset ID
- **Access**: Contract owner only

#### `mint-synthetic-asset (asset-id uint) (amount uint) (recipient principal)`
Mint synthetic asset tokens to a recipient.
- **Parameters**:
  - `asset-id`: ID of the synthetic asset
  - `amount`: Number of tokens to mint
  - `recipient`: Address to receive tokens
- **Returns**: `(response uint uint)`
- **Access**: Contract owner only

#### `update-asset-price (asset-id uint)`
Update asset price multiplier based on current sentiment.
- **Parameters**: `asset-id`: ID of the asset to update
- **Returns**: `(response uint uint)` - Returns new multiplier
- **Access**: Any user

#### `authorize-oracle (oracle principal)`
Authorize an oracle to submit sentiment data.
- **Parameters**: `oracle`: Principal address of the oracle
- **Returns**: `(response bool uint)`
- **Access**: Contract owner only

#### `deauthorize-oracle (oracle principal)`
Remove oracle authorization.
- **Parameters**: `oracle`: Principal address of the oracle
- **Returns**: `(response bool uint)`
- **Access**: Contract owner only

#### `toggle-contract-active ()`
Emergency function to pause/unpause contract.
- **Returns**: `(response bool uint)` - Returns new active status
- **Access**: Contract owner only

### Read-Only Functions

#### `get-sentiment-data (topic-id uint)`
Retrieve sentiment data for a topic.
- **Returns**: Sentiment data object or none

#### `get-synthetic-asset (asset-id uint)`
Get synthetic asset information.
- **Returns**: Asset data object or none

#### `get-user-submission (user principal) (topic-id uint)`
Get user's sentiment submission for a topic.
- **Returns**: Submission data or none

#### `get-user-asset-balance (user principal) (asset-id uint)`
Get user's balance for a synthetic asset.
- **Returns**: Balance amount (uint)

#### `get-current-asset-price (asset-id uint)`
Calculate current price of synthetic asset.
- **Returns**: `(response uint uint)` - Current price

#### `get-sentiment-count ()`
Get total number of sentiment submissions.
- **Returns**: Total count (uint)

#### `get-total-assets ()`
Get total number of synthetic assets created.
- **Returns**: Asset count (uint)

#### `is-authorized-oracle (oracle principal)`
Check if an oracle is authorized.
- **Returns**: Authorization status (bool)

#### `get-contract-active ()`
Check if contract is currently active.
- **Returns**: Active status (bool)

## 🚢 Deployment Guide

### Testnet Deployment
1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deployments generate --testnet
clarinet deployments apply --testnet
```

### Mainnet Deployment
1. Configure mainnet settings in `settings/Mainnet.toml`
2. Ensure thorough testing on testnet
3. Deploy to mainnet:
```bash
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

### Post-Deployment Steps
1. Authorize initial oracles using `authorize-oracle`
2. Set up monitoring for sentiment submissions
3. Create initial synthetic assets for target topics
4. Implement frontend integration

## 🔒 Security Notes

### Access Controls
- **Contract Owner**: Has exclusive access to asset creation, minting, and oracle management
- **Authorized Oracles**: Can submit sentiment data (when implemented)
- **Emergency Controls**: Owner can pause contract in emergency situations

### Safety Mechanisms
- Sentiment scores validated within 0-100 range
- Asset amounts must be greater than zero
- Contract can be paused to prevent operations during emergencies
- User submissions tracked to prevent manipulation

### Price Multiplier Logic
The contract implements a tiered pricing system based on sentiment:
- 0-20 (Very Negative): 0.5x multiplier
- 21-40 (Negative): 0.75x multiplier
- 41-60 (Neutral): 1.0x multiplier
- 61-80 (Positive): 1.25x multiplier
- 81-100 (Very Positive): 1.5x multiplier

### Recommendations
- Implement oracle reputation systems
- Add time-based restrictions on sentiment submissions
- Consider implementing slashing mechanisms for malicious oracles
- Regular security audits recommended before mainnet deployment
- Monitor for unusual sentiment patterns that might indicate manipulation

## 🛠️ Development

### Project Structure
```
SocialSentiment_contract/
├── contracts/
│   └── SocialSentiment.clar    # Main contract
├── settings/
│   ├── Devnet.toml            # Local development settings
│   ├── Testnet.toml           # Testnet configuration
│   └── Mainnet.toml           # Mainnet configuration
├── tests/                     # Contract tests
├── Clarinet.toml             # Project configuration
└── package.json              # Node.js dependencies
```

### Testing
Run comprehensive tests:
```bash
clarinet test
```

### Local Development
Start local blockchain:
```bash
clarinet integrate
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## ⚠️ Disclaimer

This smart contract is for educational and experimental purposes. Use at your own risk. Always conduct thorough testing and security audits before deploying to mainnet with real assets.