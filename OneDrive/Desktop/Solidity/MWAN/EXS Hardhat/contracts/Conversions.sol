// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

   
   contract Conversions{

     function calculateAddressHash(address a) public pure returns (bytes32 hash, bytes memory data)
    {
      bytes memory packed = abi.encodePacked(a);
      bytes32 hashResult = keccak256(packed);
      return(hashResult, packed);
    }

   function toBytes(uint256 x) public pure returns (bytes memory b)
    {
    b = new bytes(32);
    assembly { mstore(add(b, 32), x) }
    return b;
    }
   }