pragma Solidity ^0.8.0;

import ReentrancyGuard from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Escrow is ReentrancyGuard {
    address public escAcc;
    uint256 public escBal;
    uint256 public escAvailBal;
    uint256 public escLockedBal;
    uint256 public escTotalBal;
    uint256 public escTotalDeposits;
    uint256 public escTotalWithdrawals;
    uint256 public escTotalTransfers;
    uint256 public totalItems = 0;
    uint256 public totalOrders = 0;
    uint256 public totalConfirmed = 0;
    uint256 public totalDisputed = 0;
    uint256 public totalCancelled = 0;
    uint256 public totalCompleted = 0;
    uint256 public totalRefunded = 0;
    uint256 public totalFees = 0;
    uint256 public totalEscrow = 0;

    mapping(uint256 => ItemStruct) private items;
    mapping(uint256 => ItemStruct[]) private itemsOf;
    mapping(uint256 => ItemStruct[]) private itemsOfSeller;
    mapping(uint256 => ItemStruct[]) private itemsOfBuyer;
    mapping(uint256 => ItemStruct[]) private itemsOfEscrowAcc;
    mapping(address => mapping(uint256 => bool)) public requested;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => Available) public isAvailable;

    enum status {OPEN, CREATED, PENDING, CONFIRMED, DELIVERY, CONFIRMED, DISPUTED, WITHDRED, CANCELLED, COMPLETED, REFUNDED}

    enum Available {YES, NO}

    struct Item {
        uint256 itemId;
        uint256 orderId;
        uint256 price;
        uint256 quantity;
        uint256 total;
        uint256 fee;
        uint256 escrow;
        uint256 status;
        uint256 timestamp;
        address payable seller;
        address payable buyer;
        address payable escrowAcc;
        address payable feeAcc;
        address payable refundAcc;
        string item;
        string description;
        string metadata;
        string image;
        string category;
        string album;
        string tags;
        string statusMsg;
    }
