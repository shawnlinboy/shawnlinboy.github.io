---
layout: post
title: "AOSP: Meizu Flyme Styled PagerSlidingStrip"
date: 2014-03-05 22:06:07 +0800
comments: true
categories: Android
---
Introduction
===
最近项目里需要用到动态的 `ViewPagerTitleStrip`，本着「Don't Reinvent the Wheel」的精神，晚上阅读了 [Andreas Stütz](https://github.com/astuetz) 大神的一个开源项目，顺便用`自定义 ActionBar`的方式模仿 Flyme 3.0 自带的音乐、视频、应用中心的顶部式样做了一个 demo，放出来供更多开发者继续 「Don't Reinvent the Wheel」。

_另附上之前开源的 [《Flyme 2.0 软件中心主页面样式实现》](http://mobileoldlin.duapp.com/?p=1510)_

Usage
===
1. Clone the project.
2. Copy `PagerSlidingStrip.java` to your project.
3. Available attributions are defined at `/res/values/attrs.xml`
4. Add the following code to your layout file.
``` xml
 <me.mobilelin.meizu.lib.PagerSlidingStrip
     android:id="@+id/tabs"
     android:layout_width="match_parent"
     android:layout_height="48dip"
     android:background="@null"
     pss:indicator_color="@color/mz_strip_indicator" />
```
<!-- more -->

SnapShots
===
![](http://ww4.sinaimg.cn/large/7adcb3b9gw1ee593zawv5j20go0qo0t4.jpg)

Download
===
[![](http://ww3.sinaimg.cn/large/7adcb3b9gw1ee58nwlbb6j206e01et8i.jpg)](https://github.com/shawnlinboy/Meizu-Flyme-PagerSlidingStrip)
===
