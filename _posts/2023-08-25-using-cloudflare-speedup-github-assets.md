---
layout: post
title: "使用 Cloudflare Workers 加速 Github 静态资源"
category: Web
tags: github cloudflare
---

今天更新一篇文章，教大家如何利用 Cloudflare Workers 搭建一个 Github 图片资源的反代。

说是反代，其实说白了就是一个简单的 url 替换，让它走一遍 Cloudflare 的 CDN。另外，除了图片，理论上所有 `raw.githubusercontent.com` 开头的静态资源应该都没问题。

开始之前不得不再次感慨，Cloudflare 真的是互联网公司的大善人，这一切居然是免费的。

### 具体步骤

打开 Cloudflare 主页，进到你要使用的域名，点击左侧的 Workers & Pages, 然后右边 “Create Application"

![](Capture-180.png)

然后在创建页面点击 "Create Worker" ，下一步。

![](Capture-181.png)

取一个你喜欢的 Name，比如我直接叫 “img”，下面的代码保持默认，然后点击 "Deploy"（不用理会下方截图上 Name 后面的 Not available，是因为写文章的时候我已经创建完一个了）

![](Capture-182.png)

Cloudflare 这一点比较奇怪，必须先部署了才给编辑代码，点击 "Edit code"

![](Capture-183.png)

修改 worker.js 如下：
```js
addEventListener("fetch", event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  // Cloudflare Workers 分配的域名
  cf_worker_host = "img.cloudflareusername.workers.dev";
  // 自定义的域名
  origin_host = "img.linshen.me";
  // GitHub 仓库文件地址
  github_host = "raw.githubusercontent.com/shawnlinboy/shawnlinboy.github.io/main/assets/img/posts";
  // 替换 2 次以同时兼容 Worker 来源和域名来源
  url = request.url.replace(cf_worker_host, github_host).replace(origin_host, github_host);
  return fetch(url);
}
```

`cf_worker_host`：你的 Worker 源地址，可以在右边的调试窗口看到，直接复制粘贴。

`origin_host`：你的图片地址域名

`github_host`：你 GitHub 仓库 assest 文件目录

大家千万要理解了再替换成自己的，不要闭眼抄。写完了点右上角 "Save and deploy"

最后不要忘记绑定域名和做一下地址转发。点击你刚才新建的 Worker 里面的 "Triggers"，在 `Custom Domains` 里输入上面的 `origin_host`，再在 `Routes` 里绑定 `origin_host` 的所有 path，比如我这里就是 `img.linshen.me/*`

![](Capture-184.png)

![](Capture-185.png)

大功告成！

### Jeklly CDN 设置

如果你在用的 Jeklly 主题有 CDN 相关的设置，可以编辑 `_config.yml` 把图片前缀替换掉，比如我使用的 [Chirpy 主题](https://github.com/cotes2020/jekyll-theme-chirpy)就提供了这个功能。

```yaml
# The CDN endpoint for images.
# Notice that once it is assigned, the CDN url
# will be added to all image (site avatar & posts' images) paths starting with '/'
#
# e.g. 'https://cdn.com'
img_cdn: https://img.linshen.me
```

### 参考文章

https://senjianlu.com/2021/12/cloudflare-workers-image/
