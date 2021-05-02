---
layout: post
title: "Proguard With Gradle"
date: 2015-07-12 02:20:15 +0800
comments: true
categories: Android
---

##Why Proguard
Proguard 是什么？要清楚这个概念，我们先看看 Proguard 官方是怎么定义的，再看看 Android 官方是怎么定义

_Proguard 官方_

> ProGuard is a free Java class file shrinker, optimizer, obfuscator, and preverifier. It detects and removes unused classes, fields, methods, and attributes. It optimizes bytecode and removes unused instructions. It renames the remaining classes, fields, and methods using short meaningless names. Finally, it preverifies the processed code for Java 6 or higher, or for Java Micro Edition.
> 
ProGuard 是一个免费的压缩、优化、混淆，预验证 Java 类的工具。它能在编译期间检测并移除没有用到的类、变量、方法和属性，也能优化字节码并且移除没有用到的指令。ProGuard会把那些类、变量、和方法用一些短小且无意义的名称去重命名。最后，对于 Java 6 或者更高的版本，或者 Java Micro Edition，它还会预校验已处理的类代码，从而利于更快加载。

_看起来有点意思，再来看一下 Android 官方的定义_

> The ProGuard tool shrinks, optimizes, and obfuscates your code by removing unused code and renaming classes, fields, and methods with semantically obscure names. The result is a smaller sized .apk file that is more difficult to reverse engineer. Because ProGuard makes your application harder to reverse engineer, it is important that you use it when your application utilizes features that are sensitive to security like when you are Licensing Your Applications.
> 
ProGuard 通过移除未使用的代码和使用一些语意模糊的名字来重命名类、变量、方法和属性名，从而达到压缩、优化，和混淆代码的目的。最终可以得到一个更小的 .apk 文件，这个文件会增大软件逆向工程（反编译）的难度。正因为 ProGuard 会让你的应用更加难以被逆向工程反编译，所以对于独立应用而言，如果你对你的代码安全很敏感，建议在签名阶段还是“ ProGuard 一下” 。

<!-- more -->

## How to Proguard
因为大部分应用开发已经完全切换到了 Android Studio 下面，所以这里仅讲解一个标准的 Android Studio 工程如何启用 Proguard。

在我们新建完一个 Android 项目之后，`build.gradle` 文件中的 `minifyEnabled` 属性就用来决定我们在 debug 和 release 版本中是否启用 Proguard。举个栗子：

``` 
buildTypes {
        release {
            minifyEnabled true
            shrinkResources false
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
        debug {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
            signingConfig signingConfigs.debug
        }
    }
```

在上面的例子里面，我们就在 `release` 版本里面启用了 Proguard。`getDefaultProguardFile('proguard-android.txt')` 方法会从 Android SDK 的 `tools/proguard/` 文件夹读取默认的 Proguard 设置。前面说过，Proguard 还可以从字节码的级别优化你的代码，这部分规则可以在还是这个目录下面的 `proguard-android-optimize.txt` 找到和定义。除此之外，Andriod Studio 会在我们自己模块的根目录下面创建一个 `proguard-rules.pro` 文件，我们可以在里面针对特定的模块创建特定的混淆规则。这部分我后面会讲到。

一切搞定之后，我们进到自己的模块根目录下，执行 ./gradlew assemblePrdRelease ，编译出来的包就会经过 Proguard 的混淆，可见，启用它非常简单。

但等等！！！要知道，我们的工程师在开发应用的时候，大部分应该都会选择编译 `debug` 的 buildType 作为开发阶段的版本，这本没有问题，但如果你要开启 Proguard，请务必在开发阶段将 `debug` buildType 的 `minifyEnabled` 属性也置为 true，编译通过并测试运行 OK 之后，才能确保你的 `release` 版本混淆之后也是没有问题的。因为经过 Proguard 混淆后的代码，有的编译阶段会报错，有的编译生成 apk 没有问题，但是运行的时候会有问题。__所以请所有开启 Proguard 的应用最好都编包让测试进行基本功能验证，确认无误后再完全开启。千万不要 `debug` 版本不开 Proguard 验证，光在 `release`里打开，有可能你的包编译没有问题，但打开就报错。而这一切因为你一直都用着不开 Proguard 的 `debug` 版本，所以是无法感知的。__

## Let's Proguard
刚才上面讲到了，除了 `tools/proguard/proguard-android.txt` 定义的一部分规则，android studio 为我们在模块根目录额外创建了一个 `proguard-rules.pro` 供我们声明更多的规则。这其实是很有必要的。有一些情景对于 Proguard 而言会很难正确分析出哪些代码是你用到的，哪些代码是可以移除的，这些情景包括但不限于：

