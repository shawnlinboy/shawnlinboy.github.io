---
layout: post
title: "Octopress Speed Up"
date: 2015-05-11 01:39:08 +0800
comments: true
tags: Octopress
categories: Web
---
很长时间以来 Mobile Lin 访问慢这个问题我是知道的，但是一直也没想着去整，主要是因为觉得真正搞技术的人肯定都知道是什么原因导致访问慢，而且一定也知道加速的办法是什么。但这其实都是在为自己的懒找借口。晚上[微博](http://weibo.com/2061284281/ChfcRuA3J?from=page_1005052061284281_profile&wvr=6&mod=weibotime&type=comment)上终于有哥们儿跟我说了：

> 毕竟手机上2G网络挂着VPN来访问你的网站，也不是一件容易的事。

好吧。既然用户有需求，那就开整呗~![](http://img.t.sinajs.cn/t4/appstyle/expression/ext/normal/0b/wabi_thumb.gif)

Octopress 在国内访问速度的优化主要从两方面进行：

## googleapis 相关

Octopress 默认使用了 google fonts 和 googleapis 的 ajax，但因为众所周知的原因它们在国内是被墙的。好在数字公司在这点上做了件好事，它们有一个这玩意儿：

> [360网站卫士常用前端公共库CDN服务](http://libs.useso.com/)

这么一来就好办了，打开 `/Octopress/source/_includes/head.html` ：

``` javascript
	<script src="//ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
	<link href='http://fonts.googleapis.com/css?family=Open+Sans:400italic,400,700' rel='stylesheet' type='text/css'>
```

换成

``` javascript
	<script src="//ajax.useso.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
	<link href='http://fonts.useso.com/css?family=Open+Sans:400italic,400,700' rel='stylesheet' type='text/css'>
```

## gravatar 相关

gravatar 是一个全球公认的头像库，跟你的 e-mail 绑定。可惜，这么好的东西在我大天朝也是不存在的。不过，依旧好在国内有 duoshuo，他们提供了一个 gravatar 的缓存。打开 `/Octopress/source/_includes/header.html` ：

``` javascript
	<script type="text/javascript">
		document.write("<img src='http://www.gravatar.com/avatar/" + MD5("YOUR_EMAIL") + "?s=160' alt='Profile Picture' style='width: 160px;' />");
	</script>
```

换成：

``` javascript
	<script type="text/javascript">
		document.write("<img src='http://gravatar.duoshuo.com/avatar/" + MD5("YOUR_EMAIL") + "?s=160' alt='Profile Picture' style='width: 160px;' />");
	</script>
```

That's all，我们 `rake generate` 一下之后本地预览一下就可以看到非常显著的效果。

## 参考

> [替换Octopress Google 字体库](http://blog.depressedmarvin.com/2014/07/08/new-google-fonts-cdn/)