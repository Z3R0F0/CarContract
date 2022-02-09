// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

contract CarShop {

    address public owner;
    mapping (address => uint) public balances;
    bytes32 secretHash;     
    bytes32 sellerHash;     

    constructor() payable {
    sellState = SellState.Closed;
    owner = msg.sender;
    balances[address(this)] = 0;
}
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

     modifier onlySeller {
        require(msg.sender == car.seller);
        _;
    }

    function changeOwner(address _owner) onlyOwner public {
        owner = _owner;
    }

      uint constant _percent = 10;

    function refill(uint amount) public {
    require(msg.sender == owner, "Only the owner can refill.");
    balances[address(this)] += amount;
}

    struct Car { 
        address seller;   
        uint cost;           
  }

    enum SellState {
        Open,
        waitAccept,
        Closed
    }

    modifier inState(SellState _state) {
    require(sellState == _state);
    _;
  }

    SellState sellState;  

    Car car;

    function addCar(address sellerAdress, uint cost) public payable onlyOwner inState(SellState.Closed){
    sellState = SellState.Open;
    car = Car({
        seller: sellerAdress,
        cost: cost
    });
    }

    function sellerHashAdd(bytes32 sha256Hash) external inState(SellState.waitAccept) { //waitAccept state required
        sellerHash = sha256Hash;
    }

    function getBalance() public view onlyOwner returns(uint)  {
        return balances[address(this)];       
    } 

    function deposit(uint newDeposit) public payable {
        balances[address(owner)] += newDeposit;
    }

    function buyProduct(bytes32 sha256Hash) external payable inState(SellState.Open) {
    require(msg.sender != owner && msg.sender != car.seller);
    require(msg.value >= car.cost);

    sellState = SellState.waitAccept;
    emit BuyProduct(msg.sender);
    secretHash = sha256Hash;

    if (msg.value > car.cost) {
      emit ReturnAmount(msg.sender, msg.value - car.cost);
      payable(msg.sender).transfer(msg.value - car.cost);
    }

  }

    function acceptReceive(bytes32 _secret) external onlySeller inState(SellState.waitAccept) {
    require(_secret == secretHash);

    uint commission = (car.cost * _percent) / 100;
    payable(owner).transfer(commission);
    payable(car.seller).transfer(balances[address(this)]);

    sellState = SellState.Closed;
  }

    function consensusAlgorithm (bytes32 carHash, bytes32 customerHash) external {
        require(carHash == sellerHash);
        require(customerHash == secretHash);

        //Two parties either come to an agreement or terminate the deal

        payable(msg.sender).transfer(car.cost);
        sellState = SellState.Closed;

        //TO DO Some optional things... 
    }

    event  BuyProduct(address customer);  
    event ReturnAmount(address customer, uint count);    
  
}
