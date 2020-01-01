pragma solidity ^0.4.22;

import "./ERC20Token.sol";
import "./Owner.sol";

contract AlpaToken is owned, ERC20Token {
    /// PortfolioValue in ETH
    uint256 public portfolioValue;

    address public transferToAddress = address(this);

    address public sendBackAddress = address(this);

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
    event CalculateTokens(uint256 initSupply, uint256 portValue, uint256 sentEthers, uint256 result);

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

    function setTransferToAddress(address newTransferToAddress) onlyOwner public {
        transferToAddress = newTransferToAddress;
    }

    function setSendBackAddress(address newSendBackAddress) onlyOwner public {
        sendBackAddress = newSendBackAddress;
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() public payable {
        require(msg.value > 0);
        _mintAndTransferTokens();
    }

    function () public payable {
        require(msg.value > 0);
        _mintAndTransferTokens();
    }

    function _mintAndTransferTokens() private {
        if(sendBackAddress != msg.sender) {
            mintToken(msg.sender, _calculateTokensToIssue(msg.value));
            if(transferToAddress != address(this)) {
                transferToAddress.transfer(msg.value);
            }
        }
    }

    function _calculateTokensToIssue(uint256 value) private returns(uint256) {
      uint256 amountOfTokensToMint = 0;
      if(totalSupply > 0 && portfolioValue > 0) {
         amountOfTokensToMint = _removeSomeDigits((totalSupply * 10 ** 18 / portfolioValue) * value);               // calculates the amount
         emit CalculateTokens(totalSupply, portfolioValue, value, amountOfTokensToMint);
      } else {
        amountOfTokensToMint = value;
      }
      return amountOfTokensToMint;
    }

    /// @notice Sell `amount` tokens to contract
    /// @param _amount amount of tokens to be sold
    function sell(uint256 _amount) public {
        //address myAddress = this;
        require(balanceOf[msg.sender]>= _amount);      // checks if the contract has enough ether to buy
        uint256 sendBackEth = 0;
        if(portfolioValue > 0 && totalSupply > 0) {
            sendBackEth = _removeSomeDigits((portfolioValue * 10 ** 18 / totalSupply) * _amount);
        } else {
            sendBackEth = _amount;
        }
        //_transfer(myAddress, msg.sender, sendBackEth);              // makes the transfers
        destroyToken(msg.sender, _amount);
        msg.sender.transfer(sendBackEth);          // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }

    function _sqrt(uint x) private pure returns (uint y) {
        uint z = (x + 1) / 18;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 18;
        }
    }

    function _removeSomeDigits(uint x) private pure returns (uint y) {
        y = x;
        uint i = 0;
        while (i < 18) {
            y = y / 10;
            i++;
        }
    }
}
