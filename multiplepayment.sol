pragma solidity ^0.4.11;
contract multiplepayment {
    
    address owner;
    
    function multiplepayment() payable {
        owner=msg.sender;
    }
    
    modifier onlyOwner() { // Modifier
        require(msg.sender == owner);
        _;
    }
    
    function sendToMany(address[] recipients, uint256[] value) payable onlyOwner  {
        if(recipients.length != value.length){
            throw;
        }
        
        for(uint i = 0; i< recipients.length; i++){
            recipients[i].transfer(value[i]);
        }
    }
    
    function(){
        throw;
    }
    
    function withdraw() onlyOwner{
        owner.transfer (this.balance);
    }
}
