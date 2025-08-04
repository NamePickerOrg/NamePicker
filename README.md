<div align="center">
<img src="assets\NamePicker.png" alt="icon" width="18%">
<h1>NamePicker</h1>
<h3>一款简洁的点名软件</h3>
</div>

[QQ群（群号2153027375）](https://qm.qq.com/q/fTjhKuAlCU)

[NamePicker文档](https://namepicker-docs.netlify.app/)

> [!note]
> 
> 从v2.0.0起，NamePicker本体将基于GNU GPLv3协议开源
> 
> GNU GPLv3具有Copyleft特性，也就是说，您可以修改NamePicker的源代码，但是**必须将修改版本同样以GNU GPLv3协议开源**

> [!caution]
> 
> NamePicker是一款完全开源且免费的软件，官方也没有提供任何付费服务
> 
> 如果您需要在某处售卖NamePicker，或者需要提供有关NamePicker的付费服务，请参照[该指南](https://www.baidu.com/s?wd=家里人全死光了怎么办)

## 功能清单/大饼

> 概率内定过于缺德，并且实现难度相当高，不会考虑

1. [x] 基础的点名功能
2. [x] 人性化（大嘘）的配置修改界面
3. [x] 从外部读取名单
4. [x] 特殊点名规则
5. [x] 悬浮窗（点击展开主界面）
6. [x] 软件内更新
7. [x] 支持非二元性别
8. [x] 同时抽选多个
9. [ ] 播报抽选结果
10. [x] 与ClassIsland/Class Widgets联动（联动插件均已上架对应软件的插件商城）（目前已知ClassIsland在进行多次抽选时100%崩溃（真不是我菜在开发环境都没这破事），Class Widgets不受影响）
11. [ ] 手机遥控抽选
12. [x] 改用PyQt

## 支持的平台
1. [x] Windows 10+
2. [x] Linux（国产化系统）
3. [ ] Windows 7-8.1 （尚未测试）
4. [ ] MacOS（理论上可以，但是~~作者是懒狗~~作者没有果子设备可供测试）
## 运行指南

### 运行指南（源码）

0. （可选）创建虚拟环境
1. 安装依赖项
`pip install -r requirements.txt`
2. 运行main.py

### 打包可执行文件指南

0. （可选）创建虚拟环境
1. 安装依赖项
`pip install -r requirements.txt`
2. 在虚拟环境中运行
`pyinstaller main.spec`
3. **_必须将main.exe置于main.dist文件夹中运行，分发构建时必须分发整个main.dist文件夹_**

## FAQ
### Q:怎么配置名单

A:参见[文档](https://namepicker-docs.netlify.app/usage/names.html)

### Q:杀毒软件认为这是病毒软件

A:将该软件添加至杀毒软件的白名单/信任区中，本软件保证不含病毒，您可以亲自审查代码，如果还是觉得不放心可以不使用

### Q:打开好慢

A:Python的运行效率不高，慢属于正常现象

## 鸣谢

- 感谢[@undefftr](https://github.com/undefftr)为图标设计提供支持

- 感谢[@ShihaoShen2025](https://github.com/ShihaoShen2025)试图修改.gitignore获得贡献者身份