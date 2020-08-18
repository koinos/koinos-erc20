pragma solidity ^0.6.0;

import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";

import "./IMintableERC20.sol";
import "./KnsTokenWork.sol";
import "./KnsToken.sol";

contract KnsTokenMining
   is Initializable,
      AccessControlUpgradeSafe,
      KnsTokenWork
{
   IMintableERC20 public token;
   mapping (address => uint256) private user_pow_height;

   uint256 public constant ONE_KNS = 100000000;
   uint256 public constant MINEABLE_TOKENS = 100 * 1000000 * ONE_KNS;

   // TODO this should be a number of hashes corresponding to 1000 CPU-hours
   uint256 public constant START_HC_RESERVE = 1000;
   uint256 public constant FINAL_PRINT_RATE = 1500;  // basis points
   uint256 public constant TOTAL_EMISSION_TIME = 365 days;
   uint256 public constant EMISSION_COEFF_1 = (MINEABLE_TOKENS * (20000 - FINAL_PRINT_RATE) * TOTAL_EMISSION_TIME);
   uint256 public constant EMISSION_COEFF_2 = (MINEABLE_TOKENS * (10000 - FINAL_PRINT_RATE));
   uint256 public constant HC_RESERVE_DECAY_TIME = 5 days;
   uint256 public constant RECENT_BLOCK_LIMIT = 64;

   uint256 public start_time;
   uint256 public token_reserve;
   uint256 public hc_reserve;
   uint256 public last_mint_time;

   bool public is_testing;

   event Mine( address miner, address recipient, uint256 split_percent, uint256 hc_submit, uint256 hc_decay, uint256 token_virtual_mint, uint256 miner_tokens, uint256 recipient_tokens );

   function initialize(address tok, uint256 start_t, bool testing ) public initializer
   {
       __KnsTokenMining_init( tok, start_t, testing );
   }

   function __KnsTokenMining_init( address tok, uint256 start_t, bool testing ) internal initializer
   {
      // Initializable
      // AccessControl is Initializable, ContextUpgradeSafe
      // ContextUpgradeSafe is Initializable
      __Context_init_unchained();
      __AccessControl_init_unchained();
      __KnsTokenMining_init_unchained( tok, start_t, testing );
   }

   function __KnsTokenMining_init_unchained( address tok, uint256 start_t, bool testing ) internal initializer
   {
      token = IMintableERC20(tok);
      _setupRole( DEFAULT_ADMIN_ROLE, _msgSender() );

      start_time = start_t;
      last_mint_time = start_t;
      hc_reserve = START_HC_RESERVE;
      token_reserve = 0;

      is_testing = testing;
   }

   /**
    * Get the hash of the secured struct.
    *
    * Basically calls keccak256() on parameters.  Mainly exists for readability purposes.
    */
   function get_secured_struct_hash(
      address miner,
      address recipient,
      uint256 split_percent,
      uint256 recent_eth_block_number,
      uint256 recent_eth_block_hash,
      uint256 target,
      uint256 pow_height
      ) public pure returns (uint256)
   {
      return uint256( keccak256( abi.encode( miner, recipient, split_percent, recent_eth_block_number, recent_eth_block_hash, target, pow_height ) ) );
   }

   /**
    * Check proof of work for validity.
    *
    * Throws if the provided fields have any problems.
    */
   function check_pow(
      address miner,
      address recipient,
      uint256 split_percent,
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
      require( split_percent <= 10000, "Split percent too large." );

      require( user_pow_height[miner]+1 == pow_height, "pow_height mismatch" );
      uint256 h = get_secured_struct_hash( miner, recipient, split_percent, recent_eth_block_number, recent_eth_block_hash, target, pow_height );
      uint256[11] memory w = work( recent_eth_block_hash, h, nonce );
      require( w[10] < target, "Work missed target" );     // always fails if target == 0
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

   function mine_impl(
      address miner,
      address recipient,
      uint256 split_percent,
      uint256 recent_eth_block_number,
      uint256 recent_eth_block_hash,
      uint256 target,
      uint256 pow_height,
      uint256 nonce,
      uint256 current_time ) internal
   {
      check_pow(
         miner,
	 recipient,
	 split_percent,
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

      // Mint the tokens
      uint256 recipient_tokens = (token_mined * split_percent) / 10000;

      token.mint( miner, token_mined - recipient_tokens );
      token.mint( recipient, recipient_tokens );

      emit Mine( miner, recipient, split_percent, hc_submit, hc_decay, token_virtual_mint, token_mined - recipient_tokens, recipient_tokens );
   }

   function mine(
      address miner,
      address recipient,
      uint256 split_percent,
      uint256 recent_eth_block_number,
      uint256 recent_eth_block_hash,
      uint256 target,
      uint256 pow_height,
      uint256 nonce ) public
   {
      mine_impl( miner, recipient, split_percent, recent_eth_block_number, recent_eth_block_hash, target, pow_height, nonce, now );
   }

   function test_process_background_activity( uint256 current_time )
      public
   {
      require( is_testing, "Cannot call test method" );
      process_background_activity( current_time );
   }

   function test_mine(
      address miner,
      address recipient,
      uint256 split_percent,
      uint256 recent_eth_block_number,
      uint256 recent_eth_block_hash,
      uint256 target,
      uint256 pow_height,
      uint256 nonce,
      uint256 current_time ) public
   {
      require( is_testing, "Cannot call test method" );
      mine_impl( miner, recipient, split_percent, recent_eth_block_number, recent_eth_block_hash, target, pow_height, nonce, current_time );
   }
}
