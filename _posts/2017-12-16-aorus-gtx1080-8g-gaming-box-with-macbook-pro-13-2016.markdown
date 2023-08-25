---
layout: post
title: "2016 Macbook Pro 13' 安装 AORUS GTX1080 8G Gaming Box 完整教程"
date: 2017-12-16 01:22:21 +0800
tags: gaming Windows AORUS Macbook
categories: Geek
---
最近为了吃鸡入了一块 [AORUS GTX1080 8G Gaming Box](https://www.gigabyte.com/Graphics-Card/GV-N1080IXEB-8GD)，本来打算上 Dell 的 [外星人Alienware ALPHA(阿尔法)R2](https://item.jd.com/3122894.html)，可是实在是太太太太太贵了，再加上当时买这台 Macbook 的时候我升到了 i7 + 16G RAM，感觉也没必要为此新买一台电脑，因为理论上来讲目前的配置，只差一块给力的显卡就能顺利吃鸡，于是就有了接下来要做的。

### 前言

因为苹果的一些限制，直接在 Bootcamp 的 Windows 里插上外接显卡，系统是不会认的。而且在开机的时候，如果你不折腾一下，会直接卡死在 Windows 标志那里，所以我们需要改一下引导，让 Macbook 能带着这块显卡愉快地玩耍。

下面的教程，如果你不想来回折腾，那么请老老实实，一步一步按照我写的去做。我为了安装这块显卡，前后重装了3遍系统，翻了好多国内外论坛，踩了无数坑，最后终于搞定，因此必须先感谢一下如下这几位前辈：

1. [[Guide] AORUS GTX 1070 Gaming Box on Macbook Pro 2016](https://www.reddit.com/r/eGPU/comments/6xzrso/guide_aorus_gtx_1070_gaming_box_on_macbook_pro/)
2. [``手机锋友9b7pztp` 大哥写的一篇简易教程](http://bbs.feng.com/read-htm-tid-11490433.html)
3. [`q642638452` 开的求助帖](http://bbs.feng.com/read-htm-tid-11487637.html)

上面 3 篇文章，第 1 篇是最完整，也是质量最高的，我的教程基本是在第1篇的基础上改的，顺便加了一点原文没有提到的、我自己踩过的坑。后面两篇在我不知所措的时候也给了我不少帮助，在此一并表示感谢。

### 准备工作

* 一台带有 Thunderbolt 3 接口的 Macbook
* AORUS GTX1080 8G Gaming Box
* 一点点英文基础与一点点 Linux 命令基础

### 安装步骤

1. **[macOS]** [使用 Bootcamp 安装 Windows](https://support.apple.com/zh-cn/HT201468)。这里我自己安装的是 1709 Sept 的版本，装完之后记得安装上苹果的 Bootcamp 驱动包，打齐所有驱动，此时进设备管理器不应该看到有异常设备。

2. **[Windows]** 安装 [DDU](https://www.wagnardsoft.com/) 来[移除掉默认的 AMD/Nvidia 显卡驱动](https://i.imgur.com/HrQBazP.png)。注意，因为你在第一步已经全新安装了 Windows，所以我只执行了移除 AMD/Nvidia 的操作，Intel 的不用移除，因为第一步里苹果刚给你装上。移除完之后，请[禁用 Windows 的驱动自动安装](https://www.laptopmag.com/g00/articles/disable-automatic-driver-downloads-on-windows-10)，免得等下插上显卡之后它自作聪明给你装兼容驱动，而且还会导致 Nvidia installer 无法正常进行安装。

3. **[macOS]** **这一步比较重要**。[安装 rEFInd 启动管理器](https://github.com/aroman/elementary-on-a-mac#install-refind-boot-manager)。 把前面下载好的 zip 包解压到桌面，然后重启电脑按住 `command + R`进到恢复模式，然后点击菜单里的“终端”打开，先执行一下 `csrutil disable`，目的是为了关掉 macOS 的 SIP 验证，接着[这样操作](https://i.imgur.com/r6oSGfk.jpg)。 如果搞定的话，重启你就可以看到一个[这样的引导页面](https://i.imgur.com/EUB0S1a.jpg)。 (暂时还没有图上那三个圆的图标，先别急，你只要看到这个白底中间有几个按钮的界面就行了)。另外，如果你感觉少了分区的话，按一下 delete 键可以重新加载一下。

4. **[macOS]** 下载 [apple_set_os.efi](https://github.com/0xbb/apple_set_os.efi/releases)

5. **[macOS]** [挂载 EFI 分区](http://themacadmin.com/mounting-the-efi-boot-partition-on-mac-os-x/) 。然后进到挂载好的 EFI 分区里，**分别在两处**地方把上一步下载好的 `apple_set_os.efi` 扔进去。[第一处](https://i.imgur.com/6nNF6hh.png)；[第二处](https://i.imgur.com/m7Jc165.png)。这两处必须都要有，否则等会儿 `rEFInder` 会找不到你这个区。

6. 关机，把 AORUS GTX1080 8G Gaming Box 插电，然后连接到电脑。13寸的 Macbook Pro 用户注意，因为带宽的原因，你的电脑只有左边两个 Type-C 接口是真正的满速 Thunberbolt 3，所以建议插在电脑左边。

7. **[Windows]** 开机，理所当然会停在 `rEFInder` 让你选。把图标[移动到你 第5步 放了`apple_set_os.efi` 文件的那个 EFI 分区](https://i.imgur.com/0Boj2R9.jpg)，回车一下，这时屏幕会快速闪一下，这是正常的正常；然后选择`用 EFI 模式加载 Windows`（不是 `Legacy` 那个），开始启动。

8. **[Windows]** 打开设备管理器，此时在“显示卡”里面，你应该可以看到 Macbook 自己的一块 `Iris 550`，另外一块则是 `Microsoft VGA 兼容控制器`，没错，这其实就是你的 AORUS GTX1080 8G Gaming Box 了，只不过我们还没安装驱动，此时离成功已经不远。

9. **[Windows]** [安装 Nvidia graphics 驱动](http://www.gigabyte.cn/Graphics-Card/GV-N1080IXEB-8GD#dl)，然后重启。

10. 大功告成。

### 补充说明
上面的教程仅适用于 13寸 Macbook Pro，如果你是 15 寸 用户，可能还需要禁掉自带的一块显卡，步骤比上面稍微多出一些，具体可以参考：

https://egpu.io/forums/implementation-guides/late-2016-15-macbook-pro-rp450-gtx107032gbps-tb3-aorus-gaming-box-win10-theitsage/

https://9to5mac.com/2017/04/19/akitio-node-gtx-1080-ti-gpu-macbook-pro-gaming-egpu/

最后附几张搞定后的图。不知道是不是我火星了，刚才装完吃鸡之后第一次打开，进到设置里面，默认的显示模式居然已经切到了“极致”，看来性能真的是可以的。。。=。=

![](https://i.imgur.com/cXEQ7bp.jpg)

![](https://i.imgur.com/H4p8DjR.jpg)



