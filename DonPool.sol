//SPDX-License-Identifier: MIT
pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

import "./Interfaces.sol";
import "./SafeMathUpgradeable.sol";
import "./Events.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    
    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    function initOwner(address owner) internal {
        _owner = owner;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
    
    function isOwner() internal view {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        isOwner();
        _;
    }
    
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IPriceFeed {
    function getPriceinUSD(address tokenAddress) external view returns (uint256);
}

abstract contract PriceFeedUser is Ownable {
    IPriceFeed private priceFeed;

    function initPriceFeed() internal {
        // priceFeed = IPriceFeed(address(0xA6b48Dd14c5BE277B4c576437e64DCCAa7E50278)); // AVAX
        // priceFeed = IPriceFeed(address(0xE6AdC9ceB38258c528e93400f378d7618f5aE14A)); // MATIC
        priceFeed = IPriceFeed(address(0x6926aeb5703e9533B5Dd9AC58A9101622588aDe6)); // BNB
     }

     function setPriceFeed(address _address) public onlyOwner {
         priceFeed = IPriceFeed(_address);
     }
     
     function getPriceFeed() public view returns (IPriceFeed) {
         return priceFeed;
     }
}

interface IReferralSystem {
    function referUserFromCode(string memory code, address referrerAddress, uint256 amountInUSd) external;
    function rewardUser(address referrerAddress, uint256 totalInvestedAmount, 
                            uint256 withdarwRequestedAmount, uint256 rewardAmountInDons) external;
    function getReferredPool(address _poolAddress, address _address) external view returns (address);
    function rewardDelivered(address _address) external view returns (bool);
}

interface IPool {
    function isInvestor(address _investor) external view returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function getUserInvestedAmount(address _investor) external view returns (uint256 amountInToken);
    function getUserInvestedAmountInUSD(address _investor) external view returns (uint256 amountInUSD);
}

abstract contract ReferralSystemUser is Ownable {
     IReferralSystem private referralSystem;
     bool private referralEnabled;

    function initReferralSystem() internal {
        referralSystem = IReferralSystem(0x7e9Aa7Ecb1C2c2C3d0Ed455cE9b86B86a811BBd8);
        referralEnabled = false;
    }

     function setReferralSystem(address _address) public onlyOwner {
        referralSystem= IReferralSystem(_address);
     }
     function getReferralSystem() public view returns (IReferralSystem) {
        return referralSystem;
     }
     function isReferralEnabled() public view returns (bool){
        return referralEnabled;
     }
     function setReferralEnabled(bool isEnabled) public onlyOwner {
        referralEnabled = isEnabled;
     }
}

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}


