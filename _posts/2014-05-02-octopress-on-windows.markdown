---
layout: post
title: "Octopress on Windows"
date: 2014-05-02 22:58:35 +0800
comments: true
tags: Windows Octopress
categories: Web
---
因为预感到接下来的一段时间自己电脑要用 Windows 搞很多东西，所以昨晚回到了 Windows 8.1。然后这个事儿逼的操作系统真的好好地把我的博客艹了一番。。。

说几个注意事项吧，供兄弟们参考。

首先，因为 Octopress 是静态的，所以备份网站就很简单，直接把你网站的文件夹保存下来就好。

然后到了 Windows 下，你需要安装Git，不说了；然后是 Ruby ，Ruby 别装 2.0 的，1.9.2就好，否则会出问题；然后要装 DevKit ，虽然我也不知道为什么 Windows 下要装这货。。。另外，如果你运气不好，可能在下 Bundle 的时候会出问题，这个时候可以把你网站根目录下的 `Gemfile` 打开，修改一下第一行为 [http://ruby.taobao.org/](http://ruby.taobao.org/)，感谢淘宝！

最后，高潮来了。请千万记住 Windows 这默认的垃圾命令行是 fucking gbk 编码的，而你必须在纯 utf-8 命令行模式下执行 ruby 命令。因此，请千万记得使用 `chcp 65001 ` 将命令行切换到 utf-8 模式，否则整个网站是无法生成的。

Windows，呵呵。