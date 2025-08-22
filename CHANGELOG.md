## 新特性

- 支持在软件内注册URL Scheme

注册完成后可以通过`namepicker://`调起没有浮窗的NamePicker（和附加`noshortcut`参数效果相同）

## 已知Bug

- TOTP APP设置时看不到手动设置的代码（没啥头绪）

- Linux版本构建文件无法打开（同理，没啥头绪）

- Linux下，浮窗几乎无法使用（Qt的已知问题，等待Qt开发者进行修复）