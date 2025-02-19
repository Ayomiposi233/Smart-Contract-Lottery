// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";
import {LinkToken} from "test/Mocks/LinkToken.sol";
import {VRFCoordinatorV2_5Mock} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract InteractionsTest is Test {
    HelperConfig helperConfig;
    Raffle raffle;
    CreateSubscription createSubscription;
    FundSubscription fundSubscription;
    AddConsumer addConsumer;

    address vrfCoordinator;
    address account;
    uint256 subscriptionId;
    address linkToken;

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.deployContract();
        createSubscription = new CreateSubscription();
        fundSubscription = new FundSubscription();
        addConsumer = new AddConsumer();
        vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        account = helperConfig.getConfig().account;
        subscriptionId = helperConfig.getConfig().subscriptionId;
        linkToken = helperConfig.getConfig().link;
    }

    function testUserCanCreateFundAndAddConsumerToSubscription() external {
        // first Create a Subscription
        (subscriptionId, vrfCoordinator) = createSubscription.createSubscription(vrfCoordinator, account);
        // Verify that the Subscription is Valid
        assert(subscriptionId != 0);

        // Check balance of new subscription before funding
        (uint256 startingBalance,,,,) = VRFCoordinatorV2_5Mock(vrfCoordinator).getSubscription(subscriptionId);

        // Fund the  Subscription using config details for the ChainID
        vm.chainId(block.chainid);
        fundSubscription.fundSubscription(vrfCoordinator, subscriptionId, linkToken, account);

        // Check balance of Subscription after Funding
        (uint256 fundedBalance,,,,) = VRFCoordinatorV2_5Mock(vrfCoordinator).getSubscription(subscriptionId);
        // Verify that the Subscription has been funded by comparing starting & funded balance
        assertTrue(fundedBalance > startingBalance, "subscription is not funded");

        // Proceed to add a consumer contract to the subscription
        bool isConsumer = false;
        addConsumer.addConsumer(address(raffle), vrfCoordinator, subscriptionId, account);

        // Check that the consumer has been added for the SubscriptionID
        (,,,, address[] memory addedConsumer) = VRFCoordinatorV2_5Mock(vrfCoordinator).getSubscription(subscriptionId);

        uint256 consumerIndex;
        if (addedConsumer[consumerIndex] == address(raffle)) {
            isConsumer = true;
        }
        // Verify the added consumer by asserting that it is indeed a consumer contract
        assertTrue(isConsumer, "raffle is not an added consumer");
    }
}
