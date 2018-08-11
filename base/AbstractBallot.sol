pragma solidity ^0.4.24;

/**
 * @title 针对是否事件的投票器
 * @author luozx@1264995828@qq.com
 * 2018-04-31
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

    /**
     * 判断当前版本的 投票事件 是否已经结束, 防止一些投票参看指标在投票过程中被恶意修改.
     * 如投票添加管理员, 此modifier可以防止在投票中途有人恶意将 预定管理员 给替换掉
     */
    modifier checkBallotFinished(string affairName){
        require(ballotAffairsMap[keccak256(affairName)].isBalloting == false);
        _;
    }

    // 投票开始事件
    event BallotStart(string affairName, uint8 affairVersion);
    // 投票结束事件
    event BallotEnd(string affairName, uint8 affairVersion);

    /**
     * 投票决定启动挖矿, 超过一定比例则执行具体事务:execute(affairName)
     * 仅允许平台币管理员投票
     */
    function doBallot(string affairName) public checkPermission {
        require(bytes(affairName).length != 0);
        
        Ballot affairBallot = ballotAffairsMap[keccak256(affairName)];
        // 标识正在投票, 可以通过checkBallotFinished(string affairName)来防止投票过程中一些待定项被恶意修改
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
    
    /** 
     * 重置 投票事务affairName 的投票状态, 主要用于投票过程中出现意外,需要重新投票. tips: 建议从集体中选出一个专门服务集体的角色,如CEO之类. 
     * 不过建议此function的执行由 集体指定人员 来执行, 例如选出来的董事長\CEO角色的人, 这样的话结合 onlyOwner.sol 使用相对适合.
     */
    function resetCurrentBallotAffair(string affairName) public checkPermission {
        require(bytes(affairName).length != 0);
        
        Ballot affairBallot = ballotAffairsMap[keccak256(affairName)];
        // 强制标识当前投票已经结束
        affairBallot.isBalloting = false;
        // 更新此事务的版本
        affairBallot.affairVersion ++;
        // 重置投票数为0
        affairBallot.ballotedMemsCount = 0;
    }
    
    /**
     * 通过事件名称查看事件投票进展状况
     *
     */
    function lookUpballotAffairByName(string affairName) public view
        returns(string affairNameX, bool isBallotingX, uint256 affairVersionX, uint256 ballotedMemsCountX, uint256 successPercentX){
        Ballot affairBallot = ballotAffairsMap[keccak256(affairName)];
        affairNameX = affairName;
        isBallotingX = affairBallot.isBalloting;
        affairVersionX = affairBallot.affairVersion;
        ballotedMemsCountX = affairBallot.ballotedMemsCount;
        successPercentX = affairBallot.successPercent;
    }
    
    /** 投票成功执行具体事务, 由子合约实现. */
    function execute(string affairName) internal;

    /** 要求初始化 须要的参数: 投票人总个数 */
    function getAdminCount() internal returns(uint256);

}
