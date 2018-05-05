pragma solidity ^0.4.18;

interface Ownable {
  function owner() external view returns(address);
}

contract findSigner{
  
  function isContract(address addr) public view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

  function signer(address account) public view returns(address){
    if(isContract(account))
      return signer(Ownable(account).owner());
    else
      return account;
  }
}
