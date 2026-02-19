// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;


interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SchoolManagement {

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address tokenAddress) {
        require(tokenAddress != address(0), "Invalid token");
        owner = msg.sender;
        schoolToken = IERC20(tokenAddress);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }

    IERC20 public schoolToken;

    struct Student {
        uint256 id;
        string name;
        uint16 level;
        address wallet;
        uint256 amountPaid;
        uint256 paymentTimestamp;
        bool isActive;
    }

    struct Staff {
        uint256 id;
        string name;
        address wallet;
        uint256 salary;
        bool isActive;
    }

    mapping(uint256 => Student) public students;
    mapping(uint256 => Staff) public staffs;

    mapping(uint16 => uint256) public levelFee;
    mapping(address => bool) public studentRegistered;

    uint256 public nextStudentId;
    uint256 public nextStaffId;

    uint256[] public studentIds;
    uint256[] public staffIds;

    event StudentRegistered(
        uint256 indexed studentId,
        address indexed wallet,
        uint16 level,
        uint256 amountPaid,
        uint256 timestamp
    );

    event StaffRegistered(
        uint256 indexed staffId,
        address indexed wallet,
        uint256 salary
    );

    event StaffPaid(
        uint256 indexed staffId,
        uint256 amount,
        uint256 timestamp
    );

    event LevelFeeUpdated(uint16 indexed level, uint256 newFee);

    function setLevelFee(uint16 _level, uint256 _fee) external onlyOwner {
        require(
            _level == 100 ||
            _level == 200 ||
            _level == 300 ||
            _level == 400,
            "Invalid level"
        );
        require(_fee > 0, "Fee must be > 0");

        levelFee[_level] = _fee;
        emit LevelFeeUpdated(_level, _fee);
    }


    function registerStudent(string calldata _name, uint16 _level) external {

        require(!studentRegistered[msg.sender], "Already registered");

        require(
            _level == 100 ||
            _level == 200 ||
            _level == 300 ||
            _level == 400,
            "Invalid level"
        );

        uint256 fee = levelFee[_level];
        require(fee > 0, "Fee not set");

        // Pull payment
        bool success = schoolToken.transferFrom(
            msg.sender,
            address(this),
            fee
        );

        require(success, "Payment failed");

        uint256 studentId = nextStudentId;

        students[studentId] = Student({
            id: studentId,
            name: _name,
            level: _level,
            wallet: msg.sender,
            amountPaid: fee,
            paymentTimestamp: block.timestamp,
            isActive: true
        });

        studentRegistered[msg.sender] = true;

        studentIds.push(studentId);
        nextStudentId++;

        emit StudentRegistered(
            studentId,
            msg.sender,
            _level,
            fee,
            block.timestamp
        );
    }

    function registerStaff(
        string calldata _name,
        address _wallet,
        uint256 _salary
    ) external onlyOwner {

        require(_wallet != address(0), "Invalid wallet");
        require(_salary > 0, "Invalid salary");

        uint256 staffId = nextStaffId;

        staffs[staffId] = Staff({
            id: staffId,
            name: _name,
            wallet: _wallet,
            salary: _salary,
            isActive: true
        });

        staffIds.push(staffId);
        nextStaffId++;

        emit StaffRegistered(staffId, _wallet, _salary);
    }

    function payStaff(uint256 _staffId) external onlyOwner {

        Staff storage staff = staffs[_staffId];
        require(staff.isActive, "Inactive staff");

        uint256 contractBalance = schoolToken.balanceOf(address(this));
        require(contractBalance >= staff.salary, "Insufficient funds");

        bool success = schoolToken.transfer(
            staff.wallet,
            staff.salary
        );

        require(success, "Salary payment failed");

        emit StaffPaid(_staffId, staff.salary, block.timestamp);
    }

    function getAllStudentIds() external view returns (uint256[] memory) {
        return studentIds;
    }

    function getAllStaffIds() external view returns (uint256[] memory) {
        return staffIds;
    }

    function getStudentsByLevel(uint16 _level) external view returns (Student[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < studentIds.length; i++) {
            if (students[studentIds[i]].level == _level) {
                count++;
            }
        }

        Student[] memory result = new Student[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < studentIds.length; i++) {
            if (students[studentIds[i]].level == _level) {
                result[index] = students[studentIds[i]];
                index++;
            }
        }

        return result;
    }

    function getStaffByName(string calldata _name) external view returns (Staff[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < staffIds.length; i++) {
            if (keccak256(bytes(staffs[staffIds[i]].name)) == keccak256(bytes(_name))) {
                count++;
            }
        }

        Staff[] memory result = new Staff[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < staffIds.length; i++) {
            if (keccak256(bytes(staffs[staffIds[i]].name)) == keccak256(bytes(_name))) {
                result[index] = staffs[staffIds[i]];
                index++;
            }
        }

        return result;
    }
}
