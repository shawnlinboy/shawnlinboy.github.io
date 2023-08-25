---
layout: post
title: "由 MTK 关机闹钟实现，浅析一种低侵入式修改 framework 方案"
category: Android
tags: Android AOSP framework
---

最近在修复一款 MTK 平台机器关机闹钟相关的 bug，简单了解了一下 MTK 关机闹钟的实现原理。发现相比于在 framework 里直接大动干戈，MTK 对框架的定制修改则采用了一种侵入性相对较小的方案，本文对这种方案进行了简单分析。

## AlarmManger 实现关机闹钟
长期以来，AlarmManager 作为 Android 系统中掌管 Alarm 的组件，一直没有关机闹钟的原生实现。虽然站在 Google 的角度也能说得过去，毕竟不是所有的闹钟都需要在用户关机了之后再帮用户自动开机的。好在各家 SOC 厂商都会在交付给 OEM 的代码里加上各自的关机闹钟实现，原理大同小异，不在本文讨论范围。

Android 的系统服务，大部分由 `XXXManager`暴露给上层，并交由 `XXXManagerService`实现。在关机闹钟的需求中，主要涉及对如下几个类的修改：

```
frameworks/base/core/java/android/app/AlarmManager.java
frameworks/base/services/core/java/com/android/server/AlarmManagerService.java
```

对于关机闹钟，修改的思路其实也简单，在 `AlarmManager.java` 中新增一个 `type` 用以标记要设置的闹钟是关机闹钟，接着在 `AlarmManagerService` 里据此作具体实现。

## 大部分厂商：直接改，简单粗暴

大部分厂商在这个时候，往往会直接对上面两个类开始大刀阔斧的修改。要知道，Google 每年都会不断释放新版本的 AOSP，而厂商各种魔改之后，这些热门的类经常在 merge 变更进来的时候引入一堆冲突，而解冲突的人不但要能先从 java 代码层面把冲突处理掉，更有可能需要整个把 AlarmManager 的代码原理撸一遍才敢下手，毕竟定时器是很基础的组件，万一改完不准或者不触发就惨了。

再者，如果就单一模块倒也还好，可 Android 有上百个这样类似的组件，这就要求我们在修改的时候，需要尽量以一种侵入性相对较小的方案来做，确保在尽量维持 AOSP 实现的同时，加入我们自己的逻辑，同时也为了下一次合并 AOSP 代码的时候，能够做到快速升级。

## MTK：类似插桩，空方法插入，运行时具体实现
MTK 对整个 AOSP System Services 这一块的修改，几乎全部采用了一种**类似插桩**的方式：

先在 AOSP 的 service 里插入自己的桩点代码，然后留出一个默认的空实现，接着继承这个 service，将真正的实现写在自己的这个继承类里面，最后把这些继承类打进一个单独的 `mediatek-framework.jar`，在运行时通过反射，如果反射到，就走类内实现，反射不到，就走原生实现，同时也不会导致编译失败。

这样一来，对 AOSP 的修改就有且只有“桩点 + 空实现”，由于所有的桩点都是自己加的，并且没有具体实现乱在里面，这在后期 merge AOSP 的时候能带来极大的便利，方便快速升级到最新的 Android 版本。

下面以关机闹钟为例，进行举例说明：

按照前面说的思路，对于开发者而言，调用 `AlarmManager` 大部分是通过 `set(@AlarmType int type, long triggerAtMillis, PendingIntent operation)` 方法来进行设置的，因此 MTK 首先在 `AlarmManager.java` 增加了一种 `AlarmType`，用来区分是否关机闹钟：

``` java
public class AlarmManager {

    /**
     * M: This alarm type is used to set an alarm that would be triggered if device
     * is in powerOff state. It is set to trigger POWER_OFF_ALARM_BUFFER_TIME ms earlier
     * than the actual alarm time so that phone is in wakeup state when actual alarm
     * triggers
     */
    /** @hide */
    public static final int PRE_SCHEDULE_POWER_OFF_ALARM = 7;
    ///@}
}
```
接下来，在 `AlarmManagerService.java` 里简单修改一下代码，插入桩点，但不做具体实现：

