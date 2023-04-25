// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.19;

import "forge-std/Test.sol";

library HexDecoder {
    function decode(string memory input) public pure returns (bytes memory output) {
        uint256 len = bytes(input).length >> 1;

        //bytes memory b = bytes(input);

        output = new bytes(len);

        uint256 i = 0;

        uint256 pos;

        if (len > 8) {
            bytes1[103] memory lookup;
            bytes1[103] memory lookdown;

            lookdown[0x31] = 0x01;
            lookdown[0x32] = 0x02;
            lookdown[0x33] = 0x03;
            lookdown[0x34] = 0x04;
            lookdown[0x35] = 0x05;
            lookdown[0x36] = 0x06;
            lookdown[0x37] = 0x07;
            lookdown[0x38] = 0x08;
            lookdown[0x39] = 0x09;
            lookdown[0x41] = 0x0a;
            lookdown[0x42] = 0x0b;
            lookdown[0x43] = 0x0c;
            lookdown[0x44] = 0x0d;
            lookdown[0x45] = 0x0e;
            lookdown[0x46] = 0x0f;
            lookdown[0x61] = 0x0a;
            lookdown[0x62] = 0x0b;
            lookdown[0x63] = 0x0c;
            lookdown[0x64] = 0x0d;
            lookdown[0x65] = 0x0e;
            lookdown[0x66] = 0x0f;

            lookup[0x31] = 0x10;
            lookup[0x32] = 0x20;
            lookup[0x33] = 0x30;
            lookup[0x34] = 0x40;
            lookup[0x36] = 0x60;
            lookup[0x37] = 0x70;
            lookup[0x38] = 0x80;
            lookup[0x39] = 0x90;
            lookup[0x41] = 0xa0;
            lookup[0x42] = 0xb0;
            lookup[0x43] = 0xc0;
            lookup[0x44] = 0xd0;
            lookup[0x45] = 0xe0;
            lookup[0x46] = 0xf0;
            lookup[0x61] = 0xa0;
            lookup[0x62] = 0xb0;
            lookup[0x63] = 0xc0;
            lookup[0x64] = 0xd0;
            lookup[0x65] = 0xe0;
            lookup[0x66] = 0xf0;

            while (pos < len) {
                output[pos++] = lookdown[uint8(bytes(input)[i++])] | lookup[uint8(bytes(input)[i++])];
            }

            return output;
        }

        uint8 c;

        uint8 total;

        while (pos < len) {
            total = uint8(bytes(input)[i++]);

            if (total < 0x40) {
                total -= 0x30;
            } else if (total < 0x60) {
                total -= 0x37;
            } else {
                total -= 0x37;
            }

            total = total << 4;

            c = uint8(bytes(input)[i++]);

            if (c < 0x40) {
                total += c - 0x30;
            } else if (c < 0x60) {
                total += c - 0x37;
            } else {
                total += c - 0x57;
            }

            output[pos++] = bytes1(total);
        }
    }
}

library LibSelector {
    function remove(bytes4[] memory _facetCuts, bytes4 selector) internal pure returns (bytes4[] memory facetCuts_) {
        uint256 len = _facetCuts.length;

        facetCuts_ = new bytes4[](len- 1);

        uint256 i;

        uint256 j;

        for (; i < len;) {
            if (_facetCuts[i] == selector) {
                unchecked {
                    ++i;
                }

                continue;
            } else {
                facetCuts_[j] = _facetCuts[i];

                unchecked {
                    ++i;

                    ++j;
                }
            }
        }
    }

    function remove(bytes4[] memory _facetCuts, string memory signature)
        internal
        pure
        returns (bytes4[] memory facetCuts_)
    {
        bytes4 selector = bytes4(keccak256(bytes(signature)));

        uint256 len = _facetCuts.length;

        facetCuts_ = new bytes4[](len- 1);

        uint256 i;

        uint256 j;

        for (; i < len;) {
            if (_facetCuts[i] == selector) {
                unchecked {
                    ++i;
                }

                continue;
            } else {
                facetCuts_[j] = _facetCuts[i];

                unchecked {
                    ++i;

                    ++j;
                }
            }
        }
    }

    function remove(bytes4[] memory _facetCuts, bytes4[] memory removedSelector)
        internal
        pure
        returns (bytes4[] memory facetCuts_)
    {
        uint256 len = _facetCuts.length - removedSelector.length;

        facetCuts_ = new bytes4[](len);

        uint256 index = 0;

        for (uint256 i = 0; i < _facetCuts.length; i++) {
            bool found = false;

            for (uint256 j = 0; j < removedSelector.length; j++) {
                if (_facetCuts[i] == removedSelector[j]) {
                    found = true;

                    break;
                }
            }

            if (!found) {
                facetCuts_[index] = _facetCuts[i];

                index++;
            }
        }
    }

    function compare(bytes4[] memory arr1, bytes4[] memory arr2) public pure returns (bool) {
        if (arr1.length != arr2.length) {
            return false;
        }

        // 为两个数组排序

        sort(arr1);

        sort(arr2);

        for (uint256 i = 0; i < arr1.length; i++) {
            if (arr1[i] != arr2[i]) {
                return false;
            }
        }

        return true;
    }

    function sort(bytes4[] memory arr) internal pure {
        for (uint256 i = 0; i < arr.length - 1; i++) {
            for (uint256 j = i + 1; j < arr.length; j++) {
                if (arr[i] > arr[j]) {
                    bytes4 temp = arr[i];

                    arr[i] = arr[j];

                    arr[j] = temp;
                }
            }
        }
    }
}

contract Selectors is Test {
    bytes4[] public selectors;

    function getAllSelector(string memory path, string memory solName, string memory contractName)
        public
        returns (bytes4[] memory facetCuts)
    {
        string[] memory inputs = new string[](3);

        string memory bashCommand =
            string.concat("forge inspect ", string.concat(path, "/", solName, ":", contractName, " mi --pretty"));

        inputs[0] = "bash";
        inputs[1] = "-c";
        inputs[2] = bashCommand;
        bytes memory res = vm.ffi(inputs);

        string memory outPath = string.concat("selectors/", contractName, ".json");
        vm.writeJson(string(res), outPath);

        string memory data = vm.readLine(outPath);

        uint256 len = bytes(data).length;

        for (;;) {
            data = vm.readLine(outPath);

            len = bytes(data).length;

            if (bytes(data)[len - 1] == bytes1(0x7d)) {
                vm.closeFile(outPath);

                break;
            }

            bytes memory selector = new bytes(8);

            if (bytes(data)[len - 1] == bytes1(0x2c)) {
                for (uint256 i = 0; i < 8; ++i) {
                    selector[i] = bytes(data)[len - 10 + i];
                }
            } else {
                for (uint256 i = 0; i < 8; ++i) {
                    selector[i] = bytes(data)[len - 9 + i];
                }
            }

            selectors.push(bytes4(HexDecoder.decode(string(selector))));
        }

        facetCuts = selectors;

        selectors = new bytes4[](0);
    }
}
