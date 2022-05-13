// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/// @title  ERC1155 Uri Storage
/// @notice This contract helps to place custom metadata to the NFT and close it at the end of the collection creation
/// @author Mariano Salazar
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol)

abstract contract ERC115URIStorage is ERC1155 {
    error metadataclosed();

    using Strings for uint256;

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) public supply;

    string private _uri;

    string private uriSuffix = ".json";

    bool private close = false;

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseuri(tokenId);

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI, uriSuffix));
        }

        return super.uri(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(_exists(tokenId), "nonexistent token");
        if (close) {
            revert metadataclosed();
        }
        _tokenURIs[tokenId] = _tokenURI;
    }

    function burn_(uint256 tokenId) internal virtual {
        super._burn(msg.sender, tokenId, 1);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return supply[tokenId] > 0;
    }

    function baseuri(uint256) internal view virtual returns (string memory) {
        return _uri;
    }

    function _closeMetadata() internal virtual {
        close = true;
    }
}
