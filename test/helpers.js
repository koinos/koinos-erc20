
const BN = require("bn.js");
const { keccak256 } = require("ethereumjs-util");

function hash_uint256_seq(s)
{
   let buffers = [];
   for( let i=0; i<s.length; i++ )
   {
      buffers.push( s[i].toBuffer("be", 32) );
   }
   return new BN( keccak256( Buffer.concat( buffers ) ) );
}

function parse_transfer_log(web3, log_item)
{
   let transfer_abi_inputs = [
     { indexed: true,
       internalType: "address",
       name: "from",
       type: "address" },
     { indexed: true,
       internalType: "address",
       name: "to",
       type: "address" },
     { indexed: false,
       internalType: "uint256",
       name: "value",
       type: "uint256" } ];
   return web3.eth.abi.decodeLog(transfer_abi_inputs, log_item.data, log_item.topics.slice(1));
}

async function setup_mining(web3, mining, mining_info)
{
   let block = await web3.eth.getBlock("latest");
   mining_info.recent_block_number = block.number;
   mining_info.recent_block_hash = block.hash;
   mining_info.target = (new BN("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", 16)).div(new BN(10));
   mining_info.from = mining_info.recipients[0];
   mining_info.pow_height = (new BN(await mining.get_pow_height(mining_info.from, mining_info.recipients, mining_info.split_percents ))).add(new BN(1));
   return mining_info;
}

function hash_secured_struct(mining_info)
{
   let s = [];
   // Dynamic parameter placeholders
   s.push( new BN(0) );
   s.push( new BN(0) );
   // Static parameters
   s.push( new BN(mining_info.recent_block_number) );
   s.push( new BN(mining_info.recent_block_hash.substr(2), 16) );
   s.push( mining_info.target );
   s.push( mining_info.pow_height );

   // Initialize dynamic parameters
   s[0] = new BN(0x20 * s.length);
   s.push( new BN(mining_info.recipients.length) );
   for( let i=0; i<mining_info.recipients.length; i++ )
   {
      s.push( new BN(mining_info.recipients[i].substr(2), 16) );
   }

   s[1] = new BN(0x20 * s.length);
   s.push( new BN(mining_info.split_percents.length) );
   for( let i=0; i<mining_info.split_percents.length; i++ )
   {
      s.push( new BN(mining_info.split_percents[i]) );
   }

   return hash_uint256_seq(s);
}

module.exports = {
   hash_uint256_seq : hash_uint256_seq,
   parse_transfer_log : parse_transfer_log,
   setup_mining : setup_mining,
   hash_secured_struct : hash_secured_struct
}
