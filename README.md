# Vault Ethereum Plugin v0.3.0

The first incarnation of the `vault-ethereum` plugin was an exercise in [experimenting with an idea](https://www.hashicorp.com/resources/vault-platform-enterprise-blockchain) and [proving a point](https://immutability.io/). 2 years later, I feel both ends were acheived.

Having had several occasions to take this PoC to production with companies in the financial and blockchain communities [(plug for Immutability, LLC's custom development!)](mailto:jeff@immutability.io) I've decided to release an upgrade that tries to make the development experience better. I've also restricted the surface area of the plugin to a minimum.

Excepting the `convert` API, which I keep for entertainment value.

## Testing - in one terminal...

```sh

$ cd $GOPATH/src/github.com/immutability-io/vault-ethereum
$ make docker-build
$ make run

```

Then, **open a different terminal**...

```sh

$ cd $GOPATH/src/github.com/immutability-io/vault-ethereum/docker

# Authenticate
$ source ./local-test.sh auth
$ ./demo.sh > README.md

```

## View the demo

If everything worked... And you have run the command above, your demo is had by viewing the results: 

```sh
$ cat ./README.md
```

If everything didn't work, tell me why.

## What is the API?

The best way to understand the API is to use the `path-help` command. For example:

```sh
$ vault path-help vault-ethereum/accounts/bob/deploy                                                                [±new-version ●]
Request:        accounts/bob/deploy
Matching Route: ^accounts/(?P<name>\w(([\w-.]+)?\w)?)/deploy$

Deploy a smart contract from an account.

## PARAMETERS

    abi (string)

        The contract ABI.

    address (string)

        <no description>

    bin (string)

        The compiled smart contract.

    gas_limit (string)

        The gas limit for the transaction - defaults to 0 meaning estimate.

    name (string)

        <no description>

    version (string)

        The smart contract version.

## DESCRIPTION

Deploy a smart contract to the network.
```

## I still need help

[Please reach out to me](mailto:jeff@immutability.io). 

## Tip

Supporting OSS is very hard. 

This is my ETH address. The private keys are managed by this plugin: 

`0x68350c4c58eE921B30A4B1230BF6B14441B46981`

### Ethereum Account Operations
  - **Create Account:** `/accounts/{name}`
    - Create an Ethereum account using a generated or provided passphrase.
  - **Get Account Balance:** `/accounts/{name}/balance`
    - Return the balance for an account.
  - **Deploy Smart Contract:** `/accounts/{name}/deploy`
    - Deploy a smart contract from an account.
  - **ERC-20 Operations:**
    - **Approve Spending:** `/accounts/{name}/erc20/approve`
      - Allow spender to withdraw from your account.
    - **Get ERC-20 Balance:** `/accounts/{name}/erc20/balanceOf`
      - Return the balance for an address's ERC-20 holdings.
    - **Get ERC-20 Total Supply:** `/accounts/{name}/erc20/totalSupply`
      - Return the total supply for an ERC-20 token.
    - **Transfer ERC-20:** `/accounts/{name}/erc20/transfer`
      - Transfer ERC-20 holdings to another address.
    - **Transfer From ERC-20:** `/accounts/{name}/erc20/transferFrom`
      - Transfer ERC-20 holdings from another address to this address.
  - **Signing Operations:**
    - **Sign Message:** `/accounts/{name}/sign`
      - Sign a message.
    - **Sign Transaction:** `/accounts/{name}/sign-tx`
      - Sign a transaction.
  - **Transfer ETH:** `/accounts/{name}/transfer`
    - Send ETH from an account.
  - **List Accounts:** `/accounts/`
    - List all Ethereum accounts at this path.
  ### Plugin Configuration
  - **Configure Plugin:** `/config`
    - Configure the Vault Ethereum plugin.
  ### Ethereum Unit Conversion
  - **Convert Units:** `/convert`
    - Convert any Ethereum unit to another.