``` java
public class AlarmManagerService extends SystemService {

    void setImpl(int type, long triggerAtTime, long windowLength, long interval,
            PendingIntent operation, IAlarmListener directReceiver, String listenerTag,
            int flags, WorkSource workSource, AlarmManager.AlarmClockInfo alarmClock,
            int callingUid, String callingPackage) {
        //AOSP 省略..//

        /// M: added for powerOffAlarm feature @{
        if(!schedulePoweroffAlarm(type,triggerAtTime,interval,operation,directReceiver,
            listenerTag,workSource,alarmClock,callingPackage)){
            // FLYME: linshen@SHELL Continue setting a normal alarm if triggerAtTime can not meet
            // phone-off alarm requirements. The specification can be found at MtkAlarmManagerService {@
            Slog.w(TAG, "triggerAtTime does not meet phone-off alarm requirements, this alarm "
                    + "will not boot up your phone automatically.");
            // return;
            // @}
        }
        ///@}

        /// M: update for powerOffAlarm feature issue  @{
        if(isPowerOffAlarmType(type)) {
            type=RTC_WAKEUP;
        }
        ///@}
    }


    /// M: added for powerOffAlarm feature @{
    protected boolean isPowerOffAlarmType(int type){
        return false;
    }

    protected boolean schedulePoweroffAlarm(int type,long triggerAtTime,long interval,
        PendingIntent operation,IAlarmListener directReceiver,
        String listenerTag,WorkSource workSource,AlarmManager.AlarmClockInfo alarmClock,
        String callingPackage){
        return true;
    }

    protected void updatePoweroffAlarmtoNowRtc(){
    }

    public void cancelPoweroffAlarmImpl(String name) {
    }
    ///@}
}
```

在上述代码中，`sPowerOffAlarmType()`、`schedulePoweroffAlarm()`、`updatePoweroffAlarmtoNowRtc()`、`cancelPoweroffAlarmImpl()` 全部是 MTK 增加的方法，但实现确是空的，再将这些空方法在原生的 `setImpl()` 中，类似插桩一样插入一个个桩点进行引用。


重点来了，有了桩点 + 空方法，具体实现在哪里呢？答案是在 `vendor/mediatek/proprietary/frameworks/base/services/core/java/com/mediatek/server`：

MTK 在这里写了一个 `MtkAlarmManagerService` 来继承 `AlarmManagerService`，并在此具体实现了前面 `AlarmManagerService.java` 里面的空方法：

