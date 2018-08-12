# 团队常见事务投票器Dapp
基于"是非事件抽象投票器"的一个团队\集体\集团常见事务投票器Dapp, 更细节地说, ta其实是一个包含了基础集体事务的投票功能的基础框架."是非事件抽象投票器"详情见https://github.com/eBusinessMan/AbstractBallot
# 应用场景
凡是"集体内部具备一位集体代表,但是核心事务由集体投票确认结果,集体代表更多充当服务集体的角色"这类集体组织形式,非常适合使用此框架进行扩展.举例子,例如可用作交易所平台币\项目方发币等场景.
# 具备功能
  * 管理员等各种权限角色管理
  * 集体投票决定事务的基础功能
  * 投票决定增加\删除集体成员(即管理员)
  * 具备集体代表(owner), 集体中可以投票变更集体代表
  * 投票决定合约存量ETH资产转帐事务
  * ERC20代币标准功能
  * 投票决定增发\销毁多少代币
  * 突发情况下, 集体代表(owner)可以暂停ERC20的标准功能(如被黑客攻击) <br>
  其中集体代表(owner), 更多充当服务集体的角色, 即在核心事务上不具备一票决定权.
 # 架构分析
  基础投票功能来源于"是非事件抽象投票器", 即AbstractBallot.sol <br/>
  基础投票功能的继承链:AbstractBallot \< AbstractBallotWithOwner \< AdminManager \< EthAssetManager \< OwnerManager \< AbstractBallotMintableBurnableToken \< OrgCoin <br/>
  * AbstractBallot.sol  <br>
    "是非事件抽象投票器",详情见https://github.com/eBusinessMan/AbstractBallot
  * AbstractBallotWithOwner  <br>
    由集体代表, 即owner来重置某投票事务的投票状态
  * AdminManager <br>
    管理员增加\删除功能, 是上面"是非事件抽象投票器"的集体基础
  * EthAssetManager <br>
    由管理员投票决定转移合约中存量ETH资产
  * OwnerManager <br>
    由管理员投票决定变更owner. <br>
    Attention:<br>
      变更Owner.例如董事会罢免CEO等场景 <br>
      owner作为集体代表, 变更Owner是一件大事情! 一般发生此投票事务,是因为owner无法代表集体利益,例如叛变等, 
      因此集体需要通过投票投出新的owner. 
      投票选新的owner 跟其他集体投票事务不同性质, 要求当前owner在此事件上不具备任何操纵能力,
      因此需要可以做到"投票变更Owner"甚至连当前owner都不知道. <br>
      此OwnerManager中采取的方式是 "随机数竞选"的方式: 由竞选者往合约中注册自己以及唯一的随机数(不可重复, 具备时效性), 
      然后各集体管理员根据 随机数 在合法时效期间投票选出. <br>
  * AbstractBallotMintableBurnableToken <br>
    ERC20代币. <br>意外情况可以由owner暂停代币转帐基础功能, 还可以由集体投票决定增发\销毁代币 <br>
  * OrgCoin <br>
    你的组织代币! <br>

# 扩展注意点
  * AbstractBallot.sol的抽象function execute(string affairName) 的实现,需要特别注意继承链上的 affairName的匹配以及及时return终止.
  ```js

    function execute(string affairName) internal {
        // 务必判断是否匹配affairName
        if(affairName_asset_transfer.equals(affairName)){
            pendingEthTo.send(pendingEthTransferAmount);
            emit AssetTransfered(pendingEthTransferAmount, pendingEthTo,                        ballotAffairsMap[keccak256(affairName_asset_transfer)].ballotedMemsCount);
            
            return;
        }
        // !!!!!!如果 参数affairName 不匹配 affairName_asset_transfer, 那么肯定是需要匹配继承链的上游的 投票事务名
        super.execute(affairName);
    }
    
  ```
# 声明
  任何合约代码都存在漏洞风险, 因此建议合约编写完成后寻求外部专业代码审计机构审计代码.<br>
  本人欢迎各位使用本框架作为项目方的基础投票框架,<br>
  但是凡是使用本合约框架作为基础功能, 需要使用者自负意外事故的责任后果.



