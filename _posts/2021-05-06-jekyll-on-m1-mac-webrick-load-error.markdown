---
layout: post
title: "Apple Silicon Mac 找不到 jekyll 以及 webrick 错误的解决方案"
category: Web
tags: Jekyll WEBrick Mac M1
---

周末入了一台 M1 芯片的 2020 款 Macbook Air，这两天陆陆续续把各种环境都搭得差不多了。

## Ruby

`Ruby` 方面，如果你使用 `homebrew` 安装，脚本会自动识别你的机器，我得到的是 `3.0.1p64` 版本，看起来这个版本已经是完整支持 Apple Silicon 的版本了。

```bash
$ ruby -v
ruby 3.0.1p64 (2021-04-05 revision 0fb782ee38) [arm64-darwin20]
```

## Jekyll

`Jekyll` 的安装按照[官方文档](https://jekyllrb.com/)来就好。

如果你 `brew install` 之后仍然提示找不到 `jekyll`，检查一下你的 `/opt/homebrew/lib/ruby/gems/3.0.0/bin`，它应该被装到这里了。

## Cannot load such file -- webrick

如果你足够幸运，在搞定一切之后，会在编译时喜提下面一个报错：

```
                    ------------------------------------------------
      Jekyll 4.2.0   Please append `--trace` to the `serve` command 
                     for any additional information or backtrace. 
                    ------------------------------------------------
/opt/homebrew/lib/ruby/gems/3.0.0/gems/jekyll-4.2.0/lib/jekyll/commands/serve/servlet.rb:3:in `require': cannot load such file -- webrick (LoadError)
	from /opt/homebrew/lib/ruby/gems/3.0.0/gems/jekyll-4.2.0/lib/jekyll/commands/serve/servlet.rb:3:in `<top (required)>'
	from /opt/homebrew/lib/ruby/gems/3.0.0/gems/jekyll-4.2.0/lib/jekyll/commands/serve.rb:179:in `require_relative'
	from /opt/homebrew/lib/ruby/gems/3.0.0/gems/jekyll-4.2.0/lib/jekyll/commands/serve.rb:179:in `setup'
	from /opt/homebrew/lib/ruby/gems/3.0.0/gems/jekyll-4.2.0/lib/jekyll/commands/serve.rb:100:in `process'
	from /opt/homebrew/lib/ruby/gems/3.0.0/gems/jekyll-4.2.0/lib/jekyll/command.rb:91:in `block in process_with_graceful_fail'
	from /opt/homebrew/lib/ruby/gems/3.0.0/gems/jekyll-4.2.0/lib/jekyll/command.rb:91:in `each'
	from /opt/homebrew/lib/ruby/gems/3.0.0/gems/jekyll-4.2.0/lib/jekyll/command.rb:91:in `process_with_graceful_fail'
	from /opt/homebrew/lib/ruby/gems/3.0.0/gems/jekyll-4.2.0/lib/jekyll/commands/serve.rb:86:in `block (2 levels) in init_with_program'
	from /opt/homebrew/lib/ruby/gems/3.0.0/gems/mercenary-0.4.0/lib/mercenary/command.rb:221:in `block in execute'
	from /opt/homebrew/lib/ruby/gems/3.0.0/gems/mercenary-0.4.0/lib/mercenary/command.rb:221:in `each'
	from /opt/homebrew/lib/ruby/gems/3.0.0/gems/mercenary-0.4.0/lib/mercenary/command.rb:221:in `execute'
	from /opt/homebrew/lib/ruby/gems/3.0.0/gems/mercenary-0.4.0/lib/mercenary/program.rb:44:in `go'
	from /opt/homebrew/lib/ruby/gems/3.0.0/gems/mercenary-0.4.0/lib/mercenary.rb:21:in `program'
	from /opt/homebrew/lib/ruby/gems/3.0.0/gems/jekyll-4.2.0/exe/jekyll:15:in `<top (required)>'
	from /opt/homebrew/lib/ruby/gems/3.0.0/bin/jekyll:23:in `load'
	from /opt/homebrew/lib/ruby/gems/3.0.0/bin/jekyll:23:in `<main>'
```

这是因为 `3.0` 版本的 `ruby` 没带 `webrick` 导致的。网上一搜，大部分教程是让降到 `2.7.0` 版本的 `ruby`。WTF？我买了 M1 的 Mac 就是为了尽量不跑 x86 架构应用的好吗？

正确做法：

```bash
bundle add webrick
```
然后 `bundle` 会帮你搞定一切

```
Fetching gem metadata from https://rubygems.org/...........
Resolving dependencies...
Fetching gem metadata from https://rubygems.org/...........
Resolving dependencies...
Using public_suffix 4.0.6
Using bundler 2.2.17
Using colorator 1.1.0
Using concurrent-ruby 1.1.8
Using eventmachine 1.2.7
Using http_parser.rb 0.6.0
Using ffi 1.15.0
Using forwardable-extended 2.6.0
Using mercenary 0.4.0
Using racc 1.5.2
Using parallel 1.20.1
Using rainbow 3.0.0
Using yell 2.2.2
Using rb-fsevent 0.10.4
Using rexml 3.2.5
Using liquid 4.0.3
Using rouge 3.26.0
Using safe_yaml 1.0.5
Using unicode-display_width 1.7.0
Using jekyll-paginate 1.1.0
Using webrick 1.7.0
Using nokogiri 1.11.3 (arm64-darwin)
Using kramdown 2.3.1
Using terminal-table 2.0.0
Using nokogumbo 2.0.5
Using addressable 2.7.0
Using em-websocket 0.5.2
Using ethon 0.14.0
Using sassc 2.4.0
Using rb-inotify 0.10.1
Using kramdown-parser-gfm 1.1.0
Using typhoeus 1.4.0
Using jekyll-sass-converter 2.1.0
Using listen 3.5.1
Using html-proofer 3.19.1
Using i18n 1.8.10
Using jekyll-watch 2.2.1
Using pathutil 0.16.2
Using jekyll 4.2.0
Using jekyll-archives 2.2.1
Using jekyll-redirect-from 0.16.0
Using jekyll-sitemap 1.4.0
Using jekyll-seo-tag 2.7.1
Using jekyll-theme-chirpy 3.3.2
```

最后愉快地 `jekyll serve` 就好了。

