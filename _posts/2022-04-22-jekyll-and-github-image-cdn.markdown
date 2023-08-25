---
layout: post
title: "使用 Statically 配合 Github 做一个带 CDN 的图床"
category: Web
tags: Statically Github CDN 图床
---

Jekyll 写博客有个好处，就是可以直接调用 `assets` 下面的图片，但是部署到 Github 之后，由于众所周知的原因，在国内的访问速度可能会被图片加载拖慢，这个时候套上 Statically 可以加快访问速度，啪一下很快啊，一个图床就诞生了。

使用方法
===
1. 把文章里要引用的图片，假设叫 `screenshot.jpg`，放到网站根目录的 `assets/img/posts` 。

2. 在文章里，使用 `![My helpful screenshot](/assets/img/posts/screenshot.jpg)` 的方式引用图片。

3. 以我的博客为例，这张图片现在的最终地址默认是 `https://blog.linshen.me/assets/img/posts/screenshot.png`。

4. 把前面 `https://blog.linshen.me` 换成 `https://cdn.statically.io/gh/shawnlinboy/shawnlinboy.github.io@master`。其中 `gh` 是告诉 `statically` 这是一个 `github` 的项目，后面是`你的用户名/github pages 仓库地址@主要分支`，因人而异，理解后再复制粘贴。

5. 每张图都要换地址很麻烦是不是？不要忘记 `_config.yml` 里有 `img_cdn` 可以填。打开博客项目根目录的 `_config.yml`，把你上一步换成的内容，填到 `img_cdn` 后面即可。

效果对比
===

没有 CDN

![](https://blog.linshen.me/assets/img/posts/caldigit-ts4-front.png)

有 CDN
![](https://cdn.statically.io/gh/shawnlinboy/shawnlinboy.github.io@master/assets/img/posts/caldigit-ts4-front.png)