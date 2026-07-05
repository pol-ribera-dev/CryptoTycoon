## Gym Blockchain Tycoon

A simple on-chain idle game built with Solidity, where players earn tokens from NFTs, upgrade them over time, and trade them with other players.

The goal of this project was to practice smart contract architecture, contract interaction, testing, and security best practices using Foundry and OpenZeppelin.

There are 69 functions that ensures that all the project is secure and works perfect.

The revert errors are represented by numbers to save gas, you can check the error description in the document errors.txt

### Features
- Start playing by minting your initial NFT collection.
- Earn ERC20 rewards once per day based on your NFTs.
- Upgrade NFTs through a staking mechanism that takes time.
- Cancel upgrades with a partial refund.
- Buy and sell NFTs through an on-chain marketplace.
- Different NFT types with different progression mechanics.
- Basic protections against common vulnerabilities (reentrancy, access control, etc.).

### Project Structure

```text
contracts/
│
├── Main.sol             # Main entry point for the game
├── StakeUpgrade.sol     # Handles NFT upgrades
├── Trades.sol           # Marketplace logic
├── myNFT.sol            # ERC721 implementation
├── myToken.sol          # ERC20 reward token
├── IMain.sol            
├── IStakeUpgrade.sol     
├── ITrades.sol           
├── ImyNFT.sol           
└── ImyToken.sol          

tests/
│
└─── Main.t.sol

script/
│
└── deploy.s.sol
```

### How it Works
1. Start Playing

Calling start() mints the initial NFT collection for the player and registers them as an active player.

2. Daily Rewards

Players can claim rewards once every X amount of time.

The reward depends on:

Number of NFTs owned
NFT levels
NFT type
Whether an NFT is currently upgrading

Base NFTs generate production, while multiplier NFTs increase the total production.

3. NFT Upgrades

Players can spend tokens to upgrade an NFT.

The process consists of:

Deposit the required amount of tokens.
The NFT enters an upgrading state.
Wait for the upgrade timer to finish.
Claim the upgrade.

If the player changes their mind, they can cancel the upgrade and receive a partial refund.

4. Marketplace

Players can:

List NFTs for sale
Buy NFTs from other players
Cancel listings

When purchasing an NFT, buyers pay:

Listing price
Additional protocol fee based on the NFT value
Smart Contract Design

The system is divided into several contracts:

#### Main

Acts as the entry point for the game.

Responsible for:

Starting the game
Claiming rewards
Connecting all other contracts

#### StakeUpgrade

Responsible for:

Upgrade deposits
Upgrade completion (Lvl Up)
Upgrade cancellation

#### Trades

Responsible for:

NFT listings
Purchases
Listing cancellation

#### MyToken (ERC20)

Used as the in-game currency.

Players earn tokens from gameplay and spend them on upgrades and marketplace purchases.

#### myNFT (ERC721)

Represents production assets.

Each NFT stores:

Level
Type (Base or Multiplier)
Upgrade status
