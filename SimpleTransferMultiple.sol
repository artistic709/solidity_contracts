pragma solidity ^0.4.24;

contract transferMultiple {
    
    constructor(address[] to) public payable {
        
        uint256 value = msg.value / to.length;
        
        for(uint256 i = 0; i < to.length; ++i){
            to[i].transfer(value);
        }
        
        selfdestruct(msg.sender);
    }
    
}
