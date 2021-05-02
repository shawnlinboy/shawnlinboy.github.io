---
layout: post
title: "关于 AsyncTask 的常见问题（Common questions on AsyncTask
）"
date: 2016-03-27 03:33:07 +0800
comments: true
categories: Android
---

![](https://cdn-images-1.medium.com/max/2000/1*TA75du7-PUZ4OI1N4Pnwiw.png)

> 本文由 [Lin Shen](http://weibo.com/linshen2011) 译自 [Common questions on AsyncTask](https://medium.com/@duhroach/common-questions-on-asynctask-559aa7b07d0b#.4dcb9beca)，原文作者 [Colt McAnlis](https://plus.google.com/+ColtMcAnlis/about), __转载请务必注明出处！__

关于 AsyncTask 的常见问题
===

我在 Google 工作最喜欢的一点，就是把一些比较复杂的概念，分解成一小部分一小部分，这样就可以确保每一位工程师都能清楚地理解。在我最近的《[Android 性能优化典范](https://www.youtube.com/playlist?list=PLWz5rJ2EKKc9CBxr3BVjPTPoDPLdPIFCE)》视频中，我提到了一个表面上看上去很直观，但是它的一些属性可能会带来一些万万没想到的负面影响的东西，我是说，毫无悬念，这货就是 [关于 AsyncTask](https://www.youtube.com/watch?v=jtlRNNhane0&index=4&list=PLWz5rJ2EKKc9CBxr3BVjPTPoDPLdPIFCE):

[![](http://ww3.sinaimg.cn/large/7adcb3b9gw1f2avy38i2dj20je0ay40a.jpg)](https://www.youtube.com/watch?v=jtlRNNhane0&index=4&list=PLWz5rJ2EKKc9CBxr3BVjPTPoDPLdPIFCE)

我在这个视频里强调了一些开发者之前在使用 AsyncTask 时可能并不会注意到的事项。多亏了我们有一些非常棒的 android 开发者交流社区，能让我们看到大家反馈的一些问题：

![](https://cdn-images-1.medium.com/max/800/0*doa5AeYFIypICJZZ.)

让我们来挖掘其中的一些问题，看看能不能深入展开讨论一下：

<!--more -->

对 activity / view 使用 WeakReference?
===

![](https://cdn-images-1.medium.com/max/800/0*tRoxtnVjZiVrb2eP.)

在 Java 当中，[WeakReferences](http://developer.android.com/intl/zh-cn/reference/java/lang/ref/WeakReference.html) 是一个不错的引用对象的方法，而且当你持有对象的引用的时候，它还能保证不被 GC(garbage-collect) ([这儿](http://stackoverflow.com/questions/3243215/how-to-use-weakreference-in-java-and-android-development)有个关于这个问题不错的讨论)。

这么一来，用 WeakReference 就可以让你的异步任务对任意一个你感兴趣的 UI 对象持有引用，而且还不用担心造成内存泄露。

这确实很棒，因为这么一来似乎直接解决了我们对内存泄露的担心。可是从它自身角度来看，这不是一个完整的解决方案；它并没有解决接下来的一个问题：当这个 UI 对象被销毁的时候，你怎么办？

假设你持有的是一个对 __Activity__ 的引用，解决方法可能就比较简单，只要加几行代码判断一下 `WeakReference.get()` 是不是返回 null 就行，在一些 Activity 已经被销毁的情况下， 这样判断一下你就知道接下来该怎么做了。

而引用一些特定 __View__ 的时候也可以用相同的办法，但随之也会带来一些精神上的焦虑（至少对我而言是这样），因为你要知道，你持有的这个对象，并没办法知道在异步操作的时候，它的数据状态是不是已经冻结了。举个例子，假如你正持有的这个对象已经从 view 层级（view hierarchy）中被移除了，或者它的内容被你一个已完成的操作给刷新了。这两个例子，只要有其中一种情况，你就仍然要想一些策略来应对类似场景。 

所以说，使用 WeakReference 确实会帮助降低潜在的内存泄露风险，只要你愿意多写几行代码，一个对象一个对象地处理 `WeakReference.get()` 返回 null 的情况，那我无话可说。

把一个静态的 AsyncTask 搞成内部类吗?
===

![](https://cdn-images-1.medium.com/max/800/0*lqZRaf4eei4HVFvw.)

完全正确。（译著：这里 Colt McAnlis
 是想赞同上面这个开发者的评论，这个开发者认为静态嵌套类比内部类更好，而并不是赞同这个副标题）把 AsyncTask <u>声明成 activity 一个静态嵌套类(static nested class)</u>，可以消除一些隐式引用带来的七七八八的泄露问题。关于“静态嵌套类(static nested class)”和“内部类(inner class)”的区别， StackOverflow 上[这篇文章](http://stackoverflow.com/questions/70324/java-inner-class-and-static-nested-class)总结得相当不错:

> 一个内部类的实例只能在一个外部类的实例中存在，而且对于它的外围实例(enclosing instance)中的方法和属性有直接访问权。

这段话帮助解释了前面说的那些 “七七八八的泄露问题” 是怎么来的。再直接一点的话，静态的嵌套类就不会干这样的事，它们的实例并不需要外部类的实例。

所以，这解决了你的关于“隐式引用”的问题，但没解决_“我们究竟应该怎样持有对 UI 对象的引用”_的问题，这还是讲到目前为止的一个首要问题。

RxJava 怎么样?
===

![](https://cdn-images-1.medium.com/max/800/0*7O2EhX6ozRZbrRQe.)

从古至今，线程都是个很复杂的问题。一些线程相关的第三方库之所以成功，归功于它们“能将一些细微差别抽象出来”这个事实，而且能从代码层面使线程调度变得容易些。我记得 《[Intel Threading Building Blocks](https://www.threadingbuildingblocks.org/)》第一次出版的时候写到: “当我发现有一套‘久经考验’的线程安全容器可以给我使用，而不用我自己去折腾线程调度的时候，简直如释重负。结果也是不言而喻：我只要花很少的时间去测试线程，剩下的时间就可以拿来[制定我邪恶的计划了愚蠢的人类们哈哈哈哈](http://phineasandferb.wikia.com/wiki/List_of_Doofenshmirtz%27s_schemes_and_inventions/Season_3)（译著：美剧里面的台词，老外写文章都喜欢这样）”

诚然，[RxJava](https://github.com/ReactiveX/RxJava) 不例外又是一个围绕特定类型的用例和 API 模型设计的线程库。 由于它 API 提供的一些功能，一大帮 Android 开发者信誓旦旦地觉得“这就是我要的线程库！！！我的线程库时尚时尚最时尚……”。坦率地说，RxJava 对那些把线程相关的问题捧上天的人来讲，或者你的应用里确实有很多线程相关的复杂调度，对于这些人而言，RxJava 确实提供了很多不错的功能。

__如果 RxJava 对于你而言用着确实很称手，那么请跟着节奏继续摇摆，不要停。__

而对于那些持观望态度的人，请容我说几句：

首先， RxJava 说白了是一个纯 java 库。对于 Android 平台而言它没有任何特别的定制或者优化。

对那些用 java 开发服务端和客户端代码的人，这也许是一件幸事。对于做服务端的人，这样做对于他们完成这项工作而言，不一定要去改变原来的“心智模式”。然而，对于做客户端的人，这么搞就比较麻烦了。我们知道 Android 有自己的线程模型，而 RxJava 在用的时候呢？有些代码或者思想又是必须得保留的。怎样在 Android 里保留这些纯粹为 Java 设计的代码或者思想，你得花一番功夫吧？

坦率地说，RxJava 只是对线程优先级操作进行的一个 API 层级的替换， 而对于 Android 特定的一些，比如解决 UI 对象（或者其它对象，如果它们也很重要的话）的线程安全问题，它什么也没做。 你依然还是要想着，还是要担心怎么正确地引用一个 UI 对象， 而且当配置变化的时候你还是要写额外的代码来处理。

技术层面上讲，你也许会说“现在也有 [RxAndroid](https://github.com/ReactiveX/RxAndroid) 啊”。好吧，但我觉得，它只是在 RxJava 的基础上对 Application 的主线程有了更深的理解，使得向主线程发送消息来执行变得更容易，但依然缺少对 UI 对象的认知。

所以就有像 [AsyncTaskLoader](http://developer.android.com/intl/zh-cn/reference/android/content/AsyncTaskLoader.html) 这样框架级别的基础类（primitive），能提供比 RxJava/RxAndroid 更好的解决方案。这个类能像一个标准的 AsyncTask 一样工作，但提供了一些其它的回调，来让你看到 activity 发生了什么变化，以便你可以做出反应。它是一个“Android 生命周期感知型基础线程类（Android-lifecycle aware threading primitive）”，意味着它能随时回调给你一大堆有用的值，或者就像[这哥们儿说的一样](https://www.youtube.com/watch?v=s4eAtMHU5gI)：

路，一直都在
===

在今天结束前我得说，“线程相关的讨论”依然是这个问题里最简单的部分；你真正要想的是[如何正确地跟内存打交道](https://www.youtube.com/watch?v=tBHPmQQNiS8&index=3&list=PLWz5rJ2EKKc9CBxr3BVjPTPoDPLdPIFCE)。请留意我说的重点。

AsyncTask 仅仅是另一个实用的线程调度类，但和其它组件一样，它也有你需要注意的地方。了解这些“花边”的知识有助于你在写好一个 app 的代码时，做出更加明智的决定。

不管怎么样， 感谢关注《[Android 性能优化典范](https://www.youtube.com/playlist?list=PLWz5rJ2EKKc9CBxr3BVjPTPoDPLdPIFCE)》，如果有问题，尽管提别犹豫！


