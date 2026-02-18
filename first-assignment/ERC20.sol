// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ERC20 {

    // Maps each address to its token balance.
    mapping(address => uint256) private _balances;

    // Maps owner → spender → approved amount.
    mapping(address => mapping(address => uint256)) private _allowances;

    // Total number of tokens in existence.
    // Invariant: _totalSupply always equals the sum of all _balances entries.
    uint256 private _totalSupply;

    // Human-readable name of the token (e.g., "USD Coin").
    string private _name;

    // Ticker symbol (e.g., "USDC").
    string private _symbol;

    // Number of decimal places
    uint8 private _decimals;

    // The address with minting privileges.
    address private _owner;

    // Emitted when tokens move between addresses.
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    // Emitted when an allowance is set or changed.
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // Emitted when ownership is transferred (or renounced).
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // Restricts a function to the current owner.
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require(msg.sender == _owner, "ERC20: caller is not the owner");
    }

    // Runs exactly once during deployment. Sets metadata, records deployer
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        uint256 initialSupply
    ) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;

        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);

        if (initialSupply > 0) {
            _mint(msg.sender, initialSupply);
        }
    }

    // Returns the token name.
    function name() public view returns (string memory) {
        return _name;
    }

    // Returns the token symbol.
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // Returns the number of decimals for display formatting.
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    // Returns the total supply of tokens.
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // Returns the balance of a specific account.
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    // Returns the remaining allowance that spender can withdraw from owner.
    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        return _allowances[tokenOwner][spender];
    }

    // Transfers tokens from the caller to `to`.
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    // Sets `amount` as the allowance of `spender` over the caller's tokens.
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // Transfers tokens from `from` to `to` using the allowance mechanism.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    // Atomically increases the caller's allowance for `spender` by `addedValue`.
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address tokenOwner = msg.sender;
        _approve(tokenOwner, spender, _allowances[tokenOwner][spender] + addedValue);
        return true;
    }

    // Atomically decreases the caller's allowance for `spender` by `subtractedValue`.
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address tokenOwner = msg.sender;
        uint256 currentAllowance = _allowances[tokenOwner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

        unchecked {
            // Safe: we just verified currentAllowance >= subtractedValue
            _approve(tokenOwner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    // Creates `amount` new tokens and assigns them to `to`.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // Destroys `amount` tokens from the caller's account.
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    // Destroys `amount` tokens from `account`, deducting from the caller's allowance.
    function burnFrom(address account, uint256 amount) public {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }

    // Returns the current owner.
    function owner() public view returns (address) {
        return _owner;
    }

    // Transfers ownership to `newOwner`. Only callable by the current owner.
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "ERC20: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    // Permanently removes the owner. No one can mint after this.
    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    // Core transfer logic. Shared by transfer() and transferFrom().
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    // Creates `amount` tokens and assigns them to `account`.
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        // Checked arithmetic: reverts if _totalSupply overflows uint256
        _totalSupply += amount;

        // unchecked is safe: _totalSupply didn't overflow, and
        // _balances[account] <= _totalSupply, so this can't overflow either
        unchecked {
            _balances[account] += amount;
        }

        emit Transfer(address(0), account, amount);
    }

    // Destroys `amount` tokens from `account`.
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        // unchecked is safe:
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    // Sets `amount` as the allowance of `spender` over `owner`'s tokens.
    function _approve(address tokenOwner, address spender, uint256 amount) internal {
        require(tokenOwner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[tokenOwner][spender] = amount;
        emit Approval(tokenOwner, spender, amount);
    }

    // Deducts `amount` from the owner → spender allowance.
    function _spendAllowance(address tokenOwner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[tokenOwner][spender];

        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");

            // unchecked is safe: currentAllowance >= amount (verified above)
            unchecked {
                _approve(tokenOwner, spender, currentAllowance - amount);
            }
        }
    }

    // Internal ownership transfer helper.
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
