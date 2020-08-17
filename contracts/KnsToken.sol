
// Not using 0.6.8 to suppress SPDX license warnings, as contracts-ethereum-package does not exist until version 3.1.0
pragma solidity >0.6.0 <0.6.8;

import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";

contract KnsToken
   is Initializable,
      ContextUpgradeSafe,
      AccessControlUpgradeSafe,
      ERC20UpgradeSafe,
      ERC20CappedUpgradeSafe,
      ERC20BurnableUpgradeSafe
{
   bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
   uint256 public constant ONE_KNS = 100000000;
   uint8 public constant KNS_DECIMALS = 8;
   uint256 public constant KNS_CAP = 100 * 1000000 * ONE_KNS;

   function initialize(string memory name, string memory symbol, address minter) public initializer
   {
       __KnsToken_init(name, symbol, minter);
   }

   function __KnsToken_init( string memory name, string memory symbol, address minter ) internal initializer
   {
      // Initializable
      // AccessControl is Initializable, ContextUpgradeSafe
      // ContextUpgradeSafe is Initializable
      __Context_init_unchained();
      __AccessControl_init_unchained();
      // ERC20UpgradeSafe is Initializable, ContextUpgradeSafe, IERC20
      __ERC20_init_unchained( name, symbol );
      _setupDecimals( KNS_DECIMALS );

      // ERC20CappedUpgradeSafe is Initializable, ERC20UpgradeSafe
      __ERC20Capped_init_unchained( KNS_CAP );

      // ERC20BurnableUpgradeSafe is Initializable, ContextUpgradeSafe, ERC20UpgradeSafe
      __ERC20Burnable_init_unchained();

      __KnsToken_init_unchained( minter );
   }

   function __KnsToken_init_unchained( address minter ) internal initializer
   {
      _setupRole( DEFAULT_ADMIN_ROLE, _msgSender() );
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

   function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20UpgradeSafe, ERC20CappedUpgradeSafe)
   {
       super._beforeTokenTransfer(from, to, amount);
   }
}
