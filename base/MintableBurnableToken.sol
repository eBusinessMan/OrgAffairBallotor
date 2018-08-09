pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "./AbstractBallot.sol";
import "./LibString.sol";

/*
 * 投票挖矿增发Token、销毁token
 * authored by luozx@1264995828@qq.com
 * 2017-07-31
 */
contract MintableBurnableToken is MintableToken, AbstractBallot {
    using LibString for string;

    // 投票事件I名称
    string affairName_coin_mint = "coin_mint";
    // 投票销毁事件名称
    //string affairName_coin_burn = "coin_burn";

    // 覆盖掉 MintableToken.canMint, 为了配合使用AbstractBallot
    modifier canMint() {
        //require(!mintingFinished);
        _;
    }
    // 挖矿地址，收获token
    address miner;
    // 挖矿产生token数量（增发）
    uint256 mintAmount;
    // 记录 增发的币
    event CoinMinted(uint256 ballotMembersCount, address miner, uint256 mintCount);

    // 销毁的币地址
    //address burner;
    // 销毁的币（增发）
    //uint256 burnedAmount;
    // 记录 销毁的币
    //event CoinBurned(uint256 ballotMembersCount, address burner, uint256 BurnedCount);

    // 记录 销毁的币
    event CoinBurned(address burner, uint256 BurnedCount);

    /*
     * 构造方法
     * successPercent：投票通过数量百分比*100
     */
    constructor(uint8 coin_mint_successPercent){
        // 投票事件启停标识器
        bool isBallotFinished = false;
        // 投票事件 版本，标识第几轮
        uint8 affairVersion = 0;
        // 投票人数记录器
        uint256 ballotedMemsCount = 0;
                
        ballotAffairsMap[affairName_coin_mint] = Ballot(affairName_coin_mint, isBallotFinished, affairVersion, ballotedMemsCount, coin_mint_successPercent);
        //ballotAffairsMap[affairName_coin_burn] = Ballot(affairName_coin_burn, isBallotFinished, affairVersion, ballotedMemsCount, coin_burn_successPercent);
    }

    function execute(string affairName) internal {
        if(affairName_coin_mint.equals(affairName)){
            mint(miner, mintAmount);
            emit CoinMinted(ballotAffairsMap[affairName_coin_mint].ballotedMemsCount, miner, mintAmount);
        }
    }

    function coinMineInit(address miner_, uint256 mintAmount_) external onlyOwner {
        miner = miner_;
        mintAmount = mintAmount_;
    }

    /*
    function coinBurnInit(address burner_, uint256 burnedAmount_) external onlyOwner {
        burner = burner_;
        burnedAmount = burnedAmount_;
    }
    */

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
}