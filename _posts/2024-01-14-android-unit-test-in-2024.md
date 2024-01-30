---
layout: post
title: "Stepping into 2024: Does Your Android Project Embrace Unit Testing?"
category: android
tags: android unittest
---

Most of us Android developers are familiar with the project structure, and if you take a look, you'll likely find two folders: `androidTest` and `test`. Personally, I used to know very little about unit testing in Android development. It seems like many companies in China don't prioritize unit testing, and most developers rarely write code in these two folders. Does your company or project have unit tests? Feel free to share in the comments.

![android-test-folder.jpg](android-test-folder.jpg)

## What is Unit Testing?

Some might be nervous at this point, thinking I'm about to give a formal definition. However, that's not the case. Everything I'm about to share is based on my own experiences and my journey from not caring at all about unit testing to at least getting started.

"Unit testing" means testing the smallest units of software in a modular way. In the article [A Guide to Unit Testing for Android Beginners](https://juejin.cn/user/1468603264932014/posts), the author provides a software engineering pyramid, clearly showing that unit testing is at the bottom of this pyramid. As the saying goes, a tall building starts with a solid foundation. This illustrates that if unit testing is done robustly, it has the most significant impact on the overall robustness of the software project.

Getting a bit technical, when I mentioned the "smallest units of software," I mean every utility class (`***Utils.kt`), `***Presenter.kt`, `***Controller.kt`, `***Repository.kt`, `***Dao.kt`, and going up to the UI layer, each `Activity`, `Fragment`, `View`, `ViewModel`. By now, you should have a basic understanding of the concept of "smallest units." However, you might still have some doubts. I mentioned "smallest units," but each of these units has several methods, some even with hundreds or thousands of lines of code. Can we refine the concept of "smallest units" down to each method within a class?

Congratulations! You're on the right track. If you've grasped this concept, the rest should be straightforward. Unit testing is about testing each method within these "smallest units," and these tests are called "test cases."

## Why Do We Need Unit Testing?

I've asked myself this question numerous times because traditionally, in our field of Android development, it's often enough to complete the business requirements, do a quick check, handle edge cases, make sure it behaves as expected, doesn't crash, and submit the code. But is that really enough?

Let me illustrate with a real example:

Suppose there's a requirement for `displayName` to be the system version name, a `String` like `"Android OS 14"` or `"Android OS 15"`. The operations team assures you that the prefix `"Android OS "` will not change. The app needs to differentiate logic based on Android versions, like `14` or `15`. You create a utility class `VersionUtils` with a method `parseAndroidVersion(displayName: String)` to fulfill this requirement:

```kotlin
object VersionUtils {

    fun parseAndroidVersion(displayName: String): Int {
        val regex = "\\b(\\d+)\\b"
        val pattern = Pattern.compile(regex)
        val matcher = pattern.matcher(displayName)
        return if (matcher.find()) {
            Integer.parseInt(matcher.group(1))
        } else {
            -1
        }
    }
}
```

One day, a new colleague joins the team, looks at this method, finds it too complex, and decides to "optimize" it. They believe that given the assurance from the operations team about the prefix, there's no need for the regular expression. Instead, they can split `displayName` by `"Android OS "` and try to parse the second part. Here's their "optimized" version:

```kotlin
object VersionUtils {

    fun parseAndroidVersion(displayName: String): Int {
        val s = displayName.split("Android OS ")
        return try {
            Integer.parseInt(s[1])
        } catch (e: NumberFormatException) {
            -1
        }
    }
}
```

This colleague feels proud to have simplified the code. They even handle the case where `s[1]` might not be an integer with a try-catch block. They make the change, run some tests with versions like `"Android OS 14"` and `"Android OS 15"`, and it seems to work fine. They submit the code, and soon after, the app breaks for users who upgrade with a version like `"Android OS 14（New Year Special Edition）"`.

The lesson here is that even with assurances, assumptions about data can lead to unexpected issues. In this case, the `try-catch` block didn't prevent the problem.

## What If We Had Unit Tests?

If there were unit tests for the original `parseAndroidVersion()` method, the "optimization" would have triggered a failed test. Let's create a simple unit test using a testing framework like `Robolectric`:

```kotlin
@RunWith(RobolectricTestRunner::class)
class VersionUtilsTest {

    @Test
    fun testParseAndroidVersion() {
        // Normal scenario
        val version = VersionUtils.parseAndroidVersion("Android OS 14")
        assertEquals(14, version)

        // Scenario with a suffix
        val version2 = VersionUtils.parseAndroidVersion("Android OS 14（Special Edition）")
        assertEquals(14, version2)
    }
}
```

Assuming the original developer had written this test along with the `VersionUtils` class, the "optimization" would have failed this test. The test case would have immediately revealed the problem, allowing the team to fix it before causing issues for users.

## What Does Unit Testing Solve?

The above example vividly demonstrates that unit testing could have prevented an issue that shouldn't have occurred in the first place.

In my experience leading a team, I often told team members, "We have many changes (Change line) when writing code that only we developers are aware of. Where we modify and how it affects other parts of the code, testing colleagues won't know unless we tell them. During testing, make sure to communicate with testing colleagues, highlight the areas that might be affected, and focus on regression testing those areas. Developers won't tell, and testers won't know."

This simple principle applies across teams. Testers don't touch the code and don't know where you've written logic. Operations colleagues aren't interested in technology and won't understand if your change affects some data incompatibility. As developers, we can use unit tests to enrich the cases we can think of during code development. By doing so, we empower the future maintainers to confidently refactor or add new features, knowing that if they inadvertently break something, tests will fail. This helps detect issues early in the development process.

### How AOSP Uses Unit Testing

As many are aware, AOSP (Android Open Source Project) maintains both an internal branch (`internal`) and an external branch (`main`).

Internally, Google continually develops on the `internal` branch, periodically merging code into the `main` branch. External developers, on the other hand, submit changes directly to the `main` branch. Google checks for conflicts between these external submissions and the `internal` branch, ensuring that the submissions do not cause disruptions. Once approved through review, the changes are merged.

To illustrate this process, here's a simplified flowchart:

```
  +--------------------+             +--------------------+
  |                    |             |                    |
  |  aosp internal branch |          | External Submission       +<---+ External Developer
  |       Merge         |            |                    |             to AOSP
  |                    |             |                    |
  +--------^-----------+             +--------+-----------+
           |                                  |
      Simultaneous Internal Commits          CI Generates Internal Commits
           |                                  |
  +--------+-----------+             +--------v-----------+
  |                    |             |                    |
  |   aosp main branch  +<------  ---+  Internal Commits  |
  |       Merge        |   CI Check  |                    |
  |                    |   &         +--------------------+
  +--------------------+  Manual Review Passed
```

Given the vastness and constant evolution of Android, including both internal and external developments, Continuous Integration (CI) plays a crucial role in scrutinizing every submission. Unit testing, integrated into AOSP as a suite called [atest](https://source.android.com/docs/core/tests/development/atest), is a key component of this quality assurance process.

For those who haven't noticed, every testable project in AOSP has a `TEST_MAPPING` file in its root directory. Taking the `Settings` module as an example, let's explore its `TEST_MAPPING` file:

```json
{
   "presubmit":[
      {
         "name":"SettingsSpaUnitTests"
      },
      {
         "name":"SettingsUnitTests",
         "options":[
            {
               "include-filter":"com.android.settings.password"
            },
            {
               "include-filter":"com.android.settings.biometrics"
            },
            {
               "include-filter":"com.android.settings.biometrics2"
            }
         ]
      }
   ],
   "postsubmit":[
      {
         "name":"SettingsUnitTests",
         "options":[
            {
               "exclude-annotation":"androidx.test.filters.FlakyTest"
            }
         ]
      },
      {
         "name":"SettingsPerfTests"
      }
   ]
}
```

If you are familiar with Google's software development practices, the term `presubmit` should ring a bell. It represents a set of pre-checks performed before code submission and closely aligns with the CL (Changelist) and Code Review processes. Each project can configure its own pre-checks, and CI executes these checks for every submission. If all checks pass, a +1 or +2 is given during Code Review; otherwise, it might receive a -1 (due to unit test errors) or -2 (code failed to compile). Those interested in `presubmit` workflows should read [Efficacy Presubmit](https://testing.googleblog.com/2018/09/efficacy-presubmit.html).

From the configuration file above, the Settings project defines numerous unit test cases. The corresponding test code can be found in [packages/apps/Settings/tests/](https://cs.android.com/android/platform/superproject/main/+/main:packages/apps/Settings/tests/). These unit tests benefit developers by avoiding the uncertainty of "unknown impacts of changes" and provide testers with confidence that no scenarios are overlooked. In summary, unit testing significantly ensures project health and saves considerable time in manual testing.

## Can Unit Testing Replace Manual Testing?

The answer is unequivocally—NO.

Unit testing primarily checks whether the code's logic is working correctly, focusing on the pure logic aspects, edge cases, and proper handling of exceptions. In other words, if a method is supposed to calculate `1 + 1 = 2`, unit testing ensures that as long as `1 + 1 ≠ 2`, it will immediately notify you, without waiting until it's deployed. This brings obvious benefits, saving a lot of manpower and time and maintaining the project at a good health.

On the other hand, manual testing can evaluate the user experience of the application, such as whether the user interface is friendly, interactions are smooth, and so on. These aspects are beyond the scope of unit testing. Additionally, manual testing can better simulate user behavior and usage scenarios, checking whether the application works under various conditions. For instance, does the app function correctly when the network is unstable? Is it stable when users open multiple apps simultaneously or perform complex operations within the app? Especially in Android development, there are many scenarios where manual clicks and testing are necessary, relying on subjective judgments of smoothness, ANR (Application Not Responding), etc.

So, unit testing and manual testing should be used together, not one replacing the other. By combining both testing methods, you can ensure your application meets expectations in terms of functionality, performance, and user experience.

As a side note, with the emergence of many Android platform testing frameworks, there are now frameworks that can simulate scenarios like slow network connections, low battery levels, etc., for unit testing. I'll share more about these frameworks in future articles.

## Conclusion

In this article, I provided a simple explanation of what unit testing is, used a straightforward scenario to illustrate the need for unit testing, discussed its benefits, and touched on how AOSP incorporates unit testing.

In the past year and a half, being involved in AOSP and AndroidX, I've transitioned from being a beginner to gaining an understanding of unit testing. In subsequent personal projects, I've gradually adopted unit testing and experienced its benefits. I hope this article encourages you to start using unit testing in your projects, and don't ignore the `androidTest` folder anymore!
