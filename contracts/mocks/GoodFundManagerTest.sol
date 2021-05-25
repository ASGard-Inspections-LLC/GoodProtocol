// SPDX-License-Identifier: MIT
pragma solidity >0.5.4;

import "../staking/GoodFundManager.sol";

contract GoodFundManagerTest is GoodFundManager {
	constructor(
		NameService _ns,
		address _cDai,
		address _bridgeContract,
		address _ubiRecipient,
		uint256 _blockInterval //ActivePeriod(block.timestamp, block.timestamp * 2, _avatar)
	) GoodFundManager() {
		initialize(_ns);
	}

	/**
	 * @dev Function to test internal sorting functions
	 */
	function testSorting(uint256[] memory data, address[] memory addresses)
		public
		pure
		returns (uint256[] memory, address[] memory)
	{
		quick(data, addresses);
		return (data, addresses);
	}
}
