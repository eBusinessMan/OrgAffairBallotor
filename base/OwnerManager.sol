pragma solidity ^0.4.24;

import "./EthAssetManager.sol";
import "./LibString.sol";

/*
 * 变更Owner.例如董事会罢免CEO等场景
 * authored by luozx@1264995828@qq.com
 * 2017-07-31
 */
contract OwnerManager is EthAssetManager {
    using LibString for string;
    
    address constant public ADDRESS_0 = 0x0;
    address constant public ADDRESS_1 = 0x1;
    address constant public ADDRESS_2 = 0x2;
    address constant public ADDRESS_3 = 0x3;
    uint256 constant public Half_A_Day = 2880;
    
    // 记录 变更owner
    event OwnerChanged(address newOwner, uint256 blockNum, uint256 ballotMembersCount_);
    // 记录 新增竞选者
    event NewPendingOwner(address pendingOwner_, uint256 blockNum_);
    
    // 记录竞选Owner的历史:竞选者\随机数\投票者\总票数\时间等
    mapping(uint256 => mapping(address => uint256)) public voteOwnerRecorder;

    constructor(uint8 asset_transfer_successPercent, uint8 admin_add_successPercent, uint8 admin_del_successPercent) 
        EthAssetManager(asset_transfer_successPercent, admin_add_successPercent, admin_del_successPercent){}

    function registerOwner(uint256 randomNum) payable checkPermission public {
        // TODO ???????????
        // 随机数校验不可重复 以及 转帐额度>0.1ETH
        require(voteOwnerRecorder[randomNum][ADDRESS_0] != 1 && msg.value >= 1 * 10 ** (18-1));
        
        voteOwnerRecorder[randomNum][ADDRESS_0] = 1;// 此随机数已占用
        voteOwnerRecorder[randomNum][ADDRESS_1] = uint256(msg.sender);//竞选者
        voteOwnerRecorder[randomNum][ADDRESS_2] = 0;// 投票数
        voteOwnerRecorder[randomNum][ADDRESS_3] = block.number;//区块时间戳
        // 记录日志
        NewPendingOwner(msg.sender, block.number);
    }

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