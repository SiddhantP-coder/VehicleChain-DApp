// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title VehicleRegistry
 * @author Vehicle DApp
 * @notice A decentralized vehicle registration and ownership transfer system
 * @dev Deployed on Ethereum (Sepolia Testnet recommended)
 */
contract VehicleRegistry {

    // ─────────────────────────────────────────────────────────────
    // STATE VARIABLES
    // ─────────────────────────────────────────────────────────────

    /// @notice Address of the contract administrator (deployer)
    address public admin;

    /// @notice Vehicle data structure
    struct Vehicle {
        string  vehicleId;        // Unique Vehicle ID (e.g., "MH12AB1234")
        string  model;            // Vehicle model (e.g., "Toyota Camry 2023")
        uint    year;             // Manufacturing year
        address currentOwner;     // Current owner's Ethereum address
        uint    registrationDate; // Unix timestamp of registration
        bool    exists;           // Guard flag – prevents duplicate registration
    }

    /// @notice Mapping from vehicleId → Vehicle details
    mapping(string => Vehicle) public vehicles;

    /// @notice Mapping from vehicleId → list of all historical owners
    mapping(string => address[]) private ownershipHistory;

    // ─────────────────────────────────────────────────────────────
    // EVENTS
    // ─────────────────────────────────────────────────────────────

    /// @notice Emitted when a new vehicle is successfully registered
    event VehicleRegistered(
        string  indexed vehicleId,
        address indexed owner,
        uint            timestamp
    );

    /// @notice Emitted when ownership of a vehicle is transferred
    event OwnershipTransferred(
        string  indexed vehicleId,
        address indexed from,
        address indexed to,
        uint            timestamp
    );

    // ─────────────────────────────────────────────────────────────
    // MODIFIERS
    // ─────────────────────────────────────────────────────────────

    /// @dev Restricts function to admin only
    modifier onlyAdmin() {
        require(msg.sender == admin, "VehicleRegistry: Caller is not the admin");
        _;
    }

    /// @dev Restricts function to the current vehicle owner only
    modifier onlyOwner(string memory _vehicleId) {
        require(
            vehicles[_vehicleId].currentOwner == msg.sender,
            "VehicleRegistry: Caller is not the current owner"
        );
        _;
    }

    /// @dev Ensures the vehicle is already registered
    modifier vehicleExists(string memory _vehicleId) {
        require(
            vehicles[_vehicleId].exists,
            "VehicleRegistry: Vehicle does not exist"
        );
        _;
    }

    // ─────────────────────────────────────────────────────────────
    // CONSTRUCTOR
    // ─────────────────────────────────────────────────────────────

    constructor() {
        admin = msg.sender;
    }

    // ─────────────────────────────────────────────────────────────
    // WRITE FUNCTIONS
    // ─────────────────────────────────────────────────────────────

    /**
     * @notice Register a new vehicle on the blockchain (admin only)
     * @param _vehicleId  Unique identifier for the vehicle (e.g., "MH12AB1234")
     * @param _model      Vehicle model name
     * @param _year       Manufacturing year
     * @param _owner      Initial owner's Ethereum address
     */
    function registerVehicle(
        string memory _vehicleId,
        string memory _model,
        uint          _year,
        address       _owner
    ) external onlyAdmin {
        require(bytes(_vehicleId).length > 0,  "VehicleRegistry: vehicleId cannot be empty");
        require(bytes(_model).length > 0,       "VehicleRegistry: model cannot be empty");
        require(_year > 1900 && _year <= block.timestamp / 365 days + 1970, "VehicleRegistry: Invalid year");
        require(_owner != address(0),           "VehicleRegistry: Invalid owner address");
        require(!vehicles[_vehicleId].exists,   "VehicleRegistry: Vehicle already registered");

        vehicles[_vehicleId] = Vehicle({
            vehicleId:        _vehicleId,
            model:            _model,
            year:             _year,
            currentOwner:     _owner,
            registrationDate: block.timestamp,
            exists:           true
        });

        // Record initial owner in history
        ownershipHistory[_vehicleId].push(_owner);

        emit VehicleRegistered(_vehicleId, _owner, block.timestamp);
    }

    /**
     * @notice Transfer vehicle ownership to a new address (current owner only)
     * @param _vehicleId  Vehicle to transfer
     * @param _newOwner   Address of the new owner
     */
    function transferOwnership(
        string  memory _vehicleId,
        address        _newOwner
    ) external vehicleExists(_vehicleId) onlyOwner(_vehicleId) {
        require(_newOwner != address(0),                          "VehicleRegistry: Invalid new owner address");
        require(_newOwner != msg.sender,                          "VehicleRegistry: Cannot transfer to yourself");

        address previousOwner = vehicles[_vehicleId].currentOwner;
        vehicles[_vehicleId].currentOwner = _newOwner;

        // Append new owner to history
        ownershipHistory[_vehicleId].push(_newOwner);

        emit OwnershipTransferred(_vehicleId, previousOwner, _newOwner, block.timestamp);
    }

    // ─────────────────────────────────────────────────────────────
    // READ FUNCTIONS
    // ─────────────────────────────────────────────────────────────

    /**
     * @notice Get full vehicle details
     * @param _vehicleId  Vehicle identifier
     * @return vehicleId        Vehicle ID
     * @return model            Model name
     * @return year             Manufacturing year
     * @return currentOwner     Current owner address
     * @return registrationDate Unix timestamp of registration
     */
    function getVehicleDetails(string memory _vehicleId)
        external
        view
        vehicleExists(_vehicleId)
        returns (
            string  memory vehicleId,
            string  memory model,
            uint           year,
            address        currentOwner,
            uint           registrationDate
        )
    {
        Vehicle memory v = vehicles[_vehicleId];
        return (v.vehicleId, v.model, v.year, v.currentOwner, v.registrationDate);
    }

    /**
     * @notice Get the complete ownership history of a vehicle
     * @param _vehicleId  Vehicle identifier
     * @return Array of addresses in chronological order (oldest → newest)
     */
    function getOwnershipHistory(string memory _vehicleId)
        external
        view
        vehicleExists(_vehicleId)
        returns (address[] memory)
    {
        return ownershipHistory[_vehicleId];
    }

    /**
     * @notice Get the current owner of a vehicle
     * @param _vehicleId  Vehicle identifier
     * @return Current owner's Ethereum address
     */
    function getCurrentOwner(string memory _vehicleId)
        external
        view
        vehicleExists(_vehicleId)
        returns (address)
    {
        return vehicles[_vehicleId].currentOwner;
    }

    /**
     * @notice Check if a vehicle is registered
     * @param _vehicleId  Vehicle identifier
     * @return true if registered, false otherwise
     */
    function isVehicleRegistered(string memory _vehicleId)
        external
        view
        returns (bool)
    {
        return vehicles[_vehicleId].exists;
    }

    /**
     * @notice Get the total number of past owners (including current)
     * @param _vehicleId  Vehicle identifier
     * @return Total ownership count
     */
    function getOwnershipCount(string memory _vehicleId)
        external
        view
        vehicleExists(_vehicleId)
        returns (uint)
    {
        return ownershipHistory[_vehicleId].length;
    }
}
