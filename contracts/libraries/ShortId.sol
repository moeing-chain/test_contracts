// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// File: contracts/utils/Strings.sol

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

library ShortId {
    function shortIdFromURI(bytes memory uri) internal pure returns (uint64) {
        uint result = uint(uint8(uri[0])) - 65;
        result = result * 26 + uint(uint8(uri[1])) - 65;
        result = result * 26 + uint(uint8(uri[2])) - 65;
        uint low32 = 0;
        for(uint i = 3; i < uri.length; i++) {
            low32 = low32 * 10 + uint(uint8(uri[i])) - 48;
        }
        return uint64((1<<48) | (result<<32) | low32);
    }

    function shortIdToURI(uint64 id) internal pure returns (string memory) {
        bytes memory buffer = new bytes(3);
        uint high16 = uint(id >> 32) & ((1<<16)-1);
        buffer[2] = byte(uint8(65 + high16 % 26));
        high16 = high16 / 26;
        buffer[1] = byte(uint8(65 + high16 % 26));
        high16 = high16 / 26;
        buffer[0] = byte(uint8(65 + high16));
        string memory s = Strings.toString(uint(uint32(id)));
        return string(abi.encodePacked(buffer, s));
    }

    // 16-bit int 1, 16-bit int no larger than 17576(26*26*26), 32-bit int
    function toValidShortId(uint id) internal pure returns (uint64) {
        uint low32 = uint32(id);
        uint high16 =  (id>>32) & ((1<<16)-1);
        high16 = high16 % (26*26*26);
        return uint64((1<<48) | (high16<<32) | low32);
    }

}
