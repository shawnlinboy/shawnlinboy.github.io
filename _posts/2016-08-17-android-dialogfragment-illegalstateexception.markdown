---
layout: post
title: "解决 DialogFragment show() 方法导致的 IllegalStateException"
date: 2016-08-17 23:05:09 +0800
comments: true
categories: Android
---

问题
===

[钱包 2.0.0_beta](http://app.meizu.com/apps/public/detail?package_name=com.meizu.flyme.wallet) 版本上线之后，我们给新获得理财权限的用户增加了一个欢迎对话框。按照 Google 官方关于开发对话框时的[指导](https://developer.android.com/guide/topics/ui/dialogs.html)，钱包把所有会用到的 Dialog 全部采用 `DialogFragment` 进行了封装，并且放到了一个包下进行管理。

`DialogFragment` 的用法非常简单，而且内部封装好了`show()` 方法，很容易就可以把对话框展现出来，就像这样

``` java
public void showNoticeDialog() {
        // Create an instance of the dialog fragment and show it
        DialogFragment dialog = new NoticeDialogFragment();
        dialog.show(getSupportFragmentManager(), "NoticeDialogFragment");
    }
```

然而上线后不到一周时间，我在后台看到了很多用户遇到了这样的奔溃：

```
java.lang.IllegalStateException: Can not perform this action after onSaveInstanceState
	at android.support.v4.app.z.v(SourceFile:1440)
	at android.support.v4.app.z.a(SourceFile:1458)
	at android.support.v4.app.k.a(SourceFile:634)
	at android.support.v4.app.k.b(SourceFile:613)
	at android.support.v4.app.q.show(SourceFile:139)
	at com.meizu.flyme.wallet.fragment.p.c(SourceFile:195)
	at com.meizu.flyme.wallet.fragment.p.c(SourceFile:390)
	at com.meizu.flyme.wallet.fragment.p.b(SourceFile:61)
	at com.meizu.flyme.wallet.fragment.p$6.a(SourceFile:469)
	at com.meizu.flyme.wallet.fragment.p$6.onResponse(SourceFile:464)
	at com.android.volley.toolbox.u.deliverResponse(SourceFile:60)
	at com.android.volley.toolbox.u.deliverResponse(SourceFile:30)
	at com.android.volley.g.run(SourceFile:99)
	at android.os.Handler.handleCallback(Handler.java:815)
	at android.os.Handler.dispatchMessage(Handler.java:104)
	at android.os.Looper.loop(Looper.java:194)
	at android.app.ActivityThread.main(ActivityThread.java:5824)
	at java.lang.reflect.Method.invoke(Native Method)
	at java.lang.reflect.Method.invoke(Method.java:372)
	at com.android.internal.os.ZygoteInit$MethodAndArgsCaller.run(ZygoteInit.java:1010)
	at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:805)
```

这个错误堆栈正是在调用了 `DialogFragment` 的 `show()`方法之后才出现的，真的是非常奇怪。一开始，我们以为是简单的 fragment 生命周期问题导致的 crash，然而等我在 `show()` 方法之前加上了`isAdded()` 判断还是没有用之后，我知道事情可能没那么简单了。

<!-- more -->

分析
===
我开始关注 `DialogFragment` 的源码，当然，先看一下 `show()` 方法究竟做了什么：

``` java
public void show(FragmentManager manager, String tag) {
        this.mDismissed = false;
        this.mShownByMe = true;
        FragmentTransaction ft = manager.beginTransaction();
        ft.add(this, tag);
        ft.commit();
    }
```

分析源码可以看出，其实它的这个方法很简单。首先 `DialogFragment` 内部维护了两个成员变量，字面意思也是一看就知道，不多说。核心的展示方法，其实也是大家写烂了的 fragment 的 transact 方法，做了一个简单的封装而已。然而问题也就出现了这！

可以看到，`DialogFragment` 默认使用了 `ft` 的 `commit()`方法，而解过 fragemnt 相关 bug 的同学都会有印象，`ft` 除了有 `commit()` 方法之外，还有一个很重要的 `commitAllowingStateLoss()` 方法。两者的区别:

https://developer.android.com/reference/android/support/v4/app/FragmentTransaction.html#commit()

https://developer.android.com/reference/android/support/v4/app/FragmentTransaction.html#commitAllowingStateLoss()

其实后面这个方法，Google 官方是不太推荐的，因为一个 fragment 的 transaction 操作必须要在它 attach 的 activity 保存状态之前发起，如果在这之后做 commit，就会抛出上面那个异常，因为如这个 activity 需要从它刚才保存的状态中恢复，这样的 commit 会容易导致一些状态丢失的问题。当然了，这是 Google 认为的大部分情况下也许你会碰到的问题，如果对你而言这样的问题 okay 可接受，那么大可以使用 `commitAllowingStateLoss()` 来提交 fragment transaction。

值得一提的是，在看完 support 包里 `DialogFragment` 的源码之后，我还跑去 Android 源码里去看了一下：

[围观地址](https://android.googlesource.com/platform/frameworks/base/+/marshmallow-release/core/java/android/app/DialogFragment.java)

然后我很惊讶地看到了这段：

``` java
/** {@hide} */
    public void showAllowingStateLoss(FragmentManager manager, String tag) {
        mDismissed = false;
        mShownByMe = true;
        FragmentTransaction ft = manager.beginTransaction();
        ft.add(this, tag);
        ft.commitAllowingStateLoss();
    }
```

所以说白了，其实 Google 在源码里也是考虑到了这种情况，也做了对 `commitAllowingStateLoss()` 的封装，不过出于对某些不确定性的考虑，暂时这个 api 被打上了 `@hide` 标签，所以面向开发者提供的 support 包里，现在还找不到这个方法。

解决
===
_方案一_

在知道了原因之后，我们可以不用 `DialogFragment` 的 `show()` 方法，直接用类似操作 fragment 的代码来实现对话框的展示：

``` java
FragmentTransaction ft = manager.beginTransaction();
        ft.add(df, tag);
        ft.commitAllowingStateLoss();
```

不过看了源码的同学估计也想到了，这种“强势插入”的方法有可能会破坏 `DialogFragment` 对象的一些属性。因为上面你也看到了，`DialogFragment` 内部是维护着一些成员变量的，如果在对话框展示之后，不去给那些成员变量设值，肯定多多少少会带来一些麻烦。

_方案二_

作为对方案一遗留问题的补充，我们完全可以通过反射的方式，把源码里的 `showAllowingStateLoss()` 方法拿过来用。这里我已经给大家封装好了：

<script src="https://gist.github.com/shawnlinboy/9f4733a9d57450479d6f27bd7c8652c3.js"></script>

这样一来，所有的 `Dialog` 都可以继承这个 `DialogFragmentExt`，从而轻轻松松调用`showAllowingStateLoss()` 方法来避免开头所说的问题了。


