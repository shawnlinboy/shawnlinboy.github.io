---
layout: post
title: "Best Practise For Loading Bitmaps Into A Viewpager"
date: 2014-04-07 23:51:59 +0800
comments: true
categories: Android
---
在 Android 开发中，处理 Bitmap 一向需要小心翼翼，因为这块一旦弄得不好的话，轻者会造成应用卡顿，严重地会直接 OOM 或导致 ANR。今天在重构毕业设计[引导界面](http://mobilelin.me/blog/2014/01/23/tricks-to-improve-layout-performance/)时，使用了一个简单的优化技巧，使得应用的启动性能有了相当明显的改善。

这个页面的 ViewPager 所带动的 Fragment 的布局里含有一个 ImageView，原来在 Fragment 里加载图片时是这么处理的：
<!-- more -->
``` java
public void onViewCreated(View view, Bundle savedInstanceState) {
		// TODO Auto-generated method stub
		super.onViewCreated(view, savedInstanceState);
		mImageView = (ImageView) view.findViewById(R.id.parallax_imageview);
		if (getArguments() != null) {
			if (!getArguments().containsKey("extra_image_id"))
				mImageView.setVisibility(View.GONE);

			//Poor performance!!!
			mImageView.setImageResource(getArguments().getInt("extra_image_id"));
		}
}
```
不久之后，这个写法糟糕的启动时性能就被许总发现了。于是我仔细分析了一下，整个引导界面有4页，每页的图片文件都在700-800K左右，如果像上面这样写，在 pager 数目较少或者图片较小的情况下问题不大（但一定会造成首次启动时 load 这些图片资源阻塞住 UI 线程），一旦 pager 数量多了或者用户机器性能不行时，load 这些图片的时间要是过了5秒，就直接 ANR 了。所以，最好的办法就是让整个加载过程「Get off the fuckingUI Thread」!

首先，需要一个 `BitmapUtils.java` 工具类，它完成了 Bitmap 的二次压缩过程
``` java
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

/**
 * New skill to optimize bitmap performance
 * 
 * @author linshen
 * @since 2014/04/07
 */
public class BitmapUtils {

	public static Bitmap decodeSampledBitmapFromResource(Resources res,
			int resId, int reqWidth, int reqHeight) {

		// First decode with inJustDecodeBounds=true to check dimensions
		final BitmapFactory.Options options = new BitmapFactory.Options();
		options.inJustDecodeBounds = true;
		BitmapFactory.decodeResource(res, resId, options);

		// Calculate inSampleSize
		options.inSampleSize = calculateInSampleSize(options, reqWidth,
				reqHeight);

		// Decode bitmap with inSampleSize set
		options.inJustDecodeBounds = false;
		return BitmapFactory.decodeResource(res, resId, options);
	}

	public static int calculateInSampleSize(BitmapFactory.Options options,
			int reqWidth, int reqHeight) {
		// Raw height and width of image
		final int height = options.outHeight;
		final int width = options.outWidth;
		int inSampleSize = 1;

		if (height > reqHeight || width > reqWidth) {

			final int halfHeight = height / 2;
			final int halfWidth = width / 2;

			while ((halfHeight / inSampleSize) > reqHeight
					&& (halfWidth / inSampleSize) > reqWidth) {
				inSampleSize *= 2;
			}
		}

		return inSampleSize;
	}
}

```
接着，需要在 Viewpager 对应的 Activity 里写一个异步任务，用来完成 Bitmap 的加载，like this：
``` java
	class BitmapWorkerTask extends AsyncTask<Integer, Void, Bitmap> {

		private final WeakReference<ImageView> imageViewReference;
		private int data = 0;

		public BitmapWorkerTask(ImageView imageView) {
			imageViewReference = new WeakReference<ImageView>(imageView);
		}

		@Override
		protected Bitmap doInBackground(Integer... params) {
			data = params[0];
			return BitmapUtils.decodeSampledBitmapFromResource(getResources(),
					data, 100, 100);
		}

		@Override
		protected void onPostExecute(Bitmap bitmap) {
			// TODO Auto-generated method stub
			if (imageViewReference != null && bitmap != null) {
				final ImageView imageView = imageViewReference.get();
				if (imageView != null) {
					imageView.setImageBitmap(bitmap);
				}
			}
		}
	}
```
同时，在 Activity 的类体中提供一个 `loadBitmap`方法，like this：

``` java
public void loadBitmap(int resId, ImageView imageView) {
		BitmapWorkerTask task = new BitmapWorkerTask(imageView);
		task.execute(resId);
	}
```

最后，重构一下 Fragment 里的方法：

~~`mImageView.setImageResource(getArguments().getInt("extra_image_id"));`~~

Write like this:
``` java
((WelcomeActivity) getActivity()).loadBitmap(
					getArguments().getInt("extra_image_id"), mImageView);
```

实践表示：数据上，这种优化至少可带来 0.8s 以上的提升；在用户直观体验上，这种加载速度的提升感会更加明显！