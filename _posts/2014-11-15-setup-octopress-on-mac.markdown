---
layout: post
title: "Setup Octopress on Mac"
date: 2014-11-15 01:18:32 +0800
comments: true
categories: Mac
---
折腾了好几天总算搞定了 Mac OS 下 Octopress 的搭建。我使用的版本是 Yosemite。

要在 Mac OS 下搭建 Octopress ，需要以下几个步骤。当前，建议读者还是要有一点 Linux 基础，最好之前用过一款 Linux 发行版。

1.包管理软件
===
熟悉 Ubuntu 的同学可能知道，在 Ubuntu 下面你可以很轻松地通过 `apt-get install` 来得到你想要的包，如果没有的话还可以通过新立得来查找。而对于 Mac OS X 而言，苹果默认是不带这样一个包管理软件的，不过没关系，我们有 [Homebrew](http://brew.sh/index_zh-cn.html) 神器,你可以很简单地通过 `ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"` 命令来获取它。安装完成后请记得 `vim` 一下你的 `bash.profile` ,增加 `export PATH=/usr/local/bin:$PATH`，再 `source` 一下让它生效。

成功安装后，你甚至就可以把它想象成 `apt-get` 命令，比如你可以执行 `brew install wget` 来完成你想要的包安装。

2.Gcc 编译环境
===
gcc 编译环境是为了安装 ruby 时编译作准备的，高大上的 XCode 里面已经带了一套很好的编译环境，所以这一步你需要去装好 Xcode，并运行一次，确保安装了对应的组件。

3. Ruby 1.9.3
===
Octopress 强制要求了必须用 Ruby 1.9.3 构建，而 Yosemite 自带的 Ruby 版本已经达到了 2.0.0。那么问题就来了——“如何在不破坏系统自带的 ruby 环境的前提下，切换到 Ruby 1.9.3 ？”方法就是使用 `rbenv`，执行如下命令即可：

```
*安装 rbenv
brew update
brew install rbenv
brew install ruby-build

*使用 rbenv 安装 1.9.3
rbenv install 1.9.3-p0
rbenv local 1.9.3-p0
rbenv rehash
```
回过头去看一下，其实正是 `rbenv local 1.9.3-p0` 命令保证了你在安装 1.9.3 的 ruby 同时不会破坏原有系统变量。此时执行 `ruby -v`，如果看到版本已经切到了 1.9.3，就证明大功告成。否则请重新执行：

```
rbenv local 1.9.3-p0
rbenv rehash`
```
如果执行完之后还是不行，可能是因为你的 `rbenv` 压根没生效。请`vim`一下你的`bash.profile`,增加`export RBENV_ROOT=/usr/local/var/rbenv`，再`source`一下让它生效。

4.最后几步
===
可能看到这里你已经醉了，但很遗憾，一切已经结束，接下来的照着[官方教程](http://octopress.org/docs/setup/)走吧，Good Luck！