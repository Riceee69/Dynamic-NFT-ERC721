// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";


contract BullBearClub is ERC721, ERC721URIStorage, AutomationCompatibleInterface, VRFConsumerBaseV2Plus {
    AggregatorV3Interface internal dataFeed;

    uint256 private _nextTokenId;
    uint256 public interval;
    uint256 public lastTimeStamp;
    int public btcUsdPrice;

    uint256 public randomArrayIndex;
    uint256[] public randomWordsArray;
    uint256 public requestId;

    enum MarketTrend{
        BULL, 
        BEAR
    }
    MarketTrend public marketTrend;

    //VRF contract variables
    uint256 s_subscriptionId;
    address vrfCoordinator = 0xEc29164D68c4992cEdd1D386118A47143fdcF142;
    bytes32 s_keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a528f6719ff003f5289a;
    uint32 callbackGasLimit = 250000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;


    // IPFS URIs for the dynamic nft graphics/metadata.
    string[] bullUrisIpfs = [
        "https://ipfs.io/ipfs/QmRXyfi3oNZCubDxiVFre3kLZ8XeGt6pQsnAQRZ7akhSNs?filename=gamer_bull.json",
        "https://ipfs.io/ipfs/QmRJVFeMrtYS2CUVUM2cHJpBV5aX2xurpnsfZxLTTQbiD3?filename=party_bull.json",
        "https://ipfs.io/ipfs/QmdcURmN1kEEtKgnbkVJJ8hrmsSWHpZvLkRgsKKoiWvW9g?filename=simple_bull.json"
    ];

    string[] bearUrisIpfs = [
        "https://ipfs.io/ipfs/Qmdx9Hx7FCDZGExyjLR6vYcnutUR8KhBZBnZfAPHiUommN?filename=beanie_bear.json",
        "https://ipfs.io/ipfs/QmTVLyTSuiKGUEmb88BgXG3qNC8YgpHZiFbjHrXKH3QHEu?filename=coolio_bear.json",
        "https://ipfs.io/ipfs/QmbKhBXVWmwrYsTPFYfroR2N7NAekAMxHUVg2CWks7i9qj?filename=simple_bear.json"
    ];
        
    event TokensUpdated(string trend);

    constructor(uint256 updateInterval, uint256 subscriptionId, address _priceFeed)
        ERC721("Bull&BearClub", "BBC")
        VRFConsumerBaseV2Plus(vrfCoordinator)
    {
        s_subscriptionId = subscriptionId;
        interval = updateInterval;
        lastTimeStamp = block.timestamp;

        dataFeed = AggregatorV3Interface(
            _priceFeed
        );

        btcUsdPrice = getLatestPrice();
    }

    function safeMint() public {
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);

        // Default to a bull NFT
        string memory defaultUri = bullUrisIpfs[0];
        _setTokenURI(tokenId, defaultUri);
    }

    function checkUpkeep(bytes calldata /*checkData*/) external view 
    override returns (bool upKeepNeeded, bytes memory /*performData*/)
    {
        upKeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata /*performData*/) external override{
        if((block.timestamp - lastTimeStamp) > interval){
            int currentPrice = getLatestPrice();
            lastTimeStamp = block.timestamp;

            //Implement the Bull Bear Dynamic Mechanics
            if (currentPrice > btcUsdPrice){
                marketTrend = MarketTrend.BULL;
            }else if(currentPrice < btcUsdPrice){
                marketTrend = MarketTrend.BEAR;
            }else{
                return;
            }

            btcUsdPrice = currentPrice;
            randomArrayIndexGenerator();
        }
    }

    function getLatestPrice() public view returns(int) {
        //fetch BTC/USD price
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();

        return answer;
    }

    function randomArrayIndexGenerator() public returns(uint256){
        require(s_subscriptionId != 0, "No subscription set");
        // Will revert if subscription is not set and funded.
       requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                // Set nativePayment to true to pay for VRF requests with native token instead of LINK
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );

        return requestId;
    }

    function fulfillRandomWords(uint256 /*requestId*/, uint256[] calldata randomWords) internal override {
        randomWordsArray = randomWords;
        // transform the result to a number between 0 and 2 inclusively
        randomArrayIndex = (randomWords[0] % 3);

        string[] memory uriReqForTrend = marketTrend == MarketTrend.BULL? bullUrisIpfs : bearUrisIpfs;

        for(uint i = 0; i < _nextTokenId; i++){
            uint256 tokenId = i;
            string memory randomUriForTrend = uriReqForTrend[randomArrayIndex];
            _setTokenURI(tokenId, randomUriForTrend);
        }

        emit TokensUpdated(marketTrend == MarketTrend.BULL? "bullish" : "bearish");
    }

    function setInterval(uint256 value) public {
        interval = value;
    }


    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
