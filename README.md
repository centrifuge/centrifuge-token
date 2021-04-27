# WCFG ERC-20 Contract
Ethereum Wrapped Centrifuge Token (wCFG)

## Token Functionality
The Wrapped Centrifuge token (wCFG) is an ERC20 token that behaves according to the [ERC20 standard](https://eips.ethereum.org/EIPS/eip-20).

### Burn
Any token owner can choose to burn part of their token balance. This will allow more tokens to be minted by an authorized party.

## Architecture
This is heavily inspired by DappHub the contracts taking their learnings from years of solidity development and architecture considerations for enabling simpler formal verification of the contract.

### ERC20 Token Functionality
The ERC20 token functionality for the wCFG token is copied from the [MakerDAO Dai ERC20 contract](https://github.com/makerdao/dss/blob/master/src/dai.sol) and no modifications have been made to this contract.

### Ward
The concept of a ward is that a contract defines a single address that may interact with the contract. The ward can be changed only by the ward. This is a very flexible design that allows for further limiting the contracts or changing functionality by chaining different wards. The simplest implementation of a ward looks as follows:

```javascript
// See: https://github.com/makerdao/dss/blob/master/src/dai.sol#L19
contract Ward {
    mapping (address => uint) public wards;
    modifier auth { require(wards[msg.sender]); _; }
    function rely(address usr) public auth { wards[usr] = 1; }
    function deny(address usr) public auth { wards[usr] = 0; }
}
```

The ward has 3 methods:
1) Rely: adds an address to the list of wards
2) Deny: removes an address to the list of wards
3) Auth: a modifier that checks that msg.sender is a ward

## Contracts
### wCFG
The `wCFG` contract should be a standard conform ERC20 contract. In addition to implementing all standard ERC20 methods & events, it implements the `Ward` pattern and has a mint method. This is a copy of the MakerDAO Dai token contract.
