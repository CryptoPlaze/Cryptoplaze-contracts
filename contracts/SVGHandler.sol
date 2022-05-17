// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "base64-sol/base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library SVGHandler {
    function isValidHex(string memory hexCode) internal pure returns (bool) {
        uint256 len = bytes(hexCode).length;
        return len == 6 || len == 3;
    }

    function formatHex(string memory hexCode)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("#", hexCode));
    }

    function svgToImageURI(string memory svg)
        internal
        pure
        returns (string memory)
    {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svg)))
        );
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    function createSVG(string memory hexCode)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<svg width="100" viewBox="0 0 1 1" height="100" xmlns="http://www.w3.org/2000/svg"><rect fill="#',
                    hexCode,
                    '" width="1" height="1"/></svg>'
                )
            );
    }

    function formatTokenURI(string memory imageURI, uint256 tokenNumber)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                "Millionth puzzle piece",
                                '", "description":"#',
                                Strings.toString(tokenNumber),
                                '", "attributes":"", "image":"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}
