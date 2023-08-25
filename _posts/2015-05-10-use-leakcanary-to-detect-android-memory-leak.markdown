---
layout: post
title: "Use LeakCanary to detect Android Memory Leak"
date: 2015-05-10 02:40:28 +0800
comments: true
categories: Android
---

不得不承认，长久以来，对于大部分 Android 工程师，分析内存泄露这一问题多少还是显得有些苦巴巴。因为自己去 dump HPROF 文件，再用 MAT 这类工具分析，对于之前没有接触过这方面工作的还是要一定学习成本的。而且因为这些代(da)码(keng)真的是你一行行写(wa)出来的，每个人在查自己代码的内存泄露问题时候多少都会想着“卧槽这里怎么可能有问题？这可是我亲手写的啊！！！”，这往往就让问题更加难以被发现。

今天，哦不，凌晨了。。。昨天！昨天，Android 开源界最伟(jian)大(zhi)高(kai)效(gua)的公司 [Square](http://square.github.io) 又向业界投下一颗重磅炸弹。推出了一个叫 [LeakCanary](https://github.com/square/leakcanary) 的玩意儿，可以通过简单粗暴的方式来让开发者获取自己应用的内存泄露情况。而且得益于 `gradle` 强大的可配置性，可以确保只在编译 debug 版本时才会检查内存泄露，而编译 release 等版本的时候则会自动跳过检查，避免影响性能。当然，理论上在 debug 阶段所有发现的问题也都该在 release 之前解决掉，否则就没有办法显得逼(ku)格(bi)满满了。

这货真的有这么好用？机智的我还是决定写个 demo 跑一下试试：

## 接入步骤

`build.gradle`

因为不想让这样的检查在正式给用户的 `release` 版本中也进行，所以在 `dependencies` 里添加

``` groovy
dependencies {
    compile fileTree(dir: 'libs', include: ['*.jar'])
    compile 'com.android.support:support-v13:+'
    debugCompile 'com.squareup.leakcanary:leakcanary-android:1.3'
    releaseCompile 'com.squareup.leakcanary:leakcanary-android-no-op:1.3'
}
```
接下来，在你的应用里写一个自定义 `Application` ，并在其中“安装” `RefWatcher`：

``` java
public class AppApplication extends Application {

    private RefWatcher mRefWatcher;

    @Override
    public void onCreate() {
        super.onCreate();
        mRefWatcher = LeakCanary.install(this);
    }
}
```
记得把它作为 `android:name` 配到 `AndroidManifest.xml` 的   `Application` 节点下。

大功告成，就是这么简单。。。

<!-- more -->

## 开始测试

造一个内存泄露简直太简单了！（咦，我为什么这么说😓）。这里以我之前写代码的时候常犯的一个错误为例——__单例 Context 内存泄露__。我敢保证这种问题至今有很多程序员在写代码的时候还是会犯，要挖这个坑很简单：

假设我们有一个 `MainActivity`，它的布局很简单，里面只有一个 `TextView`:

``` xml
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:paddingBottom="@dimen/activity_vertical_margin"
    android:paddingLeft="@dimen/activity_horizontal_margin"
    android:paddingRight="@dimen/activity_horizontal_margin"
    android:paddingTop="@dimen/activity_vertical_margin"
    tools:context=".MainActivity">

    <TextView
        android:id="@+id/tv_test"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        tools:text="@string/hello_world" />

</RelativeLayout>
```

现在我们要写一个单例的 `XXXXHelper` 之类的业务类，用来给这个 `TextView` 固定设一个值，但是这个值要从 `res` 里面读，所以我们得用到 `Context`:

``` java
package com.example.linshen.testapplication;

import android.content.Context;
import android.widget.TextView;

/**
 * Created by linshen on 15/5/10.
 */
public class XXXHelper {

    private Context mCtx;
    private TextView mTextView;

    private static XXXHelper ourInstance = null;

    public static XXXHelper getInstance(Context context) {
        if (ourInstance == null) {
            ourInstance = new XXXHelper(context);
        }
        return ourInstance;
    }

    public void setRetainedTextView(TextView tv){
        this.mTextView = tv;
        mTextView.setText(mCtx.getString(android.R.string.ok));
    }

    private XXXHelper() {
    }

    private XXXHelper(Context context) {
        this.mCtx = context;
    }

}

```

我想问下有多少人已经看出了这里面的问题？或者有多少人平时写单例的时候就是这样来的？如果你现在没看出来也没关系，现在我们回到 `MainActivity.java` 来用这个单例：

``` java
public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        TextView tv = (TextView) findViewById(R.id.tv_test);
        XXXHelper.getInstance(this).setRetainedTextView(tv);
    }
}

```
是不是看着没什么事？现在让我们愉快地 run 起这个 app：

![](http://ww1.sinaimg.cn/large/7adcb3b9gw1erylk0qb3gj20w01hcwft.jpg)

一切正常，退出，再进入。很完美，而且启动速度很快有木有（废话么）！！！Wait！通知栏那是什么？拖下来看一下：

![](http://ww2.sinaimg.cn/large/7adcb3b9gw1erylmrn83pj20w01hc78k.jpg)

___恭喜你，你露了。。。___

不过没关系，点击这条通知，[LeakCanary](https://github.com/square/leakcanary) 会带你来到一个更加详细的页面，当然你在桌面上也可以找到 [LeakCanary](https://github.com/square/leakcanary) 的另外一个入口 icon，点击也能到这里，点击泄露状况右边的加号，[LeakCanary](https://github.com/square/leakcanary) 会详细告诉你这边是怎么一步步发生泄露的：

![](http://ww3.sinaimg.cn/large/7adcb3b9gw1erylppoux3j20w01hc0xl.jpg)

问题分析
===
[LeakCanary](https://github.com/square/leakcanary) 已经把问题很明显地带到了我们面前。这是一个典型的单例导致的 Context 泄露问题。我们知道 Android 的 Context 分为 `Activity Context` 和 `Application Context`，关于他们的区别这里就不再赘述了。在这段简单的代码里，我们的 `XXXHelper` 的静态实例 `ourInstance` 由于有一个对 `mTextView` 的引用，而 `mTextView` 由于要 `setText()` 所以持有了一个对 `Context` 的引用，而我们在 `MainActivity` 里获取 `XXXHelper` 实例时因为传入了 `MainActivity` 的 `Context`，这使得一旦这个 `Activity` 不在了之后， `XXXHelper` 依然会 hold 住它的 `Context` 不放，而这个时候因为 `Activity` 已经不在了，所以内存泄露自然就产生了。

事实上，如果你够留意 Google 官方博客的话，会发现 Google 早在 2009 年[一篇博文](http://android-developers.blogspot.com/2009/01/avoiding-memory-leaks.html)里就提到了这个问题。可惜那个时候国内搞 android 开发的人估计才刚刚开始，包括我自己也是后来才读到。所以更加不可能注意到这个坑了。

解决方案
===
知道了问题的来龙去脉，解决就不难了。不过在解决之前还是可以先看下 Google 给出的 solution：

> There are two easy ways to avoid context-related memory leaks. The most obvious one is to avoid escaping the context outside of its own scope. The example above showed the case of a static reference but inner classes and their implicit reference to the outer class can be equally dangerous. The second solution is to use the Application context. This context will live as long as your application is alive and does not depend on the activities life cycle. If you plan on keeping long-lived objects that need a context, remember the application object. You can obtain it easily by calling `Context.getApplicationContext()` or `Activity.getApplication()`.

我们试着改造一下 `XXXHelper`，

``` java
XXXHelper.getInstance(this.getApplication()).setRetainedTextView(tv);
```

再试跑一下。。。等等，为什么还是提示有内存泄露？我们再来看一下这次的问题：

![](http://ww3.sinaimg.cn/large/7adcb3b9gw1erz3gbqisyj20w01hcjvs.jpg)

看出区别了吗？这一次不再是 `mCtx` 的问题，而是 `mTextView` 导致。尽管我们的 `Context` 已经是 `Application Context` 了，但这种写法依然会导致`mTextView` 在退出后依旧 hold 住整个 Application 的 `Context`，最终还是导致内存泄露。

解决办法也很简单，我们在 `XXXHelper` 里增加一个 `remove` 方法试一下：

``` java
    public void removeTextView(){
      mTextView = null;
    }
```

回到 `MainActivity`，在 `onDestroy`里调用一下：

``` java
     XXXHelper.getInstance(this.getApplication()).removeTextView();

```

太棒了，现在终于没有再提示内存泄露了。

总结
===
单例模式导致的内存泄露在 Android 平台是非常常见的一种不小心就踩到的坑。在上面的例子里，虽然我们最后 fix 了两处内存泄露的地方。但是我跟中国好舍友 [@刘云龙在搞机](http://weibo.com/u/2873221102) 讨论了一下，依旧认为这样的写法不是很优雅。最佳的办法还是在 `XXXHelper` 里面写一个回调去通知 `MainActivity` 更新 `TextView` 的 UI，而 `XXXHelper` 还是注重业务逻辑本身，不要去尝试 hold 着 `TextView` 来对 UI 进行更改，`TextView` 本来就属于 `MainActivity` 里的东西，所以作为 `Helper` 只管处理逻辑就好。
