---
layout: post
title: "Linux Issue: xmapp apache not started"
date: 2014-03-15 18:42:35 +0800
comments: true
tags: xampp
categories: Web 
---

Description
===
`XAMPP` 安装后，执行 `sudo /opt/lampp/lampp start` 返回 `XAMPP: Another web server daemon with SSL is already running.`并提示 `Apache` 启动失败，但 `MySql` 等其他组件的启动正常。

Solution
===
Linux 下 Apache 启不来是一个非常典型的问题，解决方法也很简单，更改 `XAMPP` 的如下配置文件，将默认端口换掉即可:

1.
`sudo vim  /opt/lampp/etc/httpd.conf`，把 `Listen 80` 换成 `Listen 2145`，2145是自选的，你可以选择任何你确保没有被占用的端口。

2.
`sudo vim /opt/lampp/etc/extra/httpd-ssl.conf`，把 `Listen 443` 换成 `Listen 16443`，16443也是自选的，你可以选择任何你确保没有被占用的端口。

3.
`sudo vim /opt/lampp/lampp`，把 `testport 80` 和 `testport 443` 分别换成 `testport 2145` 和 `testport 16443`，和第一步和第二步中的修改对应即可。

4.重启 XAMPP

__注意__，重启过后，你需要通过 `http://localhost:2145/xampp/` 加端口号的形式来测试是否成功，而不再是默认的 `http://localhost/`。

当出现下图证明 `Apache` 已成功启动。

![](http://ww3.sinaimg.cn/large/7adcb3b9gw1eegmn80ihgj20lb0dbtbs.jpg)