* 只在 `AndroidManifest.xml` 里被引用的类。
* JNI 调用的方法
* 动态引用的字段和方法
* 一些抽象类和抽象方法，泛型相关的
* 一些开源库，它们本身就是开源的，混淆它们会显得毫无意义
* Google 自己的 Support 库，混淆它们意义也不大。（唯一的意义应该就是可以使包小一点）

一旦出现上面这些问题，Proguard 一般都会在编译时告诉你报错。这个时候只要打开 `proguard-rules.pro` 文件，加一行 `-keep` 声明，keep 掉某个类，几乎都可以解决问题。例如，我们的数据统计 SDK 当中有一个类不需要我们混淆它，这个时候只要写一行：

```
-keep class com.meizu.stats.MobEventAgent{*;}
```

就可以了。

任何一门游戏都有它自己的规则，下面花一点点时间简单介绍一下 Proguard 世界的游戏规则。

### 常用选项
| Options             	| Intro                                                                                  	|
|---------------------	|----------------------------------------------------------------------------------------	|
| -verbose            	| 传说中的“啰嗦模式”，让 Proguard 在处理过程中告诉你更多信息                             	|
| -dontnote           	| 不要在意这些细节，我的配置里有一些遗漏和潜在风险，就不要告诉我了                       	|
| -dontwarn           	| 认真你就输了，就算我有一些未解决的引用或者其它重要问题，也不要来烦我                   	|
| -ignorewarnings     	| 忽略警告，都懂的。听说有两个人走到悬崖边，看见 Warninig 指示牌，结果有一个人还是跳下去了，这个人是程序员 	|
| -printconfiguration 	| 打印已经被解析的全部配置                                                               	|
| -dump [filename]    	| 可以向指定路径输出一份类结构文件                                                       	|

### Keep 选项

| Options                                                     	| Intro                                                                                  	|
|-------------------------------------------------------------	|----------------------------------------------------------------------------------------	|
| -keep [,modifier,...] class_specification                   	| 保护指定的类文件和类的成员                                                             	|
| -keepclassmembers [,modifier,...]class_specification        	| 保护指定类的成员，比如有时候你可能想保护一个实现了 `Serializable` 接口类的所有属性和方法 	|
| -keepclasseswithmembers [,modifier,...] class_specification 	| 保护指定的类和类的成员，但条件是所有指定的类和类成员是要存在。                         	|
| -keepnames class_specification                              	| 保护指定的类和类的成员的名称（如果他们不会压缩步骤中删除）                             	|
| -keepclassmembernames class_specification                   	| 保护指定的类的成员的名称（如果他们不会压缩步骤中删除）                                 	|
| -keepclasseswithmembernames class_specification             	| 保护指定的类和类的成员的名称，如果所有指定的类成员出席（在压缩步骤之后）               	|
| -printseeds [filename]                                      	| 列出类和类的成员-keep选项的清单，标准输出到给定的文件                                  	|


###Optimization 选项
| Options                               	| Intro                                                              	|
|---------------------------------------	|--------------------------------------------------------------------	|
| -dontshrink                           	| 声明不要压缩输入的文件                                             	|
| -printusage                           	| 打印输入的类文件的调用列表，防止一些根本跑不进去的代码             	|
| -whyareyoukeeping class_specification 	| 让 Proguard 告诉你它在压缩的过程中为什么 keep 了这个类而不去压缩它 	|

### Obfuscation 选项
| Options                                   	| Intro                                                                    	|
|-------------------------------------------	|--------------------------------------------------------------------------	|
| -dontobfuscate                            	| 声明不要混淆输入的某个类文件                                             	|
| -printmapping [filename]                  	| 让 Proguard 打印混淆时旧名称跟新名称之间的映射文件                       	|
| -applymapping {filename},重用映射增加混淆 	| 声明重用之前的映射增加混淆                                               	|
| -obfuscationdictionary filename           	| 声明一个文件作为字典，让 Proguard 使用其中的名称作为混淆方法和变量的名称 	|
| -classobfuscationdictionary filename      	| 声明一个文件作为字典，让 Proguard 使用其中的名称作为类的名称             	|
| -packageobfuscationdictionary filename    	| 声明一个文件作为字典，让 Proguard 使用其中的名称作为包的名称             	|
| -useuniqueclassmembernames                	| 声明给有相同名称的类成员，在混淆时使用相同的名称。默认使用 a,b,c这样的。 	|
| -dontusemixedcaseclassnames               	| 声明混淆时不要产生大小写混合的，多种多样的类名                           	|
| -overloadaggressively                     	| 声明混淆的时候应用侵入式重载                                             	|
| -keeppackagenames [package_filter]        	| 声明不要混淆指定的包名                                                   	|
| -keepattributes [attribute_filter]        	|                                                                          	|

