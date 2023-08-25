---
layout: post
title: "Android Telephony 模块结构简析"
category: Android
tags: Android AOSP framework Telephony
---

本文永久链接：https://blog.linshen.me/posts/a-simple-analyse-of-android-telephony-related-modules

最近在公司被老大安排负责跟进通讯相关的一些问题，于是简单了解一下 Android 通讯相关的模块。

说实话，刚开始看的时候确实是一头雾水，因为设计的模块实在是太！多！了！要说多都还好，要命的是这些不同的模块还散落在 AOSP 的不同目录，如果不梳理记录一下，跳来跳去怎么都一头雾水，因此就有了这篇文章，我自己也好趁机梳理一下模块之间的联系。

本文基于 Android 12 源码，根据我自己的理解整理而来，如果有错误，欢迎评论区指出，毕竟这块我是新手，感谢。

## 主要结构

Android telephony 是一个典型的分层结构，其涉及的相关模块按照功能，从下到上，可大概分为四类：

### HAL 相关

| 目录 | 产物 | 运行进程 | 主要作用 |
| --- | --- | --- | --- |
| `hardware/ril` | N/A | N/A | N/A |

### Service 相关

| 目录 | 产物 | 运行进程 | 主要作用 |
| ------- | ------- | ------- |------- |
| `packages/service/telecomm` | `Telecom.apk` | `system_service` | 桥梁，连接下层（如 `telephony`）与上层（如 `Dailer`） |
| `packages/service/telephony` | `TeleService.apk` | `com.android.phone` | 负责调用 `frameworks/opt/telephony` 逻辑实现  |
| `frameworks/base/telecomm` | `framework.jar` | `N/A` | 无进程，仅暴露框架，从而对上层提供接口 |
| `frameworks/base/telephony` | `framework.jar` | `N/A` | 无进程，仅暴露框架，从而对上层提供接口 |
| `frameworks/opt/telephony` | `telephony-common.jar` | `system_service` 或 `com.android.phone` | 包含 `RILJ` 代码和其它，被 `frameworks/opt/telephony` 依赖 |


### App 相关

| 目录 | 产物 | 运行进程 | 主要作用 |
| --- | --- | --- | --- |
| `packages/apps/Dialer` | `Dialer.apk` | `com.android.dialer` | 拨号应用，包含拨号盘、通话记录、暗码(`*#*#4636#*#*`这种)、来去电界面（`InCallUI`）、语音信箱等 |

### Provider 相关

| 目录 | 产物 | 运行进程 | 主要作用 |
| ------- | ------- | ------- |------- |
| `packages/providers/ContactsProvider` | `ContactsProvider.apk` | `com.android.providers.contacts` | 对外提供联系人信息相关的增删改查 |
| `packages/providers/TelephonyProvider` | `TelephonyProvider.apk` | `com.android.providers.telephony` | 对外提供通讯功能（比如运营商信息配置信息）相关的增删改查 |

## 结构详解

 ### `RIL`

 先从底层的 RIL 说起。这里说底层其实也是相对而言，因为 RIL 的全称是 Radio Interface Layer，既然是个 Layer，也就意味着一定还有上下层。 比 RIL 更底层的就要到 Linux 内核 和 Modem 了，咱也不懂，咱也不敢说，因此还是只能冒上水面，浅浅地讲一讲 RIL。

RIL 本质上由两部分组成，`RILJ` 和 `RILC`。`RILJ` 负责跟上层（Java）交互，他跟 phone 在同一进程。会将上层的请求通过 `RILJ` 发送给 `RILC`，`RILC` 在 `rild` 进程中，向上负责跟 `RILJ` 进行对接（C++），向下对接 Modem。


`rild` (RIL Daemon)是系统的守护进程，系统一启动就会一直运行。手机开机时，kernel 完成初始化，系统会启动一个初始化进程 Init 用于加载系统基础服务、`Zygote` 进程、`system_server`，还有就是 `rild`：

https://android.googlesource.com/platform/hardware/ril/+/refs/heads/nougat-dev/rild/rild.rc

