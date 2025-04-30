// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "forge-std/Vm.sol";

contract Constants {
    mapping(string => address) private addressMap;
    mapping(string => bytes32) private pairCodeHash;
    //byteCodeHash for trident pairs

    string[] private addressKeys;

    constructor() {
        // set constants for tests here

        // Mainnet
        setAddress("mainnet.weth", 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        setAddress("mainnet.usdc", 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        setAddress("mainnet.rp", 0xe43ca1Dee3F0fc1e2df73A0745674545F11A59F5);

        // Optimism
        setAddress("optimism.weth", 0x4200000000000000000000000000000000000006);
        setAddress("optimism.usdc", 0x7F5c764cBc14f9669B88837ca1490cCa17c31607);
        setAddress("optimism.op", 0x4200000000000000000000000000000000000042);

        // Arbitrum


        // Polygon
        setAddress("polygon.wmatic", 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
        setAddress("polygon.usdc", 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
        setAddress("polygon.usdt", 0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
        setAddress("polygon.v2Factory", 0xc35DADB65012eC5796536bD9864eD8773aBc74C4);
        setAddress("polygon.v3Factory", 0x917933899c6a5F8E37F31E19f92CdBFF7e8FF0e2);
        setAddress("polygon.routeprocessor3", 0x0a6e511Fe663827b9cA7e2D2542b20B37fC217A6);
        setAddress("polygon.redSnwapper", 0xAC4c6e212A361c968F1725b4d055b47E63F80b75);
        // Fantom
    }

    function initAddressLabels(Vm vm) public {
        for (uint256 i = 0; i < addressKeys.length; i++) {
            string memory key = addressKeys[i];
            vm.label(addressMap[key], key);
        }
    }

    function setAddress(string memory key, address value) public {
        require(addressMap[key] == address(0), string.concat("address already exists: ", key));
        addressMap[key] = value;
        addressKeys.push(key);
    }

    function getAddress(string calldata key) public view returns (address) {
        require(addressMap[key] != address(0), string.concat("address not found: ", key));
        return addressMap[key];
    }
}