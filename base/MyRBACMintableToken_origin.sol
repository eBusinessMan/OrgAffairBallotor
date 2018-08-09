pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/RBACMintableToken.sol";
import "../node_modules/openzeppelin-solidity/contracts/access/rbac/RBAC.sol";

/*
 * 
 * authored by luozx@1264995828@qq.com
 * 2017-07-31
 */
contract MyRBACMintableToken is MintableToken, RBAC {
    // 矿工角色, 即平台币管理员角色
    string public constant ROLE_MINTER = "minter";

    // 当前矿工(管理员)个数
    uint8 public adminCount;

    // 检测请求着是不是具备 平台币管理员角色
    modifier hasMintPermission() {
        checkRole(msg.sender, ROLE_MINTER);
        _;
    }

    // 添加一名矿工,即添加平台币管理员
    function addMinter(address _minter) internal {
        addRole(_minter, ROLE_MINTER);
    }

    // 删除一名矿工,即删除平台币管理员
    function removeMinter(address _minter) internal {
        removeRole(_minter, ROLE_MINTER);
    }


    //-------------------------------------------------------------------------------------------------------------//
    //-----------------------------------------添加新矿工(管理员)---------------------------------------------------//
    // 标识 本轮添加新矿工(管理员) 是否完毕, 用于 在本轮投票环节 防止重入攻击
    bool isAddingMintersFinished = true;
    // 待定矿工列表
    address[] public pendingAddMinterList;
    // 增加新矿工(管理员)活动 投票计数
    uint8 startAddMinterBallotCount;
    // 增加新矿工(管理员)活动 版本
    uint8 startAddMinterActivityVersion;
    // 记录每轮"新矿工(管理员)添加"启动后已投票的管理员，用以防止重复投票。每轮活动完毕会重置。
    mapping (bytes32 => bool) startAddMinterBallotMapping;

    // 添加新矿工(管理员)完毕 事件
    event AllMintersAdded(uint256 startAddMinterBallotCount);
    // 记录 添加了的所有新矿工(管理员)
    event MinterAdded(address[] pendingAddMinterList);

    /*
    * 判断 投票添加新矿工(管理员) 是否已经结束
    */
    modifier mintersAddingFinished(){
        require(isAddingMintersFinished == true);
        _;
    }

    /*
    * 由 owner 补充 待定矿工(管理员), 如果已经启动投票,则无法继续更改待定矿工列表
    */
    function addPendingMintersByOwner(address[] pendingMinters) external onlyOwner mintersAddingFinished {
        require(pendingMinters.length > 0);
        pendingAddMinterList = pendingMinters;
    }

    /*
    * 清空 待定矿工(管理员)列表, 即使已经启动投票,可以清空待定矿工列表.
    * tips:如果清空了, 本轮投票还是得继续直到结束, 不过不会导致数据不一致.
    */
    function emptyPendingAddMinters() external onlyOwner {
        delete pendingAddMinterList;
    }

    /*
    * 添加 全部待定矿工(管理员) 为正式矿工(管理员)
    */
    function addPendingMinters(address[] pendingMinters) internal {
        for (uint8 i = 0; i < pendingMinters.length; i++) {
            if (pendingMinters[i] != address(0x0)) {//排除黑洞地址
                addMinter(pendingMinters[i]);
            }
        }
        MinterAdded(pendingMinters);
    }


    /*
    * 投票决定启动挖矿, 超过半数管理员则可以添加新矿工
    * 仅允许平台币管理员投票
    */
    function addMinterBallot() public hasMintPermission {
        isAddingMintersFinished = false;
        // 标识正在投票决定添加新矿工

        bytes32 key = keccak256(startAddMinterActivityVersion, msg.sender);
        require(!startAddMinterBallotMapping[key]);

        startAddMinterBallotCount ++;
        startAddMinterBallotMapping[key] = true;

        if (startAddMinterBallotCount > (adminCount / 2)) {
            addPendingMinters(pendingAddMinterList);
            // 添加 全部待定矿工(管理员) 为正式矿工(管理员)

            isAddingMintersFinished = true;
            // 标识 添加完毕
            startAddMinterActivityVersion ++;
            // 递增1
            emit AllMintersAdded(startAddMinterBallotCount);
        }
    }
    //-----------------------------------------添加新矿工(管理员)---------------------------------------------------//
    //-------------------------------------------------------------------------------------------------------------//



    //-------------------------------------------------------------------------------------------------------------//
    //-----------------------------------------删除新矿工(管理员)---------------------------------------------------//
	// 标识 本轮删除矿工(管理员) 是否完毕, 用于 在本轮投票环节 防止重入攻击
    bool isDelingMintersFinished = true;
    // 待定矿工列表
    address[] public pendingDelMinterList;
    // 增加矿工(管理员)活动 投票计数
    uint8 startDelMinterBallotCount;
    // 增加矿工(管理员)活动 版本
    uint8 startDelMinterActivityVersion;
    // 记录每轮"矿工(管理员)删除"启动后已投票的管理员，用以防止重复投票。每轮活动完毕会重置。
    mapping (bytes32 => bool) startDelMinterBallotMapping;

    // 删除矿工(管理员)完毕 事件
    event AllMintersDeled(uint256 startDelMinterBallotCount);
    // 记录 删除了的所有矿工(管理员)
    event MinterDeled(address[] pendingDelMinterList);

    /*
    * 判断 投票删除矿工(管理员) 是否已经结束
    */
    modifier mintersDelingFinished(){
        require(isDelingMintersFinished == true);
        _;
    }
    /*
    * 由 owner 补充 待定矿工(管理员), 如果已经启动投票,则无法继续更改待定矿工列表
    */
    function delPendingMintersByOwner(address[] pendingMinters) external onlyOwner mintersDelingFinished {
        require(pendingMinters.length > 0);
        pendingDelMinterList = pendingMinters;
    }

    /*
    * 清空 待定矿工(管理员)列表, 即使已经启动投票,可以清空待定矿工列表.
    * tips:如果清空了, 本轮投票还是得继续直到结束, 不过不会导致数据不一致.
    */
    function emptyPendingDelMinters() external onlyOwner {
        delete pendingDelMinterList;
    }

    /*
    * 删除 全部待定矿工(管理员) 为正式矿工(管理员)
    */
    function delPendingMinters(address[] pendingMinterList) internal {
        for (uint8 i = 0; i < pendingMinterList.length; i++) {
            if (pendingMinterList[i] != address(0x0)) {//排除黑洞地址
                addMinter(pendingMinterList[i]);
            }
        }
        MinterDeled(pendingMinterList);
    }

    /*
    * 投票决定启动挖矿, 超过半数管理员则可以删除矿工
    * 仅允许平台币管理员投票
    */
    function delMinterBallot() public hasMintPermission {
        // 标识正在投票决定删除矿工
        isDelingMintersFinished = false;
        

        bytes32 key = keccak256(startDelMinterActivityVersion, msg.sender);
        require(!startDelMinterBallotMapping[key]);

        startDelMinterBallotCount ++;
        startDelMinterBallotMapping[key] = true;

        if (startDelMinterBallotCount > (adminCount / 2)) {
            // 删除 全部待定矿工(管理员)
            delPendingMinters(pendingDelMinterList);
            
            // 标识 删除完毕
            isDelingMintersFinished = true;
            // 递增1
            startDelMinterActivityVersion ++;
            emit AllMintersDeled(startDelMinterBallotCount);
        }
    }
    //-----------------------------------------删除新矿工(管理员)---------------------------------------------------//
    //-------------------------------------------------------------------------------------------------------------//
}