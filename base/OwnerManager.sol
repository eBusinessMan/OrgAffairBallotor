pragma solidity ^0.4.24;

import "./EthAssetManager.sol";
import "./LibString.sol";

/**
 * @title 变更Owner.例如董事会罢免CEO等场景
 * owner作为集体代表, 变更Owner是一件大事情! 一般发生此投票事务,是因为owner无法代表集体利益,例如叛变等, 
 * 因此集体需要通过投票投出新的owner.
 * 投票选新的owner 跟其他集体投票事务不同性质, 要求当前owner在此事件上不具备任何操纵能力, 
 * 因此需要可以做到"投票变更Owner"甚至连当前owner都不知道.
 * 此OwnerManager中采取的方式是 "随机数竞选"的方式: 由竞选者往合约中注册自己以及唯一的随机数(不可重复, 具备时效性),
 * 然后各集体管理员根据 随机数 在合法时效期间 投票选出.
 * @author luozx@1264995828@qq.com
 * 2017-07-31
 */
contract OwnerManager is EthAssetManager {
    using LibString for string;
    /*
     * 指定特殊地址代表特殊业务意义
     */
    // 标示记录 随机数是否历史存在
    address constant public ADDRESS_0 = 0x0;
    // 标示记录 新owner竞选者
    address constant public ADDRESS_1 = 0x1;
    // 标示记录 投票数
    address constant public ADDRESS_2 = 0x2;
    // 标示记录 竞选者 注册的区块时间戳, 用来计算 随机数的时效
    address constant public ADDRESS_3 = 0x3;
    
    // 半天的区块时间, 意味着 竞选者的随机数超过半天就会时效
    uint256 constant public Half_A_Day = 2880;
    
    // 记录 变更owner
    event OwnerChanged(address newOwner, uint256 blockNum, uint256 ballotMembersCount_);
    // 记录 新增竞选者
    event NewPendingOwner(address pendingOwner_, uint256 blockNum_);
    
    // 记录竞选Owner的历史:竞选者\随机数\投票者\总票数\时间等
    mapping(uint256 => mapping(address => uint256)) public voteOwnerRecorder;

    // 此构造方法 仅仅用来传递 EthAssetManager 的构造方法的参数
    constructor(uint8 asset_transfer_successPercent, uint8 admin_add_successPercent, uint8 admin_del_successPercent) 
        EthAssetManager(asset_transfer_successPercent, admin_add_successPercent, admin_del_successPercent){}

    /**
     * @dev 意欲竞选owner的 某管理员 向合约注册自己的相关信息
     * 每次竞选者 注册owner需要 0.1ETH, 用以防止恶意刷
     * @param randomNum 随机数, 不可重复
     */ 
    function registerOwner(uint256 randomNum) payable checkPermission public {
        // 随机数校验不可重复 以及 转帐额度>0.1ETH
        require(voteOwnerRecorder[randomNum][ADDRESS_0] != 1 && msg.value >= 1 * 10 ** (18-1));
        
        voteOwnerRecorder[randomNum][ADDRESS_0] = 1;// 此随机数已占用
        voteOwnerRecorder[randomNum][ADDRESS_1] = uint256(msg.sender);//竞选者
        voteOwnerRecorder[randomNum][ADDRESS_2] = 0;// 投票数
        voteOwnerRecorder[randomNum][ADDRESS_3] = block.number;//区块时间戳
        // 记录日志
        NewPendingOwner(msg.sender, block.number);
    }

    /**
     * @dev 管理员们开始投票
     * @param randomNum 竞选者的随机数
     */
    function voteOwner(uint256 randomNum)  checkPermission public {
        // 随机数必须是已存在 && 对应的投票时效未过期:约0.5天
        require(voteOwnerRecorder[randomNum][ADDRESS_0] == 1 && (block.number - voteOwnerRecorder[randomNum][ADDRESS_3] <= Half_A_Day) );
        // 记录已投者
        voteOwnerRecorder[randomNum][msg.sender] = 1;
        voteOwnerRecorder[randomNum][ADDRESS_2] ++;
        // 判断是否到达票数
        if(voteOwnerRecorder[randomNum][ADDRESS_2] * 100 > (getAdminCount() * 50) ){
            // 更换owner
            owner = address(voteOwnerRecorder[randomNum][ADDRESS_1]);
            // 记录 日志
            OwnerChanged(owner, block.number, voteOwnerRecorder[randomNum][ADDRESS_2]);
        }
    }

}