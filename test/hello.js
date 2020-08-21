
const assert = require("assert").strict;

const { accounts, contract, web3 } = require("@openzeppelin/test-environment");
const { Contracts, ZWeb3 } = require("@openzeppelin/upgrades");
ZWeb3.initialize( web3.currentProvider );

const { keccak256 } = require("ethereumjs-util");

const { TestHelper } = require("@openzeppelin/cli");
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

const KnsToken = Contracts.getFromLocal("KnsToken");
const KnsTokenMining = Contracts.getFromLocal("KnsTokenMining");

// const BN = require("bn.js");

const { JSWork } = require("./work.js");

const START_TIME = 4102462800;

describe( "Some tests", function()
{
   const [owner, alice] = accounts;

   beforeEach(async function () {
      this.project = await TestHelper({from: owner});
      this.token_proxy = await this.project.createProxy(KnsToken,
          {
             initArgs: [
             "Test Koinos",
             "TEST.KNS",
             "0x0000000000000000000000000000000000000000",
             ],
             from: owner
          });
      this.mining_proxy = await this.project.createProxy(KnsTokenMining,
          {
             initArgs: [
             this.token_proxy.address,
             START_TIME,
             true
             ],
             from: owner
          });
      this.MINTER_ROLE = await this.token_proxy.methods.MINTER_ROLE().call();
      await this.token_proxy.methods.grantRole( this.MINTER_ROLE, this.mining_proxy.address ).send( {from: owner} );
   });

   it( "Deploy both contracts", async function()
   {
      // Check name, symbol
      let name = await this.token_proxy.methods.name().call();
      assert( name == "Test Koinos" );

      /*
      await this.mining_proxy.methods.grab( alice, 1234 ).send();
      let alice_balance = this.token_proxy.methods.balanceOf( alice ).call();
      console.log( "Alice balance now", alice_balance );
      */
   } );

   it( "Check work function", async function()
   {
      let seed = keccak256("This is the seed.");
      let secured_struct_hash = keccak256("Secured struct hash.");
      let nonce = keccak256("A test nonce");

      let w_contract = await this.mining_proxy.methods.work(seed, secured_struct_hash, nonce).call();

      let bn_seed = new BN(seed);
      let bn_h = new BN(secured_struct_hash);
      let bn_nonce = new BN(nonce);
      let w_obj = new JSWork( bn_seed, bn_h, bn_nonce );
      let w_js = w_obj.compute_work();

      console.log( "Seed", (new BN(seed)).toString( 16 ) );
      console.log( "Secured Hash", (new BN(secured_struct_hash)).toString( 16 ) );
      console.log( "Nonce", (new BN(nonce)).toString( 16 ) );

      assert( w_contract.length == w_js.length );
      for( let i=0; i<w_contract.length; i++ )
      {
          assert( (new BN(w_contract[i])).eq(w_js[i]) );
          console.log( "Work", i, (new BN(w_contract[i])).toString( 16 ) );
      }

   } );

   it( "Check emission curve", async function()
   {
      let zero = new BN(0);
      let mining = this.mining_proxy;
      let k = await mining.methods.FINAL_PRINT_RATE().call() / 10000.0;
      let sat = await mining.methods.ONE_KNS().call();
      let supply = await mining.methods.MINEABLE_TOKENS().call();
      supply = supply / sat;
      let f = function(x) { return (2.0 - k) * x - (1.0 - k) * x*x; };
      let g = function(t) { return new BN( supply * ( f(t/(60.0*60.0*24.0*365.0)) ) ); };

      let h = async function(t)
      {
         let ec = await mining.methods.get_emission_curve( START_TIME + t ).call();
         return new BN( ec / sat );
      };

      let h_0 = await h(0);
      let h_1 = await h(1);
      assert( h_0.eq(zero) );
      assert( h_1.gt(zero) );
      assert( g(0).eq(h_0) );
      assert( g(1).eq(h_1) );
      assert( g(1337).eq(await h(1337)) );
      assert( g(7654321).eq(await h(7654321)) );
      assert( g(60*60*24*365).eq(await h(60*60*24*365)) );
      assert( g(60*60*24*365).eq(new BN(supply)) );
   } );

   it( "Check emission event", async function()
   {
      let mining = this.mining_proxy;
      let start_time = await mining.methods.start_time().call();
      let last_mint_time = await mining.methods.last_mint_time().call();
      console.log( "start_time:", start_time );
      console.log( "last_mint_time:", start_time );

      let dt = 60*60*24;
      let t = START_TIME + dt;
      console.log( "t:", t );

      let ba = await mining.methods.get_background_activity( t ).call();
      console.log(ba);
      // expectEvent( txr, "HCDecay" );
   } );

   it( "Mine a nonce", async function()
   {
      let setup_mining() = async function(mining_info)
      {
         let block = await web3.eth.getBlock("latest");
         mining_info.recent_block_number = block.number;
         mining_info.recent_block_hash = block.hash;
         mining_info.pow_height = await web3.eth.get_pow_height( mining_info.recipients[0] );
         mining_info.target = new BN("0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
         return mining_info;
      };

      let mining_info = setup_mining( {"recipients" : [alice, bob], "split_percents" = [7500, 2500]} );

      console.log( "mining_info:", mining_info );

      /*
      for( let i=0; i<n; i++ )
      {
         
      }
      */
   } );
} );
