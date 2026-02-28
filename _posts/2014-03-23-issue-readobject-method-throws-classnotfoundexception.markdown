---
layout: post
title: "Android Issue: readObject method throws ClassNotFoundException"
date: 2014-03-23 01:12:49 +0800
comments: true
tags: AIDL Java
categories: Android
---
今天在项目中遇到一个问题，解决后发现也加深了我对 AIDL 的理解，果然知识到了一定水平之后确实是融会贯通的！

先看服务端的代码：
``` java
ObjectOutputStream oos = new ObjectOutputStream(socket.getOutputStream());
User user = new User();
user.setName("linshen");
oos.writeObject(user);
```
客户端：
```java
ObjectInputStream input = new ObjectInputStream(socket.getInputStream());
User user = (User) input.readObject();
Log.i(TAG, "user.name" + user.getName());
```
这两段看似太平常不过的代码，在 Android 端却抛出了 ClassNotFoundException 异常，提示 User 类找不到。后来 Google 之后看到这样一句话：

> When you use some class in two different JVMs, and you are marshalling/unmarshalling the class then the class should be exported to a common library and shared between both server and client. Having different class wont work any time.

瞬间恍然大悟！原来在服务器端，我将 User 类放在了 `me.mobilelin.lbserver.model` 包中，而在 Android 端，User 类在 `me.mobilelin.librarymanager.model`，因此 android 提示找不到 User 类。由此想到 Android 在 AIDL 或者 IPC 时，客户端 `*.aidl` 文件所在的包必须和服务器项目中 `*.aidl` 文件所在包名相同，否则两者是无法建立通信的。

知道原因后，将服务端和客户端的 User 类所在包名完全统一了一下，再次运行，问题解决。