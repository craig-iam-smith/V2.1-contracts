# Silica v2.1

Solidity smart contracts and tests for Alkimiya V2.1

## Getting Started

### Install Depenendcies

```zsh
npm install
```
### Install Foundry

```zsh
curl -L https://foundry.paradigm.xyz | bash
```

#### Update Foundry

```zsh
foundryup
```

### Install Forge dependencies

```zsh
forge update
```

### Update Rust, Foundry, and Forge dependencies

```zsh
make update
```

### Compile Contracts 

```zsh
forge build
```
## Testing

### Unit Tests (Foundry)

```zsh
forge test
forge test -vv (logs)
forge test -vvvv (call trace)
forge test --match-contract TestContractName
forge test --match-test testName
```
## Troubleshooting
### Incompatible Solidity Versions

In case you run into an issue of `forge` not being able to find a compatible version of solidity compiler for one of your contracts/scripts, you may want to install the solidity version manager `svm`. To be able to do so, you will need to have [Rust](https://www.rust-lang.org/tools/install) installed on your system and with it the acompanying package manager `cargo`. Once that is done, to install `svm` run the following command:

```zsh
cargo install svm-rs
```

To list the available versions of solidity compiler run:

```zsh
svm list
```

Make sure the version you need is in this list, or choose the closest one and install it:

```zsh
svm install "0.7.6"
```

### Dependancies Not Found

```zsh
git submodule update --init --recursive
```
or 

```zsh
forge install foundry-rs/forge-std
```
