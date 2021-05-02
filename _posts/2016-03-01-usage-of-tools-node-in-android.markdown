---
layout: post
title: "使用 tools:node 替换 AndroidManifest.xml 中的节点"
date: 2016-03-01 23:42:39 +0800
comments: true
categories: Android
---

今天下班前被组里的小伙伴问了一个问题：

> 如果一个工程需要定义两个 flavor，每个 flavor 需要用一份单独的 AndroidManifest.xml，应该怎么配置？

这个问题，熟悉 gradle 的同学应该是能轻松搞定的。我们知道，gradle 在编译 apk 的时候支持给每个不同的 flavor 指定 src、res、甚至 AndroidManifest.xml 文件都没有问题。

首先我们定义两个 flavor：

``` groovy
productFlavors {
        normal {}
        meizu {}
    }
```

为了让两个 flavor 分别取不同的 AndroidManifest.xml，我们在 src 下面建立一个叫 meizu 的文件夹，里面单独放置这个 flavor 要用的清单文件，就像这样：

![](http://ww3.sinaimg.cn/large/7adcb3b9gw1f1htfiz5e3j209m047glq.jpg)

然后我们配置 sorceSets 闭包：

``` groovy
sourceSets {
        main {
            manifest.srcFile 'src/main/AndroidManifest.xml'
        }
        meizu {
            manifest.srcFile 'src/meizu/AndroidManifest.xml'
        }
    }
```

`src/meizu/AndroidManifest.xml` 和 `src/main/AndroidManifest.xml`的区别在于，前者删掉了 SecondActivity 的 `action`，理论上，如果我们编译 meizu flavor，那么在点击按钮之后，因为采用了 action 的方式来启动 activity，会因为 action 找不到导致失效。然而结果是这样吗？大家可以试一下。

结果是我们依然可以很顺利地跳到 SecondActivity...

为什么？

这就需要大家了解 gradle 在编译时，对 manifest 采用的 merge 策略。

引用一下 [Ezio Shiki](https://www.zhihu.com/people/eizo) 在[知乎上](https://www.zhihu.com/question/22842123/answer/55675046)的一段回答：

> Manifest可以通过Merge的方式合并多个Manifest源。通常来说，有三种类型manifest文件需要被merge到最终的结果apk，下面是按照优先权排序：productFlavors和buildTypes中所指定的manifest文件应用主manifest文件库manifest文件简单来说，manifest的merge会将每个元素及其子元素的节点和属性进行合并。

例如：

```
<activity
    android:name=”com.foo.bar.ActivityOne”
 	 android:theme=”@theme1”/>
```
和

```
<activity
    android:name=”com.foo.bar.ActivityOne”
 	 android:screenOrientation=”landscape/>
```
 
合并会成为

```
<activity
    android:name=”com.foo.bar.ActivityOne”
 	 android:theme=”@theme1”
 	 android:screenOrientation=”landscape/>
```

不过

```
<activity
    android:name=”com.foo.bar.ActivityOne”
 	 android:theme=”@theme1”/>
```
 
和

```
<activity
   android:name=”com.foo.bar.ActivityOne”
 	 android:theme=”@theme2”
 	 android:screenOrientation=”landscape/>
```

合并会产生一个冲突，因为都有theme，而theme的属性不同。

> 要了解manifest合并的更高级应用，查看[Manifest Merger](http://tools.android.com/tech-docs/new-build-system/user-guide/manifest-merger)

所以，看明白了吗？简单来说，AndroidManifest.xml 文件在 gradle 打包编译的时候，__不是你指定哪个，它就100%去用哪个的。__

* 首先，你的 main 里面必须要有一份基本的，不可以因为要分 flavor 就把 main 里面的删掉，否则会直接编不过
* 接着，你要知道 Manifest 的 merge 关系，从你的 flavor 到 main，它是一层层合并的，合并的规则上面已经提到了。
* 最后，如果我有一个 Activity，或者 Service，或者 Receiver，真的要用另一份 AndroiManifest.xml 里的怎么办？

关于这个问题，官方文档给出了我们答案：

[tools:node markers](http://tools.android.com/tech-docs/new-build-system/user-guide/manifest-merger#TOC-tools:node-markers)

没错，我们可以使用 `tools:node replace` 来解决我们的问题。现在来修改一下 `src/meizu/AndroidManifest.xml`，在 SecondActivity 的声明里加上，如下图所示：

![](http://i4.tietuku.com/8fbd5b45262c6645.png)

再编译一下这个 flavor，点击按钮，可以看到报错了。

![](http://ww2.sinaimg.cn/large/7adcb3b9gw1f1hu90aydej20lh07uwik.jpg)

现在已经没有对应的 Activity 来解析这个 action 了，也就是说我们为 meizu 这个 flavor 指定的 AndroidManifest.xml 总算“生效”了。

Demo 地址：https://github.com/shawnlinboy/Android-MultiFlavors

参考文章：

> https://www.zhihu.com/question/22842123/answer/55675046
> 
> 
> http://tools.android.com/tech-docs/new-build-system/user-guide/manifest-merger#TOC-tools:node-markers
> 
> 
> http://my.oschina.net/fallenpanda/blog/373183


