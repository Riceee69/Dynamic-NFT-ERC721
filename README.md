# This is a NFT ERC721 contract that changes its URI dynamically depending upon the BTC price, If the price goes up it changes to a random bull URI and if it goes down it changes to a random bear URI from the URIs provided to the contract.

Chainlink's VRF is used for the randomisation of the URI

Chainlink's Data Feed is used for fetching the BTC/USD price

Chainlink's Automation is used to set a repeating time interval after which the price is fetched 

Read the chainlink docs to learn how to setup mock contracts to test the smart contract functionalities: https://docs.chain.link/


