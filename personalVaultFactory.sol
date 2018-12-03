pragma solidity ^0.4.24;

interface TokenERC20 {
    function balanceOf(address owner) view external returns(uint256);
    function allowance(address owner, address spender) view external returns(uint256);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function approve(address spender, uint256 value) external returns(bool);
}

contract walletOwnership {
    address public owner;
    address public recovery;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyRecovery(){
        require(msg.sender == recovery);
        _;
    }

    modifier onlyOwnerOrRecovery(){
        require(msg.sender == owner || msg.sender == recovery);
        _;
    }

    function setOwner(address _owner) onlyRecovery external{
        owner = _owner;
    }

    function setRecovery(address _recovery) onlyRecovery external{
        recovery = _recovery;
    }
}

contract personalVault is walletOwnership {
    
    mapping(address => uint256) public dailyLimit;
    mapping(address => uint256) public lastDay;
    mapping(address => uint256) public spentToday;

    event WithdrawEther(uint256 amount);
    event WithdrawToken(address token, uint256 amount);

    constructor(address _owner, address _recovery) public {
        owner = _owner;
        recovery = _recovery;
    }

    function ()public payable{
    }

    function withdraw(address token, uint256 amount) onlyOwnerOrRecovery external{
        require(isUnderLimit(token, amount) || msg.sender == recovery);
        if (token == address(0)){
            if(owner.send(amount)){
                spentToday[address(0)] += amount;
                emit WithdrawEther(amount);
            }
        }
        else{
            if(TokenERC20(token).transfer(owner,amount)){
                spentToday[token] += amount;
                emit WithdrawToken(token, amount);
            }
        }

    }

    function setLimit(address token, uint256 limit) onlyOwnerOrRecovery external{
        if(msg.sender == recovery
            || dailyLimit[token] == 0
            || dailyLimit[token] > limit)
        {
            dailyLimit[token] = limit;
        }
    }

    function isUnderLimit(address token, uint256 amount)
        internal
        returns (bool)
    {
        if (now > lastDay[token] + 24 hours) {
            lastDay[token] = now;
            spentToday[token] = 0;
        }
        if (spentToday[token] + amount > dailyLimit[token] || spentToday[token] + amount < spentToday[token])
            return false;
        return true;
    }
}

contract personalVaultFactory {

    mapping(address => bool) public isVault;

    function create(address _owner, address _recovery) public returns (address vault) {
        vault = new personalVault(_owner, _recovery);
        isVault[vault] = true;
    }
}
