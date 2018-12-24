pragma solidity ^0.4.24;

contract personalWallet {

    using BytesLib for bytes;

    address public owner;
    address public recovery;
    uint256 public nonce;

    constructor(address _owner, address _recovery) public {
        owner = _owner;
        recovery = _recovery;
    }

    function isOwner(address _owner) public view returns(bool){
        return(_owner == owner);
    }

    function owners() public view returns(address[] memory _owners){
        _owners = new address[](1);
        _owners[0] = owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyRecovery(){
        require(msg.sender == recovery);
        _;
    }

    function setOwner(address _owner) onlyRecovery external{
        owner = _owner;
    }

    function setRecovery(address _recovery) onlyRecovery external{
        recovery = _recovery;
    }


    event Execute(address to, uint256 value, bytes data);

    function execute(address _to, uint256 _value, bytes _data) public onlyOwner {
        require(_to.call.value(_value)(_data));
        emit Execute(_to, _value, _data);
    }

    function delegateExecute(
        address _to, uint256 _value,
        bytes _data, uint256 _nonce,
        uint8 _v, bytes32 _r, bytes32 _s) public {

        require(_nonce == nonce);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 digest = keccak256(abi.encodePacked(_to, _value, _data, _nonce));
        bytes32 txHash = keccak256(abi.encodePacked(prefix,digest));
        require(ecrecover(txHash, _v, _r, _s) == owner);

        require(_to.call.value(_value)(_data));
        emit Execute(_to, _value, _data);
        nonce = nonce + 1;
    }

    function batchDelegateExecute(
        address[] _to, uint256[] _value,
        uint256[] _idx, bytes _data, uint256 _nonce,
        uint8 _v, bytes32 _r, bytes32 _s) public {

        require(_nonce == nonce);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 digest = keccak256(
            abi.encodePacked(_to, _value, _idx, _data, _nonce));
        bytes32 txHash = keccak256(abi.encodePacked(prefix, digest));
        require(ecrecover(txHash, _v, _r, _s) == owner);

        uint256 start = 0;
        for (uint256 i = 0; i < _idx.length; i++) {
            require(_to[i].call.value(_value[i])(_data.slice(start, _idx[i])));
            emit Execute(_to[i], _value[i], _data.slice(start, _idx[i]));
            start += _idx[i];
        }
        nonce = nonce + 1;
  }

    function () public payable{
    }

}

contract personalWalletFactory {

    mapping(address => bool) public isWallet;

    function create(address _owner, address _recovery) public returns (address wallet) {
        wallet = new personalWallet(_owner, _recovery);
        isWallet[wallet] = true;
    }
}


/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <goncalo.sa@consensys.net>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
library BytesLib {

    function slice(bytes _bytes, uint _start, uint _length) internal  pure returns (bytes) {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

}
