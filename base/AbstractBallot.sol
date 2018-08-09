pragma solidity ^0.4.24;

/*
 * 针对是否事件的投票器
 * authored by luozx@1264995828@qq.com
 * 2017-07-31
 */
contract AbstractBallot {

    struct Ballot{
        // 投票事件名称
        string affairName;
        // 投票事件启停标识器
        bool isBalloting;
        // 投票事件 版本，标识第几轮
        uint8 affairVersion;
        // 投票人数记录器
        uint256 ballotedMemsCount;
        // 投票通过数量百分比*100
        uint8 successPercent;
        // 已投票成员记录器，防止重复投票
        mapping (bytes32 => bool) ballotedMembersMapping;
    }

    // 投票事务名 => 事务struct
    mapping(bytes32 => Ballot) public ballotAffairsMap;

    // 检测请求着是不是具备 平台币管理员角色
    modifier checkPermission(){
        _;
    }

    // 判断 投票事件 是否已经结束
    modifier checkBallotFinished(string affairName){
        require(ballotAffairsMap[keccak256(affairName)].isBalloting == false);
        _;
    }

    // 投票开始事件
    event BallotStart(string affairName, uint8 affairVersion);
    // 投票结束事件
    event BallotEnd(string affairName, uint8 affairVersion);

    // 投票成功执行具体事务
    function execute(string affairName) internal;

    // 很想在这里就实现一个总开关,可是不建议! 因为不想引入 onlyOwner ! 交由子类来实现吧,即 由子类继承Owner.sol
    function resetCurrentBallotAffair(string affairName) public;
    
    // 要求初始化 须要的参数: 投票人总个数
    function getAdminCount() internal returns(uint256);

    /*
    * 投票决定启动挖矿, 超过半数管理员则可以删除矿工
    * 仅允许平台币管理员投票
    */
    function doBallot(string affairName) public checkPermission {
        require(bytes(affairName).length != 0);
        
        Ballot affairBallot = ballotAffairsMap[keccak256(affairName)];
        // 标识正在投票
        affairBallot.isBalloting = true;
        uint8 affairVersion = affairBallot.affairVersion;
        mapping (bytes32 => bool) ballotedMembersMapping = affairBallot.ballotedMembersMapping;
        bytes32 key = keccak256(affairName, affairVersion, msg.sender);
        // 检查是否已经投过票
        require(!ballotedMembersMapping[key], "haveBalloted!");
        
        affairBallot.ballotedMemsCount ++;
        ballotedMembersMapping[key] = true;
        
        // 如果已投票人数>预设的投票临界数
        if(affairBallot.ballotedMemsCount * 100 > getAdminCount() * affairBallot.successPercent){
            // 执行对应事务
            execute(affairName);
            // 标识 投票完毕
            affairBallot.isBalloting = false;
            // 版本递增1
            affairBallot.affairVersion ++;
            // 重置投票数为0
            affairBallot.ballotedMemsCount = 0;
            emit BallotEnd(affairName, affairVersion);
        }
    }
    
    function lookUpballotAffairByName(string affairName) public 
        returns(string affairNameX, bool isBallotingX, uint256 affairVersionX, uint256 ballotedMemsCountX, uint256 successPercentX){
        Ballot affairBallot = ballotAffairsMap[keccak256(affairName)];
        affairNameX = affairName;
        isBallotingX = affairBallot.isBalloting;
        affairVersionX = affairBallot.affairVersion;
        ballotedMemsCountX = affairBallot.ballotedMemsCount;
        successPercentX = affairBallot.successPercent;
    }
}