pragma solidity ^0.4.22;

import "./ERC20Token.sol";
import "./Owner.sol";

contract AlpaToken is owned, ERC20Token {
    /// PortfolioValue in ETH
    uint256 public portfolioValue;

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor (
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) ERC20Token(initialSupply, tokenName, tokenSymbol) public {}

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
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function setPortfolioValue(uint256 newPortfolioValue) onlyOwner public {
        portfolioValue = newPortfolioValue;
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() public payable {
        mintToken(msg.sender, _calculateTokensToIssue(msg.value));
    }

    function _calculateTokensToIssue(uint value) private view returns(uint) {
      uint amountOfTokensToMint = 0;
      if(totalSupply > 0 && portfolioValue > 0) {
         amountOfTokensToMint = (totalSupply / portfolioValue) * value;               // calculates the amount
      } else {
        amountOfTokensToMint = value;
      }
      return amountOfTokensToMint;
    }

    function () public payable {
        mintToken(msg.sender, _calculateTokensToIssue(msg.value));
    }

    /// @notice Sell `amount` tokens to contract
    /// @param _amount amount of tokens to be sold
    function sell(uint256 _amount) public {
        //address myAddress = this;
        require(balanceOf[msg.sender]>= _amount);      // checks if the contract has enough ether to buy
        uint sendBackEth = 0;
        if(portfolioValue > 0 && totalSupply > 0) {
            sendBackEth = (portfolioValue / totalSupply) * _amount;
        } else {
            sendBackEth = _amount;
        }
        //_transfer(myAddress, msg.sender, sendBackEth);              // makes the transfers
        destroyToken(msg.sender, _amount);
        msg.sender.transfer(sendBackEth);          // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }
}
