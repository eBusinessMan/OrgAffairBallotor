pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/access/rbac/RBAC.sol";
import "./AdminManager.sol";
import "./LibString.sol";

/*
 * 合约中的资产转移事件投票 
 * authored by luozx@1264995828@qq.com
 * 2017-07-31
 */
contract EthAssetManager is AdminManager {
    using LibString for string;

    // 投票事件I名称
    string affairName_asset_transfer = "eth_asset_transfer";

    // 记录 已完成转移的eth资产
    event AssetTransfered(uint256 transferedAmount_, address ethTo_, uint256 ballotMemCount_);
    // 等待 转移的eth资产
    uint256 pendingEthTransferAmount;
    address pendingEthTo;
    /*
     * 构造方法
     * successPercent：投票通过数量百分比*100
     */
    constructor(uint8 asset_transfer_successPercent, uint8 admin_add_successPercent, uint8 admin_del_successPercent) AdminManager(admin_add_successPercent, admin_del_successPercent) {
        // 投票事件启停标识器
        bool isBallotFinished = false;
        // 投票事件 版本，标识第几轮
        uint8 affairVersion = 0;
        // 投票人数记录器
        uint256 ballotedMemsCount = 0;
                
        ballotAffairsMap[keccak256(affairName_asset_transfer)] = Ballot(affairName_asset_transfer, isBallotFinished, affairVersion, ballotedMemsCount, asset_transfer_successPercent);
    }

    function execute(string affairName) internal {
        if(affairName_asset_transfer.equals(affairName)){
            pendingEthTo.send(pendingEthTransferAmount);
            emit AssetTransfered(pendingEthTransferAmount, pendingEthTo, ballotAffairsMap[keccak256(affairName_asset_transfer)].ballotedMemsCount);
            
            return;
        }
        super.execute(affairName);
    }
    
    function setAssetTransferAmount(string affairName, uint256 value_, address pendingEthTo_) onlyOwner checkBallotFinished(affairName) public {
        require(this.balance >= value_ && pendingEthTo_ != address(0x0));
        pendingEthTransferAmount = value_;
        pendingEthTo = pendingEthTo_;
    }

}