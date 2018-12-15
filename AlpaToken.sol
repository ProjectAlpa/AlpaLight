pragma solidity ^0.4.0;

import "./ERC20Token.sol";
import "./Owner.sol";

contract AlpaToken is owned, ERC20Token {
    /// PortfolioValue in ETH
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

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) private {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }
    /// 
        function destroyToken (address target, uint256 destroyAmount) private {
        balanceOf[target] -= destroyAmount;
        totalSupply -= destroyAmount;
        emit Transfer(target, 0, destroyAmount);
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
        uint amountNewAlp = (totalSupply / portfolioValue) * msg.value;               // calculates the amount
///     portfolioValue = portfolioValue + msg.value
        mintToken(msg.sender , amountNewAlp)
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 _amount) public {
        address myAddress = this;
        require(balanceOf[msg.sender]>= _amount);      // checks if the contract has enough ether to buy
        unit sendBackEth = (portfolioValue / totalSupply) * _amount;
        _transfer(this, msg.sender, sendBackEth);              // makes the transfers
        destroyToken(msg.sender, _amount);
        msg.sender.transfer(sendBackEth);          // sends ether to the seller. It's important to do this last to avoid recursion attacks
        
    }
}
