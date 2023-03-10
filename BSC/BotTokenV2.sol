/************************************************************
 *
 * Autor: BotPlanet
 *
 * 446576656c6f7065723a20416e746f6e20506f6c656e79616b61 ****/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IPancakeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (
            uint amountToken,
            uint amountETH,
            uint liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path)
        external
        view
        returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path)
        external
        view
        returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract BotToken is ERC20, Ownable {
    // Usings

    using Address for address;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Structs

    struct WalletConfig {
        bool isExcludedFromFee;
        bool isExcludedFromMaxWalletAmount;
        bool isExcludedFromMaxTxAmount;
        bool isExcludedFromCirculationSupply;
    }

    // Constants

    uint256 private constant MAX = ~uint256(0);
    address public constant ROUTER_ADDRESS =
        0x10ED43C718714eb63d5aA57B78B54704E256024E; // BSC
    //address public ROUTER_ADDRESS = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // BSC TestNet
    uint256 private constant DEFAULT_MAX_TX_PER = 100;
    uint256 private constant DEFAULT_MAX_WALLET_PER = 1;
    uint256 private MAX_SUPPLY_V1 = 1000000000 * 1e18;
    uint256 private MAX_SUPPLY_V2 = 1000000000 * 1e18;

    // Attributies

    mapping(address => WalletConfig) private _configs;
    // Addressed to ignore from holder list, because is used for other reasons and is not real holders
    mapping(address => bool) internal _blockedHolders;
    EnumerableSet.AddressSet internal _holderList; // All token holders

    // Properties

    IPancakeRouter02 public immutable pcsV2Router;
    address public immutable pcsV2Pair;
    uint256 public maxTxAmount;
    uint256 public maxWalletAmount;
    uint256 public burnFee = 2; // 2%

    // Constructor

    constructor() ERC20("BOT", "BOT") {
        address tokenOwner = address(
            0xe919621cae4bE24eb2cA43E5D077816690D96767
        );

        setMaxTxPercent(DEFAULT_MAX_TX_PER);
        setMaxWalletPercent(DEFAULT_MAX_WALLET_PER);

        // Create a PancakeSwap pair for this new token
        IPancakeRouter02 _pcsV2Router = IPancakeRouter02(ROUTER_ADDRESS);
        pcsV2Pair = IPancakeFactory(_pcsV2Router.factory()).createPair(
            address(this),
            _pcsV2Router.WETH()
        );
        pcsV2Router = _pcsV2Router;

        // Owner wallet configuration
        _configs[tokenOwner].isExcludedFromFee = true;
        _configs[tokenOwner].isExcludedFromMaxWalletAmount = true;
        _configs[tokenOwner].isExcludedFromMaxTxAmount = true;
        // Current contract configuration
        _configs[address(this)].isExcludedFromFee = true;
        _configs[address(this)].isExcludedFromMaxWalletAmount = true;
        _configs[address(this)].isExcludedFromMaxTxAmount = true;
        // Pancake pair configuration
        _configs[pcsV2Pair].isExcludedFromFee = false;
        _configs[pcsV2Pair].isExcludedFromMaxWalletAmount = true;
        _configs[pcsV2Pair].isExcludedFromMaxTxAmount = true;

        // We ignore holders, who is contracts/special address and is not real holder of tokens
        _blockedHolders[address(0)] = true;
        _blockedHolders[address(this)] = true;

        // Mint tokens to owner
        _mint(tokenOwner, MAX_SUPPLY_V2);
    }

    // Private/Internal Methods

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal view override {
        require(
            amount_ > 0,
            "BotToken: Transfer amount must be greater than zero"
        );
        // Check if exceeds max transfer amount
        if (
            !_configs[from_].isExcludedFromMaxTxAmount &&
            !_configs[to_].isExcludedFromMaxTxAmount
        ) {
            require(
                amount_ <= maxTxAmount,
                "BotToken: Transfer amount exceeds the max tx amount."
            );
        }
        // Check if exceeds new wallet amount
        if (
            !_configs[from_].isExcludedFromMaxWalletAmount &&
            !_configs[to_].isExcludedFromMaxWalletAmount
        ) {
            uint256 contractBalanceRecepient = balanceOf(to_);
            require(
                contractBalanceRecepient + amount_ <= maxWalletAmount,
                "BotToken: Exceeds maximum wallet amount"
            );
        }
    }

    function _transfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal override {
        // Check if apply fee or not
        if (
            _configs[from_].isExcludedFromFee || _configs[to_].isExcludedFromFee
        ) {
            // Don't take fee
            super._transfer(from_, to_, amount_);
        } else {
            // Take fee and burn it
            uint256 toBurnAmount = (amount_ * burnFee) / 100;
            _burn(from_, toBurnAmount);
            super._transfer(from_, to_, amount_ - toBurnAmount);
        }
    }

    // With this function, after tokens is transfer, we review holder list to remove 0 balance holders,
    // and add new holders with new balance
    function _afterTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal override {
        // Step 0: Check if amount is to change anything. If is 0, we don't change any list of holders,
        // because really we don't have any change in amounts
        if (amount_ > 0) {
            // Step 1: Check from account (not accept mint case)
            if (
                from_ != address(0) &&
                balanceOf(from_) == 0 &&
                !_blockedHolders[from_]
            ) {
                // This address not has any balance
                require(
                    _holderList.remove(from_),
                    "BotToken: cannot remove holder"
                );
            }
            // Step 2: Check to account && Check if holder is allowed
            if (
                to_ != address(0) &&
                !_holderList.contains(to_) &&
                !_blockedHolders[to_]
            ) {
                // Is not burn case. Add holder to list
                require(
                    _holderList.add(to_),
                    "BotToken: cannot add new holder"
                );
            }
        }
    }

    // Public/External Methods

    function setBurnFee(uint256 burnFee_) external onlyOwner {
        require(
            burnFee_ >= 1 && burnFee_ <= 100,
            "BotToken: set bern fee percent"
        );
        burnFee = burnFee_;
    }

    function setMaxTxPercent(uint256 maxTxPercent_) public onlyOwner {
        require(
            maxTxPercent_ >= 1 && maxTxPercent_ <= 100,
            "BotToken: set max tx percent"
        );
        maxTxAmount = (totalSupply() * maxTxPercent_) / 100;
    }

    function setMaxWalletPercent(uint256 maxWalletPercent_) public onlyOwner {
        require(
            maxWalletPercent_ >= 1 && maxWalletPercent_ <= 100,
            "BotToken: set max wallet percent"
        );
        maxWalletAmount = (totalSupply() * maxWalletPercent_) / 100;
    }

    function setBlockedHolder(address account_, bool isBlocked_)
        external
        onlyOwner
    {
        _blockedHolders[account_] = isBlocked_;
    }

    function setIsExcludedFromFee(address account_, bool value_)
        public
        onlyOwner
    {
        _configs[account_].isExcludedFromFee = value_;
    }

    function setIsExcludedFromMaxWalletAmount(address account_, bool value_)
        public
        onlyOwner
    {
        _configs[account_].isExcludedFromMaxWalletAmount = value_;
    }

    function setIsExcludedFromMaxTxAmount(address account_, bool value_)
        public
        onlyOwner
    {
        _configs[account_].isExcludedFromMaxTxAmount = value_;
    }

    function setIsExcludedFromCirculationSupply(address account_, bool value_)
        public
        onlyOwner
    {
        _configs[account_].isExcludedFromCirculationSupply = value_;
    }

    function burn(uint256 amount_) public {
        _burn(msg.sender, amount_);
    }

    function holder(uint256 index_) public view returns (address) {
        return _holderList.at(index_);
    }

    function walletConfig(address account_)
        public
        view
        returns (WalletConfig memory)
    {
        return _configs[account_];
    }

    function isBlockedHolder(address account_) public view returns (bool) {
        return _blockedHolders[account_];
    }

    function numberOfHolders() external view returns (uint256) {
        return _holderList.length();
    }

    function numberTokensBurned() external view returns (uint256) {
        return MAX_SUPPLY_V1 - totalSupply();
    }

    function maxSupply() public view returns (uint256) {
        return MAX_SUPPLY_V1;
    }

    function circulationSupply() public view returns (uint256) {
        return _holderList.length() - _holderList.length();
    }

    // To recieve ETH from pcsV2Router when swaping
    receive() external payable {}
}
