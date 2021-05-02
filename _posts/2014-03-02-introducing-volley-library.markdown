---
layout: post
title: "Introducing: Volley Library"
date: 2014-03-02 23:24:38 +0800
comments: true
categories: Android
---
What is Volley?
===
> Volley is a library that makes networking for Android apps easier and most importantly, faster.

在 `Google I/O 2013`, Google 介绍了这个高大上的玩意儿。作为 Apache 的 `HttpClient` 解决方案的又一选择， `Volley` 具有如下优点：

1. `Volley` 会自动对齐所有的网络请求。
2. `Volley` 提供了完全透明化的磁盘和内存缓存。
3. `Volley` 提供了一套强大的“取消请求”的 API，可以轻松取消请求池中的请求。
4. `Volley`提供了强大的个性化功能、debug 和 跟踪工具。

然后呢，咳咳。。。嗯嗯，技术文章要严肃！据说介个呢，就是 `Volley` 一词灵感的由来了。话说乍一看这一个个的真的好像那啥啊有木有！！！真是羞羞～(｡•ˇ‸ˇ•｡)

![Volley](http://ww2.sinaimg.cn/large/7adcb3b9gw1ee1ur0z23hj20go0bt0uk.jpg)
<!-- more -->

Where to get it?
===
`Volley` 并没有像其它库一样提供现成的 jar 包给我们，而是非常可爱地提供了整个项目的源代码供我们下载，自行编译。

1.Clone Volley 的源码：
``` bash
git clone https://android.googlesource.com/platform/frameworks/volley
```
2.安装 `Ant`
``` bash
sudo apt-get install ant1.7
sudo apt-get install ant-optional
```
3.准备配置环境变量
``` bash
vim ~/.bashrc
```
4.配置 `ANDROID_HOME` 环境变量，提供我的配置供参考
``` bash
export JAVA_HOME=/opt/java
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:${PATH}:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
export ANDROID_HOME=/opt/adt/sdk
```
5.进入 `Volley` 目录，编译 jar 包
``` bash
cd volley
ant jar
```
6.从 `/volley/bin` 中获得新成就——`volley.jar`

Sample Project
===
在接下来的项目中，我用了三个按钮，分别用来:

* 获得一串Json对象
* 获取一张图片并设置到`imageView`
* 获取一张图片并设置到 `Volley` 提供的 `NetworkImageView` **(Recommended)**

在测试前，请确保已将之前获得的 `Volley.jar` 放入项目的 `/libs` 并 `add to buildpath`。另外，项目中有网络请求，所以请确保在 `AndroidManifest.xml` 中请求完全的网络访问权限。

`activity_main.xml`
``` xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:paddingBottom="@dimen/activity_vertical_margin"
    android:paddingLeft="@dimen/activity_horizontal_margin"
    android:paddingRight="@dimen/activity_horizontal_margin"
    android:paddingTop="@dimen/activity_vertical_margin"
    tools:context=".MainActivity" >

    <Button
        android:id="@+id/btn_json"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Get Json" />

    <TextView
        android:id="@+id/tv_json"
        android:layout_width="match_parent"
        android:hint="This request returns your Json-formatted ip address as reponse."
        android:layout_height="wrap_content" />

    <Button
        android:id="@+id/btn_imageview"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Set ImageView" />

    <ImageView
        android:id="@+id/iv"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content" />

    <Button
        android:id="@+id/btn_networkimageview"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Set NetworkImageView" />

    <com.android.volley.toolbox.NetworkImageView
        android:id="@+id/iv_net"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content" />

</LinearLayout>
```
`MainActivity.java`
``` java
public class MainActivity extends Activity {

	private Button mButtonJson;
	private Button mButtonImageView;
	private Button mButtonNetImageView;
	private TextView mTextViewJson;
	private ImageView mImageView;
	private NetworkImageView mNetworkImageView;

	private final String JSON_URL = "http://ip.jsontest.com/";
	private final String AVATAR_URL = "http://www.gravatar.com/avatar/2395dcaf9490cb28a21bf1e75af6f352?s=160";
	private static final String TAG = MainActivity.class.getSimpleName();

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
		findViewById();
		setJsonListener();
		setImageViewListener();
		setNetworkImageViewListener();
	}

	/**
	 * This is damned easy!!!
	 */
	private void setNetworkImageViewListener() {
		mButtonNetImageView.setOnClickListener(new OnClickListener() {

			@Override
			public void onClick(View v) {
				RequestQueue requestQueue = Volley
						.newRequestQueue(getApplicationContext());
				final LruCache<String, Bitmap> lru = new LruCache<String, Bitmap>(
						50);
				ImageCache cache = new ImageCache() {

					@Override
					public void putBitmap(String key, Bitmap value) {
						// TODO Auto-generated method stub
						lru.put(key, value);
					}

					@Override
					public Bitmap getBitmap(String key) {
						// TODO Auto-generated method stub
						Bitmap bitmap = lru.get(key);
						return bitmap;
					}
				};
				ImageLoader loader = new ImageLoader(requestQueue, cache);
				mNetworkImageView.setImageUrl(AVATAR_URL, loader);
			}
		});
	}

	/**
	 * The getImageListener's calling will need 3 parameters. Here are the
	 * official comments in volley's source code.
	 * 
	 * @param imageView
	 *            The imageView that the listener is associated with.
	 * @param defaultImageResId
	 *            Default image resource ID to use, or 0 if it doesn't exist.
	 * @param errorImageResId
	 *            Error image resource ID to use, or 0 if it doesn't exist.
	 */
	private void setImageViewListener() {
		mButtonImageView.setOnClickListener(new OnClickListener() {

			@Override
			public void onClick(View v) {
				RequestQueue requestQueue = Volley
						.newRequestQueue(getApplicationContext());
				final LruCache<String, Bitmap> lru = new LruCache<String, Bitmap>(
						50); // 50 is the cache size
				ImageCache cache = new ImageCache() {

					@Override
					public void putBitmap(String key, Bitmap value) {
						lru.put(key, value);
					}

					@Override
					public Bitmap getBitmap(String key) {
						Bitmap bitmap = lru.get(key);
						return bitmap;
					}
				};
				ImageLoader loader = new ImageLoader(requestQueue, cache);
				// Here I use "android.R.drawable.ic_delete" simply because
				// it looks like a cross which means error.
				ImageListener listener = ImageLoader.getImageListener(
						mImageView, 0, android.R.drawable.ic_delete);
				loader.get(AVATAR_URL, listener);
			}
		});
	}

	private void setJsonListener() {
		mButtonJson.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View arg0) {
				// Any of your requests should be added to the RequestQueue
				// instance. Use Volley's static method instead of retriving new
				// instance manually.
				RequestQueue requestQueue = Volley
						.newRequestQueue(getApplicationContext());
				// Build up the request
				JsonObjectRequest request = new JsonObjectRequest(
						Request.Method.GET, JSON_URL, null,
						new Listener<JSONObject>() {

							@Override
							public void onResponse(JSONObject response) {
								// TODO Auto-generated method stub
								mTextViewJson.setText(response.toString());
							}
						}, new Response.ErrorListener() {

							@Override
							public void onErrorResponse(VolleyError arg0) {
								// TODO Auto-generated method stub
								Log.i(TAG, "---->onErrorResponse");
							}
						});
				// Add the request to the request queue
				requestQueue.add(request);
			}
		});
	}

	private void findViewById() {
		mButtonJson = (Button) findViewById(R.id.btn_json);
		mButtonImageView = (Button) findViewById(R.id.btn_imageview);
		mButtonNetImageView = (Button) findViewById(R.id.btn_networkimageview);
		mTextViewJson = (TextView) findViewById(R.id.tv_json);
		mImageView = (ImageView) findViewById(R.id.iv);
		mNetworkImageView = (NetworkImageView) findViewById(R.id.iv_net);
	}
}
```

References
===
> [《Google I/O 2013 - Volley: Easy, Fast Networking for Android》](http://www.youtube.com/watch?v=yhv8l9F44qo)

> [《Android 网络通信框架 Volley 简介》](http://blog.csdn.net/t12x3456/article/details/9221611)

> [《快速构建Android REST客户端系列》](http://imid.me/blog/archives)