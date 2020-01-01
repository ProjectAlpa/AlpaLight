pragma solidity ^0.4.22;

contract owned {
    address public owner;
    mapping (address => bool) public contributors;

    constructor() public {
        owner = msg.sender;
        contributors[owner] = true;
    }

    modifier onlyOwner {
        require(contributors[msg.sender]);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    function addContributor(address newContributor) onlyOwner public {
        contributors[newContributor] = true;
    }

}
