---
layout: post
title: "Java: Everything About Interface Callback"
date: 2014-04-06 02:47:43 +0800
tags: java
categories: Java
---
Instruction
===
今天晚上在复习 Java 时对`接口回调`这一部分看得晕乎乎的，看了好几篇博客，写了几个例子之后，我想把自己的理解提炼出来。

Def
===
回调方法：必须由程序员来实现，但不能由程序员来直接调用，而是必须由其他方法在满足调用条件时去调用的。

Example
===
概念总喜欢把通俗易懂的东西变得让人摸不着头脑。通俗一点的理解，Java 里的接口回调，就是`A类调用B类里的方法C（方法C里需要一个回调接口对象作为参数），然后B类再反过来调用A类里的方法D`，此时这个D就叫”回调方法“。注意，这个”方法D“实际上不是什么新方法，而是因为A类实现了回调接口和里面的方法，所以此时B类调用时实际上是通过刚才上面说的“回调接口对象作为参数”来调用的，其传递的值在实现类A类中可以直接取出使用。

至于概念里“必须由其他方法在满足调用条件时去调用”，我把它理解成“不直接返回结果，而是把结果作为参数传给回调接口的方法”，这样“A类”就可以拿着这个结果再进行处理。

<!--more -->

DEMO
===
网上有一个很经典的打电话的例子——小王现在要打电话问小李一个问题，但是小李也得想一下啊，于是让小李在想出来的时候再打电话给小王。注意！这个“再打电话给小王”的过程其实就是“接口回调”。为了让小王能拿到小李的结果再处理，我们需要把小李“打电话给小王”这个过程用接口来做。

`SolveCallBack.java`
``` java
/**
 * 解决问题时，回调这个方法
 * @author linshen
 *
 */
public interface SolveCallBack {

	public void solve(String result);

}
```

` XiaoWang.java `（A类）
``` java
**
 * 小王打算问小李一个问题
 * @author linshen
 * 
 */
public class XiaoWang implements SolveCallBack {
	public void askQuestion(String question) {
		new XiaoLi().answer("我是小王，这里是我的问题", this);
	}

    	@Override
	public void solve(String result) {   //result可直接取出使用
		System.out.println("result--->" + result);
	}
}
```

` XiaoLi.java `（B类）
``` java
**
 * 小李是准备回答问题的那个人
 * 
 * @author linshen
 * 
 */
public class XiaoLi {

	/**
	 * 回答（C方法）
	 * 
	 * @param question
	 *            小王的问题
	 * @param callback
	 *            回答问题要调用的接口
	 */
	public void answer(String question, SolveCallBack callback) {
		System.out.println("小王的问题是：" + question);
		for (int i = 0; i < 10; i++) {
			System.out.println("小李思考中。。。");
		}
		System.out.println("想出来了");
		callback.solve("小李的结果");//（D方法）
	}
}
```

上面这个例子非常通俗易懂，大家跑一下就能明白整个流程。

Android Usage
===
实际上，如果你够敏感的话，到这里就会突然发现，这种“接口回调”模式在 Android 里应用非常广泛。最基本的“按钮响应事件”就是基于这种模式。还有 Fragment 向 Activity 传值的时候也应用了这种模式，可以参见[《Creating event callbacks to the activity》](http://developer.android.com/guide/components/fragments.html#EventCallbacks)

很多东西可能一开始仅仅“知其然”，一旦到了一定程度回头看时，往往才会“知其所以然”，并且能切实感受到这其中设计模式的伟大！