contract Pool is Ownable, Events, PriceFeedUser, ReferralSystemUser, Initializable {
    
    using SafeMathUpgradeable for uint256;
    mapping (address => InvestmentDetails) private investorInfo;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    
    uint256 public _totalSupply;
    uint8 public _decimals;
    string public _symbol;
    string public _name;

    
    address private tokenAddress;
    address private teamAddress;
    address private cronAddress;
    address private donStakingAddress;
    IDonStaking private donStaking;

    uint256 private totalInvestedAmount;
    uint256 private totalInvestedAmountInUSD;
    address public farmerAddress;
    address public adminAddress;
    
    uint256 private greyInvestorCount;
    address[] private greyInvestor;
    uint256 private totalGreyInvestedAmount;
    uint256 private totalGreyInvestedAmountInUSD;
    mapping (address => InvestmentDetails) greyInvestorAmount;
    
    uint256 private greyWithdrawalCount;
    address[] private greyWithdrawal;
    uint256 private totalGreyWithdrawAmount;
    uint256 private totalGreyWithdrawLPAmount;
    mapping (address => WithdrawalDetails) private withdrawalRequested;
    mapping (address => bool) public isUserMigrated;
    address public oldPoolAddress;

    uint256 private uniqueInvestorCount;
    uint256 public totalPoolValue;
    uint256 private oldTotalPoolValue;
    uint256 private greyWithdarwalPoolValue;
    uint256 private investedCounter;

    uint16 private FARMER_REWARD;
    uint16 private TEAM_REWARD;

    bool internal locked;
    bool internal _paused;
    bool internal _withdrawPaused;
    
    struct WithdrawalDetails {
        bool requested;
        uint256 amountInToken;
        uint256 amountInUSD;
        uint256 amountInLP;
        uint256 approxProfit;
    }

    struct InvestmentDetails {
        bool invested;
        uint256 investedAmountInToken;
        uint256 investedAmountInUSD;
    }


    constructor() public {
    }

    /**
     * @dev sets initials supply and the owner
     */
    function initialize(address _owner, address _farmer, address _admin) public initializer {
        _name = 'Don-pool';
        _symbol = 'DPL';
        _decimals = 18;
        _totalSupply = 0;
        farmerAddress = address(_farmer);
        adminAddress = address(_admin);
        
        initOwner(_owner);
        initPriceFeed();
        initReferralSystem();

        // tokenAddress = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7); //WAVAX
        // tokenAddress = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270); // WMATIC
        // tokenAddress = address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82); // CAKE
        tokenAddress = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // BUSD
        // tokenAddress = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c); // WBNB
        teamAddress = address(0x8345F3AFa13a2ACC4fCd55A173eA21078aD958e8);
        cronAddress = address(0x7FF1F8C467114BfBbCC56E406c0Ec21E781bB959);
        donStakingAddress = address(0x8d40C8a9F4bD8D23a244cEc57b20B7f8f43C5e0d);
        donStaking = IDonStaking(donStakingAddress);

        FARMER_REWARD = 500; // 5% of profit here mutlipler is 100
        TEAM_REWARD = 500; // 5% of profit  here mutlipler is 100
    }


    /* Modifiers can be called before and / or after a function.
    * This modifier prevents a function from being called while
    * it is still executing.
    */
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        isAdmin();
        _;
    }

    
    /* Modifiers can take inputs. This modifier checks that the
     * address passed in is not the zero address.
     */
    modifier validAddress(address _addr) {
        isValidAddress(_addr);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    *
    * Requirements:
    *
    * - The contract must not be paused.
    */
    modifier whenNotPaused() {
        require(!paused(), "Pool: paused");
        _;
    }

    modifier whenNotWithdrawPaused() {
        require(!withdrawPaused(), "Pool: Withdraw paused");
        _;
    }
    
    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    *
    * Requirements:
    *
    * - The contract must be paused.
    */
    modifier whenPaused() {
        require(paused(), "Pool: not paused");
        _;
    }

    modifier whenWithdrawPaused() {
        require(withdrawPaused(), "Pool: Withdraw not paused");
        _;
    }

    function isValidAddress(address _address) internal pure {
        require(_address != address(0), "Not valid address");
    }
    
    function isAdmin() internal view {
        require(adminAddress == _msgSender(), "Pool: caller is not the admin");
    }
    /**
    * @dev Returns the bep token owner.
    */
    function getOwner() public view returns (address) {
        return owner();
    }
    
    /**
    * @dev Returns the token decimals.
    */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    /**
    * @dev Returns the token symbol.
    */
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    /**
    * @dev Returns the token name.
    */
    function name() public view returns (string memory) {
        return _name;
    }
    
    /**
    * @dev See {BEP20-totalSupply}.
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    /**
    * @dev See {BEP20-balanceOf}.
    */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    /**
    * @dev Returns true if the contract is paused, and false otherwise.
    */
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    
    function withdrawPaused() public view virtual returns (bool) {
        return _withdrawPaused;
    }

    /**
    * @dev See {BEP20-transfer}.
    *
    * Requirements:
    *
    * - `recipient` cannot be the zero address.
    * - the caller must have a balance of at least `amount`.
    */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    /**
    * @dev See {BEP20-allowance}.
    */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    /**
    * @dev See {BEP20-approve}.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    /**
    * @dev See {BEP20-transferFrom}.
    *
    * Emits an {Approval} event indicating the updated allowance. This is not
    * required by the EIP. See the note at the beginning of {BEP20};
    *
    * Requirements:
    * - `sender` and `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    * - the caller must have allowance for `sender`'s tokens of at least
    * `amount`.
    */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }
    
    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() public whenNotPaused {
    
        require (owner() == _msgSender() ||
                cronAddress == _msgSender(),
                'Pool: Invalid Operation'
        );
    
        _paused = true;
        emit Paused(_msgSender());
    }
    
    function _withdrawPause() public whenNotWithdrawPaused {
    
        require (owner() == _msgSender() ||
                cronAddress == _msgSender(),
                'Pool: Invalid Operation'
        );
    
        _withdrawPaused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() public whenPaused {
    
        require (owner() == _msgSender() ||
                cronAddress == _msgSender(),
                'Pool: Invalid Operation'
        );
        _paused = false;
        emit Unpaused(_msgSender());
    }
    
    function _withdrawUnpause() public whenWithdrawPaused {
    
        require (owner() == _msgSender() ||
                cronAddress == _msgSender(),
                'Pool: Invalid Operation'
        );
        _withdrawPaused = false;
        emit Unpaused(_msgSender());
    }
    /**
    * @dev Moves tokens `amount` from `sender` to `recipient`.
    *
    * This is internal function is equivalent to {transfer}, and can be used to
    * e.g. implement automatic token fees, slashing mechanisms, etc.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - `sender` cannot be the zero address.
    * - `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
    * the total supply.
    *
    * Emits a {Transfer} event with `from` set to the zero address.
    *
    * Requirements
    *
    * - `to` cannot be the zero address.
    */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");
        
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    /**
    * @dev Destroys `amount` tokens from `account`, reducing the
    * total supply.
    *
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * Requirements
    *
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");
        
        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    /**
    * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
    *
    * This is internal function is equivalent to `approve`, and can be used to
    * e.g. set automatic allowances for certain subsystems, etc.
    *
    * Emits an {Approval} event.
    *
    * Requirements:
    *
    * - `owner` cannot be the zero address.
    * - `spender` cannot be the zero address.
    */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    /***** View Functions *****/
    
    /**
     * @dev Get cron Address of the pool
     * NOTE: None
    **/
    function getCronAddress()
        external view
        returns (address)
    {
        return cronAddress;
    }
    
    /**
     * @dev Get donStaking Address of the pool
     * NOTE: None
    **/
    function getDonStakingAddress()
        external view
        returns (address)
    {
        return donStakingAddress;
    }

    /**
     * @dev Get Investor Status of the pool
     * @param _investor Investor address
     * NOTE: None
    **/
    function isInvestor(
        address _investor
    )
        external view
        validAddress(_investor)
        returns (bool)
    {
        return (((balanceOf(_investor) > 0)  && investorInfo[_investor].invested) ||
                    (greyInvestorAmount[_investor].investedAmountInToken > 0));
    }
    
    /**
     * @dev get withdraw status of investor
     * NOTE: None
    **/
    function isWithdrawalRequested(
        address _investor
    )
        external view
        validAddress(_investor)
        returns (bool)
    {
        return withdrawalRequested[_investor].requested;
    }

    /**
     * @dev get farmer reward fee amount in percentage
     * NOTE: None
    **/
    function getFarmerRewardFee()
        public view
        returns (uint256)
    {
        return FARMER_REWARD;
    }


    /**
     * @dev get TEAM reward fee amount in percentage
     * NOTE: None
    **/
    function getTeamRewardFee()
        public view
        returns (uint256)
    {
        return TEAM_REWARD;
    }

    /**
     * @dev get user total invested amount in token including grey amount
     * @param _investor investor address
     * NOTE: None
    **/    
    function getUserInvestedAmount(
        address _investor
    )
        external view
        validAddress(_investor)
        returns (uint256 amountInToken)
    {
        amountInToken = investorInfo[_investor].investedAmountInToken
                            .add(greyInvestorAmount[_investor].investedAmountInToken);
    }

    /**
     * @dev get user total invested amount in USD including grey amount
     * @param _investor investor address
     * NOTE: None
    **/
    function getUserInvestedAmountInUSD(
        address _investor
    )
        external view 
        validAddress(_investor)
        returns (uint256 amountInUSD) 
    {
        amountInUSD = investorInfo[_investor].investedAmountInUSD
                            .add(greyInvestorAmount[_investor].investedAmountInUSD);
    }                       
    
    /**
     * @dev get user grey invested amount in token and USD
     * @param _investor investor address
     * NOTE: None
    **/
    function getUserGreyInvestedAmount(
        address _investor
    )
        external view
        validAddress(_investor)
        returns (uint256 amountInToken, uint256 amountInUsd)
    {
        amountInToken = greyInvestorAmount[_investor].investedAmountInToken;
        amountInUsd = greyInvestorAmount[_investor].investedAmountInUSD;
    }
    
    /**
     * @dev get total investor count of pool
     * NOTE: None
    **/
    function getInvestorCount()
        public view
        returns (uint256)
    {
        return uniqueInvestorCount;
    }

    /**
     * @dev get total invested amount in token of pool
     * NOTE: None
    **/
    function getTotalInvestAmount() 
        public view 
        returns (uint256 amountInToken)
    {
        amountInToken =  totalInvestedAmount
                            .add(totalGreyInvestedAmount);
    }

    /**
     * @dev get total invested amount in USD of pool
     * NOTE: None
    **/
    function getTotalInvestAmountInUSD() 
        public view 
        returns (uint256 amountInUSD)
    {
        amountInUSD = totalInvestedAmountInUSD
                            .add(totalGreyInvestedAmountInUSD);
    }
    
    /**
     * @dev get total Grey invested amount in token and USD amount
     * NOTE: None
    **/
    function getTotalGreyInvestAmount() 
        public view 
        returns (uint256 amountInToken, uint256 amountInUSD)
    {
        amountInToken =  totalGreyInvestedAmount;
        amountInUSD = totalGreyInvestedAmountInUSD;
    }

    /**
     * @dev get total Grey withdraw amount in token and LP amount
     * NOTE: None
    **/
    function getTotalGreyWithdrawalAmount() 
        public view 
        returns (uint256 amountInToken, uint256 LPAmount)
    {
        amountInToken =  totalGreyWithdrawAmount;
        LPAmount = totalGreyWithdrawLPAmount;
    }

    /**
     * @dev get total pool value including new invested values
     * NOTE: None
    **/
    function getinvestedAmountWithReward() 
        public view 
        returns (uint256 reward)
        
    {
        reward = totalPoolValue + totalGreyInvestedAmount;
    }

    /**
     * @dev get total pool value in token amount
     * NOTE: None
    **/
    function getTotalPoolValue()
        public view
        returns (uint256)
    {
        return totalPoolValue;   
    }


    /**
     * @dev get token of the pool
     * NOTE: None
    **/
    function getToken() public view returns(IBEP20){
        return IBEP20(tokenAddress);
    }

    /**
     * @dev get grey investor address array
     * NOTE: None
    **/
    function getGreyInvestorList()
        public view
        returns (address[] memory)
    {
        return greyInvestor;
    }

    /**
     * @dev get withdraw request address array
     * NOTE: None
    **/
    function getGreyWithdrawalList()
        public view
        returns (address[] memory)
    {
        return greyWithdrawal;
    }

    /**
     * @dev get new grey investorcount
     * NOTE: None
    **/
    function getGreyInvestorCount()
        public view
        returns (uint256)
    {
        return greyInvestorCount;
    }

    /**
     * @dev get withdraw request count
     * NOTE: None
    **/
    function getGreyWithdrawalCount()
        public view
        returns (uint256)
    {
        return greyWithdrawalCount;
    }

    /**
     * @dev get Investor claimable Amount including
     *       farmer and team share
     * @param _address investor address
     * @param _LPAmountInPer withdrawal amount in percentage
     * NOTE: None
    **/
    function getInvestorClaimableAmount(
        address _address,
        uint256 _LPAmountInPer
    ) 
        public view 
        validAddress(_address)
        returns (uint256 BUSDshare)
    {
        require(_LPAmountInPer <= 10000,
                    '_LPAmountInPer must be less then 100%');
        
        uint256 _LPtokens = balanceOf(_address);
        if(_LPtokens == 0 || _LPAmountInPer == 0)
            return 0;
            
        _LPtokens = _LPtokens.mul(_LPAmountInPer).div(10000);
        BUSDshare = totalPoolValue.mul(_LPtokens).div(_totalSupply);
    }

    /**
     * @dev get Investor final claimable Amount excluding
     *      farmer and team share
     * @param _address investor address
     * @param _LPAmountInPer withdrawal amount in percentage
     * NOTE: None
    **/
    function getFinalClaimableAmount(
        address _address,
        uint256 _LPAmountInPer
    ) 
        public view 
        validAddress(_address)
        returns (uint256 BUSDshare)
    {
        require(_LPAmountInPer <= 10000,
                    '_LPAmountInPer must be less then 100%');
        
        uint256 _LPtokens = balanceOf(_address);
        if(_LPtokens == 0 || _LPAmountInPer == 0)
            return greyInvestorAmount[_address].investedAmountInToken;
        
        uint256 amountInToken = investorInfo[_address].investedAmountInToken.mul(_LPAmountInPer).div(10000);
        _LPtokens = _LPtokens.mul(_LPAmountInPer).div(10000);
        BUSDshare = totalPoolValue.mul(_LPtokens).div(_totalSupply);
        
        uint256 profit = BUSDshare > amountInToken ?
                          BUSDshare - amountInToken :
                          0;
        
        if (profit > 0)
        {
            BUSDshare = BUSDshare.sub(profit.mul(FARMER_REWARD + TEAM_REWARD).div(10000));
        }

        BUSDshare += greyInvestorAmount[_address].investedAmountInToken;
    }
    
    /**
     * @dev get approx derived LP Tokens
     * @param _tokens amount of token to be invested in Pool
     * NOTE: None
    **/
    function calcLPToken(
        uint256 _tokens
    ) 
        public view
        returns (uint256 LPTokenAmount)
    {   
        LPTokenAmount =  (_totalSupply > 0 ) ? 
                        (_tokens.mul(_totalSupply)).div(totalPoolValue) :
                        _tokens;
    }

    /**
     * @dev get withdrawal request details like,
            amountInToken, amountInUSD, amountInLP, etc
     * @param _investor investor address
     * NOTE: None
    **/
    function getWithdrawalReqDetails (
        address _investor
    ) 
        public view
        validAddress(_investor) 
        returns (WithdrawalDetails memory details)
    {
        if (withdrawalRequested[_investor].requested) {
            details = withdrawalRequested[_investor];
        }
    }

    /**
     * @dev get price on token in USD
     * @param _amount amount to token
     * NOTE: None
    **/
    function getPriceinUSD(
        uint256 _amount
    ) 
        internal view 
        returns (uint256) 
    {
        return getPriceFeed().getPriceinUSD(tokenAddress).mul(_amount).div(1 ether);
    }

/********************************************************************** */
    
    /**
     * @dev set/update farmer address
     * @param _farmerAddress new farmer address
     * NOTE: Restricted to owner only
    **/
    function setFarmerAddress(
        address payable _farmerAddress
    )
        external
        validAddress(_farmerAddress)
        onlyOwner
    {
        farmerAddress = address(_farmerAddress);
    }

    /**
     * @dev set/update admin address
     * @param _adminAddress new admin address
     * NOTE: Restricted to owner only
    **/
    function setAdminAddress(
        address payable _adminAddress
    )
        external
        validAddress(_adminAddress)
        onlyOwner
    {
        adminAddress = address(_adminAddress);
    }

    /**
     * @dev set/update team address
     * @param _teamAddress new team address
     * NOTE: Restricted to owner only
    **/
    function setTeamAddress(
        address payable _teamAddress
    )
        external
        validAddress(_teamAddress)
        onlyOwner    
    {
        teamAddress = address(_teamAddress);
    }
    
    /**
     * @dev set/update cron address
     * @param _cronAddress new cron address
     * NOTE: Restricted to owner only
    **/
    function setCronAddress(
        address payable _cronAddress
    )
        external
        validAddress(_cronAddress)
        onlyOwner
    {
        cronAddress = address(_cronAddress);
    }

    /**
     * @dev set/update Pool's token Address
     * @param _address token address
     * NOTE: Restricted to owner only
    **/
    function setTokenAddress(
        address _address
    ) 
        external
        validAddress(_address)
        onlyOwner 
    {
        tokenAddress = _address;
    }
    
    /**
     * @dev set/update old Pool Address to Pool
     * @param _address old Pool address
     * NOTE: Restricted to owner only
    **/
    function setOldPoolAddress(
        address _address
    ) 
        external
        validAddress(_address)
        onlyOwner
    {
        oldPoolAddress = _address;
    }

    /**
     * @dev set/update donStaking Address to Pool
     * @param _donStakingAddress donStaking contract address
     * NOTE: Restricted to owner only
    **/
    function setDonStakingAddress(
        address payable _donStakingAddress
    )
        external
        validAddress(_donStakingAddress)
        onlyOwner
    {
        donStakingAddress = address(_donStakingAddress);
        donStaking = IDonStaking(donStakingAddress);
    }

    /**
     * @dev update farmer reward
     * @param _reward in percentage multiply by 100
     *          example if farmer reward is 10% pass 1000
     * NOTE: Restricted to owner only
    **/
    function updateFarmerReward(
        uint16 _reward
    )
        external
        onlyOwner
    {
        FARMER_REWARD = _reward;
    }
    
    /**
     * @dev update team reward
     * @param _reward in percentage multiply by 100
     *          example if team reward is 5% pass 500
     * NOTE: Restricted to onwer only
    **/
    function updateTeamReward(
        uint16 _reward
    )
        external
        onlyOwner
    {
        TEAM_REWARD = _reward;
    }
    
    /**
     * @dev function to update pool's total Value
     * @param _totalPoolValue new total pool Value
     * NOTE: Restricted to admin only
    **/
    function updateTotalPoolValue(
        uint256 _totalPoolValue
    )
        external
        onlyAdmin
    {
        require(_totalPoolValue > 0,
                    '_totalPoolValue must be non-zero');

        totalPoolValue = _totalPoolValue;
    }

    /**
     * @dev user can deposit/Invest thier Token to the pool using referral code
     * @param _tokenamount amount of token to be invested in Pool
     * @param referralCode referral code of referrer
     * NOTE: None
    **/
    function depositLiquidityWithCode(
        uint256 _tokenamount, 
        string memory referralCode
    )
        external
        whenNotPaused
    {
        uint256 usdValue = getPriceinUSD(_tokenamount);
        getReferralSystem().referUserFromCode(referralCode, _msgSender(),usdValue);
        depositLiquidity(_tokenamount);
    }
    
    /**
     * @dev user can deposit/Invest thier Token to the pool
     * @param _tokens amount of token to be invested in Pool
     * NOTE: None
    **/
    function depositLiquidity(
        uint256 _tokens
    )
        public
        whenNotPaused
        noReentrant
    {
        require(_tokens > 0,
            'POOL: token amount should be nonzero'
        );
        IBEP20 token = getToken();
        require(token.transferFrom(_msgSender(), address(this), _tokens),
            'POOL: Token transfer failed will depositing Token in POOL'
        );
        
        if (greyInvestorAmount[_msgSender()].investedAmountInToken == 0)
        {
            greyInvestorCount++;
            greyInvestor.push(_msgSender());
            if(investorInfo[_msgSender()].investedAmountInToken == 0)
            {
                uniqueInvestorCount++;
            }
        }

        uint256 amountInUSD = getPriceinUSD(_tokens);
        require(amountInUSD > 0, 'failed to get price in USD');
        greyInvestorAmount[_msgSender()].investedAmountInToken += _tokens;
        greyInvestorAmount[_msgSender()].investedAmountInUSD += amountInUSD;
        totalGreyInvestedAmount += _tokens;
        totalGreyInvestedAmountInUSD += amountInUSD;
        donStaking.increaseInvestedAmount(_msgSender(), amountInUSD);

        emit DepositLiquidty(_msgSender(), _tokens, amountInUSD, block.timestamp);
    }

    /**
     * @dev function to assign DON LP token to new investors 
     * @param _totalValue total Pool Value
     * @param _newPoolValue new total Pool Value after investment in farm
     * NOTE: Restricted to admin only
    **/    
    function assignLp(
        uint256 _totalValue,
        uint256 _newPoolValue
    )
        public
        onlyAdmin
    {

        uint256 length = greyInvestor.length;
        require(length != 0,
                "POOL: Nothing to invest");

        for(uint256 i = 0; i < length; i++)
        {
            address investor = greyInvestor[i];
            uint256 amount = greyInvestorAmount[investor].investedAmountInToken;
            uint256 userAmountWithFeeRemoved = amount * (_newPoolValue - _totalValue) / totalGreyInvestedAmount;
            uint256 LPamount =  (_totalSupply > 0 ) ? 
                                (userAmountWithFeeRemoved.mul(_totalSupply)).div(_totalValue) :
                                amount;

            _totalValue += userAmountWithFeeRemoved;
            totalGreyInvestedAmount -= amount;
            _mint(investor,LPamount);

            investorInfo[investor].investedAmountInToken += amount;
            investorInfo[investor].investedAmountInUSD += greyInvestorAmount[investor].investedAmountInUSD;
            totalInvestedAmount += amount;
            totalInvestedAmountInUSD += greyInvestorAmount[investor].investedAmountInUSD;
            investorInfo[investor].invested=true;
            emit LpAssigned(investor, amount, LPamount, block.timestamp);
            delete greyInvestorAmount[investor];
        }

        delete greyInvestor;
        totalGreyInvestedAmount = 0;
        totalGreyInvestedAmountInUSD = 0;
        greyInvestorCount = 0;
        totalPoolValue = _newPoolValue;
        _paused = false;
    }

    /**
     * @dev function to set oldPoolValue and newPoolValue, both value required
            to be set before using assignLpInSeq to assign LP in seq to new
            investor
     * @param _totalValue total Pool Value
     * @param _newPoolValue new total Pool Value after investment in farm
     * NOTE: Restricted to admin only
    **/
    function updatePoolValues(
        uint256 _totalValue,
        uint256 _newPoolValue
    )
        public
        onlyAdmin
    {
        oldTotalPoolValue = _totalValue;
        totalPoolValue = _newPoolValue;
    }
    

    /**
     * @dev function to assign DON LP token to investors in Seq, when number
            investor is increase, and can't assign LP to all user's in single
            transaction.
     * @param count number of new investors to whom LP need to be assign
     * NOTE: Restricted to admin only
    **/    
    function assignLpInSeq(
        uint256 count
    )
        public
        onlyAdmin
    {
        require(greyInvestorCount != 0,
                'Nothing to InvestInSeq');

        if (count > greyInvestorCount) {
            count = greyInvestorCount;
        }

        for(uint256 i = greyInvestorCount; count > 0; i--)
        {
            address investor = greyInvestor[i-1];
            uint256 amount = greyInvestorAmount[investor].investedAmountInToken;
            uint256 userAmountWithFeeRemoved = amount * (totalPoolValue - oldTotalPoolValue) / totalGreyInvestedAmount;
            uint256 LPamount =  (_totalSupply > 0 ) ? 
                                (userAmountWithFeeRemoved.mul(_totalSupply)).div(oldTotalPoolValue) :
                                amount;

            oldTotalPoolValue += userAmountWithFeeRemoved;
            totalGreyInvestedAmount -= amount;
            totalGreyInvestedAmountInUSD -= greyInvestorAmount[investor].investedAmountInUSD;
            _mint(investor,LPamount);

            investorInfo[investor].investedAmountInToken += amount;
            investorInfo[investor].investedAmountInUSD += greyInvestorAmount[investor].investedAmountInUSD;
            totalInvestedAmount += amount;
            totalInvestedAmountInUSD += greyInvestorAmount[investor].investedAmountInUSD;
            investorInfo[investor].invested=true;
            greyInvestorCount--;
            count--;
            emit LpAssigned(investor, amount, LPamount, block.timestamp);
            delete greyInvestorAmount[investor];
        }

        if (greyInvestorCount == 0) {
            delete greyInvestor;
            totalGreyInvestedAmount = 0;
            totalGreyInvestedAmountInUSD = 0;
            _paused = false;
        }
    }
    
    /**
     * @dev function to initate grey withdraw token request
     * @param _amountInPer withdrawal amount in percentage(muliplier of 100)
     * NOTE: None
    **/
    function withdrawGreyLiquidity(
        uint256 _amountInPer
    )
        external
        noReentrant
        whenNotPaused
        returns (uint256)
    {
        require(
            ((greyInvestorAmount[_msgSender()].investedAmountInToken > 0) &&
            (_amountInPer > 0 && _amountInPer <= 10000)),
                "POOL: Invalid Operation, fund is not withdrawable"
        );

        IBEP20 token = getToken();
        uint256 greyTokenShare = greyInvestorAmount[_msgSender()].investedAmountInToken.mul(_amountInPer).div(10000);
        uint256 greyTokenShareInUSD = greyInvestorAmount[_msgSender()].investedAmountInUSD.mul(_amountInPer).div(10000);
        
        require(token.balanceOf(address(this)) >= (greyTokenShare*98)/100, 
                            'pool doesnot have enough balance');

        if (greyTokenShare > token.balanceOf(address(this)))
            greyTokenShare = token.balanceOf(address(this));

        if (greyInvestorAmount[_msgSender()].investedAmountInToken == greyTokenShare) {
            updateGreyInvestorList(_msgSender());
            greyInvestorCount--;
        }
        totalGreyInvestedAmount = totalGreyInvestedAmount.
                                        sub(greyTokenShare);
        totalGreyInvestedAmountInUSD = totalGreyInvestedAmountInUSD.
                                        sub(greyTokenShareInUSD);
        donStaking.decreaseInvestedAmount(_msgSender(), greyTokenShareInUSD);
        greyInvestorAmount[_msgSender()].investedAmountInToken = greyInvestorAmount[_msgSender()].investedAmountInToken
                                                                    .sub(greyTokenShare);
        greyInvestorAmount[_msgSender()].investedAmountInUSD = greyInvestorAmount[_msgSender()].investedAmountInUSD
                                                                    .sub(greyTokenShareInUSD);
        
        if(investorInfo[_msgSender()].investedAmountInToken == 0)
        {
            uniqueInvestorCount--;
            investorInfo[_msgSender()].invested=false;
        }
        

        require(token.transfer(_msgSender(), greyTokenShare));
        emit GreyWithdraw(_msgSender(), _amountInPer, greyTokenShare, greyTokenShareInUSD, block.timestamp);
    }

    /**
     * @dev function to initate withdraw token request
     * @param _amountInPer withdrawal amount in percentage(muliplier of 100)
     * NOTE: None
    **/
    function withdrawLiquidity(
        uint256 _amountInPer
    )
        external
        noReentrant
        whenNotWithdrawPaused
        returns (uint256)
    {
        require(
            (_amountInPer > 0 && _amountInPer <= 10000) && 
            (!withdrawalRequested[_msgSender()].requested && 
                (investorInfo[_msgSender()].investedAmountInToken > 0)),
            "POOL: Invalid Operation, fund is not withdarwable"
        );

        uint256 _LPtokens = balanceOf(_msgSender());
        require(_LPtokens != 0 ,
                    'user Doesnot have enough LP token in his wallet');
        _LPtokens = _LPtokens.mul(_amountInPer).div(10000);

        uint256 withdrawalAmount = investorInfo[_msgSender()].investedAmountInToken.mul(_amountInPer).div(10000);
        uint256 withdrawalAmountInUSD = investorInfo[_msgSender()].investedAmountInUSD.mul(_amountInPer).div(10000);
        uint256 BUSDshare = totalPoolValue.mul(_LPtokens).div(_totalSupply);
        uint256 profit = BUSDshare > withdrawalAmount ?
                          BUSDshare - withdrawalAmount :
                          0;
        profit = profit.sub(profit.mul(FARMER_REWARD + TEAM_REWARD).div(10000));
        greyWithdrawalCount++;
        greyWithdrawal.push(_msgSender());

        withdrawalRequested[_msgSender()].requested = true;
        withdrawalRequested[_msgSender()].amountInToken = withdrawalAmount;
        withdrawalRequested[_msgSender()].amountInUSD = withdrawalAmountInUSD;
        withdrawalRequested[_msgSender()].amountInLP = _LPtokens;
        withdrawalRequested[_msgSender()].approxProfit = profit;

        totalGreyWithdrawAmount += withdrawalAmount;
        totalGreyWithdrawLPAmount += _LPtokens;

        emit WithdrawRequested(_msgSender(), _amountInPer, withdrawalAmount, withdrawalAmountInUSD, profit, block.timestamp);

        return withdrawalAmount;
    }

    /**
     * @dev function to complete withdraw process and send token to user
     * @param _totalWithdrawValue total user requested withdrawal value
     * @param _totalValue total pool value
     * NOTE: Restricted to admin only
    **/
    function withdraw(
        uint256 _totalWithdrawValue,
        uint256 _totalValue
    )
        external
        onlyAdmin
    {
        uint256 length = greyWithdrawal.length;

        require(length != 0,
                "POOL: Nothing to withdraw");

        totalPoolValue = _totalValue;
        greyWithdarwalPoolValue = _totalWithdrawValue;
        for(uint256 i = 0; i < length; i++)
        {
            address investor = greyWithdrawal[i];
            internalWithdraw(investor);
        }
        delete greyWithdrawal;
    }

    /**
     * @dev function to set totalPoolValue and greyWithdarwalPoolValue, both value
            should be updated before calling complete withdraw process and send token 
            to user in seq incase there are to-many request that can't be served 
            in single transcation
     * @param _totalPoolValue total pool value
     * @param _greyWithdarwalPoolValue total user requested withdrawal value 
     * NOTE: Restricted to admin only
    **/
    function setGreyWithdarwalTotalValue(
        uint256 _totalPoolValue,
        uint256 _greyWithdarwalPoolValue
    )
        external
        onlyAdmin
    {
        totalPoolValue = _totalPoolValue;
        greyWithdarwalPoolValue = _greyWithdarwalPoolValue;
    }


    /**
     * @dev function to complete withdraw process and send token to user in seq
            incase there are to-many request that can't be served in single
            transcation
     * @param count withdrawal requested investor count 
     * NOTE: Restricted to admin only
    **/
    function withdrawInSeq(
        uint256 count
    )
        external
        onlyAdmin
    {
        require(greyWithdrawalCount != 0,
                'Nothing to withdarwInSeq');

        if (count > greyWithdrawalCount) {
            count = greyWithdrawalCount;
        }

        for(uint256 i = greyWithdrawalCount; count > 0; i--)
        {
            address investor = greyWithdrawal[i-1];
            internalWithdraw(investor);
            count--;
        }
        
        if(greyWithdrawalCount == 0){
            delete greyWithdrawal;
        }
    }

    /**
     * @dev Internal function to complete withdraw process and send token to user
     * @param investor investor address
     * NOTE: None
    **/    
    function internalWithdraw(
        address investor
    ) 
        internal
    {
        IBEP20 token = getToken();
        uint256 _LPtokens = withdrawalRequested[investor].amountInLP;
        uint256 tokenShare = greyWithdarwalPoolValue.mul(_LPtokens).div(totalGreyWithdrawLPAmount);//getInvestorClaimableAmount(investor);

        require(token.balanceOf(address(this)) > (tokenShare*98)/100, 
                    'pool doesnot have enough balance');

        if (tokenShare > token.balanceOf(address(this)))
            tokenShare = token.balanceOf(address(this));

        _burn(investor, _LPtokens);
        greyWithdarwalPoolValue -= tokenShare;
        totalPoolValue -= tokenShare;
        uint256 profit = tokenShare > withdrawalRequested[investor].amountInToken ?
                        tokenShare - withdrawalRequested[investor].amountInToken :
                        0;
        if (profit > 0)
        {
            if(isReferralEnabled()){
                IReferralSystem  referralSystem = getReferralSystem();
                if(referralSystem.getReferredPool(address(this),investor) == address(this)){
                    uint256 referralRewardinUSD = getPriceinUSD(profit.sub(profit.mul(FARMER_REWARD + TEAM_REWARD).div(10000)));
                    require(referralRewardinUSD > 0, 'failed to get price in USD');
                    referralSystem.rewardUser(investor, investorInfo[investor].investedAmountInUSD, 
                                        withdrawalRequested[investor].amountInUSD, referralRewardinUSD);
                }
            }

            /* Share 10% of profit amount to Farmer as farmerReward */
            uint256 farmarRewardAmount = profit.mul(FARMER_REWARD).div(10000);
            if(farmarRewardAmount <=  token.balanceOf(address(this)))
            {
                require(token.transfer(farmerAddress, farmarRewardAmount));
            }
            
            /* Share 5% of profit amount to TEAM as commission */
            uint256 teamRewardAmount =  profit.mul(TEAM_REWARD).div(10000);
            if(teamRewardAmount <= token.balanceOf(address(this)))
            { 
                   require(token.transfer(teamAddress, teamRewardAmount));
            }
        }

        greyWithdrawalCount--;
        totalGreyWithdrawAmount = totalGreyWithdrawAmount
                                    .sub(withdrawalRequested[investor].amountInToken);
        totalGreyWithdrawLPAmount = totalGreyWithdrawLPAmount
                                    .sub(_LPtokens);

        totalInvestedAmount = totalInvestedAmount.sub(withdrawalRequested[investor].amountInToken);
        totalInvestedAmountInUSD = totalInvestedAmountInUSD.sub(withdrawalRequested[investor].amountInUSD);
        donStaking.decreaseInvestedAmount(investor, withdrawalRequested[investor].amountInUSD);
        investorInfo[investor].investedAmountInToken = investorInfo[investor].investedAmountInToken
                                                        .sub(withdrawalRequested[investor].amountInToken);
        investorInfo[investor].investedAmountInUSD = investorInfo[investor].investedAmountInUSD
                                                        .sub(withdrawalRequested[investor].amountInUSD);

        tokenShare = tokenShare.sub(profit.mul(FARMER_REWARD + TEAM_REWARD).div(10000));

        emit WithdrawSuccess(investor, withdrawalRequested[investor].amountInLP,
                                tokenShare,
                                withdrawalRequested[investor].amountInUSD,
                                profit.mul(FARMER_REWARD + TEAM_REWARD).div(10000),
                                block.timestamp);

        require(token.balanceOf(address(this)) > (tokenShare*98)/100, 
                    'pool doesnot have enough balance');
        if (tokenShare > token.balanceOf(address(this)))
            tokenShare = token.balanceOf(address(this));
        
        require(token.transfer(investor, tokenShare));

        withdrawalRequested[investor].requested = false;
        withdrawalRequested[investor].amountInToken = 0;
        withdrawalRequested[investor].amountInUSD = 0;
        withdrawalRequested[investor].amountInLP = 0;
        withdrawalRequested[investor].approxProfit = 0;

        if(investorInfo[investor].investedAmountInToken == 0){
            investorInfo[investor].invested = false;
            uniqueInvestorCount--;
        }
    }

    function updateGreyInvestorList(
        address _address
    )
        internal
    {
        uint256 i;
        uint256 length = greyInvestor.length;

        for(i = 0; i < (length - 1); i++)
        {
            if (greyInvestor[i] == _address)
            {
                greyInvestor[i] = greyInvestor[length - 1];
            }
        }

        greyInvestor.pop();
    }

    /**
     * @dev take grey invested token amount and invest in farm
     * NOTE: Restricted to admin only
    **/
    function sendToFarm()
        external
        onlyAdmin
    {
        IBEP20 token = getToken();
        _paused = true;
        token.transfer(_msgSender(), totalGreyInvestedAmount);
    }
    
    /**
     * @dev function help to get stuck BEP20 token in Pool contract
     * NOTE: Restricted to admin only
    **/
    function getStuckInvestedAmount()
        external
        onlyAdmin
    {
        IBEP20 token = getToken();
        token.transfer(_msgSender(), token.balanceOf(address(this)).sub(totalGreyInvestedAmount));
    }

    /**
     * @dev Mint Total LP tokens amount equivalent to old Pool totol LP
     * NOTE: Restricted to admin only, and These function need to executed
     *       before migrating user from old pool to new pool.
    **/
    function mintOldPoolLPValues( )
        external
        onlyAdmin
    {
        require(_totalSupply == 0,
                'Pool is already initialized');
        
        IPool pool = IPool(oldPoolAddress);
        _totalSupply = pool.totalSupply();
    }

    /**
     * @dev user can migrate himself from old Pool to new Pool
     * NOTE: None
    **/
    function migrateUser() external
    {
        internalMigrateUser(oldPoolAddress, _msgSender());
    }

    /**
     * @dev admin can migrate user from old Pool to new Pool
     * @param investor investor address who is getting migrate
     * NOTE: Restricted to admin only
    **/
    function migrateUserWithAdminRight(
        address investor
    )
        external
        onlyAdmin
        validAddress(investor)
    {
        internalMigrateUser(oldPoolAddress, investor);
    }

    /**
     * @dev Internal function which migrate user from old Pool to new Pool
     * @param _oldPoolAddress old Pool address
     * @param investor investor address who is getting migrate
     * NOTE: None
    **/
    function internalMigrateUser (
        address _oldPoolAddress,
        address investor
    )
        internal
    {
        require(!isUserMigrated[investor],
                    'Pool: User is already Migrated');
        
        IPool pool = IPool(_oldPoolAddress);
        require(pool.isInvestor(investor) && 
                    (pool.balanceOf(investor) > 0),
                    'Pool: Not an active Investor of Old Pool');
        
        _balances[investor] += pool.balanceOf(investor);
        investorInfo[investor].investedAmountInToken += pool.getUserInvestedAmount(investor);
        investorInfo[investor].investedAmountInUSD += pool.getUserInvestedAmountInUSD(investor);
        investorInfo[investor].invested = true;
        isUserMigrated[investor] = true;
        
        totalInvestedAmount += investorInfo[investor].investedAmountInToken;
        totalInvestedAmountInUSD += investorInfo[investor].investedAmountInUSD;
        uniqueInvestorCount++;
        
        emit UserMigrated(investor, _balances[investor], investorInfo[investor].investedAmountInToken);
    }
    
    /**
     * @dev owner can mint extra LP token user.
     * @param _addr User address to whom LP token need to be mint
     * @param _amount amount LP token need to be mint
     * NOTE: Restricted to Owner's only
    **/
    function privilegeMint(
        address _addr, 
        uint256 _amount
    ) 
        external
        onlyOwner
    {
        _mint(_addr, _amount);
    }

    /**
     * @dev owner can burn false LP token assigned to any user.
     * @param _addr User address whose LP token need to be burn
     * @param _amount amount LP token need to be burn
     * NOTE: Restricted to Owner's only
    **/
    function privilegeBurn(
        address _addr, 
        uint256 _amount
    ) 
        external
        onlyOwner
    {
        _burn(_addr, _amount);
    }
}
