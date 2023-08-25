---
layout: post
title: "Best Practise for Updating UI on AsyncTask"
date: 2016-01-12 01:37:10 +0800
comments: true
categories: Android
---
好久不更新博客，上来讲一下最近踩道的一个坑，顺便感觉可以普及一下在 AsyncTask 更新 UI 时的正确姿势

最近我负责的一个模块，后台数据统计总在报 [Glide](https://github.com/bumptech/glide) 加载图片的时候报错导致停止运行，堆栈大概是这个样子的：

```
java.lang.RuntimeException: Unable to destroy activity {MY PACKAGE NAME}: java.lang.IllegalStateException: Activity has been destroyed
    at android.app.ActivityThread.performDestroyActivity(ActivityThread.java:4097)
    at android.app.ActivityThread.handleDestroyActivity(ActivityThread.java:4115)
    at android.app.ActivityThread.access$1400(ActivityThread.java:177)
    at android.app.ActivityThread$H.handleMessage(ActivityThread.java:1620)
    at android.os.Handler.dispatchMessage(Handler.java:111)
    at android.os.Looper.loop(Looper.java:194)
    at android.app.ActivityThread.main(ActivityThread.java:5771)
    at java.lang.reflect.Method.invoke(Native Method)
    at java.lang.reflect.Method.invoke(Method.java:372)
    at com.android.internal.os.ZygoteInit$MethodAndArgsCaller.run(ZygoteInit.java:1004)
    at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:799)
Caused by: java.lang.IllegalStateException: Activity has been destroyed
    at android.app.FragmentManagerImpl.enqueueAction(FragmentManager.java:1383)
    at android.app.BackStackRecord.commitInternal(BackStackRecord.java:745)
    at android.app.BackStackRecord.commitAllowingStateLoss(BackStackRecord.java:725)
    at com.bumptech.glide.manager.RequestManagerRetriever.getRequestManagerFragment(SourceFile:159)
    at com.bumptech.glide.manager.RequestManagerFragment.onAttach(SourceFile:117)
    at android.app.FragmentManagerImpl.moveToState(FragmentManager.java:865)
    at android.app.FragmentManagerImpl.moveToState(FragmentManager.java:1079)
    at android.app.BackStackRecord.run(BackStackRecord.java:852)
    at android.app.FragmentManagerImpl.execPendingActions(FragmentManager.java:1485)
    at android.app.FragmentManagerImpl.dispatchDestroy(FragmentManager.java:1929)
    at android.app.Fragment.performDestroy(Fragment.java:2279)
    at android.app.FragmentManagerImpl.moveToState(FragmentManager.java:1029)
    at android.app.FragmentManagerImpl.moveToState(FragmentManager.java:1079)
    at android.app.FragmentManagerImpl.moveToState(FragmentManager.java:1061)
    at android.app.FragmentManagerImpl.dispatchDestroy(FragmentManager.java:1930)
    at android.app.Activity.performDestroy(Activity.java:6297)
    at android.app.Instrumentation.callActivityOnDestroy(Instrumentation.java:1151)
    at android.app.ActivityThread.performDestroyActivity(ActivityThread.java:4084)
```
于是呢，本着对开源事业的满腔热血，我二话没说便到 [Glide](https://github.com/bumptech/glide) 下面给丫开了 [issue](https://github.com/bumptech/glide/issues/850)。当然了，在此还是要赞扬一下 [@TWiStErRob](https://github.com/TWiStErRob)， 这位兄台看起来不像是 [Glide](https://github.com/bumptech/glide) 的官方作者，但一直很热心地回答着各路神仙给 [Glide](https://github.com/bumptech/glide) 开的 issue。于是毫无例外我的也很快得到了回复。但答案似乎并没有太多卵用，无非就是让我提供更多细节给他们排查……算了，求人不如求自己，给他们提供细节之前，不如我自己查一遍吧。

晚上花了一点点时间理了一下整个流程：首先，既然是 `android.app.FragmentManagerImpl.enqueueAction` 报的 `Activity has been destroyed`，肯定要想到是哪个 Activity 和它 attach 的 Activity，因为这个模块从头到尾都是我一个人在弄，所以这并不是很难。我追到了我在一个 Fragment 里，假设叫它 `MyMainFragment`，在这里里面我调用 Glide 加载了一些图片到 RecyclerView 中，这些看起来都没什么问题。但为什么会报 `Activity has been destroyed` ？我想到了去它 attach 的 Activity 去看 MyFragment 当时是怎么被 commit 进来的。

在 `MyMainFragment` attach 的 Activity 中，我看到了如下代码：

``` java
private class FireUpTask extends AsyncTask<Void, Void,Void> {

        @Override
        protected Void doInBackground(Void... params) {
            handleIntent();
            return null;
        }

        @Override
        protected void onPostExecute(Void aVoid) {
            super.onPostExecute(aVoid);
            initFragment();
        }
    }

    private void initFragment() {
        if (!isDestroyed()) {
            FragmentTransaction fragmentTransaction = getFragmentManager().beginTransaction();
            fragmentTransaction.add(R.id.main_container, MyMainFragment.newInstance());
            fragmentTransaction.commitAllowingStateLoss();
        }
    }
```

这个 `FireUpTask` 在 Activity 的 onCreate() 方法中被创建并执行，其实要做的很简单，无非就是想在后台异步把跳转进来的 Intent 处理完，然后再切到 `MyMainFragment`，看起来是没什么问题，而且为了防止有时候操作很快或者 Monkey 测试的时候如果切到 `MyMainFragment` 时 Activity 已经被销毁，我还特地加多了 `if (!isDestroyed())` 判断，可为什么还是出问题？

先看一下 [isDestroyed()](http://developer.android.com/intl/zh-cn/reference/android/app/Activity.html#isDestroyed()) 方法：

> Returns true if the final onDestroy() call has been made on the Activity, so this instance is now dead.

看来，SDK 告诉我们，如果这个方法返回 true ，那证明 Activity 的最后 onDestroy() 已经被调用，Activity 实例现在已经挂掉了。对啊！！！确实是这样啊，我都加了这个判断了啊，可为什么还是报错？

别着急，就在 [isDestroyed()](http://developer.android.com/intl/zh-cn/reference/android/app/Activity.html#isDestroyed()) 下面，还有一个方法，[isFinishing()](http://developer.android.com/intl/zh-cn/reference/android/app/Activity.html#isFinishing())，于是赶紧看了一下文档：

> Check to see whether this activity is in the process of finishing, either because you called finish() on it or someone else has requested that it finished. This is often used in onPause() to determine whether the activity is simply pausing or completely finishing.

这下子一目了然了吧，如果你的 Activity 正在结束，或者因为你主动调了 `finish()` (我在这个 Activity 里确实有一处会主动调 `finish()`，又或者因为其它别的什么鬼导致了 Activity 被请求销毁，这个时候可能 [isDestroyed()](http://developer.android.com/intl/zh-cn/reference/android/app/Activity.html#isDestroyed()) 可能还没有来得及返回 true，但是 [isFinishing()](http://developer.android.com/intl/zh-cn/reference/android/app/Activity.html#isFinishing()) 就会返回 true 告诉你 Activity 确实正在被停止。

为了证实这一点，我尝试搜索了 Android 源码对这两个方法的使用。发现 Google 官方在拨号应用里就尝试做出了这样的判断：

http://androidxref.com/6.0.0_r1/xref/packages/apps/Dialer/src/com/android/dialer/calllog/ClearCallLogDialog.java#74

在“电话”应用的清除通话记录对话框中，Google 也是简单粗暴地 new 了一个 AsyncTask 来在后台清掉通话记录，然后在 ` onPostExecute(Void result)` 中去更新 UI。亮点在于，大家可以看 Google 的工程师写了什么：

``` java
final Activity activity = progressDialog.getOwnerActivity();
if (activity == null || activity.isDestroyed() || activity.isFinishing()) {
	return;
}
if (progressDialog != null && progressDialog.isShowing()) {
	progressDialog.dismiss();
}
```

它拿了这个 dialogFragment 的宿主 Activity，然后对当前 Activity 的“死活”做出了判断，在 `activity == null || activity.isDestroyed() || activity.isFinishing()` 这三个都不会发生的时候，才会继续后面的操作。

这是至关重要的！虽然我们都知道，Dialog 这种东西是必须 attach 在一个带合法 Window Token 的组件，比如 Activity 或者 Frgament 上，理论上只要 Dialog 显示着，这个组件都不会被销毁。但是，我们却无法考虑到一些极端情况，比如有的用户手速确实很快，或者有些机器性能确实比较好反应很快，或者，你的应用在跑 Monkey 测试的时候，更加有可能出现这种 Activity 提前挂掉的情况。这个时候，如果应用内部不 handle 这个问题，那么呵呵呵，停止运行就来了。

回到我自己的这个问题，既然可以从源码里读到 Google 给出的答案，下面就是修自己的锅了，很简单，我们也可以仿照加上类似的处理：

``` java
private class FireUpTask extends AsyncTask<Void, Void,Void> {

        @Override
        protected Void doInBackground(Void... params) {
            handleIntent();
            return null;
        }

        @Override
        protected void onPostExecute(Void aVoid) {
            super.onPostExecute(aVoid);
            if (isDestroyed() || isFinishing()) {
                return;
            }
            initFragment();
        }
    }

    private void initFragment() {
            FragmentTransaction fragmentTransaction = getFragmentManager().beginTransaction();
            fragmentTransaction.add(R.id.main_container, MyMainFragment.newInstance());
            fragmentTransaction.commitAllowingStateLoss();
    }
```

这样一来，如果 AsyncTask 跑完，准备去切 Fragment 的时候，Activity 已经挂了，这个时候就不会再进到 transaction 里面，自然 Fragment 也不会被 attach 进来，自然 Glide 去加载图片那些问题就都不会有了。

看来平时还是要多看看 Android 源码，感觉很多坑 Google 的工程师也知道并且有填坑攻略，但还是要自己去发现的。

