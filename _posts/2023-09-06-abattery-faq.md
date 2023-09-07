---
layout: post
title: "FAQ about aBattery"
category: abattery
tags: abattery
---

Last update: 2023-09-07 00:18:19

Target version: 1.0.6

[aBattery](https://play.google.com/store/apps/details?id=me.linshen.abattery) is a ready-to-use battery information viewing tool. It is so lightweight and straightforward, allowing for immediate use and departure, while continuously accepting user feedback and making incessant improvements.

The information aBattery queries mainly comes from the battery-health related APIs introduced in Android 14. However, since some manufacturers have written some information even in earlier versions of Android, aBattery also attempt to read this. Nonetheless, to ensure the information is as reliable as possible, the application only supports Android 11+.

Here are the answers to some common questions you may encounter during use:

<br>

__Q: What features are planned for development?__

Appwidgets, SystemUI Tiles support... Please do let me know if you have additional ideas💡.

<br>

__Q: Why aren't `Manufacture date`, `First usage date` and `Charging policy` displayed?__

These details are applicable only for Android 14+.

<br>

__Q: Why `Cycle count` shows 0?__

This value was optional before Android 14, hence your device manufacturer might not have correctly reported it. Please upgrade to Android 14 and check again.

<br>

__Q: Why does my `Maximum capacity` display differently compared to other similar applications?__

Algorithm diff leads to this after looking into the source. 
Many other apps read data by calling `BatteryManager.getIntProperty(BATTERY_PROPERTY_STATE_OF_HEALTH)` directly, while I read `charge_full` and `charge_full_design` under `/sys/class/power_supply/battery/` then do the division.

There are 2 reasons for doing so: 

1. Calling `BatteryManager.getIntProperty` requires a system privileged permission, which is prohibited after Android 10 even with the help of Shizuku. As aBattery targets Android 14, it may not be able to do this.
2. The value of `BATTERY_PROPERTY_STATE_OF_HEALTH` excessively dependents on OEM's HAL implmentation, so right now aBattery choose to calculate this value by itself.

<br>

__Q: I've already granted permissions, why does it still display `Device denied this query`?__

This issue has been detected on some Samsung, Xiaomi, and OnePlus devices. The reasons can be:
* Your device manufacturer indeed has additional security policies that intercept such queries, for example [Samsung Knox](https://www.samsungknox.com/) does this.
* Your device truly did not find the corresponding battery information.
* Some information may only be available after upgrading your device to Android 14.

<br>

__Q: Why some information not displayed on my device?__

Your device manufacturer might not have reported or erroneously reported this information. aBattery will make a simple judgement - if it deems the value unreasonable, it will directly hide this piece of information.

<br>

__Q: What is Shizuku and why do I need to install another application?__

When you require privileged permission, it indicates that the information you are viewing is restricted by Google's regulations. Only system applications or applications with advanced permissions (root permissions) can access this information. However, most users are not adept at rooting devices and are adverse to it. Hence, aBattery supports [Shizuku](https://shizuku.rikka.app/introduction), allowing you to grant application system permissions without having to root your device. 

Also it is worth mentioning that I have no vested interests with Shizuku or its author.
