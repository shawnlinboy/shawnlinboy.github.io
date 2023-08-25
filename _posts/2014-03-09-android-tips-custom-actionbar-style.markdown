---
layout: post
title: "Android Tips: Customize ActionBar Style"
date: 2014-03-09 02:14:28 +0800
comments: true
categories: Android
---
如果要让项目里所有 ActionBar 样式统一，我们需要重写一下 `style.xml`

Android 4.0 起的工程一般会默认使用 `AppTheme` 这个主题，它继承自 `AppBaseTheme`，我们可以在`style.xml` 中看到如下代码：
``` xml
<style name="AppBaseTheme" parent="android:Theme.Light">
</style>
<!-- Application theme. -->
<style name="AppTheme" parent="AppBaseTheme">
    <!-- All customizations that are NOT specific to a particular API-level can go here. -->
</style>
```
Android 已经告诉了我们，要自定义一些设置，可以在 `AppTheme` 节点下定义，在此我定义了 `ActionBar` 的样式：
``` xml
<item name="android:actionBarStyle">@style/MyActionBar</item>
```
接着，你需要给出这个样式：
``` xml
<!-- ActionBar styles -->
<style name="MyActionBar" parent="@android:style/Widget.Holo.Light.ActionBar.Solid.Inverse">
    <item name="android:background">@color/hhit_blue</item>
    <item name="android:backgroundSplit">@android:color/black</item>
</style>
```
<!-- more -->
上面的代码中，我将 android 默认的 splitActionBar 背景换成了纯黑色，默认的灰色看着真的很蛋疼。

需要说明的是，当你在写 `MyActionBar` 这个样式时， eclipse 并不会给全具体的属性提示，比如 `android:backgroundSplit` 这个属性，eclipse 默认是不给出的，尚不清楚 Android Studio 有无这个问题，所以关于 ActionBar 的更多属性，大家还需要养成勤查文档的习惯才行！

__效果图__

![](http://ww1.sinaimg.cn/large/7adcb3b9gw1ee8wsz8oqoj20m80hqgmf.jpg)