``` java

public class MtkAlarmManagerService extends AlarmManagerService {

    // M: added for powerOffAlarm feature @{
    @Override
    protected boolean isPowerOffAlarmType(int type){
        if(type != PRE_SCHEDULE_POWER_OFF_ALARM)
            return false;
        else
            return true;
    }


    @Override
    protected boolean schedulePoweroffAlarm(int type,
        long triggerAtTime,long interval,PendingIntent operation,IAlarmListener directReceiver,
        String listenerTag,WorkSource workSource,AlarmManager.AlarmClockInfo alarmClock,
        String callingPackage)
    {
        /// M:add for PowerOffAlarm feature(type 7) for booting phone before actual alarm@{
        if (type == PRE_SCHEDULE_POWER_OFF_ALARM) {
            if (mNativeData == -1) {
                Slog.w(TAG, "alarm driver not open ,return!");
                return false;
            }
            /// M: Extra Logging @{
            if (DEBUG_ALARM_CLOCK) {
                Slog.d(TAG, "alarm set type 7 , package name " + operation.getTargetPackage());
            }
            ///@}
            String packageName = operation.getTargetPackage();

            String setPackageName = null;
            long nowTime = System.currentTimeMillis();
            triggerAtTime = triggerAtTime - POWER_OFF_ALARM_BUFFER_TIME;

            if (triggerAtTime < nowTime) {
                /// M: Extra Logging @{
                if (DEBUG_ALARM_CLOCK) {
                    Slog.w(TAG, "PowerOff alarm set time is wrong! nowTime = " + nowTime
                       + " ; triggerAtTime = " + triggerAtTime);
                }
                ///@}
                return false;
            }
            /// M: Extra Logging @{
            if (DEBUG_ALARM_CLOCK) {
                Slog.d(TAG, "PowerOff alarm TriggerTime = " + triggerAtTime +" now = " + nowTime);
            }
            ///@}
            synchronized (mPowerOffAlarmLock) {
                removePoweroffAlarmLocked(operation.getTargetPackage());
                final int poweroffAlarmUserId = UserHandle.getCallingUserId();
                Alarm alarm = new Alarm(type, triggerAtTime, 0, 0, 0,
                        interval, operation, directReceiver, listenerTag,
                        workSource, 0, alarmClock,
                        poweroffAlarmUserId, callingPackage);
                addPoweroffAlarmLocked(alarm);
                if (mPoweroffAlarms.size() > 0) {
                    resetPoweroffAlarm(mPoweroffAlarms.get(0));
                }
            }
            type = RTC_WAKEUP;

        }
        return true;
    }

    @Override
    protected void updatePoweroffAlarmtoNowRtc(){
        final long nowRTC = System.currentTimeMillis();
        updatePoweroffAlarm(nowRTC);
    }


    /**
     * For PowerOffalarm feature, this function is used for APP to
     * cancelPoweroffAlarm
     */
    @Override
    public void cancelPoweroffAlarmImpl(String name) {
        /// M: Extra Logging @{
        if (DEBUG_ALARM_CLOCK) {
            Slog.i(TAG, "remove power off alarm pacakge name " + name);
        }
        ///@}
        // not need synchronized
        synchronized (mPowerOffAlarmLock) {
            removePoweroffAlarmLocked(name);
            // AlarmPair tempAlarmPair = mPoweroffAlarms.remove(name);
            // it will always to cancel the alarm in alarm driver
            if (mNativeData != 0 && mNativeData != -1) {
                if (name.equals("com.android.deskclock")) {
                    set(mNativeData, PRE_SCHEDULE_POWER_OFF_ALARM, 0, 0);
                }
            }
            if (mPoweroffAlarms.size() > 0) {
                resetPoweroffAlarm(mPoweroffAlarms.get(0));
            }
     }
    ///@}
}

```
看到这里，你可能隐约感觉到上面这个类的路径似乎很眼熟。事实上，MTK 确实使用了一种相对规范的方法来定制框架，他们新建了 `vendor/mediatek/proprietary` 目录，以此作为自己的源码根目录，如下图所示。

在这个目录下，MTK 参考了 AOSP 根目录的结构创建对应的子目录，每一个目录直接跟 AOSP 对应的目录对应，包含的全是 MTK 自己的实现，这样既方便查找代码位置，也避免了直接将自己的代码实现一股脑儿往 AOSP 里面直接塞。

