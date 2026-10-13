// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.6/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.6/contracts/security/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.6/contracts/utils/Base64.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.6/contracts/utils/Strings.sol";

/**
 * @title VehicleRegistry
 * @author Vehicle DApp
 * @notice A decentralized vehicle registration and ownership transfer system
 * @dev Deployed on Ethereum (Sepolia Testnet recommended)
 */
contract VehicleRegistry is ERC721, ReentrancyGuard {
    using Strings for uint256;

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

    /// @notice Each registered vehicle is minted as one ERC-721 token
    mapping(string => uint256) public vehicleTokenIds;
    mapping(uint256 => string) private tokenVehicleIds;
    mapping(uint256 => uint256) public salePrices;
    uint256 public nextTokenId = 1;

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

    event VehiclePriceUpdated(string indexed vehicleId, uint256 priceWei);
    event VehiclePurchased(string indexed vehicleId, address indexed seller, address indexed buyer, uint256 priceWei);

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

    constructor() ERC721("VehicleChain Vehicle", "VCAR") {
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

        uint256 tokenId = nextTokenId++;
        vehicleTokenIds[_vehicleId] = tokenId;
        tokenVehicleIds[tokenId] = _vehicleId;

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
        _safeMint(_owner, tokenId);

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

        _transfer(msg.sender, _newOwner, vehicleTokenIds[_vehicleId]);
    }

    function setVehiclePrice(string memory _vehicleId, uint256 _priceWei)
        external
        vehicleExists(_vehicleId)
        onlyOwner(_vehicleId)
    {
        uint256 tokenId = vehicleTokenIds[_vehicleId];
        salePrices[tokenId] = _priceWei;
        emit VehiclePriceUpdated(_vehicleId, _priceWei);
    }

    function buyVehicle(string memory _vehicleId) external payable nonReentrant vehicleExists(_vehicleId) {
        uint256 tokenId = vehicleTokenIds[_vehicleId];
        uint256 price = salePrices[tokenId];
        address seller = ownerOf(tokenId);

        require(price > 0, "VehicleRegistry: Vehicle is not for sale");
        require(msg.value == price, "VehicleRegistry: Incorrect ETH amount");
        require(msg.sender != seller, "VehicleRegistry: Seller cannot buy own vehicle");

        salePrices[tokenId] = 0;
        _safeTransfer(seller, msg.sender, tokenId, "");

        (bool paid, ) = payable(seller).call{value: msg.value}("");
        require(paid, "VehicleRegistry: ETH payment failed");
        emit VehiclePurchased(_vehicleId, seller, msg.sender, price);
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

    function getVehicleTokenId(string memory _vehicleId) external view vehicleExists(_vehicleId) returns (uint256) {
        return vehicleTokenIds[_vehicleId];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        string memory vehicleId = tokenVehicleIds[tokenId];
        Vehicle storage vehicle = vehicles[vehicleId];
        bytes memory metadata = abi.encodePacked(
            '{"name":"', _escapeJson(vehicle.model), ' #', _escapeJson(vehicleId),
            '","description":"VehicleChain ownership token for ', _escapeJson(vehicleId),
            '","attributes":[{"trait_type":"Vehicle ID","value":"', _escapeJson(vehicleId),
            '"},{"trait_type":"Year","display_type":"number","value":', vehicle.year.toString(), '}]}'
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(metadata)));
    }

    function _escapeJson(string memory value) private pure returns (string memory) {
        bytes memory input = bytes(value);
        bytes memory output = new bytes(input.length * 6);
        bytes16 hexSymbols = "0123456789abcdef";
        uint256 outputLength;

        for (uint256 i = 0; i < input.length; i++) {
            bytes1 character = input[i];
            uint8 characterValue = uint8(character);
            if (character == '"' || character == '\\') {
                output[outputLength++] = '\\';
                output[outputLength++] = character;
            } else if (characterValue < 0x20) {
                output[outputLength++] = '\\';
                output[outputLength++] = 'u';
                output[outputLength++] = '0';
                output[outputLength++] = '0';
                output[outputLength++] = hexSymbols[characterValue >> 4];
                output[outputLength++] = hexSymbols[characterValue & 0x0f];
            } else {
                output[outputLength++] = character;
            }
        }

        assembly { mstore(output, outputLength) }
        return string(output);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from != address(0) && to != address(0)) {
            string memory vehicleId = tokenVehicleIds[tokenId];
            salePrices[tokenId] = 0;
            ownershipHistory[vehicleId].push(to);
            vehicles[vehicleId].currentOwner = to;
            emit OwnershipTransferred(vehicleId, from, to, block.timestamp);
        }
    }
}
