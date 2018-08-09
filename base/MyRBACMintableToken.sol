pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "../node_modules/openzeppelin-solidity/contracts/access/rbac/RBAC.sol";
import "./AdminManager.sol";

/*
 * 平台管理员角色权限
 * authored by luozx@1264995828@qq.com
 * 2017-07-31
 */
contract MyRBACMintableToken is MintableToken, AdminManager {

}