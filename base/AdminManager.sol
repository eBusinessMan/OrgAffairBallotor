pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/access/rbac/RBAC.sol";
import "./AbstractBallotWithOwner.sol";
import "./LibString.sol";

/**
 * @title 集体管理员 的管理: 增加\删除; 由 owner 协助
 * @author luozx@1264995828@qq.com
 * 2018-05-23
 */
contract AdminManager is AbstractBallotWithOwner, RBAC {
    using LibString for string;

    // 矿工角色, 即平台币管理员角色
    string public constant ROLE_ADMIN = "role_admin";
    // 当前的管理员总数
    uint256 public adminCount;

    // 投票事件I名称
    string affairName_admin_add = "admin_add";
    // 投票事件II名称
    string affairName_admin_del = "admin_del";

    // 添加新矿工(管理员)完毕 事件
    event AllAdminsAdded(uint256 ballotMembersCount);
    // 记录 添加了的所有新矿工(管理员)
    event AdminAdded(address[] pendingList);
    // 添加新矿工(管理员)完毕 事件
    event AllAdminsDeled(uint256 ballotMembersCount);
    // 记录 添加了的所有新矿工(管理员)
    event AdminDeled(address[] pendingList);

    // 待加矿工列表
    address[] public pendingAddAdminList;
    // 待删矿工列表
    address[] public pendingDelAdminList;

    // 检测请求着是不是具备 平台币管理员角色
    modifier checkPermission() {
        checkRole(msg.sender, ROLE_ADMIN);
        _;
    }

    /**
     * @dev 构造方法
     * @param admin_add_successPercent 增加管理员事务投票通过数量百分比*100
     * @param admin_del_successPercent 删除管理员事务投票通过数量百分比*100
     */
    constructor(uint8 admin_add_successPercent, uint8 admin_del_successPercent){
        // 投票事件启停标识器
        bool isBalloting = false;
        // 投票事件 版本，标识第几轮
        uint8 affairVersion = 0;
        // 投票人数记录器
        uint256 ballotedMemsCount = 0;
                
        ballotAffairsMap[keccak256(affairName_admin_add)] = Ballot(affairName_admin_add, isBalloting, affairVersion, ballotedMemsCount, admin_add_successPercent);
        ballotAffairsMap[keccak256(affairName_admin_del)] = Ballot(affairName_admin_del, isBalloting, affairVersion, ballotedMemsCount, admin_del_successPercent);
    }

    // 添加一名矿工,即添加平台币管理员
    function addAdmin(address _admin) internal {
        addRole(_admin, ROLE_ADMIN);
    }

    // 删除一名矿工,即删除平台币管理员
    function removeAdmin(address _admin) internal {
        removeRole(_admin, ROLE_ADMIN);
    }

    /**
     * @dev 添加 全部待定矿工(管理员) 为正式矿工(管理员)
     */
    function addPendingAdmins(address[] pendingAdmins) internal {
        for (uint8 i = 0; i < pendingAdmins.length; i++) {
            if (pendingAdmins[i] != address(0x0)) {//排除黑洞地址
                addAdmin(pendingAdmins[i]);
                adminCount ++;
            }
        }
        AdminAdded(pendingAdmins);
    }
        
    /**
    * @dev 由 owner 补充 待定矿工(管理员), 如果已经启动投票,则无法继续更改待定矿工列表
    */
    function addPendingAdminsByOwner(address[] pendingAdmins) external onlyOwner checkBallotFinished(affairName_admin_add) {
        require(pendingAdmins.length > 0);
        pendingAddAdminList = pendingAdmins;
    }

    /**
    * @dev 清空 待定矿工(管理员)列表, 即使已经启动投票,可以清空待定矿工列表.
    * tips:如果清空了, 本轮投票还是得继续直到结束, 不过不会导致数据不一致.
    */
    function emptyPendingAddAdmins() external onlyOwner {
        delete pendingAddAdminList;
    }

    /**
     * @dev 覆盖父合约
     */
    function execute(string affairName) internal {
        // 此处务必做 affairName匹配判断
        if(affairName_admin_add.equals(affairName)){
            addPendingAdmins(pendingAddAdminList);
            emit AllAdminsAdded(ballotAffairsMap[keccak256(affairName_admin_add)].ballotedMemsCount);
            return;
        }

        // 此处务必做 affairName匹配判断
        if(affairName_admin_del.equals(affairName)){
            delPendingAdmins(pendingDelAdminList);
            emit AllAdminsDeled(ballotAffairsMap[keccak256(affairName_admin_del)].ballotedMemsCount);
            return;
        }
    }

    /**
    * @dev 删除 全部待定矿工(管理员)
    */
    function delPendingAdmins(address[] pendingAdmins) internal {
        for (uint8 i = 0; i < pendingAdmins.length; i++) {
            if (pendingAdmins[i] != address(0x0)) {//排除黑洞地址
                removeAdmin(pendingAdmins[i]);
                adminCount --;
            }
        }
        AdminDeled(pendingAdmins);
    }
        
    /**
    * @dev 由 owner 补充 待定删除的矿工(管理员), 如果已经启动投票,则无法继续更改待定矿工列表
    */
    function delPendingAdminsByOwner(address[] pendingAdmins) external onlyOwner checkBallotFinished(affairName_admin_del) {
        require(pendingAdmins.length > 0);
        pendingDelAdminList = pendingAdmins;
    }

    /**
    * @dev 清空 待定矿工(管理员)列表, 即使已经启动投票,可以清空待定矿工列表.
    * tips:如果清空了, 本轮投票还是得继续直到结束, 不过不会导致数据不一致.
    */
    function emptyPendingDelAdmins() external onlyOwner {
        delete pendingDelAdminList;
    }
    
    /**
     * @dev 要求初始化 须要的参数: 投票人总个数
     */
    function getAdminCount() internal returns(uint256) {
        return adminCount;
    }

    /**
     * @dev 要求子类初始化 须要的参数: 投票人总个数
     */
    function setAdminCount(uint256 adminCount_) internal;
}