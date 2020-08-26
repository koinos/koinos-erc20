
// Not using 0.6.8 to suppress SPDX license warnings, as contracts-ethereum-package does not exist until version 3.1.0
pragma solidity >0.6.0 <0.6.8;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";

contract KnsToken
   is AccessControl,
      ERC20,
      ERC20Capped,
      ERC20Burnable
{
   bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
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

   function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Capped)
   {
       super._beforeTokenTransfer(from, to, amount);
   }
}
