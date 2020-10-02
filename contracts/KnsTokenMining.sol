// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./IMintableERC20.sol";
import "./KnsTokenWork.sol";
import "./KnsToken.sol";

contract KnsTokenMining
   is AccessControl,
      KnsTokenWork
{
   IMintableERC20 public token;
   mapping (uint256 => uint256) private user_pow_height;

   uint256 public constant ONE_KNS = 100000000;
   uint256 public constant MINEABLE_TOKENS = 100 * 1000000 * ONE_KNS;

   uint256 public constant FINAL_PRINT_RATE = 1500;  // basis points
   uint256 public constant TOTAL_EMISSION_TIME = 180 days;
   uint256 public constant EMISSION_COEFF_1 = (MINEABLE_TOKENS * (20000 - FINAL_PRINT_RATE) * TOTAL_EMISSION_TIME);
   uint256 public constant EMISSION_COEFF_2 = (MINEABLE_TOKENS * (10000 - FINAL_PRINT_RATE));
   uint256 public constant HC_RESERVE_DECAY_TIME = 5 days;
   uint256 public constant RECENT_BLOCK_LIMIT = 96;

   uint256 public start_time;
   uint256 public token_reserve;
   uint256 public hc_reserve;
   uint256 public last_mint_time;

   bool public is_testing;

   event Mine( address[] recipients, uint256[] split_percents, uint256 hc_submit, uint256 hc_decay, uint256 token_virtual_mint, uint256[] tokens_mined );

   constructor( address tok, uint256 start_t, uint256 start_hc_reserve, bool testing )
      public
   {
      token = IMintableERC20(tok);
      _setupRole( DEFAULT_ADMIN_ROLE, _msgSender() );

      start_time = start_t;
      last_mint_time = start_t;
      hc_reserve = start_hc_reserve;
      token_reserve = 0;

      is_testing = testing;
   }

   /**
    * Get the hash of the secured struct.
    *
    * Basically calls keccak256() on parameters.  Mainly exists for readability purposes.
    */
   function get_secured_struct_hash(
      address[] memory recipients,
      uint256[] memory split_percents,
      uint256 recent_eth_block_number,
      uint256 recent_eth_block_hash,
      uint256 target,
      uint256 pow_height
      ) public pure returns (uint256)
   {
      return uint256( keccak256( abi.encode( recipients, split_percents, recent_eth_block_number, recent_eth_block_hash, target, pow_height ) ) );
   }

   /**
    * Require w[0]..w[9] are all distinct values.
    *
    * w[10] is untouched.
    */
   function check_uniqueness(
      uint256[11] memory w
      ) public pure
   {
      // Implement a simple direct comparison algorithm, unroll to optimize gas usage.
      require( (w[0] != w[1]) && (w[0] != w[2]) && (w[0] != w[3]) && (w[0] != w[4]) && (w[0] != w[5]) && (w[0] != w[6]) && (w[0] != w[7]) && (w[0] != w[8]) && (w[0] != w[9])
                              && (w[1] != w[2]) && (w[1] != w[3]) && (w[1] != w[4]) && (w[1] != w[5]) && (w[1] != w[6]) && (w[1] != w[7]) && (w[1] != w[8]) && (w[1] != w[9])
                                                && (w[2] != w[3]) && (w[2] != w[4]) && (w[2] != w[5]) && (w[2] != w[6]) && (w[2] != w[7]) && (w[2] != w[8]) && (w[2] != w[9])
                                                                  && (w[3] != w[4]) && (w[3] != w[5]) && (w[3] != w[6]) && (w[3] != w[7]) && (w[3] != w[8]) && (w[3] != w[9])
                                                                                    && (w[4] != w[5]) && (w[4] != w[6]) && (w[4] != w[7]) && (w[4] != w[8]) && (w[4] != w[9])
                                                                                                      && (w[5] != w[6]) && (w[5] != w[7]) && (w[5] != w[8]) && (w[5] != w[9])
                                                                                                                        && (w[6] != w[7]) && (w[6] != w[8]) && (w[6] != w[9])
                                                                                                                                          && (w[7] != w[8]) && (w[7] != w[9])
                                                                                                                                                            && (w[8] != w[9]),
               "Non-unique work components" );
   }

   /**
    * Check proof of work for validity.
    *
    * Throws if the provided fields have any problems.
    */
   function check_pow(
      address[] memory recipients,
      uint256[] memory split_percents,
      uint256 recent_eth_block_number,
      uint256 recent_eth_block_hash,
      uint256 target,
      uint256 pow_height,
      uint256 nonce
      ) public view
   {
      require( recent_eth_block_hash != 0, "Zero block hash not allowed" );
      require( recent_eth_block_number <= block.number, "Recent block in future" );
      require( recent_eth_block_number + RECENT_BLOCK_LIMIT > block.number, "Recent block too old" );
      require( nonce >= recent_eth_block_hash, "Nonce too small" );
      require( (recent_eth_block_hash + (1 << 128)) > nonce, "Nonce too large" );
      require( uint256( blockhash( recent_eth_block_number ) ) == recent_eth_block_hash, "Block hash mismatch" );

      require( recipients.length <= 5, "Number of recipients cannot exceed 5" );
      require( recipients.length == split_percents.length, "Recipient and split percent array size mismatch" );
      array_check( split_percents );

      require( get_pow_height( _msgSender(), recipients, split_percents ) + 1 == pow_height, "pow_height mismatch" );
      uint256 h = get_secured_struct_hash( recipients, split_percents, recent_eth_block_number, recent_eth_block_hash, target, pow_height );
      uint256[11] memory w = work( recent_eth_block_hash, h, nonce );
      check_uniqueness( w );
      require( w[10] < target, "Work missed target" );     // always fails if target == 0
   }

   function array_check( uint256[] memory arr )
   internal pure
   {
      uint256 sum = 0;
      for (uint i = 0; i < arr.length; i++)
      {
         require( arr[i] <= 10000, "Percent array element cannot exceed 10000" );
         sum += arr[i];
      }
      require( sum == 10000, "Split percentages do not add up to 10000" );
   }

   function get_emission_curve( uint256 t )
      public view returns (uint256)
   {
      if( t < start_time )
         t = start_time;
      if( t > start_time + TOTAL_EMISSION_TIME )
         t = start_time + TOTAL_EMISSION_TIME;
      t -= start_time;
      return ((EMISSION_COEFF_1 - (EMISSION_COEFF_2*t))*t) / (10000 * TOTAL_EMISSION_TIME * TOTAL_EMISSION_TIME);
   }

   function get_hc_reserve_multiplier( uint256 dt )
      public pure returns (uint256)
   {
      if( dt >= HC_RESERVE_DECAY_TIME )
         return 0x80000000;
      int256 idt = (int256( dt ) << 32) / int32(HC_RESERVE_DECAY_TIME);
      int256 y = -0xa2b23f3;
      y *= idt;
      y >>= 32;
      y += 0x3b9d3bec;
      y *= idt;
      y >>= 32;
      y -= 0xb17217f7;
      y *= idt;
      y >>= 32;
      y += 0x100000000;
      if( y < 0 )
         y = 0;
      return uint256( y );
   }

   function get_background_activity( uint256 current_time ) public view
      returns (uint256 hc_decay, uint256 token_virtual_mint)
   {
      hc_decay = 0;
      token_virtual_mint = 0;

      if( current_time <= last_mint_time )
         return (hc_decay, token_virtual_mint);
      uint256 dt = current_time - last_mint_time;

      uint256 f_prev = get_emission_curve( last_mint_time );
      uint256 f_now = get_emission_curve( current_time );
      if( f_now <= f_prev )
         return (hc_decay, token_virtual_mint);

      uint256 mul = get_hc_reserve_multiplier( dt );
      uint256 new_hc_reserve = (hc_reserve * mul) >> 32;
      hc_decay = hc_reserve - new_hc_reserve;

      token_virtual_mint = f_now - f_prev;

      return (hc_decay, token_virtual_mint);
   }

   function process_background_activity( uint256 current_time ) internal
      returns (uint256 hc_decay, uint256 token_virtual_mint)
   {
      (hc_decay, token_virtual_mint) = get_background_activity( current_time );
      hc_reserve -= hc_decay;
      token_reserve += token_virtual_mint;
      last_mint_time = current_time;
      return (hc_decay, token_virtual_mint);
   }

   /**
    * Calculate value in tokens the given hash credits are worth
    **/
   function get_hash_credits_conversion( uint256 hc )
      public view
      returns (uint256)
   {
      require( hc > 1, "HC underflow" );
      require( hc < (1 << 128), "HC overflow" );

      // xyk algorithm
      uint256 x0 = token_reserve;
      uint256 y0 = hc_reserve;

      require( x0 < (1 << 128), "Token balance overflow" );
      require( y0 < (1 << 128), "HC balance overflow" );

      uint256 y1 = y0 + hc;
      require( y1 < (1 << 128), "HC balance overflow" );

      // x0*y0 = x1*y1 -> x1 = (x0*y0)/y1
      // NB above require() ensures overflow safety
      uint256 x1 = ((x0*y0)/y1)+1;
      require( x1 < x0, "No tokens available" );

      return x0-x1;
   }

   /**
    * Executes the trade of hash credits to tokens
    * Returns number of minted tokens
    **/
   function convert_hash_credits(
      uint256 hc ) internal
      returns (uint256)
   {
      uint256 tokens_minted = get_hash_credits_conversion( hc );
      hc_reserve += hc;
      token_reserve -= tokens_minted;

      return tokens_minted;
   }

   function increment_pow_height(
      address[] memory recipients,
      uint256[] memory split_percents ) internal
   {
      user_pow_height[uint256( keccak256( abi.encode( _msgSender(), recipients, split_percents ) ) )] += 1;
   }

   function mine_impl(
      address[] memory recipients,
      uint256[] memory split_percents,
      uint256 recent_eth_block_number,
      uint256 recent_eth_block_hash,
      uint256 target,
      uint256 pow_height,
      uint256 nonce,
      uint256 current_time ) internal
   {
      check_pow(
         recipients,
         split_percents,
         recent_eth_block_number,
         recent_eth_block_hash,
         target,
         pow_height,
         nonce
         );
      uint256 hc_submit = uint256(-1)/target;

      uint256 hc_decay;
      uint256 token_virtual_mint;
      (hc_decay, token_virtual_mint) = process_background_activity( current_time );
      uint256 token_mined;
      token_mined = convert_hash_credits( hc_submit );

      uint256[] memory distribution = distribute( recipients, split_percents, token_mined );
      increment_pow_height( recipients, split_percents );

      emit Mine( recipients, split_percents, hc_submit, hc_decay, token_virtual_mint, distribution );
   }

   /**
    * Get the total number of proof-of-work submitted by a user.
    */
   function get_pow_height(
      address from,
      address[] memory recipients,
      uint256[] memory split_percents
    )
      public view
      returns (uint256)
   {
      return user_pow_height[uint256( keccak256( abi.encode( from, recipients, split_percents ) ) )];
   }

   /**
    * Executes the distribution, minting the tokens to the recipient addresses
    **/
   function distribute(address[] memory recipients, uint256[] memory split_percents, uint256 token_mined)
   internal returns ( uint256[] memory )
   {
      uint256 remaining = token_mined;
      uint256[] memory distribution = new uint256[]( recipients.length );
      for (uint i = distribution.length-1; i > 0; i--)
      {
         distribution[i] = (token_mined * split_percents[i]) / 10000;
	 token.mint( recipients[i], distribution[i] );
	 remaining -= distribution[i];
      }
      distribution[0] = remaining;
      token.mint( recipients[0], remaining );

      return distribution;
   }

   function mine(
      address[] memory recipients,
      uint256[] memory split_percents,
      uint256 recent_eth_block_number,
      uint256 recent_eth_block_hash,
      uint256 target,
      uint256 pow_height,
      uint256 nonce ) public
   {
      require( now >= start_time, "Mining has not started" );
      mine_impl( recipients, split_percents, recent_eth_block_number, recent_eth_block_hash, target, pow_height, nonce, now );
   }

   function test_process_background_activity( uint256 current_time )
      public
   {
      require( is_testing, "Cannot call test method" );
      process_background_activity( current_time );
   }

   function test_mine(
      address[] memory recipients,
      uint256[] memory split_percents,
      uint256 recent_eth_block_number,
      uint256 recent_eth_block_hash,
      uint256 target,
      uint256 pow_height,
      uint256 nonce,
      uint256 current_time ) public
   {
      require( is_testing, "Cannot call test method" );
      mine_impl( recipients, split_percents, recent_eth_block_number, recent_eth_block_hash, target, pow_height, nonce, current_time );
   }
}