//EVENTS
    event Action (
        uint256 itemId,
        string actionType,
        Status status,
        address indexed executor
    );
    constructor(uint256 _escFee) {
        escAcc = msg.sender;
        escBal = 0;
        escAvailBal = 0;
        escFee = _escFee;
    }
    function createItem(
        string calldata purpose 
    ) payable external returns (bool) {
        require(bytes(purpose).length > 0, "Purpose must be provided");
        require(msg.value > 0, "Item cannot be zero ethers");

        uint256 itemId = totalItems + 1;
        ItemStruct storage item = items[itemId];
        item.itemId = itemId;
        item.purpose = purpose;
        item.amount = msg.value;
        item.status = Status.OPEN;

        itemsOf[msg.sender].push(item);
        ownerOf[itemId] = msg.sender;
        isAvailable[itemId] = Available.YES;
        escBal += msg.value;

        emit Action(itemId, "Item Created", Status.OPEN, msg.sender);
        return true;
    }
    function getItem(uint256 itemId) external view returns (ItemStruct memory) {
        require(itemId > 0 && itemId <= totalItems, "Item does not exist");
        return items[itemId];
    }
    function getItems(uint256 offset, uint256 limit) external view returns (ItemStruct[] memory) {
        require(offset >= 0 && limit > 0, "Invalid offset or limit");
        uint256 length = itemsOf[msg.sender].length;
        if (offset > length) return new ItemStruct[](0);
        uint256 size = offset + limit;
        if (size > length) size = length;
        ItemStruct[] memory result = new ItemStruct[](size - offset);
        for (uint256 i = offset; i < size; i++) {
            result[i - offset] = itemsOf[msg.sender][i];
        }
        return result;
    }
    function getItemsOfSeller(address seller, uint256 offset, uint256 limit) external view returns (ItemStruct[] memory) {
        require(offset >= 0 && limit > 0, "Invalid offset or limit");
        uint256 length = itemsOfSeller[seller].length;
        if (offset > length) return new ItemStruct[](0);
        uint256 size = offset + limit;
        if (size > length) size = length;
        ItemStruct[] memory result = new ItemStruct[](size - offset);
        for (uint256 i = offset; i < size; i++) {
            result[i - offset] = itemsOfSeller[seller][i];
        }
        return result;
    }
    function getItemsOfBuyer(address buyer, uint256 offset, uint256 limit) external view returns (ItemStruct[] memory) {
        require(offset >= 0 && limit > 0, "Invalid offset or limit");
        uint256 length = itemsOfBuyer[buyer].length;
        if (offset > length) return new ItemStruct[](0);
        uint256 size = offset + limit;
        if (size > length) size = length;
        ItemStruct[] memory result = new ItemStruct[](size - offset);
        for (uint256 i = offset; i < size; i++) {
            result[i - offset] = itemsOfBuyer[buyer][i];
        }
        return result;
    }
    function myItems()
    external
    view 
    returns (ItemStruct[] memory) {
        return itemsOf[msg.sender];
    }
    function requestItem(uint256 itemId) external returns (bool) {
        require(itemId > 0 && itemId <= totalItems, "Item does not exist");
        require(isAvailable[itemId] == Available.YES, "Item is not available");
        require(requested[msg.sender][itemId] == false, "Item already requested");
        ItemStruct storage item = items[itemId];
        require(item.status == Status.OPEN, "Item is not available");
        item.status = Status.PENDING;
        requested[msg.sender][itemId] = true;
        itemsOfBuyer[msg.sender].push(item);
        emit Action(itemId, "Item Requested", Status.PENDING, msg.sender);
        return true;
    }
    function approveItem(uint256 itemId) external returns (bool) {
        require(itemId > 0 && itemId <= totalItems, "Item does not exist");
        require(isAvailable[itemId] == Available.YES, "Item is not available");
        ItemStruct storage item = items[itemId];
        require(item.status == Status.PENDING, "Item is not available");
        require(ownerOf[itemId] == msg.sender, "Only owner can approve");
        item.status = Status.CONFIRMED;
        isAvailable[itemId] = Available.NO;
        itemsOfEscrowAcc[msg.sender].push(item);
        emit Action(itemId, "Item Approved", Status.CONFIRMED, msg.sender);
        return true;
    }
    function rejectItem(uint256 itemId) external returns (bool) {
        require(itemId > 0 && itemId <= totalItems, "Item does not exist");
        require(isAvailable[itemId] == Available.YES, "Item is not available");
        ItemStruct storage item = items[itemId];
        require(item.status == Status.PENDING, "Item is not available");
        require(ownerOf[itemId] == msg.sender, "Only owner can reject");
        item.status = Status.OPEN;
        isAvailable[itemId] = Available.YES;
        requested[msg.sender][itemId] = false;
        emit Action(itemId, "Item Rejected", Status.OPEN, msg.sender);
        return true;
    }
    function cancelItem(uint256 itemId) external returns (bool) {
        require(itemId > 0 && itemId <= totalItems, "Item does not exist");
        require(isAvailable[itemId] == Available.YES, "Item is not available");
        ItemStruct storage item = items[itemId];
        require(item.status == Status.OPEN, "Item is not available");
        require(ownerOf[itemId] == msg.sender, "Only owner can cancel");
        item.status = Status.CANCELLED;
        isAvailable[itemId] = Available.NO;
        requested[msg.sender][itemId] = false;
        emit Action(itemId, "Item Cancelled", Status.CANCELLED, msg.sender);
        return true;
    }
    function performDelivery(uint256 itemId) external returns (bool) {
        require(msg.sender == items[itemsId].provider, "Service not awarded to you");
        require(!items[itemsId].status == Status.CONFIRMED, "Service not confirmed");
        require(!items[itemsId].delivered, "Service already delivered");

        items[itemsId].delivered = true;
        items[itemsId].status = Status.DELIVERY;
        emit Action(itemsId, "Service Delivered", Status.CONFIRMED, msg.sender);

        return true;
    }
    function performDelivery(uint256 itemId) external returns (bool) {
        require(msg.sender == items[itemsId].provider, "Service not awarded to you");
        require(!items[itemsId].status == Status.CONFIRMED, "Service not confirmed");
        require(!items[itemsId].delivered, "Service already delivered");

        items[itemsId].delivered = true;
        items[itemsId].status = Status.DELIVERY;
        emit Action(itemsId, "Service Delivered", Status.CONFIRMED, msg.sender);

        return true;
    }
    function confirmDelivery(uint256 itemId, bool provided) external returns (bool) {
        require(msg.sender == ownerOf[itemsId], "Only owner can confirm");
        require(items[itemsId].status == Status.DELIVERY, "Service not delivered");
        require(items[itemsId].status != Status.REFUNDED, " already refunded, CREATE A NEW Item");

        if(provided) {
            uint256 fee = items[itemsId].price * 10 / 100;
            payTo(items[itemsId].provider, items[itemsId].price - fee);
            escBal -= fee;

            items[itemsId].status = Status.COMPLETED;
            items[itemsId].confirmed = true;
            totalItemsCompleted++;
        }else {
            items[itemsId].status = status.DISPUTED;
        }
        emit Action(itemsId, "Service Confirmed", items[itemsId].status, msg.sender);
        return true;
    }
    function refundItem(uint256 itemId) external returns (bool) {
        require(itemId > 0 && itemId <= totalItems, "Item does not exist");
        require(isAvailable[itemId] == Available.NO, "Item is not available");

        payTo(items[itemsId].provider, items[itemsId].price);
        escBal -= items[itemsId].price;
        items[itemsId].status = Status.REFUNDED;
        totalDisputedItems++;
        ItemStruct storage item = items[itemId];
        require(item.status == Status.CONFIRMED, "Item is not available");
        require(ownerOf[itemId] == msg.sender, "Only owner can refund");
        item.status = Status.REFUNDED;
        isAvailable[itemId] = Available.YES;
        requested[msg.sender][itemId] = false;
        emit Action(itemId, "Item Refunded", Status.REFUNDED, msg.sender);
        return true;
    }  
    function withdrawFund(
    address to, uint256 amount
    ) external returns (bool) {
    require(msg.sender == escrowAcc, "Only escrow account can withdraw");
    require(escBal >= amount, "Insufficient balance");
    escBal -= amount;
    payable(to).transfer(amount);
    emit FundWithdrawn(block.timestamp, "WITHDRAWED", Status.WITHDRAWED, msg.sender, amount);
    return true;
    }
    function payTo(address to, uint256 amount) internal returns (bool) {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed.");
        return true;
    }
    function getItemsOfBuyer(address buyer) external view returns (ItemStruct[] memory) {
        return itemsOfBuyer[buyer];
    }
    function getItemsOfEscrowAcc(address escrowAcc) external view returns (ItemStruct[] memory) {
        return itemsOfEscrowAcc[escrowAcc];
    }
    function getItemsOfProvider(address provider) external view returns (ItemStruct[] memory) {
        return itemsOfProvider[provider];
    }
    function getItemsOfOwner(address owner) external view returns (ItemStruct[] memory) {
        return itemsOfOwner[owner];
    }
}