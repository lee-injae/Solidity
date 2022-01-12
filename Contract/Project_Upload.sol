//**************************************  CONTRACT  **************************************//

pragma solidity >=0.7.0 <0.9.0;

contract NFTProject is ERC721Enumerable, Ownable {
  using Strings for uint256;

  // Input: URI
  string baseURI;
  string public baseExtension = ".json";
  
  // Input: Key variables - whitelist sale
  uint256 public whitelistSalePrice = 0.01 ether;
  uint256 public maxWhitelistSupply = 100;
  uint256 public maxWhitelistSaleMintAmount = 5;
  uint256 public nftPerAddressLimit = 5;
  mapping(address => bool) public presale_whitelisted;
  mapping(address => uint256) public addressMintedBalance;

  // Input: Key variables - public sale
  uint256 public publicSalePrice = 0.02 ether;
  uint256 public maxSupply = 1000;
  uint256 public maxPublicSaleMintAmount = 5;
  
  // Input: Control
  bool public publicSaleIsActive = false;
  bool public whitelistSaleIsActive = false;
  //string public PROVENANCE; Does this allow randomization of token minting process?

  // Input: Constructor
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }

  //**************************************  INTERNAL  **************************************//

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  //**************************************  MINT  **************************************//

  function mintWhitelist(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(whitelistSaleIsActive, "Minting not ready yet!");
    require(presale_whitelisted[msg.sender], "User is not whitelisted");
    require(_mintAmount > 0, "Let's mint more than one");
    require(_mintAmount <= maxWhitelistSaleMintAmount, "Maximum mint quantity exceeeded");
    require(supply + _mintAmount <= maxWhitelistSupply, "Purchase would exceed maximum supply of whitelist mintable tokens");

    if (msg.sender != owner()) {
      uint256 ownerMintedCount = addressMintedBalance[msg.sender];
      require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "Exceeds number of tokens allowed per wallet"); // limits the WL address from transfering and getting a new one
      require(msg.value >= whitelistSalePrice * _mintAmount, "Lacks Ether"); //gets error message from time to time
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
        addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }
  
  function mintPublic(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(publicSaleIsActive, "Minting is not ready yet!");
    require(_mintAmount > 0, "Let's mint more than one");
    require(_mintAmount <= maxPublicSaleMintAmount, "Maximum mint quantity exceeeded");
    require(supply + _mintAmount <= maxSupply, "Purchase would exceed maximum supply of tokens");

    if (msg.sender != owner()) {
      require(msg.value >= publicSalePrice * _mintAmount); //gets error message from time to time
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

//**************************************  PUBLIC  **************************************//

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
  //return super.supportsInterface(interfaceId);
  //}
  // Do we need this?

  //**************************************  ONLY FOR OWNER  **************************************//

  // Whitelist sale control
  function whitelistedList(address[] memory _users) public onlyOwner {
     for(uint i = 0; i < _users.length; i++)
       presale_whitelisted[_users[i]] = true;
  }

  function nftPerAddressLimitSet(uint256 _newLimit) public onlyOwner() {
  nftPerAddressLimit = _newLimit;
  }

  function whitelistUserRemove(address _users) public onlyOwner {
  presale_whitelisted[_users] = false;
  }

  function whitelistSaleStateSet(bool whitelistSaleEnabled) public onlyOwner {
  whitelistSaleIsActive = whitelistSaleEnabled;
  }

  function whitelistSalePriceSet(uint256 _newWhitelistSalePrice) public onlyOwner() {
    whitelistSalePrice = _newWhitelistSalePrice;
  }

  function whitelistMaxMintAmount(uint256 _newmaxWhitelistSaleMintAmount) public onlyOwner() {
    maxWhitelistSaleMintAmount = _newmaxWhitelistSaleMintAmount;
  }

  // Public sale control
  function publicSaleStateSet(bool publicSaleEnabled) public onlyOwner {
  publicSaleIsActive = publicSaleEnabled;
  }

  function publicSalePriceSet(uint256 _newPublicSalePrice) public onlyOwner() {
    publicSalePrice = _newPublicSalePrice;
  }

  function publicMaxMintAmountSet(uint256 _newmaxPublicSaleMintAmount) public onlyOwner() {
    maxSupply = _newmaxPublicSaleMintAmount;
  }

  // URI control
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  // Other control
  function reserve() public onlyOwner {
  uint supply = totalSupply();
  uint i;
  for (i = 1; i < 20; i++) {
      _safeMint(msg.sender, supply + i);
      }
  }

  //function setProvenance(string memory provenance) public onlyOwner {
  //    PROVENANCE = provenance;
  //}
  // Does this allow randomization of token minting process?

  // Withdraw control
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}