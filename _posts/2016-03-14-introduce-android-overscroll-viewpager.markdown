---
layout: post
title: "Android Overscroll Viewpager"
date: 2016-03-14 23:59:55 +0800
comments: true
categories: Android
---

Project Home
======
https://github.com/shawnlinboy/android-OverscrollViewPager/

Description
======

最近项目里接到一个需求，效果如下：

![](http://ww2.sinaimg.cn/large/7adcb3b9gw1f1wxdnmcfrg20dw0ope81.gif)

简而言之，需要在 ViewPager 滑到最左或者最右的时候，仍然支持可滑动。

具体就是根据是在 ViewPager 最右边向右滑了，还是在最左边向左滑了，做出响应。这就要求对 ViewPager 的 `overscroll` 行为做出监听。

网上也有一些类似的轮子，但是我感觉做得真心复杂，而且都是为了实现轮播的，所以可扩展性并不强。因此我这里要做的，就是对 ViewPager 的`overscroll` 行为做出简单的监听并封装。剩下的，交给开发者自己去 do whatever you want 就好。

原理很简单，对手势做出监听即可。所以也算是对ViewPager 的`overscroll` 行为监听的另一种实现思路吧。

使用上，只需要把 ViewPager 替换成我这个就好，adapter 不需要改，也没必要改。因为我只会告诉你，你的 ViewPager 是否到头了，然后是哪边到头向哪边滑了，剩下的是你的 `//TODO`。

欢迎各路大神对它进行拓展并发起 pr。

Demo
======
![](http://ww3.sinaimg.cn/large/7adcb3b9gw1f1wx0i5vnbg20qo1bfdt0.gif)



