// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.19;

import "../src/upgradeInitializers/DiamondInit.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src//facets/OwnershipFacet.sol";
import "../src/facets/Test1Facet.sol";
import "../src/facets/Test2Facet.sol";
import "../src/Diamond.sol";
import "../src/interfaces/IDiamond.sol";

import "../script/libraries/diamond.sol";

contract Deploy is Selectors {
    using LibSelector for bytes4[];

    DiamondInit diamondInit;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    Diamond diamond;

    Test1Facet test1Facet;
    Test2Facet test2Facet;

    function setUp() public {
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

        bytes4[] memory facetFunctionSelectors =
            DiamondLoupeFacet(address(diamond)).facetFunctionSelectors(address(diamondCutFacet));
        assertTrue(LibSelector.compare(facetFunctionSelectors, facetCuts[0].functionSelectors));

        facetFunctionSelectors = DiamondLoupeFacet(address(diamond)).facetFunctionSelectors(address(diamondLoupeFacet));
        assertTrue(LibSelector.compare(facetFunctionSelectors, facetCuts[1].functionSelectors));

        facetFunctionSelectors = DiamondLoupeFacet(address(diamond)).facetFunctionSelectors(address(ownershipFacet));
        assertTrue(LibSelector.compare(facetFunctionSelectors, facetCuts[2].functionSelectors));
    }

    function testDiamond() public {
        // Add Test1Facet

        {
            test1Facet = new Test1Facet();

            IDiamond.FacetCut[] memory facetCuts = new IDiamond.FacetCut[](1);
            facetCuts[0].facetAddress = address(test1Facet);
            facetCuts[0].action = IDiamond.FacetCutAction.Add;
            facetCuts[0].functionSelectors =
                getAllSelector("src/facets", "Test1Facet.sol", "Test1Facet").remove("supportsInterface(bytes4)");

            DiamondCutFacet(address(diamond)).diamondCut(facetCuts, address(0), "");

            bytes4[] memory facetFunctionSelectors =
                DiamondLoupeFacet(address(diamond)).facetFunctionSelectors(address(test1Facet));
            assertTrue(LibSelector.compare(facetFunctionSelectors, facetCuts[0].functionSelectors));

            Test1Facet(address(diamond)).test1Func1();
            assertEq(Test1Facet(address(diamond)).test1Func2(), address(diamond));
        }

        // Replace supportsInterface function

        {
            IDiamond.FacetCut[] memory facetCuts = new IDiamond.FacetCut[](1);
            facetCuts[0].facetAddress = address(test1Facet);
            facetCuts[0].action = IDiamond.FacetCutAction.Replace;
            bytes4[] memory ReplaceSelectors = new bytes4[](1);
            ReplaceSelectors[0] = Test1Facet.supportsInterface.selector;
            facetCuts[0].functionSelectors = ReplaceSelectors;

            DiamondCutFacet(address(diamond)).diamondCut(facetCuts, address(0), "");

            bytes4[] memory facetFunctionSelectors =
                DiamondLoupeFacet(address(diamond)).facetFunctionSelectors(address(test1Facet));
            bytes4[] memory AllSelectors = getAllSelector("src/facets", "Test1Facet.sol", "Test1Facet");
            assertTrue(LibSelector.compare(facetFunctionSelectors, AllSelectors));
        }

        // Add Test2Facet

        {
            test2Facet = new Test2Facet();

            IDiamond.FacetCut[] memory facetCuts = new IDiamond.FacetCut[](1);
            facetCuts[0].facetAddress = address(test2Facet);
            facetCuts[0].action = IDiamond.FacetCutAction.Add;
            facetCuts[0].functionSelectors = getAllSelector("src/facets", "Test2Facet.sol", "Test2Facet");

            DiamondCutFacet(address(diamond)).diamondCut(facetCuts, address(0), "");

            bytes4[] memory facetFunctionSelectors =
                DiamondLoupeFacet(address(diamond)).facetFunctionSelectors(address(test2Facet));
            assertTrue(LibSelector.compare(facetFunctionSelectors, facetCuts[0].functionSelectors));
        }

        // Remove some test2 functions

        {
            IDiamond.FacetCut[] memory facetCuts = new IDiamond.FacetCut[](1);

            facetCuts[0].facetAddress = address(0);
            facetCuts[0].action = IDiamond.FacetCutAction.Remove;
            bytes4[] memory RemoveSelectors = new bytes4[](2);
            RemoveSelectors[0] = Test2Facet.test2Func1.selector;
            RemoveSelectors[1] = Test2Facet.test2Func2.selector;
            facetCuts[0].functionSelectors = RemoveSelectors;

            DiamondCutFacet(address(diamond)).diamondCut(facetCuts, address(0), "");

            bytes4[] memory facetFunctionSelectors =
                DiamondLoupeFacet(address(diamond)).facetFunctionSelectors(address(test2Facet));

            bytes4[] memory remainder =
                (getAllSelector("src/facets", "Test2Facet.sol", "Test2Facet").remove(RemoveSelectors));
            assertTrue(LibSelector.compare(facetFunctionSelectors, remainder));
        }
    }
}
