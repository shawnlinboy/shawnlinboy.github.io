---
layout: post
title: "Sign Apk With system certification"
date: 2014-07-24 01:17:21 +0800
comments: true
categories: Android
---
如果你的 App 因为权限原因需要设置 `android:sharedUserId="android.uid.system"` 那么 IDE 编译出的包通常是无法直接安装的，查看控制台会发现报 `INSTALL_FAILED_SHARED_USER_INCOMPATIBLE` 错误。这是必须的，随随便便一个 App 声明一下就可以和系统用户共享 ID ，岂不乱套了？

解决方法有如下两种：

__第一种__

如果你 repo sync 了 android 的整个源码，那么可以直接把你的 app 放到 `/packages/apps` 下面去 `mm` ，不过要记得在 Android.mk 中增加 LOCAL_CERTIFICATE 属性，这个属性具体有三个值：

系统中所有使用 android.uid.system 作为共享 UID 的 APK ，都会首先在 manifest 节点中增加android:sharedUserId="android.uid.system"，然后在 Android.mk 中增加 LOCAL_CERTIFICATE := platform。可以参见 Settings 等

系统中所有使用android.uid.shared作为共享 UID 的 APK，都会在 manifest 节点中增加android:sharedUserId="android.uid.shared"，然后在 Android.mk 中增加 LOCAL_CERTIFICATE := shared。可以参见 Launcher 等

系统中所有使用 android.media 作为共享 UID 的 APK，都会在 manifest 节点中增加android:sharedUserId="android.media"，然后在 Android.mk 中增加 LOCAL_CERTIFICATE := media。可以参见 Gallery 等。

__第二种__

当然，毕竟不是每个人都有机会，或者有必要下载整个源码的。 简单地，当你用 IDE 编出 apk 之后，可以去 `/build/tools/signapk/` 找到 `signapk.jar` 文件；再去 `/build/target/product/security/` 里找到 `platform.pk8` 、 `platform.x509.pem` 这两个文件。把它们连同你的 apk 扔进一个文件夹，然后 cd 到该文件夹下执行 `java -jar signapk.jar platform.x509.pem platform.pk8 Origin.apk Signed.apk`，得到的 `Signed.apk` 就可以直接 `adb install`了。