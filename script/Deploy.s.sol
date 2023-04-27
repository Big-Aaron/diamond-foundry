// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/upgradeInitializers/DiamondInit.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src//facets/OwnershipFacet.sol";
import "../src/facets/Test1Facet.sol";
import "../src/facets/Test2Facet.sol";
import "../src/Diamond.sol";
import "../src/interfaces/IDiamond.sol";

import "./libraries/diamond.sol";

contract DeployScript is Script, Selectors {
    using LibSelector for bytes4[];

    DiamondInit diamondInit;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    Diamond diamond;

    Test1Facet test1Facet;
    Test2Facet test2Facet;

    function run() external {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));

        vm.startBroadcast(deployerPrivateKey);

        {
            string[] memory inputs = new string[](3);

            inputs[0] = "bash";
            inputs[1] = "-c";
            inputs[2] = string.concat("mkdir selectors");
            vm.ffi(inputs);

            diamondInit = new DiamondInit();
            diamondCutFacet = new DiamondCutFacet();
            diamondLoupeFacet = new DiamondLoupeFacet();
            ownershipFacet = new OwnershipFacet();

            IDiamond.FacetCut[] memory facetCuts = new IDiamond.FacetCut[](3);
            facetCuts[0].facetAddress = address(diamondCutFacet);
            facetCuts[0].action = IDiamond.FacetCutAction.Add;
            facetCuts[0].functionSelectors = getAllSelector("src/facets", "DiamondCutFacet.sol", "DiamondCutFacet");

            facetCuts[1].facetAddress = address(diamondLoupeFacet);
            facetCuts[1].action = IDiamond.FacetCutAction.Add;
            facetCuts[1].functionSelectors = getAllSelector("src/facets", "DiamondLoupeFacet.sol", "DiamondLoupeFacet");

            facetCuts[2].facetAddress = address(ownershipFacet);
            facetCuts[2].action = IDiamond.FacetCutAction.Add;
            facetCuts[2].functionSelectors = getAllSelector("src/facets", "OwnershipFacet.sol", "OwnershipFacet");

            bytes memory initCalldata = abi.encodeWithSelector(DiamondInit.init.selector);

            DiamondArgs memory args =
                DiamondArgs({owner: msg.sender, init: address(diamondInit), initCalldata: initCalldata});

            diamond = new Diamond(facetCuts, args);
            console.log("Diamond deployed at address: %s", address(diamond));
        }
    }
}
