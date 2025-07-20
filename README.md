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
6. [ ] 软件内更新
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
`nuitka --standalone --enable-plugin=pyqt5 --windows-console-mode=attach --include-data-dir=assets=assets --include-data-files=LICENSE=LICENSE --windows-icon-from-ico=./assets/favicon.ico main.py`
3. **_必须将main.exe置于main.dist文件夹中运行，分发构建时必须分发整个main.dist文件夹_**

## FAQ
### Q:怎么配置名单

A:从v2.0.1dev起，NamePicker已经内置名单编辑器，以下是手动修改指南

修改names.csv，第一行别改，第二行开始按照"学生名字,性别（0=男，1=女，2=非二元，不符合标准的性别代号理论上会被忽视）,学号"来填写，**务必使用英文符号**

就像这样：
```
name,sex,no
example,0,1
caixukun,2,2
sunxiaochuan,1,3
```
PS:不建议设置重复的学号和姓名，以免在使用时带来困扰

当然，也没人拦着你用Excel或WPS Office编辑，但是请记住 _**务必使用UTF-8编码保存**_ ，否则会导致无法读取名单

### Q:杀毒软件认为这是病毒软件

A:将该软件添加至杀毒软件的白名单/信任区中，本软件保证不含病毒，您可以亲自审查代码，如果还是觉得不放心可以不使用

### Q:打开好慢

A:Python的运行效率不高，慢属于正常现象