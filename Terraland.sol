// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./ERC721Connector.sol";
import "./Lucre.sol";

contract Terraland is ERC721Connector {
  string[] public terralandz;
  Lucre public lucre;
  address public owner;

  mapping(string => bool)  _terralandzExists;

  constructor(Lucre _lucre) ERC721Connector('Terraland','TLND') {
    lucre = _lucre;
    owner = _msgSender();
  }

  function terralandz_ () external view returns (string[] memory) {
    return terralandz;
  }

  function mint(uint256 coinBurn, string memory _terraland) public {

    require(!_terralandzExists[_terraland], 'Error: Terraland Already Exists!');
    
    //burn token from Origin for minting
    lucre.burn(_msgSender(), coinBurn);

    terralandz.push(_terraland);
    uint _id = terralandz.length -1;

   _mint(_msgSender(),_id);

   _terralandzExists[_terraland] = true;
  }

  function mint1(string memory _terraland) public {

  require(!_terralandzExists[_terraland], 'Error: Terraland Already Exists!');
  
  //burn token from Origin for minting
  //lucre.burn(_msgSender(), coinBurn);

  terralandz.push(_terraland);
  uint _id = terralandz.length -1;

  _mint(_msgSender(),_id);

  _terralandzExists[_terraland] = true;
}

  function burn(uint256 tokenId) public {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
    _burn(tokenId);

    //reset royalty of the token
    _resetTokenRoyalty(tokenId);
  }


//---------------selling and Buying of NFT-----------------------------//

  mapping(address => mapping(uint256 => listing)) public listings;
  mapping(uint256 => bool) public _tokenIdListed;

  struct listing {
    uint256 price;
    address seller;
  }

  function addListing(uint256 price, uint256 tokenId) public {
    Terraland token = Terraland(address(this));
    setApprovalForAll(address(this), true);

    require(_exists(tokenId), "Error: NFT does not exists!");
    require(ownerOf(tokenId) == _msgSender(),"Error: Not the owner!");
    require(token.isApprovedForAll(_msgSender(), address(this)),"Error: Contract must be approved");
    require(!_tokenIdListed[tokenId], "Error: NFT already listed");

    listings[address(this)][tokenId] = listing(price, _msgSender());
    _tokenIdListed[tokenId] = true;


    //---- TO SET THE ROYALTY INDIVIDUALLY PER TOKEN ID -----////
    //_setTokenRoyalty(tokenId, _msgSender(), 100);
  }

  function purchase(uint256 tokenId) public payable{
    listing memory item = listings[address(this)][tokenId];
    require(_tokenIdListed[tokenId], "Error: NFT is not for sale");
    require(msg.value >= item.price, "Error: Insufficient funds");
    require(item.seller != _msgSender(), "Error: Cannot buy own NFT");

    
     //transfer royalty to the NFT's minter
    (address reciever , uint royaltyAmount) = royaltyInfo(tokenId, item.price);
    address payable royalty_wallet = payable(reciever);
    royalty_wallet.transfer(royaltyAmount);

     //transfer marketCut to the marketCut_wallet
    uint256 marketCut = (item.price * 450) / 10000;
    address payable marketCut_wallet = payable(0xdf78bB5C470268bF46b6424b56DdA9834FBe63f6);
    marketCut_wallet.transfer(marketCut);
    
    //transfer of payment from BUYER to SELLER
    address payable sellers_wallet = payable(item.seller);
    uint sellerPayment = item.price - (royaltyAmount + marketCut);
    sellers_wallet.transfer(sellerPayment);

    //transfer of NFT from SELLER to BUYER
    Terraland token = Terraland(address(this));
    token.safeTransferFrom(item.seller, _msgSender(), tokenId, "");


    _tokenIdListed[tokenId] = false;
   
  }

  function deList(uint256 tokenId) public {
    require(_exists(tokenId), "Error: NFT does not exists!");
    require(ownerOf(tokenId) == _msgSender(),"Error: Not the owner!");
    require(_tokenIdListed[tokenId], "Error: NFT is not listed for sale!");
    //require(token.isApprovedForAll(_msgSender(), address(this)),"Error: Contract must be approved");

    _tokenIdListed[tokenId] = false;
  }


  //---------------ROYALTY-----------------------------//

    /**
    * @dev Sets the royalty information that all ids in this contract will default to.
    *
    * Requirements:
    *
    * - `receiver` cannot be the zero address.
    * - `feeNumerator` cannot be greater than the fee denominator.
    */

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) public {
    require(owner == _msgSender(),"Error: Not the contract's owner");
    _setDefaultRoyalty(receiver, feeNumerator);
  }

    /**
     * @dev Removes default royalty information.
  */

  function deleteDefaultRoyalty_() external {
    require(owner == _msgSender(),"Error: Not the contract's owner");
    _deleteDefaultRoyalty();
  }
  

      /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
  function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public {
    require(_exists(tokenId), "Error: NFT does not exists!");
    require(ownerOf(tokenId) == _msgSender(),"Error: Not the owner!");
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
  function resetTokenRoyalty(uint256 tokenId) public {
    require(_exists(tokenId), "Error: NFT does not exists!");
    require(ownerOf(tokenId) == _msgSender(),"Error: Not the owner!");
    _resetTokenRoyalty(tokenId);
  }




}