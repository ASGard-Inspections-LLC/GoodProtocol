// SPDX-License-Identifier: MIT

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

contract DSMath {
	function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = (x * y + (10**27 / 2)) / 10**27;
	}

	function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = (x * (10**27) + (y / 2)) / y;
	}
}
