pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./AbstractBallot.sol";

/*
 * 重置指定的投票事件
 * authored by luozx@1264995828@qq.com
 * 2017-07-31
 */
contract AbstractBallotWithOwner is Ownable, AbstractBallot {
    
    /*
     * 重置指定的投票事件
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