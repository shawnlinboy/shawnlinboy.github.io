---
layout: post
title: "WDMyCloud 3T NAS 添加迅雷远程下载（Mac 用户）"
date: 2016-12-25 22:48:01 +0800
comments: true
tags: WDMyCloud
categories: Geek
---

WDMyCloud 买了将近一年时间了，本来准备只给 Mac 做 Time Machine 备份用的，奈何 3T 空间实在撑不满，多着也是浪费，再加上平时白天上班，家里带宽闲着也是闲着，于是今天折腾了一下给他添加了迅雷远程下载功能，亲测可用。

首先需要说明的是，网上大部分教程抄来抄去，几乎全是 Windows 下操作的版本，其实对于 Mac 用户而言，完全不用 PuTTY，因为 Mac 自带的终端一直都支持 ssh ，而 WinSCP 在 Mac 下有更好的替代软件 `Cyberduck`，俗称小黄鸭。所以对于 Mac 用户而言，理论上你只需要准备后者，剩下的完全不需要考虑。

步骤
===
__一、降级 WDMyCloud 固件版本__

迅雷官方的远程下载模块目前不支持 4.0+ 版本的 WDMyCloud 固件，所以如果你不小心被西部数据升级到了最新版本，需要先降回去。方法很简单：

万事先理清思路，我们的思路：v04.04 -> V04.00 -> V03.04

所以，先准备好这两个版本的固件：

http://download.wdc.com/nas/sq-040000-607-20140630.deb

http://download.wdc.com/nas/sq-030401-230-20140415.deb

然后照着[这篇文章](http://www.nasyun.com/thread-24089-1-1.html)完成降级就好，很简单。

这一步我遇到几个问题，注意一下：

* Mac 用户如果不知道你的 WDMyCloud 在局域网内 IP 是多少，可以通过 ping 一下 `wdmycloud.local` 获得。

* 在降到 V04.00 之后，再次上传固件准备降到 V03.04 的时候，WDMyCloud 会提示你没有空间上传固件了，我初步判断是 WDMyCloud 的一个 bug 导致的，它在升完之后没把我们上一次传的 deb 文件删掉导致。解决办法就是去 `设置->实用工具->系统出厂还原->仅系统` 还原一下系统，然后再继续降级。如果你没找到，看下图：

![](http://ww4.sinaimg.cn/large/7adcb3b9gw1fb3fpq1wigj20st0irq53.jpg)

* V04.00 -> V03.04 刷完之后 WDMyCloud 会提示“升级失败”。这是正常的，因为我们本身就是在做降级操作。去“固件”里看一下，已经是 V03.04 了就算大功告成。另外记得把自动更新关掉，防止再次被升级到最新固件。

![](http://ww4.sinaimg.cn/large/7adcb3b9gw1fb3frmssoaj20s107kgme.jpg)

<!-- more -->

__二、上传迅雷远程下载的文件__

这一步需要用到 `Cyberduck`，没安装的自行 Google 一下。

WDMyCloud 支持的迅雷远程下载版本是 `Xware1.0.31_armel_v5te_glibc.zip`，我搜到的下载地址是这个： http://luyou.xunlei.com/forum.php?mod=attachment&aid=MjUxNDB8NGQ1OWUzZmN8MTQ4ODcxNzg0MnwxMjk3ODl8MTI1NDU=

下载完后解压，里面只有4个文件，看一眼，没啥事儿，关掉。

![](http://ww1.sinaimg.cn/large/7adcb3b9gw1fb3fyc69hnj20h408bgmp.jpg)

然后打开 `Cyberduck`，新建一个连接，协议选择 `SFTP`，IP 地址就是上面你 ping 出来的地址，用户名是 `root`，密码 `welc0me`：

![](http://ww2.sinaimg.cn/large/7adcb3b9gw1fb3g3cqsszj20jt0hjaby.jpg)

连接建立之后，进到 `/DataVolume`，新建一个 `Thunder` 文件夹，然后进去这个文件夹，再把上面下载的那4个文件上传进来。至此，你已经完成一半了。

__三、一键安装并绑定下载器__

打开 Terminal，输入

`ssh root@192.168.100.48`，其中后面那个 IP 需要换成上面你 ping 到的，回车，密码依旧是 `welc0me`，再回车。

然后进到我们上面新建的 `/DataVolume/Thunder` 文件夹，执行以下命令给所有文件授权：

`chmod 777 * -R`

接着执行一键安装脚本：

`./portal`

之后便会看到我们要的激活码：

![](http://ww1.sinaimg.cn/large/7adcb3b9gw1fb3gbvzp2zj20ky08y74o.jpg)

有了激活码就简单了，打开 `http://yuancheng.xunlei.com`，登录你的迅雷账号，然后添加一个下载器，输入你刚才的激活码，确定后就可以看到一个名为类似 `XUNLEI_ARM_V5TE` 字样的下载器在线。

然后回到 WDMyCloud 的控制面板，新建一个文件夹，用来当下载文件夹，我在这里就给他叫 `TDDOWNLOAD`。注意，这个文件夹在 WDMyCloud 的文件系统里映射的地址是 `shares/TDDOWNLOAD`，因为 WDMyCloud 能看到的目录都是以“共享文件夹”的概念存在的，所以后面新建下载的时候你需要把目标地址写这个，不然不好找。

![](http://ww2.sinaimg.cn/large/7adcb3b9gw1fb3giqxkngj20t00i50ur.jpg)

最后，我们来测试一下，打开 `http://yuancheng.xunlei.com`，新建一个下载，我喜欢用 QQ PC 版的链接做下载测试，因为鹅厂的 CDN 做得比较好，基本可以看出下载速度是否正常。当然了，你需要注意“存储路径”，填写上面说的映射到的那个路径：

![](http://ww2.sinaimg.cn/large/7adcb3b9gw1fb3gl9o69bj20fi0euabx.jpg)

然后按“添加到远程下载”，嗯，速度还可以：

![](http://ww4.sinaimg.cn/large/7adcb3b9gw1fb3gmh3asgj20lq049aav.jpg)

下载完成之后，打开 `TDDOWNLOAD` 文件夹看一下：

![](http://ww1.sinaimg.cn/large/7adcb3b9gw1fb3gnkywx7j20ld0c9jss.jpg)

Nice，文件已经在里面了：

![](http://ww2.sinaimg.cn/large/7adcb3b9gw1fb3goueqanj20lg0c53zs.jpg)

至此，你的 WDMyCloud 已经变成一台带迅雷远程下载的机器了。

遗留问题
===

目前暂时只发现一个遗留问题，就是因为系统限制关系，如果 WDMyCloud 重启，需要重新去启动一下服务，方法是用 Terminal 进到 `/DataVolume/Thunder` 下面执行一次 `/.portal`，之后便可以了。不过这个问题不大，因为应该不会有人闲着没事就去天天重启家里的 NAS 吧。。。一般稳定运行就可以。后面如果实在忍不了了，因为 WDMyCloud 的控制系统本身也就是个小型的 Linux，我们可以写一个小脚本让机器每次开机的时候手动跑一下  `/DataVolume/Thunder/.portal` 就行了。所以问题不大。