```
service ril-daemon /system/bin/rild
    class main
    socket rild stream 660 root radio
    socket sap_uim_socket1 stream 660 bluetooth bluetooth
    socket rild-debug stream 660 radio system
    user root
    group radio cache inet misc audio log readproc wakelock
```

到这里，我可以画一幅图，按照从上到下，简单描述一些这几层之间的关系。

![选区_023](https://raw.githubusercontent.com/shawnlinboy/assets/master/20220715/选区_023.png)

在这里提一个对上层应用开发小伙伴而言相对偏“冷”的知识吧。你们肯定听过一道很经典的面试八股题：《Binder 这么好用，那为什么 Zygote 的 IPC 通信机制用 Socket 而不用 Binder》？背答案的时候都会背，实际用在了哪里呢？现在你就看到了，在 Android 8.0 之前，`RILC` 与 Modem 的通讯一直就是采用 Socket 的，但之后被 [HIDL][hidl] 替代了，后者可以简化代码量，使条理逻辑更加清晰，也方便 OEM 快速适配机型，这块的变化可以参考下文。

https://blog.csdn.net/dxpqxb/article/details/103381911

对 `RIL` 的介绍打算言尽于此，多的我我也没有深入去研究，毕竟只是先了解一下整个的结构关系。而且这部分的代码一般都是由 SOC 厂商和 Google 去维护的，除非有特殊的通讯相关需求，否则一般 OEM 也不会动到。`RILC` 的代码位于源码根目录下 `hardware/ril`, `RILJ` 的代码则位于源码根目录下 `frameworks/opt/telephony`，将在下面提到。

> 注意，虽然 `RILJ` 的代码位于 `Telephony`，但不要认为 `Telephony` 整个就是为了实现 `RILJ`，因为除此之外，`RILJ` 还包含 `CallTacker` `Phone` `CallManger` 等众多逻辑。

### `TeleService`

 这部分的介绍也尽量由下往上，既然上面提到了 `RILJ`，就先看这部分的代码。

`RILJ` 的代码主要位于 `frameworks/opt/telephony`，大概看一下这个项目的 `Android.bp`：

``` bp
java_library {
    name: "telephony-common",
    installable: true,

    aidl: {
        local_include_dirs: ["src/java"],
    },
    srcs: [
        ":opt-telephony-common-srcs",
        ":framework-telephony-common-shared-srcs",
        ":net-utils-telephony-common-srcs",
        ":statslog-telephony-java-gen",
        ":statslog-cellbroadcast-java-gen",
        "src/java/**/I*.aidl",
        "src/java/**/*.logtags",
    ],

    jarjar_rules: ":jarjar-rules-shared",

    libs: [
        "android.hardware.radio-V1.0-java",
        "android.hardware.radio-V1.1-java",
        "android.hardware.radio-V1.2-java",
        "android.hardware.radio-V1.3-java",
        "android.hardware.radio-V1.4-java",
        "android.hardware.radio-V1.5-java",
        "voip-common",
        "ims-common",
        "unsupportedappusage",
    ],
    static_libs: [
        "android.hardware.radio.config-V1.0-java-shallow",
        "android.hardware.radio.config-V1.1-java-shallow",
        "android.hardware.radio.config-V1.2-java-shallow",
        "android.hardware.radio.deprecated-V1.0-java-shallow",
        "ecc-protos-lite",
        "libphonenumber-nogeocoder",
        "PlatformProperties",
        "net-utils-framework-common",
        "telephony-protos",
    ],

}
```
可以得出如下信息：

* 项目代码包含 java ，还定义了一些 aidl 接口，并且用了 [HIDL][hidl] 和底层交互
* 项目产物是 `telephony-common.jar`
* 可以根据[分包名称](https://cs.android.com/android/platform/superproject/+/master:frameworks/opt/telephony/src/java/com/android/internal/telephony/)大概知道都包含哪些功能接口。

另外通过阅读项目下的 [README.txt](https://cs.android.com/android/platform/superproject/+/master:frameworks/opt/telephony/README.txt) 还可以得知，`telephony-common.jar` 里很多 API 都是通过 HIDL 调用定义在 `hardware/interfaces/radio/` `hardware/interfaces/radio/config` 的接口的方式下放给 radio 层来获得返回值的。另外，在 `frameworks/base/telephony/` 里有一些 aidl 定义，在这个库和 `packages/services/Telephony` 这两个库里实现，这套 IPC 机制保证了调用者可以在它们自己的进程里跑公开的 API 代码，而和通讯相关的代码则跑在 `com.android.phone`，类似的实现可以参考 `PhoneInterfaceManager`, `SubscriptionController`。

继续我们的分析，既然上文提到了 `packages/services/Telephony`，我们有必要立刻打开它来一探究竟 ，先看下它的 `Android.bp`：

```bp

// Build the Phone app which includes the emergency dialer. See Contacts
// for the 'other' dialer.

android_app {
    name: "TeleService",

    libs: [
        "telephony-common",
        "voip-common",
        "ims-common",
        "libprotobuf-java-lite",
        "unsupportedappusage",
    ],

    static_libs: [
        "androidx.appcompat_appcompat",
        "androidx.preference_preference",
        "androidx.recyclerview_recyclerview",
        "androidx.legacy_legacy-preference-v14",
        "android-support-annotations",
        "com.android.phone.common-lib",
        "guava",
        "PlatformProperties",
    ],

    srcs: [
        ":framework-telephony-common-shared-srcs",
        "src/**/*.java",
        "sip/src/**/*.java",
        "ecc/proto/**/*.proto",
        "src/com/android/phone/EventLogTags.logtags",
    ],

    jarjar_rules: ":jarjar-rules-shared",

    resource_dirs: [
        "res",
        "sip/res",
    ],

    asset_dirs: [
        "assets",
        "ecc/output",
    ],

    aaptflags: [
        "--extra-packages com.android.services.telephony.sip",
    ],

    platform_apis: true,

    certificate: "platform",
    privileged: true,

    optimize: {
        proguard_flags_files: [
            "proguard.flags",
            "sip/proguard.flags",
        ],
    },

    proto: {
        type: "lite",
    },
}
```

可以得出如下信息：

* 项目的确依赖了 `telephony-common`，除此之外还有诸如 `voip-common`, `ims-common` 等模块
* 产物是 `TeleService.apk`
* `TeleService.apk` 内部还包含了紧急通话的一些逻辑，包括紧急通话的拨号盘，而常规模式下的拨号盘，在 `Dialer` 模块

既然是 `apk`，肯定要看一下它的 `AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
        xmlns:androidprv="http://schemas.android.com/apk/prv/res/android"
        package="com.android.phone"
        coreApp="true"
        android:sharedUserId="android.uid.phone"
        android:sharedUserLabel="@string/phoneAppLabel">

        <application android:name="PhoneApp"
            android:persistent="true"
            android:label="@string/phoneAppLabel"
            android:icon="@mipmap/ic_launcher_phone"
            android:allowBackup="false"
            android:supportsRtl="true"
            android:usesCleartextTraffic="true"
            android:defaultToDeviceProtectedStorage="true"
            android:directBootAware="true">
            
            ...

    </application>
</manifest>
```
这下子我们又可以知道更多信息：

* `PhoneApp.java` 是整个 App 的入口，在 Application 里应该有初始化的逻辑。
* `TeleService.apk` 会运行在 `com.android.phone` 进程
* `coreApp="true"`声明了这是个重要的系统模块，`android:directBootAware="true"` 保证了它在开机后即使用户没解锁也可以立刻启动

再简单看一下代码结构，主要包含两个包：

* `com.android.phone`：基础包，包含 PhoneApp、PhoneGlobals 等很多基础类。另外，拨号盘->设置->更多设置页面和逻辑也在这里实现。
* `com.android.services.telephony`：与通讯相关的服务的具体实现代码，比如 `TelephonyConnectionService`。

### `Telecom`

继续我们的探索，有了 `service`，又有了应用，他们之间是不是就可以直接通讯了呢？答案是否定的，在他们之间还有一个承上启下的关键组件 `Telecom.apk`，位于源码根目录的 `packages/services/Telecomm`，为了研究它，我们照理从它的 `Android.bp`入手：

``` bp
genrule {
    /.../
}

filegroup {
    name: "Telecom-srcs",
    srcs: [
        "src/**/*.java",
        ":statslog-telecom-java-gen",
    ],
}

// Build the Telecom service.
android_app {   
    name: "Telecom",
    srcs: [
        ":Telecom-srcs",
        "proto/**/*.proto",
    ],
    resource_dirs: ["res"],
    proto: {
        type: "nano",
        local_include_dirs: ["proto/"],
        output_params: ["optional_field_style=accessors"],
    },
    platform_apis: true,
    certificate: "platform",
    privileged: true,
    optimize: {
        proguard_flags_files: ["proguard.flags"],
    },
    defaults: ["SettingsLibDefaults"],
}

android_test {
    /.../
}
```

可以看出：

* `Telecom` 是一个 `service`，产物是 `Telecom.apk`。
* 从代码目录的 `callfiltering`、`callredirection` 分包可以窥见，`Telecom` 应该在上层应用（如 `Dialer.apk`）和下层服务(比 `TeleService.apk`) 之间，起到一个承上启下的左右，由它来过滤和沟通所有的请求是否要下方到底层服务，并在接收到底层服务后，再经由它传递给上层应用。可想而知，这个结构的好处使得不管是上层应用，还是底层服务，都只要专注做好自己领域的工作，而其它过滤、日志、跟踪记录等行为，就交由它这个中间层来执行。
* 有同学可能会想就此感慨一下 Android 架构设计的巧妙之处，其实 `Telecom` 也是 Android 5.0 之后才被引入的，Google 在 `packages/services/Telecomm/src/com/android/server/telecom/README` 有写到，大部分代码都是从 `TeleService.apk` 模块剥离到这里的。所以好的架构从来都不是天生的，也需要后期演变。

照例，既然是 `apk`，我们需要大概看一下 `AndroidManifest.xml`:

``` xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
        xmlns:androidprv="http://schemas.android.com/apk/prv/res/android"
        package="com.android.server.telecom"
        coreApp="true"
        android:sharedUserId="android.uid.system">

    <protected-broadcast android:name="android.intent.action.SHOW_MISSED_CALLS_NOTIFICATION" />
    <protected-broadcast android:name="com.android.server.telecom.MESSAGE_SENT" />

     <application android:label="@string/telecommAppLabel"
            android:icon="@mipmap/ic_launcher_phone"
            android:allowBackup="false"
            android:supportsRtl="true"
            android:process="system"
            android:usesCleartextTraffic="false"
            android:defaultToDeviceProtectedStorage="true"
            android:directBootAware="true">

    </application>
</manifest>
```
可以得知：

* `Telecom` 的进程应该是 `system_server`，使用平台签名
* 模块没有像 `TeleSevice` 那样在 `Application` 里去初始化逻辑，它的启动入口在 `frameworks/base/services/core/java/com/android/server/telecom/TelecomLoaderService.java` ，并在启动 system service 阶段跟随一起起来。

### `Dialer`

Dialer 顾名思义就是“拨号盘”了，代码位于 `packages/apps/Dialer`，这个没什么好讲的。需要注意的是，`Dialer` 内部还包含了通话界面（`InCallUI`）、语音信箱（`voicemail`）的代码。实际开发过程中，有些 OEM 厂商并不一定会内置这个 `Dialer`，而是倾向于把 `Dialer` 和 `InCallUI` 做成两个独立的 apk 内置，也方便做 SDK 化，跟系统源码解耦。

如此一来，我们可以对上面的图进行一次修改，补充一下模块名称，并且修改一下各个模块的描述：

![选区_026](https://raw.githubusercontent.com/shawnlinboy/assets/master/20220715/选区_026.png)

## 总结

以上就是对 Android Telephony 相关模块结构的简单解析。本文不对模块做深入，也不进行源码分析，因为我自己也还在学习当中。后面等我看得差不多了，有时间再来针对每个模块写一些源码解析的文章。

[hidl]: https://source.android.com/devices/architecture/hidl
