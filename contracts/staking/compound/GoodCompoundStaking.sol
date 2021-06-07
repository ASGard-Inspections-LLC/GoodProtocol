// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;
import "../SimpleStaking.sol";
import "../../Interfaces.sol";

/**
 * @title Staking contract that donates earned interest to the DAO
 * allowing stakers to deposit Token
 * or withdraw their stake in Token
 * the contracts buy cToken and can transfer the daily interest to the  DAO
 */
contract GoodCompoundStaking is SimpleStaking {
	// Address of the TOKEN/USD oracle from chainlink
	address public tokenUsdOracle;

	// Address of COMP usd oracle
	address public compUsdOracle;

	/**
	 * @param _token Token to swap DEFI token
	 * @param _iToken DEFI token address
	 * @param _ns Address of the NameService
	 * @param _tokenName Name of the staking token which will be provided to staker for their staking share
	 * @param _tokenSymbol Symbol of the staking token which will be provided to staker for their staking share
	 * @param _tokenSymbol Determines blocks to pass for 1x Multiplier
	 * @param _tokenUsdOracle address of the TOKEN/USD oracle
	 * @param _collectInterestGasCost Gas cost for the collect interest of this staking contract
	 */
	function init(
		address _token,
		address _iToken,
		NameService _ns,
		string memory _tokenName,
		string memory _tokenSymbol,
		uint64 _maxRewardThreshold,
		address _tokenUsdOracle,
		uint32 _collectInterestGasCost
	) public {
		initialize(
			_token,
			_iToken,
			_ns,
			_tokenName,
			_tokenSymbol,
			_maxRewardThreshold,
			_collectInterestGasCost
		);
		//above  initialize going  to revert on second call, so this is safe
		tokenUsdOracle = _tokenUsdOracle;
		compUsdOracle = address(0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5);
	}

	/**
	 * @dev stake some Token
	 * @param _amount of Token to stake
	 */
	function mintInterestToken(uint256 _amount) internal override {
		cERC20 cToken = cERC20(address(iToken));
		require(
			cToken.mint(_amount) == 0,
			"Minting cToken failed, funds returned"
		);
	}

	/**
	 * @dev redeem Token from compound
	 * @param _amount of token to redeem in Token
	 */
	function redeem(uint256 _amount) internal override {
		cERC20 cToken = cERC20(address(iToken));
		require(
			cToken.redeemUnderlying(_amount) == 0,
			"Failed to redeem cToken"
		);
	}

	/**
	 * @dev Function to redeem cToken for DAI, so reserve knows how to handle it. (reserve can handle dai or cdai)
	 * @dev _amount of token in iToken
	 * @return return address of the DAI and amount of the DAI
	 */
	function redeemUnderlyingToDAI(uint256 _amount)
		internal
		override
		returns (address, uint256)
	{
		if (address(iToken) == nameService.getAddress("CDAI")) {
			return (address(iToken), _amount); // If iToken is cDAI then just return cDAI, as reserve is in CDAI we save conversion from dai to cdai
		}
		cERC20 cToken = cERC20(address(iToken));
		require(cToken.redeem(_amount) == 0, "Failed to redeem cToken");
		uint256 redeemedAmount = token.balanceOf(address(this));
		address daiAddress = nameService.getAddress("DAI");
		address[] memory path = new address[](2);
		path[0] = address(token);
		path[1] = daiAddress;
		Uniswap uniswapContract =
			Uniswap(nameService.getAddress("UNISWAP_ROUTER"));
		token.approve(address(uniswapContract), redeemedAmount);
		uint256[] memory swap =
			uniswapContract.swapExactTokensForTokens(
				redeemedAmount,
				0,
				path,
				address(this),
				block.timestamp
			);

		uint256 dai = swap[1];
		require(dai > 0, "token selling failed");
		return (daiAddress, swap[1]);
	}

	/**
	 * @dev returns decimals of token.
	 */
	function tokenDecimal() internal view override returns (uint256) {
		ERC20 token = ERC20(address(token));
		return uint256(token.decimals());
	}

	/**
	 * @dev returns decimals of interest token.
	 */
	function iTokenDecimal() internal view override returns (uint256) {
		ERC20 cToken = ERC20(address(iToken));
		return uint256(cToken.decimals());
	}

	function currentGains(
		bool _returnTokenBalanceInUSD,
		bool _returnTokenGainsInUSD
	)
		public
		view
		override
		returns (
			uint256,
			uint256,
			uint256,
			uint256,
			uint256
		)
	{
		cERC20 cToken = cERC20(address(iToken));
		uint256 er = cToken.exchangeRateStored();
		(uint256 decimalDifference, bool caseType) = tokenDecimalPrecision();
		uint256 mantissa = 18 + tokenDecimal() - iTokenDecimal();
		uint256 tokenBalance =
			iTokenWorthInToken(iToken.balanceOf(address(this)));
		uint256 balanceInUSD =
			_returnTokenBalanceInUSD
				? getTokenValueInUSD(tokenUsdOracle, tokenBalance)
				: 0;
		if (tokenBalance <= totalProductivity) {
			return (0, 0, tokenBalance, balanceInUSD, 0);
		}
		uint256 tokenGains = tokenBalance - totalProductivity;
		uint256 iTokenGains;
		if (caseType) {
			iTokenGains =
				((tokenGains / 10**decimalDifference) * 10**mantissa) /
				er; // based on https://compound.finance/docs#protocol-math
		} else {
			iTokenGains =
				((tokenGains * 10**decimalDifference) * 10**mantissa) /
				er; // based on https://compound.finance/docs#protocol-math
		}
		uint256 tokenGainsInUSD =
			_returnTokenGainsInUSD
				? getTokenValueInUSD(tokenUsdOracle, tokenGains)
				: 0;
		return (
			iTokenGains,
			tokenGains,
			tokenBalance,
			balanceInUSD,
			tokenGainsInUSD
		);
	}

	function getGasCostForInterestTransfer()
		external
		view
		override
		returns (uint32)
	{
		return collectInterestGasCost;
	}

	/**
	 * @dev Calculates worth of given amount of iToken in Token
	 * @param _amount Amount of token to calculate worth in Token
	 * @return Worth of given amount of token in Token
	 */
	function iTokenWorthInToken(uint256 _amount)
		public
		view
		override
		returns (uint256)
	{
		cERC20 cToken = cERC20(address(iToken));
		uint256 er = cToken.exchangeRateStored();
		(uint256 decimalDifference, bool caseType) = tokenDecimalPrecision();
		uint256 mantissa = 18 + tokenDecimal() - iTokenDecimal();
		uint256 tokenWorth =
			caseType == true
				? (_amount * (10**decimalDifference) * er) / 10**mantissa
				: ((_amount / (10**decimalDifference)) * er) / 10**mantissa; // calculation based on https://compound.finance/docs#protocol-math
		return tokenWorth;
	}
}
