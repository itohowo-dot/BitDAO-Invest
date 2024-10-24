# Bitcoin Investment DAO

A decentralized autonomous organization (DAO) smart contract built on Stacks blockchain for collectively managing Bitcoin investments. This DAO enables members to pool resources, create proposals, vote on investment decisions, and execute approved transactions.

## Features

- **Membership Management**: Join the DAO by paying a membership fee in STX
- **Proposal System**: Create and vote on investment proposals
- **Democratic Governance**: Weighted voting based on member stakes
- **Treasury Management**: Secure handling of pooled funds
- **Automated Execution**: Automatic execution of approved proposals

## Technical Overview

### Core Components

1. **Membership System**

   - Minimum membership fee: 1 STX (1,000,000 microSTX)
   - Each member's voting power is proportional to their STX contribution
   - Member data tracking includes:
     - Join date
     - STX balance
     - Voting power
     - Proposals created
     - Last vote timestamp

2. **Proposal System**

   - Proposal duration: ~1 day (144 blocks)
   - Quorum threshold: 51%
   - Proposal data includes:
     - Title (max 50 characters)
     - Description (max 500 characters)
     - Requested amount
     - Recipient address
     - Voting statistics
     - Execution status

3. **Voting Mechanism**
   - One voting power per STX contributed
   - Members can only vote once per proposal
   - Votes are immutable once cast
   - Vote tracking includes both the decision and voting power used

### Error Codes

```clarity
ERR-OWNER-ONLY (u100): Operation restricted to owner
ERR-NOT-MEMBER (u101): User is not a DAO member
ERR-ALREADY-MEMBER (u102): User is already a member
ERR-INSUFFICIENT-BALANCE (u103): Treasury lacks requested funds
ERR-PROPOSAL-NOT-FOUND (u104): Proposal ID doesn't exist
ERR-ALREADY-VOTED (u105): Member has already voted
ERR-PROPOSAL-EXPIRED (u106): Proposal voting period has ended
ERR-INSUFFICIENT-QUORUM (u107): Proposal lacks required votes
ERR-PROPOSAL-NOT-PASSED (u108): Proposal didn't meet approval threshold
ERR-INVALID-AMOUNT (u109): Invalid transaction amount
ERR-UNAUTHORIZED (u110): Unauthorized operation
ERR-PROPOSAL-EXECUTED (u111): Proposal already executed
```

## Usage Guide

### Joining the DAO

```clarity
(contract-call? .bitcoin-investment-dao join-dao)
```

Requires sending the minimum membership fee (1 STX). Upon successful joining, member data is initialized and the treasury balance is updated.

### Creating a Proposal

```clarity
(contract-call? .bitcoin-investment-dao create-proposal
    "Investment in BTC Mining"
    "Proposal to invest in mining equipment"
    u5000000000
    'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

Creates a new investment proposal. Requirements:

- Must be a DAO member
- Requested amount must be within treasury balance
- Title and description must not be empty
- Valid recipient address

### Voting on Proposals

```clarity
(contract-call? .bitcoin-investment-dao vote-on-proposal u1 true)
```

Cast a vote on a proposal. Requirements:

- Must be a DAO member
- Proposal must be active
- Haven't voted on this proposal before

### Executing Proposals

```clarity
(contract-call? .bitcoin-investment-dao execute-proposal u1)
```

Execute a successful proposal. Requirements:

- Proposal must have ended
- Must meet quorum threshold
- Must not be already executed

### Reading DAO State

```clarity
;; Get DAO statistics
(contract-call? .bitcoin-investment-dao get-dao-info)

;; Get proposal details
(contract-call? .bitcoin-investment-dao get-proposal u1)

;; Get member information
(contract-call? .bitcoin-investment-dao get-member 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)

;; Get vote details
(contract-call? .bitcoin-investment-dao get-vote u1 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

## Security Considerations

1. **Funds Safety**

   - All treasury operations are controlled by the contract
   - Proposals require majority approval and quorum
   - Member balances are tracked separately from voting power

2. **Vote Integrity**

   - Single vote per member per proposal
   - Votes cannot be changed once cast
   - Voting power is proportional to stake

3. **Proposal Lifecycle**
   - Clear timeframes for voting
   - Automated execution checks
   - Prevention of double execution

## Development and Testing

To deploy and test this contract:

1. Install Clarinet for local development
2. Deploy using the Stacks CLI
3. Test all functions thoroughly before mainnet deployment
4. Recommended test coverage:
   - Membership operations
   - Proposal creation and validation
   - Voting mechanics
   - Execution conditions
   - Treasury management

## Contributing

This DAO contract is open for community improvements. When contributing:

1. Follow Clarity best practices
2. Add comprehensive tests
3. Document all changes
4. Submit detailed pull requests

## License

This smart contract is releasedunder the MIT License. See the [LICENSE](LICENSE) file for details.
