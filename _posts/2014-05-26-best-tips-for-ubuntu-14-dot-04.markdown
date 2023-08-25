---
layout: post
title: "Best tips for Ubuntu 14.04"
date: 2014-05-26 00:28:05 +0800
comments: true
tags: Ubuntu Linux
categories: Linux
---
Ubuntu 14.04
===
相信我，Ubuntu 14.04 一定是 Canonical 迄今为止做出的最漂亮的 Ubuntu，当然，也是最事儿逼的。因为它让我两天内很无语地重装了三次。。。

以下这些问题大多数人在安装过时或者安装后一定都会遇到，希望你能在这里找到**真正有效**的答案。

F&Q
===
1.如何禁用触控板

如果你在装完 14.04 之后发现你亲爱的触控板开关快捷键不起作用了，请 vim 一下 `/etc/modprobe.d/blacklist.conf` ，在文件最后加入以下语句，保存，重启即可：
``` bash
blacklist psmouse
```

2.adb 提示 No such method or directory

此问题是由于 adb 是32位的，你无法直接在 64 位系统上运行。你需要使用如下命令安装这些 library packages：
``` bash
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386
```

3.android studio 编译时提示 aapt error=2

此问题原因同上，但这次你是需要这几个包：
``` bash
sudo apt-get install lib32stdc++6
sudo apt-get install lib32z1
```

4.VMware 虚拟机启动时提示 Could not open /dev/vmmon:

遇到这个问题，先用手动把你的 VM 服务调起来：
``` bash
/etc/init.d/vmware start
```
然后把这个服务添加到系统里去跟着开机启动
``` bash
cd /etc/init.d/
chkconfig -a vmware
```

5.有童鞋表示竟然不会配 JDK ，我表示只能默默贡献出我的 `.bashrc` 了：
``` bash
export JAVA_HOME=/opt/java
export ANDROID_HOME=/opt/adt/sdk
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib::${JRE_HOME}/lib:$CLASSPATH
export PATH=${JAVA_HOME}/bin:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:$PATH
```
别忘了完事儿之后指定一下系统 java 常见命令的默认版本：
``` bash
 sudo update-alternatives --install "/usr/bin/javac" "javac" "/opt/java/bin/javac" 1
 sudo update-alternatives --install "/usr/bin/java" "java" "/opt/java/bin/java" 1
```

6.开机提示”/检查磁盘时发生严重错误“

这个问题基本可以确定为 14.04 最奇葩的一个bug，因为身边也有小伙伴出现了这样的问题。如果你不愿意折腾，可以在它提示的时候按 i 键跳过。如果愿意折腾，可以[参考一下这里](http://jingyan.baidu.com/article/0aa22375bbffbe88cc0d6419.html)。