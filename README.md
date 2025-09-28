# WorkerVote

WorkerVote is a secure platform for workplace democracy and union contract ratification built on the Stacks blockchain. This smart contract enables workers to create and vote on workplace proposals with secure identity verification and transparent voting processes.

## Features

- **Secure Worker Authentication**: Only verified eligible workers can participate in voting
- **Proposal Management**: Create, vote on, and finalize workplace proposals
- **Multiple Proposal Types**: Support for contract ratification, policy changes, and general proposals
- **Transparent Voting**: All votes are recorded on the blockchain for full transparency
- **Time-bound Voting**: Proposals have defined start and end blocks for voting periods
- **Majority-based Decision Making**: Proposals require majority approval from eligible voters
- **Admin Controls**: Administrative functions for managing worker eligibility
- **Vote Tracking**: Comprehensive tracking of individual votes and participation rates

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity
- **Version**: 1.0.0
- **Clarity Version**: 2
- **Epoch**: 2.5

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development tool
- Node.js (for development dependencies)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd WorkerVote
```

2. Navigate to the contract directory:
```bash
cd WorkerVote_contract
```

3. Install dependencies:
```bash
npm install
```

4. Check contract syntax:
```bash
clarinet check
```

## Usage Examples

### Creating a Proposal

```clarity
(contract-call? .WorkerVote create-proposal
  "Union Contract 2024"
  "Vote to ratify the new union contract with improved benefits and working conditions"
  u1440  ;; 1440 blocks (~10 days)
  "contract")
```

### Casting a Vote

```clarity
;; Vote YES on proposal ID 1
(contract-call? .WorkerVote cast-vote u1 true)

;; Vote NO on proposal ID 1
(contract-call? .WorkerVote cast-vote u1 false)
```

### Checking Proposal Status

```clarity
;; Get proposal details
(contract-call? .WorkerVote get-proposal u1)

;; Get proposal results
(contract-call? .WorkerVote get-proposal-results u1)

;; Check if proposal is still active
(contract-call? .WorkerVote is-proposal-active u1)
```

## Contract Functions Documentation

### Public Functions

#### Admin Functions

- **`add-eligible-worker(worker: principal)`**
  - Adds a worker to the eligible voters list
  - Only callable by contract admin
  - Returns: `(response bool uint)`

- **`remove-eligible-worker(worker: principal)`**
  - Removes a worker from the eligible voters list
  - Only callable by contract admin
  - Returns: `(response bool uint)`

- **`transfer-admin(new-admin: principal)`**
  - Transfers admin rights to a new principal
  - Only callable by current admin
  - Returns: `(response bool uint)`

- **`cancel-proposal(proposal-id: uint)`**
  - Cancels an active proposal
  - Only callable by contract admin
  - Returns: `(response bool uint)`

#### Voting Functions

- **`create-proposal(title, description, duration-blocks, proposal-type)`**
  - Creates a new proposal for voting
  - Only callable by eligible workers
  - Parameters:
    - `title`: String (max 100 chars) - Proposal title
    - `description`: String (max 500 chars) - Detailed description
    - `duration-blocks`: uint - Number of blocks for voting period
    - `proposal-type`: String (max 20 chars) - Type: "contract", "policy", or "general"
  - Returns: `(response uint uint)` - Proposal ID on success

- **`cast-vote(proposal-id: uint, vote: bool)`**
  - Casts a vote on an active proposal
  - Only callable by eligible workers who haven't voted yet
  - Parameters:
    - `proposal-id`: uint - ID of the proposal
    - `vote`: bool - true for YES, false for NO
  - Returns: `(response bool uint)`

- **`finalize-proposal(proposal-id: uint)`**
  - Finalizes a proposal after voting period ends
  - Callable by anyone after end block
  - Determines pass/fail based on majority vote
  - Returns: `(response string-ascii uint)` - Final status

### Read-Only Functions

- **`is-eligible-worker(worker: principal)`** - Check worker eligibility
- **`get-proposal(proposal-id: uint)`** - Get proposal details
- **`get-vote(proposal-id: uint, voter: principal)`** - Get specific vote details
- **`has-voted(proposal-id: uint, voter: principal)`** - Check if voter participated
- **`get-next-proposal-id()`** - Get next proposal ID
- **`get-admin()`** - Get current admin principal
- **`get-proposal-results(proposal-id: uint)`** - Get comprehensive results including participation rate
- **`is-proposal-active(proposal-id: uint)`** - Check if proposal is currently active

## Deployment Guide

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy the contract:
```clarity
(contract-call? .WorkerVote add-eligible-worker 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Testnet Deployment

1. Configure your testnet settings in `settings/Testnet.toml`

2. Deploy using Clarinet:
```bash
clarinet deployments generate --testnet
clarinet deployments apply --testnet
```

### Mainnet Deployment

1. Configure your mainnet settings in `settings/Mainnet.toml`

2. Deploy using Clarinet:
```bash
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## Security Notes

### Access Control
- Only eligible workers can create proposals and vote
- Admin functions are restricted to the contract administrator
- Vote eligibility is verified before each vote cast

### Vote Integrity
- Each worker can only vote once per proposal
- Votes cannot be changed once cast
- All votes are permanently recorded on the blockchain

### Proposal Security
- Proposals have time bounds to prevent indefinite voting
- Only active proposals accept votes
- Proposals require majority approval from eligible voters

### Best Practices
- Regularly audit the eligible workers list
- Use appropriate voting periods for different proposal types
- Monitor proposal participation rates
- Ensure admin key security

## Data Structures

### Proposal Structure
```clarity
{
  title: (string-ascii 100),
  description: (string-ascii 500),
  creator: principal,
  start-block: uint,
  end-block: uint,
  yes-votes: uint,
  no-votes: uint,
  total-eligible: uint,
  proposal-type: (string-ascii 20),
  status: (string-ascii 10)
}
```

### Vote Structure
```clarity
{
  vote: bool,
  block-height: uint
}
```

## Error Codes

- `u100`: ERR_UNAUTHORIZED - Caller lacks required permissions
- `u101`: ERR_PROPOSAL_NOT_FOUND - Proposal ID does not exist
- `u102`: ERR_PROPOSAL_ENDED - Proposal voting period has ended
- `u103`: ERR_ALREADY_VOTED - Voter has already cast a vote
- `u104`: ERR_NOT_ELIGIBLE - Caller is not an eligible worker
- `u105`: ERR_INVALID_PROPOSAL - Proposal parameters are invalid
- `u106`: ERR_PROPOSAL_ACTIVE - Proposal is still active

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.