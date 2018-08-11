pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./AbstractBallot.sol";

/**
 * @title 引入owner的是非事件投票器
 * @dev 抽象合约, 其中owner一般指集体代表,如 董事长\CEO角色之人
 *将"重置指定的投票事件状态"改为由owner执行即可.
 * @author luozx@1264995828@qq.com
 * 2018-05-22
 */
contract AbstractBallotWithOwner is Ownable, AbstractBallot {
    /**
     * @dev 重置指定的投票事件状态, 仅仅owner可以操作
     * 覆盖 resetCurrentBallotAffair
     */
    function resetCurrentBallotAffair(string affairName) onlyOwner public {
        require(bytes(affairName).length != 0);
        
        Ballot affairBallot = ballotAffairsMap[keccak256(affairName)];
        // 强制标识当前投票已经结束
        affairBallot.isBalloting = false;
        // 更新此事务的版本
        affairBallot.affairVersion ++;
        // 重置投票数为0
        affairBallot.ballotedMemsCount = 0;
    }
}