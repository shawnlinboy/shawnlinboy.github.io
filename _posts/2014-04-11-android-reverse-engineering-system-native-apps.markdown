---
layout: post
title: "Android Reverse Engineering System Native Apps"
date: 2014-04-11 23:12:57 +0800
comments: true
categories: Android
---
之前写过一篇关于反编译 android 软件的[总结](http://mobileoldlin.duapp.com/?p=884)，不过那是针对一些第三方应用的。针对系统应用，需要一些“特殊”的办法。

Why odex？
===
在 android 系统中，所有的系统级软件都被分解成了两个文件，而不是单纯的“apk file”。以图库为例，在 /system/app 下可见 “Gallery2.apk”和“Gallery2.odex” 两个文件。至于为什么要这样分解，下面这段文字可以解释：
> In Android file system, applications come in packages with the extension .apk. These application packages, or APKs contain certain .odex files whose supposed function is to save space. These ‘odex’ files are actually collections of parts of an application that are optimized before booting. Doing so speeds up the boot process, as it preloads part of an application. On the other hand, it also makes hacking those applications difficult because a part of the coding has already been extracted to another location before execution.

Let's hack on!
===
要想逆向这些系统级应用，你需要如下5步：

1. 下载 `baksmali-2.0.3.jar` 和 `smali-2.0.3.jar` 两个 jar 包.如果你连他们都搜不到，我相信你暂时还不适合做这行。

2. 将 /System/framework 文件夹拽到你的本地硬盘。同时拽出你要 reverse 的系统app，比如第一段中说的 “Gallery2.apk”和“Gallery2.odex” 。

3. OK，你现在拥有2个 jar 文件，1个 apk 文件，1个 odex 文件，1个 /framework 文件夹。Now，在你本地硬盘上新建一个文件夹，把这些东西全部放在一起。然后在终端 cd 到这个目录，执行 `java -jar baksmali.jar -d ./system/framework -x “Gallery2.odex`

4. 执行 `java -Xmx512M -jar smali.jar out -o classes.dex` ，将 第三步中得到的 out 文件夹中的 class 文件编译成 `classes.dex`。

5. 有了 dex 文件，再用 dex2jar 转换成 jar 文件，拿 JD-GUI 打开就可以查看了。

注意，第3步中的 -d 参数告诉了反编译器 /framework 文件夹的位置，里面有一些系统的核心 jar 包是反编译时需要调用的。这个参数不加，会抛一个 `org.jf.util.ExceptionWithContext: Cannot locate boot class path file /system/framework/core.odex` 的 exception。如果你按部就班照着网上的教程来，呵呵，大部分会卡在这一步。

Good luck!  :)