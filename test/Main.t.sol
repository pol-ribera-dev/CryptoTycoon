// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/Main.sol";

//Test of Main.sol with 100% coverage

contract MainTest is Test {
    string tokenName = "Gains";
    string tokenSymbol = "ATP";
    string NFTName = "Train";
    string NFTSymbol = "KG";
    string baseUri = "bafybeia4v7eadp6r4nuf3ei5cucf62hwigari6kbvbqggkg5e2dfxwqhxe/";
    uint256 feeRefund = 10;
    uint256 upgradePeriodPerLvl = 1 days;
    uint256 boostPercentagePerLvl = 5;
    uint256 baseProductionPerLvl = 1000;
    uint256 relationPriceProduction = 10;
    uint256 maxLvlBase = 10;
    uint256 maxLvlMulti = 20;
    uint256 amountBase = 5; //!0
    uint256 amountMulti = 1; //!0

    MainGym gym;

    address randomUser = vm.addr(1);
    address randomUser2 = vm.addr(2);

    function setUp() public {
        gym = new MainGym(
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
    }

    function testBankCorrectlyDeployed() external view {
        assertTrue(address(gym.token()) != address(0));
        assertTrue(address(gym.nft()) != address(0));
        assertTrue(address(gym.upgrade()) != address(0));
        assertTrue(address(gym.marketplace()) != address(0));

        assertEq(address(gym.Itoken()), address(gym.token()));
        assertEq(address(gym.Inft()), address(gym.nft()));
        assertEq(address(gym.Iupgrade()), address(gym.upgrade()));
        assertEq(address(gym.Imarketplace()), address(gym.marketplace()));

        assertEq(gym.token().upgrade(), address(gym.upgrade()));
        assertEq(gym.token().trades(), address(gym.marketplace()));
        assertEq(gym.nft().upgrade(), address(gym.upgrade()));
    }

    function testStartCorrect() external {
        vm.startPrank(randomUser);

        uint256 balanceNFTBefore = gym.nft().balanceOf(randomUser);
        bool userPlayingBefore = gym.playing(randomUser);

        gym.start();

        uint256 balanceNFTAfter = gym.nft().balanceOf(randomUser);
        bool userPlayingAfter = gym.playing(randomUser);

        (, bool multi,) = gym.nft().IdToData(amountBase);

        assert(multi);
        assert(!userPlayingBefore);
        assert(userPlayingAfter);
        assertEq(balanceNFTBefore, 0);
        assertEq(balanceNFTAfter, amountBase + amountMulti);

        vm.stopPrank();
    }

    function testNotPlaying() external {
        vm.startPrank(randomUser);

        gym.start();

        vm.expectRevert(bytes("01"));

        gym.start();

        vm.stopPrank();
    }

    function testTwoClaimsCorrect() external {
        vm.startPrank(randomUser);

        gym.start();

        uint256 tokensBefore = gym.token().balanceOf(randomUser);

        vm.warp(block.timestamp + 1.1 days);
        gym.getRewards();

        vm.warp(block.timestamp + 1.2 days);
        gym.getRewards();

        uint256 tokensAfter = gym.token().balanceOf(randomUser);

        uint256 expectedAmount = amountBase * baseProductionPerLvl * (100 + boostPercentagePerLvl * amountMulti);

        assertEq(tokensAfter - tokensBefore, expectedAmount / 100 * 2);
        assertEq(block.timestamp, gym.timeLastReward(randomUser));

        vm.stopPrank();
    }

    function testGetRewardsAllLvl1Correct() external {
        vm.startPrank(randomUser);

        gym.start();

        uint256 tokensBefore = gym.token().balanceOf(randomUser);

        vm.warp(block.timestamp + 2 days);

        gym.getRewards();

        uint256 tokensAfter = gym.token().balanceOf(randomUser);

        uint256 expectedAmount = amountBase * baseProductionPerLvl * (100 + boostPercentagePerLvl * amountMulti);

        assertEq(tokensAfter - tokensBefore, expectedAmount / 100);

        vm.stopPrank();
    }

    function testGetRewardsBaseMaxLvlCorrect() external {
        vm.startPrank(randomUser);
        gym.start();
        vm.stopPrank();

        uint256 tokensBefore = gym.token().balanceOf(randomUser);

        vm.startPrank(address(gym.upgrade()));
        for (uint256 i = 1; i < maxLvlBase; i++) {
            gym.nft().lvlUp(0);
        }
        vm.stopPrank();

        vm.startPrank(randomUser);
        vm.warp(block.timestamp + 2 days);
        gym.getRewards();

        uint256 tokensAfter = gym.token().balanceOf(randomUser);
        uint256 expectedAmount = (baseProductionPerLvl * maxLvlBase + (amountBase - 1) * baseProductionPerLvl)
            * (100 + boostPercentagePerLvl * amountMulti);
        assertEq(tokensAfter - tokensBefore, expectedAmount / 100);
        vm.stopPrank();
    }

    function testGetRewardsMultiMaxLvlCorrect() external {
        vm.startPrank(randomUser);
        gym.start();
        uint256 tokensBefore = gym.token().balanceOf(randomUser);
        vm.stopPrank();

        vm.startPrank(address(gym.upgrade()));
        for (uint256 i = 1; i < maxLvlMulti; i++) {
            gym.nft().lvlUp(amountBase);
        }
        vm.stopPrank();

        vm.startPrank(randomUser);
        vm.warp(block.timestamp + 2 days);
        gym.getRewards();

        uint256 tokensAfter = gym.token().balanceOf(randomUser);
        uint256 expectedAmount = amountBase * baseProductionPerLvl * (100 + boostPercentagePerLvl * maxLvlMulti);

        if (amountMulti == 1) {
            assertEq(tokensAfter - tokensBefore, expectedAmount / 100);
        } else {
            assert(tokensAfter - tokensBefore > expectedAmount / 100);
        }

        vm.stopPrank();
    }

    function testGetRewardsMoreMultiCorrect() external {
        vm.startPrank(randomUser);
        gym.start();
        vm.stopPrank();

        vm.startPrank(address(gym));
        gym.nft().mintAll(randomUser);
        vm.stopPrank();

        uint256 tokensBefore = gym.token().balanceOf(randomUser);

        vm.startPrank(randomUser);

        vm.warp(block.timestamp + 2 days);

        gym.getRewards();

        uint256 tokensAfter = gym.token().balanceOf(randomUser);

        uint256 expectedAmount = amountBase * 2 * baseProductionPerLvl * (100 + boostPercentagePerLvl * amountMulti * 2);

        assertEq(tokensAfter - tokensBefore, expectedAmount / 100);

        vm.stopPrank();
    }

    function testHasToBePlayingRewards() external {
        vm.startPrank(randomUser);

        vm.warp(block.timestamp + 2 days);

        vm.expectRevert(bytes("15"));

        gym.getRewards();

        vm.stopPrank();
    }

    function testHasToBePlayingList() external {
        vm.startPrank(randomUser);

        vm.expectRevert(bytes("15"));

        gym.listNFT(0, 1);

        vm.stopPrank();
    }

    function testHasToBePlayingCancelList() external {
        vm.startPrank(randomUser);

        vm.expectRevert(bytes("15"));

        gym.cancelList(0);

        vm.stopPrank();
    }

    function testHasToBePlayingBuy() external {
        vm.startPrank(randomUser);

        vm.expectRevert(bytes("15"));

        gym.buyNFT(0);

        vm.stopPrank();
    }

    function testHasToBePlayingDeposit() external {
        vm.startPrank(randomUser);

        vm.expectRevert(bytes("15"));

        gym.depositToUpgrade(0);

        vm.stopPrank();
    }

    function testHasToBePlayingCancelUpgrade() external {
        vm.startPrank(randomUser);

        vm.expectRevert(bytes("15"));

        gym.cancelUpgrade(0);

        vm.stopPrank();
    }

    function testHasToBePlayingClaim() external {
        vm.startPrank(randomUser);

        vm.expectRevert(bytes("15"));

        gym.claim(0);

        vm.stopPrank();
    }

    function testNotWaiting() external {
        vm.startPrank(randomUser);

        gym.start();

        vm.warp(block.timestamp + 2 days);

        gym.getRewards();

        vm.expectRevert(bytes("02"));

        gym.getRewards();

        vm.stopPrank();
    }

    // MARKETPLACE

    // List:

    function testJustMainCanList() external {
        uint256 NFTid = 0;
        uint256 price = 1;

        vm.startPrank(randomUser);
        gym.start();
        assertEq(gym.nft().ownerOf(NFTid), randomUser);
        Trades a = gym.marketplace();
        vm.expectRevert(bytes("08"));
        a.listNFT(randomUser, NFTid, price);
        vm.stopPrank();
    }

    function testListCorrect() external {
        uint256 NFTid = 0;
        uint256 price = 1;

        vm.startPrank(randomUser);
        gym.start();
        assertEq(gym.nft().ownerOf(NFTid), randomUser);
        gym.listNFT(NFTid, price);
        vm.stopPrank();

        (address lister_, uint256 price_) = gym.marketplace().listing(NFTid);

        assertEq(lister_, randomUser);
        assertEq(price_, price);
    }

    function testShouldRevertIfPriceIsZero() external {
        uint256 NFTid = 0;
        uint256 price = 0;

        vm.startPrank(randomUser);
        gym.start();
        assertEq(gym.nft().ownerOf(NFTid), randomUser);
        vm.expectRevert(bytes("14"));
        gym.listNFT(NFTid, price);
        vm.stopPrank();
    }

    function testListShouldRevertIfNotOwner() public {
        uint256 NFTid = 0;
        uint256 price = 1;

        vm.startPrank(randomUser);
        gym.start();
        assertEq(gym.nft().ownerOf(NFTid), randomUser);
        vm.stopPrank();

        assert(gym.nft().ownerOf(NFTid) != randomUser2);

        vm.startPrank(randomUser2);
        gym.start();
        vm.expectRevert(bytes("03"));
        gym.listNFT(NFTid, price);
        vm.stopPrank();
    }

    function testListShouldRevertIfNotExist() public {
        uint256 NFTid = 99;
        uint256 price = 1;

        vm.startPrank(randomUser);
        gym.start();
        vm.expectRevert();
        gym.listNFT(NFTid, price);
        vm.stopPrank();
    }

    // Cancel List:

    function testJustMainCanCancelList() external {
        uint256 NFTid = 0;
        uint256 price = 1;

        vm.startPrank(randomUser);
        gym.start();
        assertEq(gym.nft().ownerOf(NFTid), randomUser);
        gym.listNFT(NFTid, price);

        Trades a = gym.marketplace();
        vm.expectRevert(bytes("08"));
        a.cancelList(randomUser, NFTid);
        vm.stopPrank();
    }

    function testCancelListCorrect() external {
        uint256 NFTid = 0;
        uint256 price = 1;

        vm.startPrank(randomUser);
        gym.start();
        assertEq(gym.nft().ownerOf(NFTid), randomUser);
        gym.listNFT(NFTid, price);

        (address listerBefore_, uint256 priceBefore_) = gym.marketplace().listing(NFTid);

        gym.cancelList(NFTid);
        vm.stopPrank();

        (address listerAfter_, uint256 priceAfter_) = gym.marketplace().listing(NFTid);

        assertEq(listerBefore_, randomUser);
        assertEq(priceBefore_, price);

        assertEq(listerAfter_, address(0));
        assertEq(priceAfter_, 0);
    }

    function testCancelListShouldRevertIfNFTNotListed() external {
        uint256 NFTid = 0;
        uint256 price = 1;
        uint256 NFTNotListed = 1;

        vm.startPrank(randomUser);
        gym.start();
        assertEq(gym.nft().ownerOf(NFTid), randomUser);
        gym.listNFT(NFTid, price);

        vm.expectRevert(bytes("05"));
        gym.cancelList(NFTNotListed);
        vm.stopPrank();
    }

    function testCancelListShouldRevertIfNFTNotExist() external {
        uint256 NFTid = 0;
        uint256 price = 1;
        uint256 NFTNonExistent = 99;

        vm.startPrank(randomUser);
        gym.start();
        assertEq(gym.nft().ownerOf(NFTid), randomUser);
        gym.listNFT(NFTid, price);

        vm.expectRevert(bytes("05"));
        gym.cancelList(NFTNonExistent);
        vm.stopPrank();
    }

    function testCancelListShouldRevertIfNotOwner() public {
        uint256 NFTid = 0;
        uint256 price = 1;
        uint256 otherNFTid = 7;

        vm.startPrank(randomUser);
        gym.start();
        assertEq(gym.nft().ownerOf(NFTid), randomUser);
        gym.listNFT(NFTid, price);
        vm.stopPrank();

        assert(gym.nft().ownerOf(NFTid) != randomUser2);

        vm.startPrank(randomUser2);
        gym.start();
        gym.listNFT(otherNFTid, price);
        vm.expectRevert(bytes("05"));
        gym.cancelList(NFTid);
        vm.stopPrank();
    }

    // Buy:

    function testJustMainCanBuy() external {
        uint256 NFTid = 0;
        uint256 price = 1;

        vm.startPrank(randomUser);
        gym.start();
        assertEq(gym.nft().ownerOf(NFTid), randomUser);

        gym.listNFT(NFTid, price);
        gym.nft().approve(address(gym.marketplace()), NFTid);
        vm.stopPrank();

        vm.startPrank(randomUser2);
        gym.start();
        vm.warp(block.timestamp + 2 days);
        gym.getRewards();

        Trades a = gym.marketplace();
        vm.expectRevert(bytes("08"));
        a.buyNFT(randomUser, NFTid);
        vm.stopPrank();
    }

    function testBuyCorrect() external {
        uint256 NFTid = 0;
        uint256 price = 1;

        vm.startPrank(randomUser);
        gym.start();
        assertEq(gym.nft().ownerOf(NFTid), randomUser);

        gym.listNFT(NFTid, price);
        gym.nft().approve(address(gym.marketplace()), NFTid);
        vm.stopPrank();

        vm.startPrank(randomUser2);
        gym.start();
        vm.warp(block.timestamp + 2 days);
        gym.getRewards();

        uint256 tokensBeforeSeller = gym.token().balanceOf(randomUser);
        uint256 tokensBeforeBuyer = gym.token().balanceOf(randomUser2);
        (address listerBefore_, uint256 priceBefore_) = gym.marketplace().listing(NFTid);
        address ownerBefore = gym.nft().ownerOf(NFTid);

        gym.buyNFT(NFTid);
        vm.stopPrank();

        uint256 tokensAfterSeller = gym.token().balanceOf(randomUser);
        uint256 tokensAfterBuyer = gym.token().balanceOf(randomUser2);
        (address listerAfter_, uint256 priceAfter_) = gym.marketplace().listing(NFTid);
        address ownerAfter = gym.nft().ownerOf(NFTid);
        uint256 extraPrice = gym.nft().getPrice(NFTid) / relationPriceProduction;

        assertEq(listerBefore_, randomUser);
        assertEq(priceBefore_, price);

        assertEq(listerAfter_, address(0));
        assertEq(priceAfter_, 0);

        assertEq(tokensAfterSeller - tokensBeforeSeller, price);
        assertEq(tokensBeforeBuyer - tokensAfterBuyer, price + extraPrice);

        assertEq(ownerBefore, randomUser);
        assertEq(ownerAfter, randomUser2);
    }

    function testBuyOwnself() external {
        uint256 NFTid = 0;
        uint256 price = 1;

        vm.startPrank(randomUser);
        gym.start();
        assertEq(gym.nft().ownerOf(NFTid), randomUser);

        gym.listNFT(NFTid, price);
        gym.nft().approve(address(gym.marketplace()), NFTid);
        vm.warp(block.timestamp + 2 days);
        gym.getRewards();

        uint256 tokensBefore = gym.token().balanceOf(randomUser);
        (address listerBefore_, uint256 priceBefore_) = gym.marketplace().listing(NFTid);
        address ownerBefore = gym.nft().ownerOf(NFTid);

        gym.buyNFT(NFTid);
        vm.stopPrank();

        uint256 tokensAfter = gym.token().balanceOf(randomUser);
        (address listerAfter_, uint256 priceAfter_) = gym.marketplace().listing(NFTid);
        address ownerAfter = gym.nft().ownerOf(NFTid);
        uint256 extraPrice = gym.nft().getPrice(NFTid) / relationPriceProduction;

        assertEq(listerBefore_, randomUser);
        assertEq(priceBefore_, price);

        assertEq(listerAfter_, address(0));
        assertEq(priceAfter_, 0);

        assertEq(tokensAfter + extraPrice, tokensBefore);

        assertEq(ownerBefore, randomUser);
        assertEq(ownerAfter, randomUser);
    }

    function testRevertIfNotApprove() external {
        uint256 NFTid = 0;
        uint256 price = 1;

        vm.startPrank(randomUser);
        gym.start();

        assertEq(gym.nft().ownerOf(NFTid), randomUser);
        gym.listNFT(NFTid, price);
        vm.stopPrank();

        vm.startPrank(randomUser2);
        gym.start();
        vm.warp(block.timestamp + 2 days);
        gym.getRewards();
        vm.expectRevert();

        gym.buyNFT(NFTid);
        vm.stopPrank();
    }

    function testRevertIfNotEnoughFunds() external {
        uint256 NFTid = 0;
        uint256 price = 1000000;

        vm.startPrank(randomUser);
        gym.start();
        assertEq(gym.nft().ownerOf(NFTid), randomUser);

        gym.listNFT(NFTid, price);
        gym.nft().approve(address(gym.marketplace()), NFTid);
        vm.stopPrank();

        vm.startPrank(randomUser2);
        gym.start();
        vm.warp(block.timestamp + 2 days);
        gym.getRewards();

        assert(gym.token().balanceOf(randomUser2) < price);
        vm.expectRevert();

        gym.buyNFT(NFTid);
        vm.stopPrank();
    }

    function testRevertIfNotExtraFunds() external {
        uint256 NFTid = 0;

        vm.startPrank(randomUser);
        gym.start();
        assertEq(gym.nft().ownerOf(NFTid), randomUser);
        vm.stopPrank();

        vm.startPrank(randomUser2);
        gym.start();
        vm.warp(block.timestamp + 2 days);
        gym.getRewards();
        vm.stopPrank();

        uint256 price = gym.token().balanceOf(randomUser2);

        vm.startPrank(randomUser);
        gym.listNFT(NFTid, price);
        gym.nft().approve(address(gym.marketplace()), NFTid);
        vm.stopPrank();

        vm.startPrank(randomUser2);
        vm.expectRevert();
        gym.buyNFT(NFTid);
        vm.stopPrank();
    }

    function testCanNotBuyUnlistedNFT() external {
        uint256 NFTid = 0;
        uint256 price = 1;
        uint256 NFTNotListed = 1;

        vm.startPrank(randomUser);
        gym.start();
        assertEq(gym.nft().ownerOf(NFTid), randomUser);

        gym.listNFT(NFTid, price);
        gym.nft().approve(address(gym.marketplace()), NFTid);
        vm.stopPrank();

        vm.startPrank(randomUser2);
        gym.start();
        vm.warp(block.timestamp + 2 days);
        gym.getRewards();
        vm.expectRevert(bytes("04"));

        gym.buyNFT(NFTNotListed);
        vm.stopPrank();
    }

    // STAKEUPGRADE

    // Deposit:

    function testJustMainCanDeposit() external {
        uint256 NFTid = 0;

        vm.startPrank(address(gym));
        gym.token().mint(randomUser, 15000);
        vm.stopPrank();

        vm.startPrank(randomUser);
        gym.start();

        StakeUpgrade a = gym.upgrade();
        vm.expectRevert(bytes("08"));

        a.depositToUpgrade(randomUser, NFTid);
        vm.stopPrank();
    }

    function testDepositCorrect() external {
        uint256 NFTid = 0;

        vm.startPrank(address(gym));
        gym.token().mint(randomUser, 15000);
        vm.stopPrank();

        vm.startPrank(randomUser);
        gym.start();

        assertEq(gym.nft().ownerOf(NFTid), randomUser);
        (,, bool updatingBefore) = gym.nft().IdToData(NFTid);

        uint256 tokensBefore = gym.token().balanceOf(randomUser);

        gym.depositToUpgrade(NFTid);
        vm.stopPrank();

        (,, bool updatingAfter) = gym.nft().IdToData(NFTid);
        uint256 tokensAfter = gym.token().balanceOf(randomUser);

        assertEq(tokensBefore - tokensAfter, gym.nft().getPrice(NFTid));
        assertFalse(updatingBefore);
        assertTrue(updatingAfter);
        assertEq(gym.upgrade().elapseTimeNFT(NFTid), block.timestamp);
    }

    function testDepositRevertIfNotOwner() external {
        uint256 NFTid = 0;

        vm.startPrank(address(gym));
        gym.token().mint(randomUser2, 15000);
        vm.stopPrank();

        vm.prank(randomUser);
        gym.start();

        vm.startPrank(randomUser2);
        gym.start();
        assert(gym.nft().ownerOf(NFTid) != randomUser2);

        vm.expectRevert(bytes("03"));
        gym.depositToUpgrade(NFTid);
        vm.stopPrank();
    }

    function testDepositRevertIfNotEnoughMoney() external {
        uint256 NFTid = 0;

        vm.startPrank(randomUser);
        gym.start();

        assertEq(gym.nft().ownerOf(NFTid), randomUser);

        vm.warp(block.timestamp + 2 days);
        gym.getRewards();
        assert(gym.token().balanceOf(randomUser) < gym.nft().getPrice(NFTid));

        vm.expectRevert(bytes("07"));
        gym.depositToUpgrade(NFTid);
        vm.stopPrank();
    }

    function testCanNotDepositWhileUpdating() external {
        uint256 NFTid = 0;

        vm.startPrank(address(gym));
        gym.token().mint(randomUser, 30000);
        vm.stopPrank();

        vm.startPrank(randomUser);
        gym.start();

        gym.depositToUpgrade(NFTid);

        assertEq(gym.nft().ownerOf(NFTid), randomUser);

        (,, bool updating) = gym.nft().IdToData(NFTid);
        assertTrue(updating);
        assert(gym.nft().getPrice(NFTid) < gym.token().balanceOf(randomUser));

        vm.expectRevert(bytes("11"));
        gym.depositToUpgrade(NFTid);

        vm.stopPrank();
    }

    function testCanNotBeUpgradedBase() external {
        uint256 NFTid = 0;
        vm.startPrank(randomUser);
        gym.start();
        vm.stopPrank();

        vm.startPrank(address(gym.upgrade()));

        for (uint256 i = 1; i < maxLvlBase; i++) {
            gym.nft().lvlUp(NFTid);
        }
        vm.stopPrank();

        (uint256 lvl,,) = gym.nft().IdToData(NFTid);
        assertEq(lvl, maxLvlBase);

        vm.startPrank(randomUser);

        vm.expectRevert(bytes("06"));
        gym.depositToUpgrade(NFTid);

        vm.stopPrank();
    }

    function testCanNotBeUpgradedMulti() external {
        uint256 NFTid = amountBase;
        vm.startPrank(randomUser);
        gym.start();
        vm.stopPrank();

        vm.startPrank(address(gym.upgrade()));

        for (uint256 i = 1; i < maxLvlMulti; i++) {
            gym.nft().lvlUp(NFTid);
        }
        vm.stopPrank();

        (uint256 lvl,,) = gym.nft().IdToData(NFTid);
        assertEq(lvl, maxLvlMulti);

        vm.startPrank(randomUser);

        vm.expectRevert(bytes("06"));
        gym.depositToUpgrade(NFTid);

        vm.stopPrank();
    }

    // Cancel Upgrade:

    function testJustMainCanCancelUpgrade() external {
        uint256 NFTid = 0;

        vm.startPrank(address(gym));
        gym.token().mint(randomUser, 15000);
        vm.stopPrank();

        vm.startPrank(randomUser);
        gym.start();

        gym.depositToUpgrade(NFTid);

        StakeUpgrade a = gym.upgrade();
        vm.expectRevert(bytes("08"));

        a.cancelUpgrade(randomUser, NFTid);
        vm.stopPrank();
    }

    function testCancelUpgradeCorrect() external {
        uint256 NFTid = 0;

        vm.startPrank(address(gym));
        gym.token().mint(randomUser, 15000);
        vm.stopPrank();

        vm.startPrank(randomUser);
        gym.start();

        gym.depositToUpgrade(NFTid);

        (,, bool updatingBefore) = gym.nft().IdToData(NFTid);
        uint256 tokensBefore = gym.token().balanceOf(randomUser);
        assertEq(gym.nft().ownerOf(NFTid), randomUser);

        gym.cancelUpgrade(NFTid);

        (,, bool updatingAfter) = gym.nft().IdToData(NFTid);
        uint256 tokensAfter = gym.token().balanceOf(randomUser);

        vm.stopPrank();

        assert(
            tokensAfter - tokensBefore < gym.nft().getPrice(NFTid)
                && (tokensAfter - tokensBefore) * 10 > gym.nft().getPrice(NFTid) * 8
        );
        assertTrue(updatingBefore);
        assertFalse(updatingAfter);
        assertEq(gym.upgrade().elapseTimeNFT(NFTid), 0);
    }

    function testCancelUpgradeRevertNotOwner() external {
        uint256 NFTid = 0;

        vm.startPrank(address(gym));
        gym.token().mint(randomUser, 15000);
        vm.stopPrank();

        vm.startPrank(randomUser);
        gym.start();

        gym.depositToUpgrade(NFTid);

        vm.stopPrank();

        vm.startPrank(randomUser2);

        gym.start();
        assertNotEq(gym.nft().ownerOf(NFTid), randomUser2);

        vm.expectRevert(bytes("03"));
        gym.cancelUpgrade(NFTid);
        vm.stopPrank();
    }

    function testCancelUpgradeRevertNotDeposed() external {
        uint256 NFTid = 0;

        vm.startPrank(randomUser);
        gym.start();

        assertEq(gym.nft().ownerOf(NFTid), randomUser);

        vm.expectRevert(bytes("12"));
        gym.cancelUpgrade(NFTid);
        vm.stopPrank();
    }

    // Claim:

    function testJustMainCanClaim() external {
        uint256 NFTid = 0;

        vm.startPrank(address(gym));
        gym.token().mint(randomUser, 15000);
        vm.stopPrank();

        vm.startPrank(randomUser);
        gym.start();

        gym.depositToUpgrade(NFTid);

        vm.warp(block.timestamp + upgradePeriodPerLvl + 0.5 days);

        StakeUpgrade a = gym.upgrade();
        vm.expectRevert(bytes("08"));

        a.claim(randomUser, NFTid);
        vm.stopPrank();
    }

    function testClaimCorrect() external {
        uint256 NFTid = 0;

        vm.startPrank(address(gym));
        gym.token().mint(randomUser, 15000);
        vm.stopPrank();

        vm.startPrank(randomUser);
        gym.start();

        gym.depositToUpgrade(NFTid);

        (uint8 lvlBefore,, bool updatingBefore) = gym.nft().IdToData(NFTid);
        uint256 tokensBefore = gym.token().balanceOf(randomUser);
        assertEq(gym.nft().ownerOf(NFTid), randomUser);

        vm.warp(block.timestamp + upgradePeriodPerLvl + 0.5 days);

        gym.claim(NFTid);

        (uint8 lvlAfter,, bool updatingAfter) = gym.nft().IdToData(NFTid);
        uint256 tokensAfter = gym.token().balanceOf(randomUser);

        vm.stopPrank();

        assert(lvlAfter == lvlBefore + 1);
        assertEq(tokensAfter, tokensBefore);
        assertTrue(updatingBefore);
        assertFalse(updatingAfter);
        assertEq(gym.upgrade().elapseTimeNFT(NFTid), 0);
    }

    function testRevertIfClaimBeforeReady() external {
        uint256 NFTid = 0;

        vm.startPrank(address(gym));
        gym.token().mint(randomUser, 15000);
        vm.stopPrank();

        vm.startPrank(randomUser);
        gym.start();

        gym.depositToUpgrade(NFTid);

        (,, bool updating) = gym.nft().IdToData(NFTid);
        assertEq(gym.nft().ownerOf(NFTid), randomUser);
        assertTrue(updating);

        vm.expectRevert(bytes("13"));
        gym.claim(NFTid);

        vm.stopPrank();
    }

    function testLvlChangeClaimTime() external {
        uint256 NFTid = 0;

        vm.startPrank(address(gym));
        gym.token().mint(randomUser, 100000);
        vm.stopPrank();

        vm.startPrank(randomUser);
        gym.start();

        gym.depositToUpgrade(NFTid);
        vm.warp(block.timestamp + upgradePeriodPerLvl + 0.1 days);
        gym.claim(NFTid);

        gym.depositToUpgrade(NFTid);
        vm.warp(block.timestamp + upgradePeriodPerLvl * 2 + 0.2 days);
        gym.claim(NFTid);

        gym.depositToUpgrade(NFTid);
        vm.warp(block.timestamp + upgradePeriodPerLvl + 0.3 days);
        vm.expectRevert(bytes("13"));
        gym.claim(NFTid);

        vm.stopPrank();
    }

    function testClaimRevertNotOwner() external {
        uint256 NFTid = 0;

        vm.startPrank(address(gym));
        gym.token().mint(randomUser, 15000);
        vm.stopPrank();

        vm.startPrank(randomUser);
        gym.start();

        gym.depositToUpgrade(NFTid);

        vm.stopPrank();

        vm.warp(block.timestamp + 1.5 days);

        vm.startPrank(randomUser2);

        gym.start();
        assertNotEq(gym.nft().ownerOf(NFTid), randomUser2);

        vm.expectRevert(bytes("03"));
        gym.claim(NFTid);
        vm.stopPrank();
    }

    function testClaimRevertNotDeposed() external {
        uint256 NFTid = 0;

        vm.startPrank(randomUser);
        gym.start();

        assertEq(gym.nft().ownerOf(NFTid), randomUser);
        vm.warp(block.timestamp + 1.5 days);

        vm.expectRevert(bytes("12"));
        gym.claim(NFTid);
        vm.stopPrank();
    }

    // TOKEN

    function testJustAllowedCanMint() external {
        myToken a = gym.token();

        vm.startPrank(address(gym.upgrade()));

        a.mint(randomUser, 100);

        vm.stopPrank();
        assertEq(a.balanceOf(randomUser), 100);

        vm.startPrank(address(gym));

        a.mint(randomUser, 100);

        vm.stopPrank();
        assertEq(a.balanceOf(randomUser), 200);

        vm.startPrank(address(gym.marketplace()));

        a.mint(randomUser, 100);

        vm.stopPrank();
        assertEq(a.balanceOf(randomUser), 300);

        vm.startPrank(randomUser);

        vm.expectRevert(bytes("08"));
        a.mint(randomUser, 100);

        vm.stopPrank();
    }

    function testJustUpgradeCanBurn() external {
        myToken a = gym.token();

        vm.startPrank(address(gym.upgrade()));

        a.mint(randomUser, 100);
        a.burn(randomUser, 40);

        vm.stopPrank();

        assertEq(a.balanceOf(randomUser), 60);

        vm.startPrank(address(gym.marketplace()));

        a.burn(randomUser, 10);

        vm.stopPrank();

        assertEq(a.balanceOf(randomUser), 50);

        vm.startPrank(address(gym));

        vm.expectRevert(bytes("08"));
        a.burn(randomUser, 40);
        vm.stopPrank();
    }

    function testJustMainCanSetUpgrade() external {
        myToken a = gym.token();

        vm.startPrank(address(gym));

        a.setUpgrade(address(gym));

        vm.stopPrank();

        assertEq(a.upgrade(), address(gym));

        vm.startPrank(randomUser);

        vm.expectRevert(bytes("08"));
        a.setUpgrade(randomUser);
        vm.stopPrank();
    }

    function testJustMainCanSetTrades() external {
        myToken a = gym.token();

        vm.startPrank(address(gym));
        a.setTrades(address(gym));
        vm.stopPrank();

        assertEq(a.trades(), address(gym));

        vm.startPrank(randomUser);
        vm.expectRevert(bytes("08"));
        a.setTrades(randomUser);
        vm.stopPrank();
    }

    // NFT

    function testJustTradesCanTransferNFT() external {
        myNFT a = gym.nft();
        vm.startPrank(address(gym));
        a.mintAll(randomUser2);
        vm.stopPrank();
    }

    function testJustTradesCanSafeTransferNFT() external {
        uint256 NFTid = 0;
        uint256 NFTid2 = 1;
        myNFT a = gym.nft();

        vm.startPrank(address(gym));
        a.mintAll(randomUser);
        vm.stopPrank();

        vm.startPrank(randomUser);
        gym.nft().approve(address(gym.marketplace()), NFTid);
        gym.nft().approve(address(randomUser2), NFTid2);
        vm.stopPrank();

        vm.startPrank(address(gym.marketplace()));
        assertEq(gym.nft().ownerOf(NFTid), randomUser);
        a.safeTransferFrom(randomUser, randomUser2, NFTid);
        assertEq(gym.nft().ownerOf(NFTid), randomUser2);
        vm.stopPrank();

        vm.startPrank(address(randomUser2));
        assertEq(gym.nft().ownerOf(NFTid2), randomUser);
        vm.expectRevert(bytes("08"));
        a.safeTransferFrom(randomUser, randomUser2, NFTid2);
        vm.stopPrank();
    }

    function testJustMainCanMintNFT() external {
        myNFT a = gym.nft();

        vm.startPrank(address(gym));
        a.mintAll(randomUser2);
        vm.stopPrank();

        assertEq(a.balanceOf(randomUser2), amountMulti + amountBase);

        vm.startPrank(randomUser);
        vm.expectRevert(bytes("08"));
        a.mintAll(randomUser);
        vm.stopPrank();
    }

    function testJustMainCanSetUpgradeNFT() external {
        myNFT a = gym.nft();

        vm.startPrank(address(gym));

        a.setUpgrade(address(gym));

        vm.stopPrank();

        assertEq(a.upgrade(), address(gym));

        vm.startPrank(randomUser);

        vm.expectRevert(bytes("08"));
        a.setUpgrade(randomUser);
        vm.stopPrank();
    }

    function testJustMainCanSetTradesNFT() external {
        myNFT a = gym.nft();

        vm.startPrank(address(gym));
        a.setTrades(address(gym));
        vm.stopPrank();

        assertEq(a.trades(), address(gym));

        vm.startPrank(randomUser);
        vm.expectRevert(bytes("08"));
        a.setTrades(randomUser);
        vm.stopPrank();
    }

    function testJustUpgradeCanUpgradeNFT() external {
        myNFT a = gym.nft();

        vm.startPrank(address(gym.upgrade()));

        a.setUpgrading(0, true);

        vm.stopPrank();

        vm.startPrank(randomUser);

        vm.expectRevert(bytes("08"));
        a.setUpgrading(1, false);
        vm.stopPrank();
    }

    function testJustUpgradeCanLvlUpNFT() external {
        myNFT a = gym.nft();

        vm.startPrank(address(gym.upgrade()));

        a.lvlUp(0);

        vm.stopPrank();

        vm.startPrank(randomUser);

        vm.expectRevert(bytes("08"));
        a.lvlUp(0);
        vm.stopPrank();
    }

    function testGetPriceDiferentLvlNFT() external {
        vm.startPrank(address(gym));
        gym.nft().mintAll(randomUser);
        vm.stopPrank();

        uint256 lvl1_base = gym.nft().getPrice(0);

        uint256 lvl1_multi = gym.nft().getPrice(amountBase);

        vm.startPrank(address(gym.upgrade()));
        gym.nft().lvlUp(0);
        gym.nft().lvlUp(0);
        gym.nft().lvlUp(0);

        gym.nft().lvlUp(amountBase);
        gym.nft().lvlUp(amountBase);
        gym.nft().lvlUp(amountBase);
        vm.stopPrank();

        uint256 lvl4_base = gym.nft().getPrice(0);

        uint256 lvl4_multi = gym.nft().getPrice(amountBase);

        assertEq(lvl1_base, baseProductionPerLvl * relationPriceProduction * 1);
        assertEq(lvl1_multi, boostPercentagePerLvl * baseProductionPerLvl * 1);
        assertEq(lvl4_base, baseProductionPerLvl * relationPriceProduction * 4);
        assertEq(lvl4_multi, boostPercentagePerLvl * baseProductionPerLvl * 8);
    }

    function testUrisCorrect() external {
        string memory base64;

        vm.startPrank(randomUser);
        gym.start();
        vm.stopPrank();

        base64 =
            "data:application/json;base64,eyJuYW1lIjogIlBsYXRlcyAoQmFzZSkiLCJkZXNjcmlwdGlvbiI6ICJORlQgb2YgdHljb29uIGd5bSIsImltYWdlIjogImlwZnM6Ly9iYWZ5YmVpYTR2N2VhZHA2cjRudWYzZWk1Y3VjZjYyaHdpZ2FyaTZrYnZicWdna2c1ZTJkZnh3cWh4ZS8xLnBuZyIsImF0dHJpYnV0ZXMiOiBbeyJ0cmFpdF90eXBlIjogIkxldmVsIiwgInZhbHVlIjogMX0seyJ0cmFpdF90eXBlIjoiUHJvZHVjdGlvbiIsICJ2YWx1ZSI6IDEwMDB9LHsidHJhaXRfdHlwZSI6ICJVcGdyYWRlX3ByaWNlIiwgInZhbHVlIjogMTAwMDB9XX0=";
        assertEq(base64, gym.nft().tokenURI(0));

        base64 =
            "data:application/json;base64,eyJuYW1lIjogIkNyZWF0aW5lIChNdWx0aSkiLCJkZXNjcmlwdGlvbiI6ICJORlQgb2YgdHljb29uIGd5bSIsImltYWdlIjogImlwZnM6Ly9iYWZ5YmVpYTR2N2VhZHA2cjRudWYzZWk1Y3VjZjYyaHdpZ2FyaTZrYnZicWdna2c1ZTJkZnh3cWh4ZS8xMS5wbmciLCJhdHRyaWJ1dGVzIjogW3sidHJhaXRfdHlwZSI6ICJMZXZlbCIsICJ2YWx1ZSI6IDF9LHsidHJhaXRfdHlwZSI6IkJvb3N0ICglKSIsICJ2YWx1ZSI6IDEwNX0seyJ0cmFpdF90eXBlIjogIlVwZ3JhZGVfcHJpY2UiLCAidmFsdWUiOiA1MDAwfV19";
        assertEq(base64, gym.nft().tokenURI(amountBase));

        vm.startPrank(address(gym.upgrade()));
        gym.nft().lvlUp(0);
        gym.nft().lvlUp(amountBase);
        vm.stopPrank();

        base64 =
            "data:application/json;base64,eyJuYW1lIjogIlBsYXRlcyAoQmFzZSkiLCJkZXNjcmlwdGlvbiI6ICJORlQgb2YgdHljb29uIGd5bSIsImltYWdlIjogImlwZnM6Ly9iYWZ5YmVpYTR2N2VhZHA2cjRudWYzZWk1Y3VjZjYyaHdpZ2FyaTZrYnZicWdna2c1ZTJkZnh3cWh4ZS8yLnBuZyIsImF0dHJpYnV0ZXMiOiBbeyJ0cmFpdF90eXBlIjogIkxldmVsIiwgInZhbHVlIjogMn0seyJ0cmFpdF90eXBlIjoiUHJvZHVjdGlvbiIsICJ2YWx1ZSI6IDIwMDB9LHsidHJhaXRfdHlwZSI6ICJVcGdyYWRlX3ByaWNlIiwgInZhbHVlIjogMjAwMDB9XX0=";
        assertEq(base64, gym.nft().tokenURI(0));

        base64 =
            "data:application/json;base64,eyJuYW1lIjogIkNyZWF0aW5lIChNdWx0aSkiLCJkZXNjcmlwdGlvbiI6ICJORlQgb2YgdHljb29uIGd5bSIsImltYWdlIjogImlwZnM6Ly9iYWZ5YmVpYTR2N2VhZHA2cjRudWYzZWk1Y3VjZjYyaHdpZ2FyaTZrYnZicWdna2c1ZTJkZnh3cWh4ZS8xMS5wbmciLCJhdHRyaWJ1dGVzIjogW3sidHJhaXRfdHlwZSI6ICJMZXZlbCIsICJ2YWx1ZSI6IDJ9LHsidHJhaXRfdHlwZSI6IkJvb3N0ICglKSIsICJ2YWx1ZSI6IDExMH0seyJ0cmFpdF90eXBlIjogIlVwZ3JhZGVfcHJpY2UiLCAidmFsdWUiOiAxMDAwMH1dfQ==";
        assertEq(base64, gym.nft().tokenURI(amountBase));
    }

    function testCanNotGetUriOfInexistendNFT() external {
        myNFT a = gym.nft();

        vm.startPrank(randomUser);

        gym.start();
        vm.expectRevert();
        a.tokenURI(10);

        vm.stopPrank();
    }

    // COMPOSITE FUNCTIONS

    function testRevertsClaimAfterCancelDeposit() external {
        uint256 NFTid = 0;

        vm.startPrank(address(gym));
        gym.token().mint(randomUser, 15000);
        vm.stopPrank();

        vm.startPrank(randomUser);
        gym.start();

        gym.depositToUpgrade(NFTid);

        gym.cancelUpgrade(NFTid);

        vm.expectRevert(bytes("12"));

        gym.claim(NFTid);

        vm.stopPrank();
    }

    function testRevertsBuyAfterCancelList() external {
        uint256 NFTid = 0;
        uint256 price = 1;

        vm.startPrank(randomUser);
        gym.start();
        assertEq(gym.nft().ownerOf(NFTid), randomUser);
        gym.listNFT(NFTid, price);
        gym.nft().approve(address(gym.marketplace()), NFTid);
        gym.cancelList(NFTid);
        vm.stopPrank();

        vm.startPrank(randomUser2);
        gym.start();
        vm.warp(block.timestamp + 2 days);
        gym.getRewards();
        vm.expectRevert(bytes("04"));

        gym.buyNFT(NFTid);
        vm.stopPrank();
    }

    function testGetRewardsAfterSelling() external {
        uint256 NFTid = 0;
        uint256 price = 1;

        vm.startPrank(randomUser);
        gym.start();
        assertEq(gym.nft().ownerOf(NFTid), randomUser);
        gym.listNFT(NFTid, price);
        gym.nft().approve(address(gym.marketplace()), NFTid);
        vm.stopPrank();

        vm.startPrank(randomUser2);
        gym.start();
        vm.warp(block.timestamp + 2 days);
        gym.getRewards();
        gym.buyNFT(NFTid);
        vm.stopPrank();

        vm.startPrank(randomUser);

        uint256 tokensBefore = gym.token().balanceOf(randomUser);
        vm.warp(block.timestamp + 2 days);
        gym.getRewards();
        uint256 tokensAfter = gym.token().balanceOf(randomUser);

        uint256 expectedAmount = (amountBase - 1) * baseProductionPerLvl * (100 + boostPercentagePerLvl * amountMulti);

        assertEq(tokensAfter - tokensBefore, expectedAmount / 100);

        vm.stopPrank();
    }

    function testBuyWhileUpgrading() external {
        uint256 NFTid = 0;
        uint256 price = 1;

        vm.startPrank(address(gym));
        gym.token().mint(randomUser, 15000);
        vm.stopPrank();

        vm.startPrank(randomUser);
        gym.start();

        assertEq(gym.nft().ownerOf(NFTid), randomUser);
        (,, bool updatingBefore) = gym.nft().IdToData(NFTid);

        gym.depositToUpgrade(NFTid);

        gym.listNFT(NFTid, price);
        gym.nft().approve(address(gym.marketplace()), NFTid);
        vm.stopPrank();

        vm.startPrank(randomUser2);
        gym.start();
        vm.warp(block.timestamp + 2 days);
        gym.getRewards();

        gym.buyNFT(NFTid);

        (,, bool updatingAfter) = gym.nft().IdToData(NFTid);
        assertFalse(updatingBefore);
        assertTrue(updatingAfter);

        uint256 tokensBefore = gym.token().balanceOf(randomUser2);
        gym.cancelUpgrade(NFTid);
        uint256 tokensAfter = gym.token().balanceOf(randomUser2);
        assert(tokensAfter > tokensBefore);

        assertEq(gym.nft().ownerOf(NFTid), randomUser2);

        vm.stopPrank();
    }

    function testUpgradeWhileSelling() external {
        uint256 NFTid = 0;
        uint256 price = 1;
        vm.startPrank(address(gym));
        gym.token().mint(randomUser, 15000);
        vm.stopPrank();

        vm.startPrank(randomUser);
        gym.start();
        assertEq(gym.nft().ownerOf(NFTid), randomUser);
        gym.listNFT(NFTid, price);

        gym.depositToUpgrade(NFTid);
        (uint8 lvlBefore,, bool updatingBefore) = gym.nft().IdToData(NFTid);
        assertEq(gym.nft().ownerOf(NFTid), randomUser);
        vm.warp(block.timestamp + upgradePeriodPerLvl + 0.5 days);
        gym.claim(NFTid);

        (address lister_, uint256 price_) = gym.marketplace().listing(NFTid);
        assertEq(lister_, randomUser);
        assertEq(price_, price);

        gym.cancelList(NFTid);
        (address listerAfter_, uint256 priceAfter_) = gym.marketplace().listing(NFTid);
        assertEq(listerAfter_, address(0));
        assertEq(priceAfter_, 0);

        (uint8 lvlAfter,, bool updatingAfter) = gym.nft().IdToData(NFTid);
        assert(lvlAfter == lvlBefore + 1);
        assertTrue(updatingBefore);
        assertFalse(updatingAfter);

        vm.stopPrank();
    }
}

