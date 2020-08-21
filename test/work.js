// JavaScript implementation of the work algorithm

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

class JSWork
{
   constructor(seed, h, nonce)
   {
      this.seed = seed;
      this.h = h;
      this.nonce = nonce;
      this.p = 0xffff;
      this.q = [0x0000fffd, 0x0000fffb, 0x0000fff7, 0x0000fff1, 0x0000ffef, 0x0000ffe5, 0x0000ffdf, 0x0000ffd9, 0x0000ffd3, 0x0000ffd1];

      this.p = new BN(this.p);
      for(let i=0;i<this.q.length;i++)
         this.q[i] = new BN(this.q[i]);
   }

   w(i)
   {
      return hash_uint256_seq( [this.seed, i] );
   }

   f_a(a, x)
   {
      let one = new BN(1);
      let x2 = x.mul(x);
      let x3 = x2.mul(x);
      let x4 = x3.mul(x);
      let result = (a.mod(this.q[0]).add(one)        ).add
                   (a.mod(this.q[1]).add(one).mul(x )).add
                   (a.mod(this.q[2]).add(one).mul(x2)).add
                   (a.mod(this.q[3]).add(one).mul(x3)).add
                   (a.mod(this.q[4]).add(one).mul(x4));
      return result;
   }

   f_nonce(x)
   {
      return this.f_a(this.nonce, x);
   }

   xor(u)
   {
      let result = new BN("0");
      for(let i=0;i<u.length;i++)
      {
         result = result.xor(u[i]);
      }
      return result;
   }

   y(i)
   {
      let f_result = this.f_nonce(this.h.mod(this.q[i]));
      return f_result.mod(this.p);
   }

   compute_work()
   {
      let _this = this;
      let w = function(i) { return _this.w(i); };
      let y = function(i) { return _this.y(i); };
      let v = [w(y(0)), w(y(1)), w(y(2)), w(y(3)), w(y(4)), w(y(5)), w(y(6)), w(y(7)), w(y(8)), w(y(9))];
      let work = this.xor(v).xor(this.h);
      v.push(work);
      return v;
   }
}

module.exports = {
   JSWork : JSWork,
   hash_uint256_seq : hash_uint256_seq,
}
