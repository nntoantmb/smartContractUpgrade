// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

interface IWMATIC is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

interface IWhileListUser {
    function isWhiteList(address user) external returns (bool);
}

contract MarketUpgradeable is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable{
  using CountersUpgradeable for CountersUpgradeable.Counter;
  CountersUpgradeable.Counter private _itemIds;
  CountersUpgradeable.Counter private _itemsSold;

  address walletFeeAddress;
  uint256 listingPrice;
  IWMATIC public wmatic;
  IWhileListUser public contractWhiteList;

  // /**
  //   * @notice Constructor
  //   * @param _wmatic: address of token wrap wmatic
  //   * @param _whiteListAddress: address of while list contract
  // */
  // constructor(IWMATIC _wmatic, IWhileListUser _whiteListAddress) {
  //   walletFeeAddress = msg.sender;
  //   wmatic = _wmatic;
  //   contractWhiteList = _whiteListAddress;
  // }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize() initializer public {
    __Ownable_init();
    __UUPSUpgradeable_init();
    __ReentrancyGuard_init();
  }

  struct MarketItem {
    uint itemId;
    address nftContract;
    uint256 tokenId;
    address seller;
    address owner;
    uint256 price;
    bool sold;
    bool canceled;
  }

  mapping(uint256 => MarketItem) private idToMarketItem;

  uint8 constant LISTING = 0; 
  uint8 constant BUY_NFT = 1; 
  uint8 constant CANCEL_SALE = 2; 
  uint8 constant CHANGE_PRICE = 3; 

  struct HistoryTransaction {
    uint8 typeTransaction; // 0: listing; 1: buyNFT; 2: cancelSale
    address sender;
    address receiver;
    uint256 price;
    uint256 time;
  }

  mapping(uint256 => mapping(uint256 => HistoryTransaction)) public historyTransaction;
  mapping(uint256 => uint256) public countHistory;

  event MarketItemCreated (
    uint indexed itemId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address owner,
    uint256 price,
    bool sold,
    bool canceled
  );

  event MaketItemSaled (
    uint indexed itemId,
    uint256 tokenId,
    address buyer,
    uint256 price
  );

  event ChangeItemPrice (
    uint itemId,
    uint256 tokenId,
    uint256 newPrice
  );

  event CacnelMaketItem (
    uint itemId,
    uint256 tokenId,
    address owner
  );

  function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
  {}

  // custom
  function version() pure public virtual returns(string memory){
    return 'V1';
  }


  /** 
    * set new address receiver fee listing
    * @param _walletFeeAddress: wallet receive fee 
  */
  function setAddressFee(address _walletFeeAddress) external{
    walletFeeAddress = _walletFeeAddress;
  }

  /** 
    * set new matic address
    * @param _wmaticAddress: matic address
  */
  function setTokenSale(IWMATIC _wmaticAddress) external{
    wmatic = _wmaticAddress;
  }

  /** 
    * set new white list contract address
    * @param _whiteListAddress: new white list contract address
  */
  function setWhiteListAddress(IWhileListUser _whiteListAddress) external {
    contractWhiteList = _whiteListAddress;
  }

  /* Returns the listing price of the contract */
  function getListingPrice() public view returns (uint256) {
    return listingPrice;
  }

  /** 
    * set new listing fee
    * @param _newlistingPrice: set new listing fee
  */
  function setNewListingFee(uint256 _newlistingPrice) external onlyOwner {
    listingPrice = _newlistingPrice;
  }

  /** 
    * Places an item for sale on the marketplace
    * @param nftContract: contract address of nft
    * @param tokenId: token need sale
    * @param price: price of nft
  */
  function createMarketItem(
    address nftContract,
    uint256 tokenId,
    uint256 price
  ) external payable nonReentrant {
    require(contractWhiteList.isWhiteList(msg.sender), "user is not in white list");
    require(price > 0, "Price must be at least 1 wei");
    require(msg.value == listingPrice, "Price must be equal to listing price");
    require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "ERC721: transfer from incorrect owner");

    _itemIds.increment();
    uint256 itemId = _itemIds.current();
    uint256 countTransaction = countHistory[tokenId];
  
    wmatic.deposit{value: msg.value}(); // convert to erc20 (wmatic)
    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

    idToMarketItem[itemId] =  MarketItem(
      itemId,
      nftContract,
      tokenId,
      msg.sender,
      address(0),
      price,
      false,
      false
    );

    historyTransaction[tokenId][countTransaction] = HistoryTransaction(
      LISTING,
      msg.sender,
      address(0),
      price,
      block.timestamp
    );
    countHistory[tokenId] += 1;

    emit MarketItemCreated(
      itemId,
      nftContract,
      tokenId,
      msg.sender,
      address(0),
      price,
      false,
      false
    );
  }

  /** 
    * Creates the sale of a marketplace item 
    * Transfers ownership of the item, as well as funds between parties
    * @param itemId: id of market item
  */
  function createMarketSale(
    uint256 itemId
  ) external payable nonReentrant {
    require(contractWhiteList.isWhiteList(msg.sender), "user is not in white list");
    MarketItem memory marketItemData = idToMarketItem[itemId];
    uint256 countTransaction = countHistory[marketItemData.tokenId];

    require(msg.value == marketItemData.price, "Please submit the asking price in order to complete the purchase");
    require(marketItemData.seller != msg.sender, "cannot buy from owner of item");
    require(!marketItemData.sold, "item is sold");
    require(!marketItemData.canceled, "item is canceled");

    // marketItemData.seller.transfer(msg.value);
    wmatic.deposit{value: msg.value}(); // convert to erc20 (wmatic)
    wmatic.transfer(marketItemData.seller, msg.value);
    wmatic.transfer(walletFeeAddress, listingPrice);
    IERC721(marketItemData.nftContract).transferFrom(address(this), msg.sender, marketItemData.tokenId);
    
    idToMarketItem[itemId].owner = payable(msg.sender);
    idToMarketItem[itemId].sold = true;
    _itemsSold.increment();

    historyTransaction[marketItemData.tokenId][countTransaction] = HistoryTransaction(
      BUY_NFT,
      marketItemData.seller,
      msg.sender,
      marketItemData.price,
      block.timestamp
    );
    countHistory[marketItemData.tokenId] += 1;

    emit MaketItemSaled(
      itemId, 
      idToMarketItem[itemId].tokenId,
      msg.sender, 
      msg.value
    );
  }
  
  /** 
    * change price of market item
    * @param itemId: id of market item
    * @param newPrice: new price of item
  */
  function changeItemPrice(uint256 itemId, uint256 newPrice) external nonReentrant {
    MarketItem memory marketItemData = idToMarketItem[itemId];
    uint256 countTransaction = countHistory[marketItemData.tokenId];

    require(contractWhiteList.isWhiteList(msg.sender), "user is not in white list");
    require(marketItemData.price != newPrice, "New price The new price must not be the same as the old price");
    require(marketItemData.seller == msg.sender, "change price from incorrect owner");
    require(!marketItemData.sold, "item is sold");
    require(!marketItemData.canceled, "item is canceled");

    idToMarketItem[itemId].price = newPrice;

    historyTransaction[marketItemData.tokenId][countTransaction] = HistoryTransaction(
      CHANGE_PRICE,
      address(0),
      address(0),
      newPrice,
      block.timestamp
    );
    countHistory[marketItemData.tokenId] += 1;

    emit ChangeItemPrice(
      itemId, 
      idToMarketItem[itemId].tokenId,
      newPrice
    );
  }

  /** 
    * cancel market item
    * @param itemId: id of market item
  */
  function cancelMaketItem(uint256 itemId) external nonReentrant {
    MarketItem memory marketItemData = idToMarketItem[itemId];
    uint256 countTransaction = countHistory[marketItemData.tokenId];

    require(contractWhiteList.isWhiteList(msg.sender), "user is not in white list");
    require(marketItemData.seller == msg.sender, "cancel item from incorrect owner");
    require(!marketItemData.sold, "item is sold");
    require(!marketItemData.canceled, "item is canceled");

    idToMarketItem[itemId].canceled = true;
    IERC721(marketItemData.nftContract).transferFrom(address(this), msg.sender, marketItemData.tokenId);

    historyTransaction[marketItemData.tokenId][countTransaction] = HistoryTransaction(
      CHANGE_PRICE,
      address(0),
      address(0),
      marketItemData.price,
      block.timestamp
    );
    countHistory[marketItemData.tokenId] += 1;

    emit CacnelMaketItem(itemId, idToMarketItem[itemId].tokenId, marketItemData.seller);
  }

  /** 
    * get information of market item
    * @param itemId: id of market item
  */
  function getInforMarketItem(uint256 itemId) external view returns (MarketItem memory) {
    MarketItem memory marketItemData = idToMarketItem[itemId];
    return marketItemData;
  }

  /** 
    * get history transaction
    * @param tokenId: tokenId of nft
    * @param count: history transaction
  */
  function getHistoryTransaction(uint256 tokenId, uint256 count) external view returns (HistoryTransaction memory) {
    HistoryTransaction memory history = historyTransaction[tokenId][count];
    return history;
  }

  /** 
    * get itemId current
  */
  function getItemIdCurrent() external view returns (uint) {
    return _itemIds.current();
  }

  /** 
  * get length item sale
  */
  function getLengthItemSale() external view returns (uint) {
    return _itemIds.current() - _itemsSold.current();
  }

  /** 
    * get history count of tokenId
    * @param tokenId: tokenId of nft
  */
  function getCountHistoryOfTokenId( uint256 tokenId) external view returns (uint256) {
    return countHistory[tokenId];
  }

  /** 
    * Get all item market sale
    * @param limit: limit get infor nft
    * @param offset: offset
  */
  function fetchAllDataMarketItems(uint limit, uint offset) public view returns (MarketItem[] memory) {
    require(offset > 0, "offset must be bigger than zero");
    uint currentIndex = (offset - 1) * limit;
    uint itemCount;
    if (_itemIds.current() > currentIndex + limit) {
      itemCount = currentIndex + limit;
    } else {
      itemCount = _itemIds.current();
    }
    uint limitOffset = itemCount - currentIndex;
    if (offset == 1) limitOffset - 1;

    MarketItem[] memory items = new MarketItem[](limitOffset);

    uint index = 0;
    for (uint itemId = currentIndex; itemId < itemCount; itemId++) {
      if (itemId == 0) continue;
      items[index] = idToMarketItem[itemId];
      index += 1;
    }
    return items;
  }

  /** 
    * Get history of tokenId
    * @param limit: limit get infor nft
    * @param offset: offset
    * @param tokenId: tokenId of nft
  */
  function fetchAllHistoryOfTokenId(uint limit, uint offset, uint tokenId) public view returns (HistoryTransaction[] memory) {
    require(offset > 0, "offset must be bigger than zero");
    uint256 countTransaction = countHistory[tokenId];

    uint currentIndex = (offset - 1) * limit;
    uint transactionCount;
    if (countTransaction > currentIndex + limit) {
      transactionCount = currentIndex + limit;
    } else {
      transactionCount = countTransaction;
    }
    uint limitOffset = transactionCount - currentIndex;
    HistoryTransaction[] memory history = new HistoryTransaction[](limitOffset);

    uint index = 0;
    for (uint indexTransaction = currentIndex; indexTransaction < transactionCount; indexTransaction++) {
      history[index] = historyTransaction[tokenId][indexTransaction];
      index += 1;
    }
    return history;
  }


  /* Returns all unsold market items */
  function fetchMarketItems() public view returns (MarketItem[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
    uint currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    for (uint i = 0; i < itemCount; i++) {
      if (idToMarketItem[i + 1].owner == address(0)) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* Returns onlyl items that a user has purchased */
  function fetchMyNFTs() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* Returns only items a user has created */
  function fetchItemsCreated() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == msg.sender) {
        itemCount += 1; 
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == msg.sender) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }
  
}