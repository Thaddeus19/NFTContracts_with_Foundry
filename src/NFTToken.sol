// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "./AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title ERC721 contract
 * ERC721 contract has minting functionality.
 */
contract NFTToken is ERC721, AccessControl, Ownable {
    ///@notice custom errors
    error thecontractispaused();
    error havenoadminrole();
    //error havenominterrole();
    error maxsupplyexceeded();
    error wrongpayment();
    error failwithdraw();
    error nonexistenttoken(uint256 _tokenId);

    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter public _nextTokenId;

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    ///@dev If you do not wish to have a minter role and leave the minting open
    ///@dev you can delete or comment out this variable. 
    //bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public maxSupply = 1000;

    uint256 public cost = 1 ether;

    bool public paused = false;

    bool public reveal = false;

    ///@dev Here should be the url of the metadata with the information
    ///@dev prior to revealing the actual metadata of the project. 
    string public hideUri =
        "https://gateway.pinata.cloud/ipfs/QmQwWMSWTV928UfMBHT8ibWTikrQ8suB7GP73ARyWuaATq";

    constructor(string memory _baseUri) ERC721("NFT Test", "CNFT") {
        ///@param nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        _nextTokenId.increment();

        ///@notice This function (_setupRole) helps to assign an administrator role 
        ///@notice that can then assign new roles.
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        //_setupRole(MINTER_ROLE, msg.sender);

        ///@dev If you already have the IPFS url where the final metadata of the project 
        ///@dev is you can load it here in the builder. Otherwise you can delete this line 
        ///@dev and when you have the url load it by calling the function setUriPrefix 
        setUriPrefix(_baseUri);
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) public {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert havenoadminrole();
        }
        if (paused) {
            revert thecontractispaused();
        }
        if (totalSupply() >= maxSupply) {
            revert maxsupplyexceeded();
        }
        uint256 currentTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(_to, currentTokenId);
    }

    function mint() public payable {
        if (paused) {
            revert thecontractispaused();
        }
        if(msg.value < cost){
            revert wrongpayment();
        }
        if (totalSupply() >= maxSupply) {
            revert maxsupplyexceeded();
        }
        uint256 currentTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(msg.sender, currentTokenId);
    }

    ///@dev Returns the total tokens minted so far.
    ///@dev 1 is always subtracted from the Counter since it tracks the next available tokenId.
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    ///@notice If you need the option to pause the contract, 
    ///@notice activate this function, only the ADMIN role can do it.
    function setPaused(bool _state) public {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert havenoadminrole();
        }
        paused = _state;
    }

    ///@notice Returns the url of the metadata, 
    ///@notice if the reveal option is set to false then the generic metadata is returned. 
    ///@notice If reveal is set to true it returns the official metadata of the collection. 
    ///@param _tokenId Is the id from which you want to get the url of the metadata
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if(!_exists(_tokenId)){
            revert nonexistenttoken(_tokenId);
       }
        if (!reveal) {
            return hideUri;
        } else {
            string memory currentBaseURI = _baseURI();
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            _tokenId.toString(),
                            uriSuffix
                        )
                    )
                    : "";
        }
    }

    ///@notice This function allows to place the IPFS url for the official metadata. 
    ///@notice it can only be called by the admin roll.
    ///@param _uriPrefix is the IPFS url for the official metadata 
    function setUriPrefix(string memory _uriPrefix) public {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert havenoadminrole();
        }
        uriPrefix = _uriPrefix;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    ///@notice This function helps to reveal the official metadata of the project. 
    ///@notice Once set to true it cannot be modified, it can only be called by the admin roll.
    function setreveal() public {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert havenoadminrole();
        }
        reveal = true;
    }

    function withdraw() public {  
    ///@dev Do not remove this otherwise you will not be able to withdraw the funds.
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
        revert havenoadminrole();
    }
    uint256 balance = address(this).balance;
    (bool success, ) = payable(msg.sender).call{value: balance}("");
    if(!success){
        revert failwithdraw();
    }
  }

    ///@dev Use this function only in testnet to delete the contract at the end of the tests
    function kill() public {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert havenoadminrole();
        }
        address payable addr = payable(address(msg.sender));
        selfdestruct(addr);
    }
}
