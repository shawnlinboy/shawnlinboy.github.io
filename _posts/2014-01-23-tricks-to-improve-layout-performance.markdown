---
layout: post
title: "Android 布局优化日记"
date: 2014-01-23 14:39:27 +0800
comments: true
categories: Android
--- 
### 什么，你是写UI的？

很多人在 android 开发过程中看不起布局优化工作，觉得布局工作是一件 low 爆了的工作，完全体现不出码农那种牛逼轰轰的优越感。我也曾因为“长期处于‘Layout’层”被 team 里干“上层”的队友嘲笑过不会写代码。而事实真的是这样吗？

要知道，一款“如丝般顺滑”的软件，流程自然是有它的道理的。比如我的偶像，新浪微博第三方客户端 [Fuubo](http://fuubo.me) 的开发者 [@碎星iKe](http://weibo.com/issacsuixing) ，他本人就很精通布局的优化之道，并且专注于流畅体验应用的开发。当然，这也得益于他经常看 [Google I/O](https://developers.google.com/events/io/) 和 [Android Developer](http://developer.android.com/index.html) 的缘故，并且这一点也深深地影响了我。回想起来，当时学 Android 开发时跌跌撞撞买的书也不少，但是越往后看你越会发现这些书讲得要么都非常浅，要么就是有股作者自身浓浓的“代码风”，看一章下来脑袋里满是疑问“为什么要在那里那么写？作者是怎么知道的？”其实这些所有的疑问都可以在 [Android Developer](http://developer.android.com/index.html) 上找到答案，就包括现在大家热议的 [Android Design](http://developer.android.com/design/index.html) ，如果你经常看官网的话对这些概念的理解都会是很自然而然的事情，对一些新组件的学习也会非常快。
<!--more--> 
### 问题提出
好了，说了那么多废话，下面开始进入主题——

寒假在家做毕业设计界面的时候，遇到的第一个问题就是引导界面的问题，先来一张最终效果：

![1](http://ww1.sinaimg.cn/large/7adcb3b9gw1ecthgy92d0j20m80zkjuj.jpg)

这个设计里面包含了三个基本的小要求：

1. 滑动时需要保证「Logo」和「登录」按钮始终显示；
2. 每一页的「Title」和「Subtitle」不能相同。
3. 下面的小圆点指示目前在哪一页

有了这个需求，下面开始给这个界面分层：

1. 「Title」、「Subtitle」以及背景「imageView」可以作为 ViewPager 所滑动的 Fragment 的 rootView；
2. 「Logo」、「登录」、「小圆点」作为该 Activity 的 contentView。

这里贴出 Activity 的布局：

``` xml
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/main_layout"
    android:layout_width="fill_parent"
    android:layout_height="fill_parent" >

    <android.support.v4.view.ViewPager
        android:id="@+id/vp_unlogin"
        android:layout_width="fill_parent"
        android:layout_height="fill_parent" />

    <ImageView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_gravity="center_horizontal"
        android:layout_marginTop="90.0dip"
        android:background="@drawable/ic_launcher" />

    <LinearLayout
        android:id="@+id/ll_unlogin_bottombar"
        android:layout_width="fill_parent"
        android:layout_height="wrap_content"
        android:layout_gravity="bottom|center"
        android:layout_marginBottom="20.0dip"
        android:orientation="horizontal" >

        <Button
            android:id="@+id/btn_unlogin_login"
            android:layout_width="0dip"
            android:layout_height="wrap_content"
            android:layout_gravity="center_horizontal"
            android:layout_marginLeft="@dimen/activity_horizontal_margin"
            android:layout_marginRight="@dimen/activity_horizontal_margin"
            android:layout_weight="1.0"
            android:background="@drawable/btn_public_blue_selector"
            android:gravity="center"
            android:minHeight="44.0dip"
            android:text="@string/action_login"
            android:textColor="@android:color/white"
            android:textSize="16.0sp" />
    </LinearLayout>

    <LinearLayout
        android:id="@+id/ll_unlogin_indicator"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_alignParentBottom="true"
        android:layout_centerHorizontal="true"
        android:layout_gravity="bottom|center"
        android:layout_marginBottom="79.0dip"
        android:orientation="horizontal" >

        <ImageView
            android:id="@+id/iv_unlogin_indicator1"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_gravity="center_vertical"
            android:padding="10.0dip"
            android:src="@drawable/ic_dot_selector" />

        <ImageView
            android:id="@+id/iv_unlogin_indicator2"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_gravity="center_vertical"
            android:padding="10.0dip"
            android:src="@drawable/ic_dot_selector" />

        <ImageView
            android:id="@+id/iv_unlogin_indicator3"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_gravity="center_vertical"
            android:padding="10.0dip"
            android:src="@drawable/ic_dot_selector" />

        <ImageView
            android:id="@+id/iv_unlogin_indicator4"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_gravity="center_vertical"
            android:padding="10.0dip"
            android:src="@drawable/ic_dot_selector" />
    </LinearLayout>
</FrameLayout>
```

这个布局乍一看是没什么问题的。但是如果你跑一下，或者用 `Hierarchy View` 看一下，就会发现里面的层级套用相当复杂。如果你不太会看 `Hierarchy View` ，也可以用 DDMS 里的一个 ![UI Automator](http://ww1.sinaimg.cn/large/7adcb3b9gw1ecti0pibv3j2018019a9t.jpg)工具，此时分析的结果是这样：

![2](http://ww3.sinaimg.cn/large/7adcb3b9gw1ecti2k4cvxj208k06k0t9.jpg)
### 解决方案
问题是，我们的代码里并没有那么多的「FrameLayout」，所以我们需要用到 `<merge></merge>` 标签对来解决这个问题。

顾名思义，`<merge></merge>` 标签可以在开发过程中帮助有效减少 View 的层级数量。举个例子：如果你的布局的 root 是一个垂直的 LinearLayout_1 ，这个 LinearLayout_1 里面需要再放一个垂直的 LinearLayout_2 ，然后这个 LinearLayout_2 里有两个 Button ，听起来很完美，但只是因为这个布局较为简单，一旦层级关系多了之后，诸如前面描述的情况，一层层嵌套着的 LinearLayout 就会拖慢整体的绘图性能，而事实上这几个 LinearLayout 几乎都是一样属性的，只不过是包含的子空间不同，因为我们完全可以就写一个 LinearLayout，而在其它地方使用`<include></include>`重用这个布局即可。

在这里，我们只需简单地把根结点的`<FrameLayout></FrameLayout>`换成`<merge></merge>`，布局本身的样式不会有任何变化，但当我们再次使用`UI Automator`查看，会发现布局层级已经显著减少了，如下图：

![3](http://ww1.sinaimg.cn/large/7adcb3b9gw1ectih7qcj9j207r0440t4.jpg)

事实上，随着内部元素越来越多，使用这个优化技巧所提高的性能会越来越明显。而 Android 本身优化 Layout 方面也还有很多技巧有待发掘，有机会我会再与大家分享！

推荐参考：[Improving Layout Performance](http://developer.android.com/training/improving-layouts/index.html)