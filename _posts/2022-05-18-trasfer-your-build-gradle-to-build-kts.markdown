---
layout: post
title: "build.gradle，从 groovy 到 kts 迁移指南"
category: Android
tags: Android gradle kotlin kts
---

## 先说结论

- 为什么要迁移？主要是因为现在够稳定了。而且说实话，大部分国内 andriod 开发者对 `groovy`也就是个依葫芦画瓢的水平，而 `Kotlin` 是 app 开发过程中的主要语言，是一定要熟练掌握的，现在 Gradle 插件开发也支持用 `Kotlin` 写了，迁过去之后也方便无缝学习插件开发，没必要硬着头皮再去啃 `groovy`。
- 迁移不难，但官方现在没有提供工具，没办法像 `Java -> Kotlin` 那样可以在 Android Studio 点击 `Code -> Convert Java File to Kotlin File` 那样傻瓜化，你只能一个个文件去重命名。
- 要改的不多，所有的差异 Google 几乎都在[这篇文档][1]讲明白了。
- 如果遇到不会写的地方，可以看[官方文档](https://developer.android.com/studio/build/dependencies)，在 `Groovy` 与 `Kotlin` 之间来回切换，对比一下差异就知道怎么改了。 
- 我会把几处常见的修改点放在文末，如果你的配置文件从最开始就写得够规范，那么改起来工作量应该不大。

## 迁移步骤与方法

建议的步骤是从项目的 `settings.gradle` 开始，然后项目的 `build.gradle`，最后是各个模块的 `build.gradle`。不要自作聪明，记得[一步一个文件改](https://developer.android.com/studio/build/migrate-to-kts#migrating_one_file_at_a_time)，步子迈大了容易扯到蛋。

方法是直接把文件重命名。`settings.gradle -> settings.gradle.kts`，`build.gradle -> build.gradle.kts`，然后 Gradle sync，之后解决错误。

不要害怕 Gradle sync 之后的报错，大部分都是因为两种 DSL 之间的差异导致的，在上面说的 Google 的[这篇文章][1]里几乎都有列出来。

### `settings.gradle.kts` 主要变更

``` kotlin
//include ':app'
include("app")
```

``` kotlin

/*maven {
            url 'https://maven.aliyun.com/repository/google'
}*/

maven {
            url = uri("https://maven.aliyun.com/repository/google")
}
```

### 项目 `build.gradle.kts` 主要变更

``` kotlin
/*plugins {
    id 'com.android.application' version '7.1.3' apply false
    id 'com.android.library' version '7.1.3' apply false
    id 'org.jetbrains.kotlin.android' version '1.5.30' apply false
}*/

plugins {
    id("com.android.application") version "7.1.3" apply false
    id("com.android.library") version "7.1.3" apply false
    id("org.jetbrains.kotlin.android") version "1.5.30" apply false
}
```

``` kotlin
/*task clean(type: Delete) {
    delete rootProject.buildDir
}*/
tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
```

### 模块 `build.gradle.kts` 主要变更

``` kotlin
/*plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android'
}*/

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}
```

``` kotlin
    //compileSdk 32
    compileSdk = 32  //加 = 号
    
    /*buildFeatures {
        viewBinding true
    }*/
    
    buildFeatures {
        viewBinding = true //还是加 = 号，理解了就行
    }

    /*defaultConfig {
        applicationId "com.example.myapplication"
        minSdk 21
        targetSdk 32
        versionCode 1
        versionName "1.0"

        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
    }*/

    //继续加 = 号，一定要理解
    defaultConfig {
        applicationId = "com.example.myapplication"
        minSdk = 21
        targetSdk = 32
        versionCode = 1
        versionName = "1.0"
   }
 ```
 
 ``` kotlin
 /*buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }*/
    
    buildTypes {
    //注意这里这个方法
        getByName("release") {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }
 ```
 
 ``` kotlin
 /*compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }*/
    
 //注意这里我换到了 JDK 11，如果你的项目受限，依然还是可以用 1.8，虽然真的太老了……   
 compileOptions {
        sourceCompatibility(JavaVersion.VERSION_11)
        targetCompatibility(JavaVersion.VERSION_11)
    }
 ```
 
 ``` kotlin
    // Dependency on a local library module
    //implementation project(':mylibrary')
    implementation(project(":mylibrary"))
    // Dependency on local binaries
    //implementation fileTree(dir: 'libs', include: ['*.jar'])
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.jar"))))
    // Dependency on a remote binary
    //implementation 'com.example.android:app-magic:12.3'
    implementation("com.example.android:app-magic:12.3")
 ```


[1]: https://developer.android.com/studio/build/migrate-to-kts