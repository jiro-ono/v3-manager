-include .env.defaults
-include .env
export

SCRIPT_DIR = ./script
TEST_DIR = ./test

build:
	forge build
rebuild: clean build
install: init
init:
	git submodule update --init --recursive
	git update-index --assume-unchanged playground/*
	forge install
test:
	forge test -vv
test-gas-report:
	forge test -vv --gas-report
trace:
	forge test -vvvv
remappings:
	forge remappings > remappings.txt

playground: FOUNDRY_TEST:=playground
playground:
	forge test --match-path playground/Playground.t.sol -vv
playground-trace: FOUNDRY_TEST:=playground
playground-trace:
	forge test --match-path playground/Playground.t.sol -vvvv --gas-report

deploy:
	forge script ./scripts/DeployTokenChomper.s.sol --broadcast --slow --optimize --optimizer-runs 999999 --verify --rpc-url ${RPC_URL} --chain ${CHAIN_ID} --etherscan-api-key ${ETHERSCAN_API_KEY}

.PHONY: test playground