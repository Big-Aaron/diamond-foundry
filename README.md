# Diamond in Foundry

之前使用Diamond代理都是使用Hardhat框架，因为对于扫描合约的函数选择器（selector）比较麻烦。

但是，今天偶然看到foundry的[inspect](https://book.getfoundry.sh/reference/forge/forge-inspect)命令，可以获取合约的全部选择器。解决了脚本化获取合约的函数选择器问题。

所以，根据foundry的inspect命令，编写了Diamond in Foundry。

## 测试

```
forge test --mt testDiamond -vvvvv
```

## 部署

```
forge script script/Deploy.s.sol --rpc-url your_rpc -vvvvv --broadcast
```