![proprietary_001](https://raw.githubusercontent.com/shawnlinboy/assets/master/20220715/proprietary_001.png)

问题来了，就这样改一下，android 在运行时就自己知道要来这里找具体实现了吗？

当然不是。要查这个问题，我们需要先看一下 `vendor/mediatek/proprietary/frameworks/base`，了解一下 `base` 模块是怎么编译的：

``` bp
java_library {
    name: "mediatek-framework",
    installable: true,
    libs: [
```

可以看到，MTK 将他们自己的 framework 编译成一个 `mediatek-framework.jar` 放到 `system/framework` 下面，但又在哪里用到呢？

我们知道，Android 在进系统后，系统服务是由 `SystemServer` 来管理启动的，因此尝试去 `frameworks/base/services/java/com/android/server/SystemServer.java` 寻找答案：

``` java
public final class SystemServer {

    ///M: for mtk SystemServer @{
        private Object mMtkSystemServerInstance = null;
        private static Class<?> sMtkSystemServerClass = getMtkSystemServer();
    ///@}

    ///M: for mtk SystemServer @{
        private static MtkSystemServer sMtkSystemServerIns = MtkSystemServer.getInstance();
    ///@}

    /// M: For mtk system server.
    private static Class<?> getMtkSystemServer() {
        try {
            String className = "com.mediatek.server.MtkSystemServer";
            String mtkSServerPackage = "system/framework/mediatek-services.jar";
            PathClassLoader mtkSsLoader = new PathClassLoader(mtkSServerPackage,
            SystemServer.class.getClassLoader());
            return Class.forName(className, false, mtkSsLoader);
        } catch (Exception e) {
             Slog.e(TAG, "getMtkSystemServer:" + e.toString());
             return null;
        }
    }

    private void run() {
        //AOSP 省略..//
        TimingsTraceAndSlog t = new TimingsTraceAndSlog();
        // Start services.
        try {
            //AOSP 省略..//
            /// M: for mtk other service.
            sMtkSystemServerIns.startMtkCoreServices();
            startOtherServices(t)
        } catch (Throwable ex) {
            //AOSP 省略..//
        } finally {
            //AOSP 省略..//
        }
    }

    /**
     * Starts a miscellaneous grab bag of stuff that has yet to be refactored and organized.
     */
    private void startOtherServices(@NonNull TimingsTraceAndSlog t) {
        t.traceBegin("StartAlarmManagerService");
        if(!sMtkSystemServerIns.startMtkAlarmManagerService()){
            mSystemServiceManager.startService(new AlarmManagerService(context));
        }
        t.traceEnd();
    }

     /**
     * Starts some essential mtk services that are not tangled up in the bootstrap process.
     */
    private void startMtkCoreServices(){
        Slog.i(TAG, "startMtkCoreServices start");
        try {
            if (mMtkSystemServerInstance != null) {
                Method method = sMtkSystemServerClass.getMethod("startMtkCoreServices");
                method.invoke(mMtkSystemServerInstance);
            }
        }catch (Exception e) {
            Slog.e(TAG, "reflect  startMtkCoreServices error" + e.toString());
        }

    }
    /// @}

}
```

到这里已经很清晰了，MTK 首先修改了 `SystemServer.java`，尝试通过反射去获得 `mediatek-services.jar` 内的 `MtkSystemServer`，并且直接获得 `sMtkSystemServerIns`， 紧接着在 `run()` 内部通过 `sMtkSystemServerIns` 再反射调用对应的 `startMtkXXXServices()` 方法。

而对于 `startMtkAlarmManagerService()` 这种相对比较独立，不属于哪一组类型的服务，则直接插桩到 AOSP 的 `startOtherServices()` 内部，通过拦截的形式修改启动流程，先尝试通过 `sMtkSystemServerIns.startMtkAlarmManagerService()` 启动自己的 `MtkAlarmManagerService`，如果失败了，用 `mSystemServiceManager.startService(new AlarmManagerService(context));` 启动原生的 AlarmManagerService 来兜底。

接着看一下位于 `frameworks/base/services/core/java/com/mediatek/server` 的 `MtkSystemServer.java`，整个类就100行出头，清晰明了，原理依旧是反射，在 `getInstance()` 的时候拿到 `MtkSystemServerImpl`，所有的 `startMtkXXXServices()` 方法，因为这是在 `frameworks/base` 下，所以在这里依旧是空实现，不作具体实现。

``` java
public class MtkSystemServer {
    private static MtkSystemServer sInstance;
    public static PathClassLoader sClassLoader;

    public static MtkSystemServer getInstance() {
        if (null == sInstance) {
            String className = "com.mediatek.server.MtkSystemServerImpl";
            String classPackage = "/system/framework/mediatek-services.jar";
            Class<?> clazz = null;
            try {
                sClassLoader = new PathClassLoader(classPackage,
                        MtkSystemServer.class.getClassLoader());
                clazz = Class.forName(className, false, sClassLoader);
                Constructor constructor = clazz.getConstructor();
                sInstance = (MtkSystemServer) constructor.newInstance();
            } catch (Exception e) {
                Slog.e("MtkSystemServer", "getInstance: " + e.toString());
                sInstance = new MtkSystemServer();
            }
        }
        return sInstance;
    }

    public boolean startMtkAlarmManagerService() {
        return false;
    }

    public void startMtkCoreServices() {
    }

}
```
那么实现类究竟在哪呢？理所当然我们找到 `MtkSystemServerImpl.java`，它位于`vendor/mediatek/proprietary/frameworks/base/services/core/java/com/mediatek/server`，还记得前面说的吗？MTK 将自己的实现全部放在这边：

``` java
public class MtkSystemServerImpl extends MtkSystemServer {

    private static final String MTK_ALARM_MANAGER_SERVICE_CLASS =
            "com.mediatek.server.MtkAlarmManagerService";

        /**
         * Starts MtkAlarmManagerService if existed
         */
        @Override
        public boolean startMtkAlarmManagerService() {

            traceBeginAndSlog("startMtkAlarmManagerService");
            try {
                startService(MTK_ALARM_MANAGER_SERVICE_CLASS);
            } catch (Throwable e) {
                Slog.e(TAG, "Exception while starting MtkAlarmManagerService" +e.toString());
                return false;
            }
            traceEnd();
            return true;
        }

        /**
         * Starts some essential mtk services that are not tangled up in the bootstrap process.
         */
        @Override
        public void startMtkCoreServices() {
            Slog.i(TAG, "startMtkCoreServices ");
            //**MTK, TOO LONG **/
        }

        //**MTK, TOO LONG **/

}
```

在这个类里，我们终于看到了喜闻乐见的 `MtkAlarmManagerService`，原来是在这里被启动的，还有很多其它 MTK 定制的服务也一并在这里启动。事实上，MTK 在尽量避免把所有的接口、实现、修改全部侵入到 AOSP 的前提下，正是通过这种方式，完成了对 AOSP 绝大多数模块的定制修改。

## 优缺点分析

没有任何一种方案或架构是完美的，任何时候都一定有它的优缺点。采用 MTK 这种类似插桩的方式对 AOSP 进行定制修改，有如下几点：

* 优点
    * 尽可能减少了对 AOSP 代码的大面积入侵
    * 对 AOSP 不可避免的修改也只留桩点，逻辑清晰，方便后期合并上游代码做升级
    * 桩点的具体实现可单独打包（`mediatek-services.jar`），与 AOSP 完全解耦，方便测试验证问题（即使不把模块编进去也不报错，还可以直接走原生逻辑做到兼容）。
    * 理论上可结合 [APEX](https://source.android.com/devices/tech/ota/apex) 做模块升级（未验证）
* 缺点
    * 结构上减少了入侵，但实际上可能需要修改更多的文件。（比如在本文的例子中，直接改原生的 `AlarmManagerService` 可更为简单粗暴，但为了实现这种插桩式修改，反而要修改 `SystemServer` 增加启动点，并且新增`mediatek-services.jar`模块编译）
    * 如果 Google 在版本升级后修改了父类方法，继承类有可能需要跟着修改
    * 代码可读性降低，因为空实现与具体实现分开在两个库，要跳着看，略微增加了维护成本。

## 总结

本文结合 MTK 平台关机闹钟的实现，结合对 `MtkAlarmManagerService` 的修改，分析了一种对 AOSP 低侵入式修改的方法。值得再次强调的是，这种修改方式的目标并不是为了减少代码修改行数，或是减少文件修改个数，而是旨在修改的时候做到避免大面积入侵，避免将厂商自己的逻辑实现全部填塞到原生代码里，而是通过桩点 + 空实现 + 实际实现的形式来做到低侵入修改，以期在后续维护升级时能感受到便捷，以至快速交付。
