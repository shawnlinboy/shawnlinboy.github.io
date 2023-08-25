---
layout: post
title: "Introducing: Parcelable Interface"
date: 2014-02-15 22:00:16 +0800
comments: true
categories: Android
---
Introduction
===
在 Android 开发过程中，我们无法直接将一个对象的引用传给 Activity 或者 Fragment，而必须将其放在 Bundle 或者 Intent 中。通过最近的实践，我发现 Android 并未在 Bundle 或者 Intent 中对 Java 的一些数据封装方式进行良好的支持。比如，当需要使用 Intent 传递一个 ArrayList 时，Intent 并未提供一个良好的方法。仅有的 `putParcelableArrayList()` 方法虽然可以通过将对象强制类型转换传过去，但最终会得到这样的代码，看着让人十分不舒服：

``` java
 bundle.putParcelableArrayList("selectedContact",  
                (ArrayList<? extends Parcelable>) selectedList);  
```

而实际上，这个方法也暗示了我们在 Android 开发时，可以使用 Android 自己特有的一套封装数据模型的实现接口，那就是 [Parcelable](http://developer.android.com/intl/zh-cn/reference/android/os/Parcelable.html)。
<!-- more -->

`Parcelable` 是 Android 特有的一个数据封装接口，效率要比 `Serializable` 高很多，不会引起频繁的 GC ，而且还可以运用在 IPC 中。


Usage
===
`Parcelable` 的使用没有 `Serializable` 那么简单直观。在 Java 中，实现 `Serializable` 非常简单，让类体直接实现 `Serializable` 接口就行。而在这里，除了实现这个接口后需要重写的两个方法之外，类体里面还必须包含一个名为 `CREATOR` 的静态变量，这个变量是一个实现了 `Parcelable.Creator` 的对象，而这个对象里又包含两个方法需要覆盖。自然代码看起来也没有 `Serializable` 那么优雅了。如下是一个简单的 Person 类：

``` java
public class Person implements Parcelable {

	public String name;
	public boolean isChecked;
	public int age;

	public int getAge() {
		return age;
	}

	public void setAge(int age) {
		this.age = age;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public boolean isChecked() {
		return isChecked;
	}

	public void setChecked(boolean isChecked) {
		this.isChecked = isChecked;
	}

	public static final Parcelable.Creator<Person> CREATOR = new Parcelable.Creator<Person>() {

		@Override
		public Person createFromParcel(Parcel source) {
			// TODO Auto-generated method stub
			Person p = new Person();
			p.name = source.readString();
			p.age = source.readInt();
			p.isChecked = source.readInt() == 1;
			return p;
		}

		@Override
		public Person[] newArray(int size) {
			// TODO Auto-generated method stub
			return new Person[size];
		}
	};

	@Override
	public int describeContents() {
		// TODO Auto-generated method stub
		return 0;
	}

	@Override
	public void writeToParcel(Parcel dest, int flags) {
		// TODO Auto-generated method stub
		dest.writeString(name);
		dest.writeInt(age);
		dest.writeInt(isChecked ? 1 : 0);
	}
}
```
这样一个简单的 Person 类就完成了。试着写两个 Activity ，在第一个 Activity 中，将一个 Person 对象调用 intent 的 `putExtra (String name, Parcelable value)` 方法放入，并传到第二个 Activity ，再在第二个 Activity 中通过 ` getParcelableExtra (String name)` 即可取出这个对象，从而获得其中的这些属性了。


Parcelable vs Serializable
===
这个问题直接引用 [Google 工程师](http://stackoverflow.com/a/3612364/2388326) 的回答:
> For in-memory use, Parcelable is far, far better than Serializable. I strongly recommend not using Serializable.

> You can't use Parcelable for data that will be stored on disk (because it doesn't have good guarantees about data consistency when things change), however Serializable is slow enough that I would strongly urge not using it there either. You are better off writing the data yourself.

> Also, one of the performance issues with Serializable is that it ends to spin through lots of temporary objects, causing lots of GC activity in your app. It's pretty heinous.