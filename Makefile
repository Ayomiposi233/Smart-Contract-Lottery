-include .env

.PHONY: all test deploy

build:; forge build

test:; forge test

update:; forge update

format:; forge fmt

install:; forge install cyfrin/foundry-devops@0.2.2 --no-commit && forge install smartcontractkit/chainlink-brownie-contract@1.1.1 --no-commit && forge install foundry-rs/forge-std@v1.8.2 --no-commit && forge install transmissions11/solmate@v6 --no-commit

deploy-sepolia:
	@forge script script/DeployRaffle.s.sol --rpc-url $(SEPOLIA_RPC_URL) --account default --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

deploy-anvil:
	@forge script script/DeployRaffle.s.sol --rpc-url http://127.0.0.1:8545 --account --broadcast --verify -vvvv