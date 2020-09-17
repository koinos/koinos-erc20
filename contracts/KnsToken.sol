// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";

contract KnsToken
   is AccessControl,
      ERC20,
      ERC20Capped,
      ERC20Burnable,
      ERC20Snapshot
{
   bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
   bytes32 public constant SNAPSHOTTER_ROLE = keccak256("SNAPSHOTTER_ROLE");
   uint256 public constant ONE_KNS = 100000000;
   uint8 public constant KNS_DECIMALS = 8;
   uint256 public constant KNS_CAP = 100 * 1000000 * ONE_KNS;

   constructor(string memory name, string memory symbol, address minter)
      ERC20( name, symbol )
      ERC20Capped( KNS_CAP )
      public
   {
      _setupDecimals( KNS_DECIMALS );
      _setupRole( DEFAULT_ADMIN_ROLE, _msgSender() );
      if( minter != address(0) )
         _setupRole( MINTER_ROLE, minter );
   }

   /**
    * @dev Creates `amount` new tokens for `to`.
    *
    * See {ERC20-_mint}.
    *
    * Requirements:
    *
    * - the caller must have the `MINTER_ROLE`.
    */
   function mint(address to, uint256 amount) public
   {
      require(hasRole(MINTER_ROLE, _msgSender()), "KnsToken: mint() requires MINTER_ROLE");
      _mint(to, amount);
   }

   /**
    * @dev Creates a snapshot of current token balances.
    *
    * See {ERC20Snapsot-_snapshot}.
    *
    * Requirements:
    *
    * - the caller must have the 'SNAPSHOTTER_ROLE'.
    */
   function snapshot() public
   {
      require(hasRole(SNAPSHOTTER_ROLE, _msgSender()), "KnsToken: snapshot() requires SNAPSHOTTER_ROLE");
      _snapshot();
   }

   function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Capped)
   {
       super._beforeTokenTransfer(from, to, amount);
   }

   function _burn(address account, uint256 value) internal override(ERC20, ERC20Snapshot)
   {
       super._burn(account, value);
   }

   function _mint(address account, uint256 amount) internal override(ERC20, ERC20Snapshot)
   {
       super._mint(account, amount);
   }

   function _transfer(address sender, address recipient, uint256 amount) internal override(ERC20, ERC20Snapshot)
   {
       super._transfer(sender, recipient, amount);
   }
}
