pragma solidity ^0.4.15;
contract adseller {
    address private owner;
    uint256 public bidDueTime;
    uint public marginRatio;
    
    string public currentAdContent;
    address private currentAdOwner;
    uint256 private currentAdValue;
    
    string  private nextAdContent;
    address private nextAdOwner;
    uint256 public highestBid;
    
    function adseller(){
        owner=msg.sender;
        bidDueTime=now+1 weeks;
        marginRatio=5;
    }
    
    function gotoNext() returns(bool success){
        if(bidDueTime>now){
            return false;
        }
        else{
            bidDueTime+= 1 weeks;
            address redeemaddress = currentAdOwner;
            uint256 redeemvalue = marginRatio*currentAdValue/(marginRatio+1);
            
            currentAdValue = highestBid;
            currentAdContent = nextAdContent;
            currentAdOwner = nextAdOwner;
            nextAdContent = "-";
            nextAdOwner = 0x0;
            highestBid = 0;
            redeemaddress.transfer(redeemvalue);
            return true;
        }
    }
    
    function bid(string ad) payable returns(bool success){

        if(bidDueTime<now){
            gotoNext();
        }
        if(msg.value*105<=100*highestBid){
            revert();
            return false;
        }
        else{
            address redeemaddress = nextAdOwner;
            uint256 redeemvalue = highestBid;
            nextAdContent = ad;
            nextAdOwner = msg.sender;
            highestBid = msg.value;
            if(redeemaddress!=0x0)
                redeemaddress.transfer(redeemvalue);
            
            return true;
        }
        
    }
    
    function judge() returns(bool success){
        require(msg.sender==owner);
        currentAdValue = 0;
        currentAdContent = "-";
        currentAdOwner = 0x0;
        return true;
    }
    
    function collect() returns(bool success){
        require(msg.sender==owner);
        owner.transfer(this.balance-currentAdValue);
        return true;
    }
    
    function setRatio(uint newRatio) returns(bool success){
        require(msg.sender==owner);
        marginRatio = newRatio;
        return true;
    }
    
}
