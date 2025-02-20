<div align="center">
<h1>bullet-screen-cj</h1>
</div>

<p align="center">
<img alt="" src="https://img.shields.io/badge/release-v1.0.0-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/build-pass-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjc-v0.53.18-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjcov-NA%25-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/project-open-brightgreen" style="display: inline-block;" />
</p>

## 介绍

bullet-screen-cj 是一款弹幕框架，支持发送纯文本弹幕、设置弹幕在屏幕的显示区域、控制弹幕播放状态等功能

## 效果展示
<p align="left">
<img src="./doc/danmaku2.jpg" width="30%" >
<img src="./doc/danmaku1.jpg" width="30%" >
</p>

### 特性

1. 支持顶部弹幕
1. 支持底部弹幕
1. 支持左右滚动弹幕
1. 支持弹幕播放暂停继续
1. 支持纯文本弹幕
1. 支持弹幕隐藏显示
1. 支持设置弹幕显示区域大小

### 源码目录

```shell
/bullet-screen-cj             # 项目根目录
├─AppScope
├─doc                         # API文档和使用手册存放目录                   
├─entry                       # 示例代码文件夹    
├─hvigor                      # 构建工具目录              
├─danmaku                     # 弹幕库文件夹                   
│  └─src
│      └─main
│          ├─cangjie
│          │  └─src           # 库源代码目录
│          └─resources
├─README.md                   # 弹幕库介绍及使用说明
```

### 接口说明

主要类和函数接口说明详见 [API](doc/feature_api.md)

## 使用说明

### 编译构建


### 功能示例

用例代码在entry目录下 [功能示例](entry/src/main/cangjie/src/index.cj)


## 约束与限制

在下述版本验证通过：

    DevEco Studio 5.0.2 Release
    DevEco Studio Cangjie Plugin 5.0.7.100

## 开源协议

本项目基于 [Apache License 2.0](./LICENSE) ，请自由的享受和参与开源。

## 参与贡献

欢迎给我们提交PR，欢迎给我们提交Issue，欢迎参与任何形式的贡献。