### Preverification 选项

| Options        	| Intro                                                	|
|----------------	|------------------------------------------------------	|
| -dontpreverify 	| 声明不要预校验输入的类文件                           	|
| -microedition  	| 声明要处理的 Java 类文件是 Java Micro Edition 版本的 	|

## After Proguard
在我们应用 Proguard 之后，gradle 在编译你的模块的时候会在 `build/outs/` 下面生成一个 `mapping.txt` 文件。这个文件在你的应用被混淆之后__非常重要__。因为一旦你的应用出错，打印了堆栈信息，没有它，你看到的类永远只有 abcd 这样。。。。而有了 `mapping.txt` 文件，就可以通过 `retrace.sh` 把堆栈文件转化成可读的。 `retrace.sh`位于 `<sdk_root>/tools/proguard/` 下面，执行它的规则是：

```
retrace.bat|retrace.sh [-verbose] mapping.txt [<stacktrace_file>]
```

比如：

```
retrace.sh -verbose mapping.txt obfuscated_trace.txt
```
当然，为了避免每次都进到 SDK 下面，我们可以给 `retrace.sh` 建一个连接。

```
sudo ln -sf /Users/linshen/Library/Android/sdk/tools/proguard/bin/retrace.sh /usr/local/bin/
```

这样子，生成的 `obfuscated_trace.txt` 就是一个可以被看懂的 log 文件了。

`mapping.txt` 文件是非常重要的，大家最好让它跟着版本走。因为 Proguard 每执行一次，`mapping.txt` 文件都会被重新覆盖。假如有一天，你编了一个 `release` 的包并且发出去了，此时它会生成一个 `mapping.txt` 文件，然后你继续写功能，继续编包，这个时候你的`mapping.txt` 文件其实已经被覆盖了。假如这时候你外面的版本出了问题，测试给你一段 log，这个时候因为你后来动过。你的`mapping.txt` 文件已经无法正确将 log 恢复成可读的了。

关于这个问题，SCM 的同事以后会在我们每次出发 `MEIZU_APPS_BUILD` 任务之后把对应的`mapping.txt` 文件保存下来，我们注意区分一下版本，知道哪个`mapping.txt` 对应哪个，这样就不用担心还原不了 log 文件了。

## Android Common Config

下面这些属性几乎是作为一个 Android 应用开启混淆时的“公共”部分，大家可以根据自己的需要添加到自己模块的混淆规则中去：

```

	# 保留资源文件属性和行号
	-renamesourcefileattribute SourceFile
	-keepattributes SourceFile,LineNumberTable

	# RemoteViews 有时候会需要用到注解.
	-keepattributes *Annotation*

	# 保留所有重要组件
	-keep public class * extends android.app.Activity
	-keep public class * extends android.app.Application
	-keep public class * extends android.app.Service
	-keep public class * extends android.content.BroadcastReceiver
	-keep public class * extends android.content.ContentProvider


	# 保留所有 View 的实现，和它们包含 Context 参数的构造方法，还有 set 方法
	-keep public class * extends android.view.View {
	    public <init>(android.content.Context);
	    public <init>(android.content.Context, android.util.AttributeSet);
	    public <init>(android.content.Context, android.util.AttributeSet, int);
	    public void set*(...);
	}

	# 保留所有含有特殊 Context 参数构造方法的类
	-keepclasseswithmembers class * {
	    public <init>(android.content.Context, android.util.AttributeSet);
	}
	-keepclasseswithmembers class * {
   		 public <init>(android.content.Context, android.util.AttributeSet, int);
	}
	
	## 保留所有 Parcelable 实现类的特殊属性.
	-keepclassmembers class * implements android.os.Parcelable {
    	 static android.os.Parcelable$Creator CREATOR;
	}
	
	## 有些 Android support 包里面的 api 不是在所有平台都存在的，但是我们自己用的时候有数就行
	-dontwarn android.support.**

	## 用到枚举的地方
	-keepclassmembers class * extends java.lang.Enum {
    	 public static **[] values();
   		 public static ** valueOf(java.lang.String);
	}
	
	## 用到序列化的实体类
	-keepclassmembers class * implements java.io.Serializable {
    	 static final long serialVersionUID;
   	 	 static final java.io.ObjectStreamField[] serialPersistentFields;
    	 private void writeObject(java.io.ObjectOutputStream);
    	 private void readObject(java.io.ObjectInputStream);
    	 java.lang.Object writeReplace();
    	 java.lang.Object readResolve();
	}
```

