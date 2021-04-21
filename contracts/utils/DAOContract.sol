// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../DAOStackInterfaces.sol";
import "./NameService.sol";

/**
@title Simple contract that adds onlyAvatar modifier
*/

contract DAOContract {
	Controller public dao;

	Avatar public avatar;

	NameService public nameService;

	function _onlyAvatar() internal {
		require(
			address(dao.avatar()) == msg.sender,
			"only avatar can call this method"
		);
	}

	function setDAO(NameService _ns) internal {
		dao = Controller(_ns.getAddress("CONTROLLER"));
		nameService = _ns;
		updateAvatar();
	}

	function updateAvatar() public {
		avatar = dao.avatar();
	}

	uint256[50] private gap;
}
