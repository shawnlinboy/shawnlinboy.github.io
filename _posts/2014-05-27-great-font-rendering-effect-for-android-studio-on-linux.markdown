---
layout: post
title: "great font rendering effect for android studio on linux"
date: 2014-05-27 17:29:57 +0800
comments: true
tags: android studio
categories: Android
---
> 一年后的今天，当我鼓起勇气再一次打开 Android Studio，这 Linux 下华丽的字体渲染再一次把我亮瞎了。

治疗 Linux 下 Android Studio 的字体渲染症，你需要如下几个步骤：

首先，vim 一下 `android-studio/bin` 下的 `studio64.vmoptions` 文件（32位系统则对应 `studio.vmoptions` ），在最后面作如下修改和添加：
```
-Dawt.useSystemAAFontSettings=on
-Dswing.aatext=true
-Dsun.java2d.xrender=true
```
然后，安装 [macfonts.tar.gz](http://pan.baidu.com/s/1gdvImD9) 包中提供的所有字体，这是 Mac 的默认西文字体，逼格尽显：
``` bash
tar zxvf macfonts.tar.gz && sudo cp -r macfonts/ /usr/share/fonts/ && sudo fc-cache -f -v
```

接着，你需要用 `font-forge` 处理一下字体的 hint 信息。当然如果你比较懒，是的没错我在压缩包里已经提供好了处理后的字体，你只需要安装一下就好。

最后，打开 Android Studio 的 Settings，“Appearance” 里面的字体选择 “LucidaMac”，Code 的字体选择 “Ubuntu Mono”，或者选择上面一步中你安装的字体。

重启一下 Android Studio ，尽情享受吧！

![](http://ww4.sinaimg.cn/large/7adcb3b9gw1egsyiolepqj211y0lcgrn.jpg)
