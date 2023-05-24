# Diamond in Foundry

基于foundry的[inspect](https://book.getfoundry.sh/reference/forge/forge-inspect)命令，获取合约的全部选择器。解决脚本化获取合约的函数选择器问题。


## 测试

```
forge test --mt testDiamond -vvvvv
```

## 部署

```
forge script script/Deploy.s.sol --rpc-url your_rpc -vvvvv --broadcast
```