## 干货来袭！！！

```
	# for meizu UsageStatus analystics	-keep class com.meizu.experiencedatasync.util.Utils {*;}	-keep class com.meizu.stats.UsageStatusLog {*;}	-dontwarn com.meizu.experiencedatasync.util.Utils	-dontwarn com.meizu.stats.UsageStatusLog

	# for google protobuf	-keep public class * extends com.google.protobuf.GeneratedMessage { *; }	-keep class com.google.protobuf.** { *; }	-keep public class * extends com.google.protobuf.** { *; }

	#for LeakCanary
	-keep class org.eclipse.mat.** { *; }
	-keep class com.squareup.leakcanary.** { *; }
	
	#for android support v7
	-keep public class android.support.v7.widget.** { *; }
	-keep public class android.support.v7.internal.widget.** { *; }
	-keep public class android.support.v7.internal.view.menu.** { *; }

	-keep public class * extends android.support.v4.view.ActionProvider {
   	 	public <init>(android.content.Context);
	}
	
	# for picasso / retrofit / rxjava    -dontwarn com.squareup.picasso.Transformation	-dontwarn com.squareup.okhttp.**	-dontwarn okio.**	-dontwarn rx.**	-dontwarn retrofit.appengine.UrlFetchClient
	keepattributes Annotation	-keep class retrofit.** { *; }   -keepclasseswithmembers class * {		@retrofit.http.* <methods>;	}	-keepattributes Signature
	
	## ActionBarSherlock 4.4.0 specific rules ##

	-keep class android.support.v4.app.** { *; }
	-keep interface android.support.v4.app.** { *; }
	-keep class com.actionbarsherlock.** { *; }
	-keep interface com.actionbarsherlock.** { *; }
	-keepattributes *Annotation*

	## hack for Actionbarsherlock 4.4.0, see https://github.com/JakeWharton/	ActionBarSherlock/issues/1001 ##
	-dontwarn com.actionbarsherlock.internal.**
	
	## AndroidAnnotations specific rules ##
	# Only required if not using the Spring RestTemplate
	-dontwarn org.androidannotations.api.rest.**
	
	#butterknife
	-keep class butterknife.** { *; }
	-dontwarn butterknife.internal.**
	-keep class **$$ViewInjector { *; }
	-keepclasseswithmembernames class * {
    	@butterknife.* <fields>;
	}
	-keepclasseswithmembernames class * {
    	@butterknife.* <methods>;
	}
	
	# Glide specific rules #
	# https://github.com/bumptech/glide
	-keep public class * implements com.bumptech.glide.module.GlideModule
	-keep public enum com.bumptech.glide.load.resource.bitmap.ImageHeaderParser$** {
    **[] $VALUES;
    public *;
}

	## GSON 2.2.4 specific rules ##

	# Gson uses generic type information stored in a class file when working with fields. Proguard
	# removes such information by default, so configure it to keep all of it.
	-keepattributes Signature

	# For using GSON @Expose annotation
	-keepattributes *Annotation*

	-keepattributes EnclosingMethod

	# Gson specific classes
	-keep class sun.misc.Unsafe { *; }
	-keep class com.google.gson.stream.** { *; }
	
	# OkHttp
	-keepattributes Signature
	-keepattributes *Annotation*
	-keep class com.squareup.okhttp.** { *; }
	-keep interface com.squareup.okhttp.** { *; }
	-dontwarn com.squareup.okhttp.**
	
	## Square Picasso specific rules ##
	## https://square.github.io/picasso/ ##
	-dontwarn com.squareup.okhttp.**
	
```
当然，github 上有位好人一生平安的家伙整理了[更多](https://github.com/krschultz/android-proguard-snippets/tree/master/libraries)。

## Finally

以上便是关于 Proguard 的一个简单介绍。其实说白了，我们要做的无非就这几件事：

* 启用 Proguard
* 确保启用后可以编过，如果编不过，看看哪个类有问题，或者是类里面的属性还是方法有问题，再考虑是 keep 还是 downwarn 掉
* 确保编过的 apk 是安装 + 运行正常的
* 保存本次编译的 `mapping.txt` 文件，等待用户反馈问题时用于把 log 文件转回来。

欢迎大家对本文的内容提出指正，也可以把你项目的 `proguard-rules.pro` 贴出来造福一下大家。