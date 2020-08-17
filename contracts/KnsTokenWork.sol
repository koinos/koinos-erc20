/**************************************************************************************
 *                                                                                    *
 *                             GENERATED FILE DO NOT EDIT                             *
 *   ___  ____  _  _  ____  ____    __   ____  ____  ____     ____  ____  __    ____  *
 *  / __)( ___)( \( )( ___)(  _ \  /__\ (_  _)( ___)(  _ \   ( ___)(_  _)(  )  ( ___) *
 * ( (_-. )__)  )  (  )__)  )   / /(__)\  )(   )__)  )(_) )   )__)  _)(_  )(__  )__)  *
 *  \___/(____)(_)\_)(____)(_)\_)(__)(__)(__) (____)(____/   (__)  (____)(____)(____) *
 *                                                                                    *
 *                             GENERATED FILE DO NOT EDIT                             *
 *                                                                                    *
 **************************************************************************************/
pragma solidity ^0.6.0;

import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";

contract KnsTokenWork
{
   /**
    * Compute the work function for a seed, secured_struct_hash, and nonce.
    *
    * work_result[10] is the actual work function value, this is what is compared against the target.
    * work_result[0] through work_result[9] (inclusive) are the values of w[y_i].
    */
   function work(
      uint256 seed,
      uint256 secured_struct_hash,
      uint256 nonce
      ) public pure returns (uint256[11] memory work_result)
   {
      uint256 w;
      uint256 x;
      uint256 y;
      uint256 result = secured_struct_hash;
      uint256 coeff_0 = (nonce % 0x0000fffd)+1;
      uint256 coeff_1 = (nonce % 0x0000fffb)+1;
      uint256 coeff_2 = (nonce % 0x0000fff7)+1;
      uint256 coeff_3 = (nonce % 0x0000fff1)+1;
      uint256 coeff_4 = (nonce % 0x0000ffef)+1;




      x = secured_struct_hash % 0x0000fffd;
      y = coeff_4;
      y *= x;
      y += coeff_3;
      y *= x;
      y += coeff_2;
      y *= x;
      y += coeff_1;
      y *= x;
      y += coeff_0;
      y %= 0x0000ffff;
      w = uint256( keccak256( abi.encode( seed, y ) ) );
      work_result[0] = w;
      result ^= w;


      x = secured_struct_hash % 0x0000fffb;
      y = coeff_4;
      y *= x;
      y += coeff_3;
      y *= x;
      y += coeff_2;
      y *= x;
      y += coeff_1;
      y *= x;
      y += coeff_0;
      y %= 0x0000ffff;
      w = uint256( keccak256( abi.encode( seed, y ) ) );
      work_result[1] = w;
      result ^= w;


      x = secured_struct_hash % 0x0000fff7;
      y = coeff_4;
      y *= x;
      y += coeff_3;
      y *= x;
      y += coeff_2;
      y *= x;
      y += coeff_1;
      y *= x;
      y += coeff_0;
      y %= 0x0000ffff;
      w = uint256( keccak256( abi.encode( seed, y ) ) );
      work_result[2] = w;
      result ^= w;


      x = secured_struct_hash % 0x0000fff1;
      y = coeff_4;
      y *= x;
      y += coeff_3;
      y *= x;
      y += coeff_2;
      y *= x;
      y += coeff_1;
      y *= x;
      y += coeff_0;
      y %= 0x0000ffff;
      w = uint256( keccak256( abi.encode( seed, y ) ) );
      work_result[3] = w;
      result ^= w;


      x = secured_struct_hash % 0x0000ffef;
      y = coeff_4;
      y *= x;
      y += coeff_3;
      y *= x;
      y += coeff_2;
      y *= x;
      y += coeff_1;
      y *= x;
      y += coeff_0;
      y %= 0x0000ffff;
      w = uint256( keccak256( abi.encode( seed, y ) ) );
      work_result[4] = w;
      result ^= w;


      x = secured_struct_hash % 0x0000ffe5;
      y = coeff_4;
      y *= x;
      y += coeff_3;
      y *= x;
      y += coeff_2;
      y *= x;
      y += coeff_1;
      y *= x;
      y += coeff_0;
      y %= 0x0000ffff;
      w = uint256( keccak256( abi.encode( seed, y ) ) );
      work_result[5] = w;
      result ^= w;


      x = secured_struct_hash % 0x0000ffdf;
      y = coeff_4;
      y *= x;
      y += coeff_3;
      y *= x;
      y += coeff_2;
      y *= x;
      y += coeff_1;
      y *= x;
      y += coeff_0;
      y %= 0x0000ffff;
      w = uint256( keccak256( abi.encode( seed, y ) ) );
      work_result[6] = w;
      result ^= w;


      x = secured_struct_hash % 0x0000ffd9;
      y = coeff_4;
      y *= x;
      y += coeff_3;
      y *= x;
      y += coeff_2;
      y *= x;
      y += coeff_1;
      y *= x;
      y += coeff_0;
      y %= 0x0000ffff;
      w = uint256( keccak256( abi.encode( seed, y ) ) );
      work_result[7] = w;
      result ^= w;


      x = secured_struct_hash % 0x0000ffd3;
      y = coeff_4;
      y *= x;
      y += coeff_3;
      y *= x;
      y += coeff_2;
      y *= x;
      y += coeff_1;
      y *= x;
      y += coeff_0;
      y %= 0x0000ffff;
      w = uint256( keccak256( abi.encode( seed, y ) ) );
      work_result[8] = w;
      result ^= w;


      x = secured_struct_hash % 0x0000ffd1;
      y = coeff_4;
      y *= x;
      y += coeff_3;
      y *= x;
      y += coeff_2;
      y *= x;
      y += coeff_1;
      y *= x;
      y += coeff_0;
      y %= 0x0000ffff;
      w = uint256( keccak256( abi.encode( seed, y ) ) );
      work_result[9] = w;
      result ^= w;


      work_result[10] = result;
      return work_result;
   }
}
