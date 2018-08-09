pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/PausableToken.sol";
import "./OwnerManager.sol";
import "./LibString.sol";

/*
 * 投票挖矿增发Token、销毁token
 * authored by luozx@1264995828@qq.com
 * 2017-07-31
 */
contract AbstractBallotMintableBurnableToken is PausableToken, OwnerManager {
    using LibString for string;

    /* 是否可以开启新一轮币增发的初始化,用于防止在投票过程中遭到owner恶意修改增发币量和接收地址 */
    modifier canMineInit() {
       require(ballotAffairsMap[keccak256(affairName_coin_mint)].isBalloting == false);
       _;
    }

    // 投票事件I名称
    string affairName_coin_mint = "coin_mine";
    // 挖矿地址，收获token
    address miner;
    // 挖矿产生token数量（增发）
    uint256 mintAmount;
    // 记录 增发的币
    event CoinMinted(uint256 ballotMembersCount, address miner, uint256 mintCount);

    // 记录 销毁的币
    event CoinBurned(address burner, uint256 burnedAmount);

    /*
     * 构造方法
     * successPercent：投票通过数量百分比*100
     */
    constructor(uint8 coin_mint_successPercent, uint8 asset_transfer_successPercent, uint8 admin_add_successPercent, uint8 admin_del_successPercent)
        OwnerManager(asset_transfer_successPercent, admin_add_successPercent, admin_del_successPercent){
        // 投票事件启停标识器
        bool isBallotFinished = false;
        // 投票事件 版本，标识第几轮
        uint8 affairVersion = 0;
        // 投票人数记录器
        uint256 ballotedMemsCount = 0;
                
        ballotAffairsMap[keccak256(affairName_coin_mint)] = Ballot(affairName_coin_mint, isBallotFinished, affairVersion, ballotedMemsCount, coin_mint_successPercent);
        //ballotAffairsMap[affairName_coin_burn] = Ballot(affairName_coin_burn, isBallotFinished, affairVersion, ballotedMemsCount, coin_burn_successPercent);
    }

    function execute(string affairName) internal {
        if(affairName_coin_mint.equals(affairName)){
            mint(miner, mintAmount);
            emit CoinMinted(ballotAffairsMap[keccak256(affairName_coin_mint)].ballotedMemsCount, miner, mintAmount);
            
            return;
        }
        super.execute(affairName);
    }

    /*开启新一轮币增发的相关参数初始化*/
    function coinMineInit(address miner_, uint256 mintAmount_) external onlyOwner canMineInit {
        require(miner_ != 0x0 && totalSupply_.add(mintAmount_) > totalSupply_);
        
        miner = miner_;
        mintAmount = mintAmount_;
    }
    
    /*挖矿*/
    function mint(address _to, uint256 _amount) internal returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /*
     * @dev 燃烧一定数量的代币(总Token数量会下降)
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit CoinBurned(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
    
    /*
     * 必须实现此抽象方法
     */
    function init(string tokenName_, uint256 decimals_, string tokenSymbol_, uint256 adminCount_) internal;

}