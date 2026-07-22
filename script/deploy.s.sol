pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {MainGym} from "../src/Main.sol";

contract Deploy is Script {
    function run() external returns (MainGym) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        string memory tokenName = "Gains";
        string memory tokenSymbol = "ATP";
        string memory NFTName = "Train";
        string memory NFTSymbol = "KG";
        string memory baseUri = "bafybeia4v7eadp6r4nuf3ei5cucf62hwigari6kbvbqggkg5e2dfxwqhxe/";
        uint256 feeRefund = 10;
        uint256 upgradePeriodPerLvl = 1 days;
        uint256 boostPercentagePerLvl = 5;
        uint256 baseProductionPerLvl = 1000;
        uint256 relationPriceProduction = 10;
        uint256 maxLvlBase = 10;
        uint256 maxLvlMulti = 20;
        uint256 amountBase = 5; //!0
        uint256 amountMulti = 1; //!0

        MainGym tycoon = new MainGym(
            tokenName,
            tokenSymbol,
            NFTName,
            NFTSymbol,
            baseUri,
            feeRefund,
            upgradePeriodPerLvl,
            boostPercentagePerLvl,
            baseProductionPerLvl,
            relationPriceProduction,
            maxLvlBase,
            maxLvlMulti,
            amountBase,
            amountMulti
        );

        vm.stopBroadcast();
        return tycoon;
    }
}
