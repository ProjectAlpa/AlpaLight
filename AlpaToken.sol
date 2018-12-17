pragma solidity ^0.4.0;

import "./ERC20Token.sol";
import "./Owner.sol";

contract AlpaToken is owned, ERC20Token {

    uint256 public portfolioValue;

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) ERC20Token(initialSupply, tokenName, tokenSymbol) public {}

    
    /*  _tranfer is already defined in ERC20TOken.sol, we can delete it

    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }*/

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    function setPrices(uint256 newPortfolioValue) onlyOwner public {
        portfolioValue = newPortfolioValue;
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() payable public {
        uint amountOfNewlyCreatedTokens = msg.value / buyPrice;                     // calculates amount of newly created tokens
        _transfer(this, msg.sender, amountOfNewlyCreatedTokens);                    // tranfers the amount of newly created tokens to ETH sender Address
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) public {
        address AddressOfContract = this;                                           // defines the SmartContract Address as this
        require(AddressOfContract.balance >= amountOfTokensToBeSold * sellPrice);   // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amountOfTokensToBeSold);                        // transfers the amount of tokens to be sold back to the SmartContract
        msg.sender.transfer(amountOfTokensToBeSold * sellPrice);                    // sends ether to the seller. It's important to do this last to avoid recursion attacks
     }
}
