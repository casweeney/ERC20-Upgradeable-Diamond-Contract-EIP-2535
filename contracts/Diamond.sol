// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {ERC20Storage} from "./libraries/LibERC20Storage.sol";
import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";

contract Diamond {
    ERC20Storage internal token;

    constructor(
        address _contractOwner,
        address _diamondCutFacet,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimal,
        uint256 tokenSupply,
        address facetAddress,
        bytes memory constructData
    ) payable {
        LibDiamond.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({facetAddress: _diamondCutFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors});
        LibDiamond.diamondCut(cut, facetAddress, constructData);

        token._name = tokenName;
        token._symbol = tokenSymbol;
        token._decimal = tokenDecimal;
        token._totalSupply = tokenSupply * tokenDecimal;
        token._owner = _contractOwner;

        // Examples of ways to mint ERC20 token on deployment

        // Eg:1
        // token._balances[_contractOwner] = tokenSupply;
        // emit Transfer(address(0), account, amount);

        // Eg:2
        /**
        1. Import AppStorage into Diamond.sol and declare it in Diamond.sol so you can use it. For example: AppStorage storage s 
        2. Then copy the internal function _mint() from your facet into Diamond.sol  and call it in the constructor function
        If _mint() calls other internal functions then you need to copy those into Diamond.sol too
        If there is a lot of copying then I suggest instead making Diamond inherit a contract that includes the internal functions you need so you can call _mint 
        Or you could create a Solidity library with only internal functions which includes _mint   and import and use that in your Diamond.sol and in your ERC20Facet.   This way you are only have the code in one place (the Solidity library)  and you can import and use it in different places.
        The other way to handle this is this:
        1. Deploy your ERC20Facet.
        2. Pass the ERC20Face address as a parameter to the Diamond.sol constructor function and execute mint  with delegatecall on the ERC20Facet address,   and make sure your diamond has permission to call that function 
         */
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}
