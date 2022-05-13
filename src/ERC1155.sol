// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./AccessControl.sol";
import "./ERC115URIStorage.sol";

/// @title  ERC1155 contract
/// @notice This contract is to create an ERC1155 collection with custom metadata.
/// @author Mariano Salazar
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol)

contract Objects is AccessControl, Ownable, ERC115URIStorage {
    error exceedssupply();
    error havenoadminrole();

    using Strings for uint256;
    // Token name
    string private _name;
    // Token symbol
    string private _symbol;

    constructor() ERC1155("") {
        create(
            0,
            99,
            "https://ipfs.moralis.io:2053/ipfs/QmbCUjN57GbsPsQhcqjNwSf2DDbRthqy5DYKbqPSwwTBX6/metadata/0.json",
            ""
        );
        create(
            1,
            100,
            "https://ipfs.moralis.io:2053/ipfs/QmbCUjN57GbsPsQhcqjNwSf2DDbRthqy5DYKbqPSwwTBX6/metadata/1.json",
            ""
        );
        create(
            2,
            1,
            "https://ipfs.moralis.io:2053/ipfs/QmbCUjN57GbsPsQhcqjNwSf2DDbRthqy5DYKbqPSwwTBX6/metadata/2.json",
            ""
        );
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _name = "Test ERC1155";
        _symbol = "TE1155";
    }

    function create(
        uint256 id,
        uint256 amount,
        string memory _tokenURI,
        bytes memory data
    ) public {
        uint256 max = supply[id];
        if (max >= 100) {
            revert exceedssupply();
        }
        supply[id] += amount;
        _mint(msg.sender, id, amount, data);
        _setTokenURI(id, _tokenURI);
    }

    function closeMetadata() public virtual {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert havenoadminrole();
        }
        _closeMetadata();
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
}
