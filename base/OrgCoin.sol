pragma solidity ^0.4.24;

import "./AbstractBallotMintableBurnableToken.sol";

/*
 * 机构平台币,如交易所
 * authored by luozx@1264995828@qq.com
 * 2017-06-31
 */
contract OrgCoin is AbstractBallotMintableBurnableToken {
    //---------------------------------------------------------------------------------//
    //-----------------------------必须初始化的 状态变量---------------------------------//
    /*
     * Token相关
     */
    string public name ;                   //fancy name: eg Simon Bucks
    uint256 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX

    //-----------------------------必须初始化的 状态变量---------------------------------//
    //---------------------------------------------------------------------------------//

    /*
     * 构造器: 初始化 7个平台币管理员
     */
    constructor(uint8 coin_mint_successPercent, uint8 asset_transfer_successPercent, uint8 admin_add_successPercent, uint8 admin_del_successPercent)
        AbstractBallotMintableBurnableToken(coin_mint_successPercent, asset_transfer_successPercent, admin_add_successPercent, admin_del_successPercent){
        // 初始化管理员
        // owner
        address initAdmin01 = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c;
        
        address initAdmin02 = 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c;
        address initAdmin03 = 0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db;
        address initAdmin04 = 0x583031d1113ad414f02576bd6afabfb302140225;
        address initAdmin05 = 0xdd870fa1b7c4700f2bd7f44238821c26f7392148;
        //address initAdmin06 = 0x0;
        //address initAdmin07 = 0x0;
        addAdmin(initAdmin01);
        addAdmin(initAdmin02);
        addAdmin(initAdmin03);
        addAdmin(initAdmin04);
        addAdmin(initAdmin05);
        //addAdmin(initAdmin06);
        //addAdmin(initAdmin07);

        // 初始化管理员总数
        uint256 adminCount_ = 5;
        
        // 直接将initAdmin01 作为 owner
        owner = initAdmin01;
        
        string memory tokenName_ = "ORG_TOKEN";
        uint256 decimals_ = 18;
        string memory tokenSymbol_ = "ORG_COIN";
        uint256 _initialTokenAmount = 5000000;
        totalSupply_ =  _initialTokenAmount * 10 ** uint256(decimals);
        balances[initAdmin01] = totalSupply_;
        
        // 初始化参数
        init(tokenName_, decimals_, tokenSymbol_, adminCount_);
    }

    /*
     * 重写实现 init
     */
    function init(string tokenName_, uint256 decimals_, string tokenSymbol_, uint256 adminCount_) internal {
        name = tokenName_;
        decimals = decimals_;
        symbol = tokenSymbol_; 
        // 初始化个数
        setAdminCount(adminCount_);
    }
    
    // AdminManager.sol要求初始化 须要的参数
    function setAdminCount(uint256 adminCount_) internal {
        adminCount = adminCount_;
    }

}
