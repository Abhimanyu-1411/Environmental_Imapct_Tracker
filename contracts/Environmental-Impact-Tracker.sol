
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract EnvironmentalImpactTracking {
    // Struct to store environmental data
    struct EnvironmentalData {
        uint256 carbonFootprint; // Carbon footprint of the company
        uint256 energyConsumption; // Energy consumption of the company
        uint256 wasteProduction; // Waste production of the company
        uint256 timestamp; // Timestamp of when the data was recorded
    }

    // Struct to store company information
    struct Company {
        string name; // Name of the company
        address wallet; // Wallet address of the company
        uint256[] records; // Array of indexes pointing to environmental data records
        uint256 tokenBalance; // Token balance of the company
    }

    // Mapping from company wallet address to Company struct
    mapping(address => Company) public companies;
    address public admin; // Admin address

    // Mapping from record index to EnvironmentalData struct
    mapping(uint256 => EnvironmentalData) public environmentalData;
    uint256 public nextRecordIndex = 0; // Index for the next environmental data record

    // Events to log actions
    event EnvironmentalDataRecorded(address indexed company, uint256 timestamp);
    event TokensAwarded(address indexed company, uint256 amount);
    event CompanyRegistered(string name, address indexed wallet);
    event CompanyDeregistered(address indexed wallet);

    // Modifier to restrict access to admin only
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    // Modifier to restrict access to registered companies only
    modifier onlyCompany() {
        require(bytes(companies[msg.sender].name).length != 0, "Only registered companies can perform this action");
        _;
    }

    // Constructor to set the admin address to the contract deployer
    constructor() {
        admin = msg.sender;
    }

    // Function to register a new company
    function registerCompany(string memory _name, address _wallet) public onlyAdmin {
        require(bytes(_name).length > 0, "Company name cannot be empty");
        require(_wallet != address(0), "Invalid wallet address");
        require(bytes(companies[_wallet].name).length == 0, "Company already registered");

        companies[_wallet] = Company({
            name: _name,
            wallet: _wallet,
            records: new uint256[](0), // Initialize an empty array of uint256
            tokenBalance: 0
        });

        emit CompanyRegistered(_name, _wallet);
    }

    // Function to deregister an existing company
    function deregisterCompany(address _wallet) public onlyAdmin {
        require(bytes(companies[_wallet].name).length != 0, "Company not registered");
        delete companies[_wallet];
        emit CompanyDeregistered(_wallet);
    }

    // Function to record environmental data for a company
    function recordEnvironmentalData(uint256 _carbonFootprint, uint256 _energyConsumption, uint256 _wasteProduction) public onlyCompany {
        require(_carbonFootprint >= 0, "Carbon footprint must be non-negative");
        require(_energyConsumption >= 0, "Energy consumption must be non-negative");
        require(_wasteProduction >= 0, "Waste production must be non-negative");

        EnvironmentalData memory newData = EnvironmentalData({
            carbonFootprint: _carbonFootprint,
            energyConsumption: _energyConsumption,
            wasteProduction: _wasteProduction,
            timestamp: block.timestamp
        });

        // Store the new data in the mapping
        environmentalData[nextRecordIndex] = newData;

        // Add the index to the company's records array
        companies[msg.sender].records.push(nextRecordIndex); 
        nextRecordIndex++;

        emit EnvironmentalDataRecorded(msg.sender, block.timestamp);
    }

    // Function to verify if a company complies with a given carbon footprint threshold
    function verifyCompliance(address _company, uint256 _carbonFootprintThreshold) public view returns (bool) {
        require(bytes(companies[_company].name).length != 0, "Company not registered");
        uint256[] storage records = companies[_company].records;
        if (records.length == 0) return false;

        uint256 latestRecordIndex = records[records.length - 1];
        EnvironmentalData storage latestRecord = environmentalData[latestRecordIndex]; 
        return latestRecord.carbonFootprint <= _carbonFootprintThreshold;
    }

    // Function to award tokens to a company based on carbon footprint reduction
    function awardTokens(address _company, uint256 _carbonFootprintReduction) public onlyAdmin {
        require(bytes(companies[_company].name).length != 0, "Company not registered");

        uint256 rewardAmount;

        if (_carbonFootprintReduction >= 20) {
            rewardAmount = 1000; // Highest tier reward
        } else if (_carbonFootprintReduction >= 10) {
            rewardAmount = 500; // Mid-tier reward
        } else if (_carbonFootprintReduction >= 5) {
            rewardAmount = 200; // Lower tier reward
        } else {
            rewardAmount = 0; // No reward for reductions below 5%
        }

        companies[_company].tokenBalance += rewardAmount;
        emit TokensAwarded(_company, rewardAmount);
    }

    // Function to get the name and token balance of a company
    function getCompanyData(address _company) public view returns (string memory, uint256) {
        require(bytes(companies[_company].name).length != 0, "Company not registered");
        return (companies[_company].name, companies[_company].tokenBalance);
    }

    // Function to get the count of environmental data records for a company
    function getEnvironmentalDataCount(address _company) public view returns (uint256) {
        require(bytes(companies[_company].name).length != 0, "Company not registered");
        return companies[_company].records.length;
    }

    // Function to get environmental data by index for a company
    function getEnvironmentalDataByIndex(address _company, uint256 index) public view returns (uint256, uint256, uint256, uint256) {
        require(bytes(companies[_company].name).length != 0, "Company not registered");
        require(index < companies[_company].records.length, "Index out of bounds");

        uint256 recordIndex = companies[_company].records[index];
        EnvironmentalData storage data = environmentalData[recordIndex];
        return (data.carbonFootprint, data.energyConsumption, data.wasteProduction, data.timestamp);
    }
}
