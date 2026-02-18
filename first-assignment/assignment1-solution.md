# Assignment 1


## Solution

### 1. Where Are Structs, Mappings, and Arrays Stored?

In Solidity, there are four main data locations: **storage**, **memory**, **calldata**, and **stack**.

#### Storage

* Storage is the persistent area of the blockchain.
* Any variable declared at the contract level is automatically stored in storage, including structs, mappings, and arrays.
* Example:

```solidity
contract LibraryRegistry {

    struct Book {
        string title;
        address borrower;
        uint256 dueDate;
    }

    Book public lastBorrowed;                   // Stored in storage
    mapping(bytes32 => Book) public books;      // Stored in storage
    bytes32[] public bookIds;                   // Stored in storage
}
```

No `storage` keyword is required because state variables are automatically placed in storage.

#### Memory

* Memory is temporary and exists only during function execution.
* Structs and arrays can be placed in memory inside functions, creating **independent copies**.


Example:

```solidity
function createTemporaryRecord() external pure returns (uint256) {
    Record memory temp = Record({
        timestamp: block.timestamp,
        owner: msg.sender,
        description: "temporary"
    });

    return temp.timestamp;
}
```

The `temp` struct exists only during execution and is removed once the function completes.

Memory arrays must have a fixed size when created and cannot be resized using `push()` or `pop()`.

#### Calldata

* Calldata is **read-only** and used for external function parameters.
* Structs and arrays can exist in calldata but cannot be modified.


Example:

```solidity
function inspectIds(bytes32[] calldata ids) external pure returns (bytes32) {
    return ids[0];
}
```

The `ids` array is read-only and cannot be modified inside the function.


#### Stack

* Value types like `uint256`, `bool`, and `address` are stored on the stack.
* Reference types (structs, arrays, mappings) do **not** live on the stack directly, but references/pointers to them are temporarily stored there during execution.


### 2. Why Don’t You Need to Specify `memory` or `storage` with Mappings?

Mappings are special in Solidity:

* They can **only** exist in storage.
* They do not track keys, have no length, and cannot be copied.
* Their values are accessed via a hash of the key and storage slot.

Because mappings:

1. Cannot be copied into memory.
2. Cannot be serialized for calldata.
3. Require storage’s hashing mechanism to work.

Solidity automatically places them in storage, so specifying `memory` or `calldata` is not allowed.

```solidity
mapping(bytes32 => Book) public books; // Always storage

function _fetch(mapping(bytes32 => Book) storage bks, bytes32 id) internal view returns (address) {
    return bks[id].borrower;
}
```


### 3. How Structs, Mappings, and Arrays Behave in Storage, Memory, Calldata, and Stack

#### Storage

* Variables live permanently.
* Modifying them directly updates the blockchain.
* Example:

```solidity
function updateBorrower(bytes32 id, address newBorrower) external {
    Book storage b = books[id];
    b.borrower = newBorrower; // Changes persist
}
```

#### Memory

* Memory variables are temporary copies.
* Modifying them **does not affect storage**.

```solidity
function readBorrower(bytes32 id) external view returns (address) {
    Book memory copy = books[id];
    return copy.borrower; // Storage remains unchanged
}
```

#### Calldata

* Read-only and temporary for external calls.
* Cannot modify.

```solidity
function checkBorrowers(bytes32[] calldata ids) external pure returns (bytes32) {
    return ids[0]; // Only reading
}
```

#### Stack

* Holds value types temporarily for execution.
* Automatically cleared after function ends.
* You do not control stack manually.


### 4. How Structs, Mappings, and Arrays Behave When Executed or Called

* **Storage variables:** Permanent; changes persist after function execution.
* **Memory variables:** Temporary copies; cleared after function finishes.
* **Calldata variables:** Read-only for external calls; cleared after execution.
* **Stack variables:** For intermediate value types; cleared after execution.

**Reference type rules in functions:**

* Local reference variables must specify `memory` (copy) or `storage` (reference).
* Function parameters must specify `memory` or `calldata`.
* Mappings are always storage; cannot be memory or calldata.
