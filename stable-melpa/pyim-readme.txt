* pyim 使用说明                                          :README:doc:
** 截图
[[./snapshots/pyim-linux-x-with-toolkit.png]]

** 简介
pyim 是 Emacs 环境下的一个中文输入法，最初它只支持全拼输入，所以当时
"pyim" 代表 "Chinese Pinyin Input Method" 的意思，后来根据同学的提议，
添加了五笔的支持，再叫 “拼音输入法” 就不太合适了，所以你现在可以将它理解
为 “PengYou input method”： 平时像朋友一样帮助你，偶尔也像朋友一样犯二 。。。

** 背景
pyim 的代码源自 emacs-eim。

emacs-eim 是 Emacs 环境下的一个中文输入法框架， 支持拼音，五笔，仓颉以及二笔等
多种输入法，但遗憾的是，2008 年之后它就停止了开发，我认为主要原因是外部中文输入法快速发展。

虽然外部输入法功能强大，但不能和 Emacs 默契的配合，这一点极大的损害了 Emacs 那种 *行云流水*
的感觉。而本人在使用（或者叫折腾） emacs-eim 的过程中发现：

1. *当 emacs-eim 词库词条超过 100 万时，选词频率大大降低，中文体验增强。*
3. *随着使用时间的延长，emacs-eim 会越来越好用（个人词库的积累）。*

于是我 fork 了 emacs-eim 输入法的部分代码, 创建了一个项目：pyim。

** 目标
pyim 的目标是： *尽最大的努力成为一个好用的 Emacs 中文输入法* ，
具体可表现为三个方面：

1. Fallback:     当外部输入法不能使用时，比如在 console 或者 cygwin 环境
   下，尽最大可能让 Emacs 用户不必为输入中文而烦恼。
2. Integration:  尽最大可能减少输入法切换频率，让中文输入不影响 Emacs
   的体验。
3. Exchange:     尽最大可能简化 pyim 使用其他优秀输入法的词库
   的难度和复杂度。

** 特点
1. pyim 支持全拼，双拼，五笔和仓颉，其中对全拼的支持最好。
2. pyim 通过添加词库的方式优化输入法。
3. pyim 使用文本词库格式，方便处理。

** 安装
1. 配置 melpa 源，参考：http://melpa.org/#/getting-started
2. M-x package-install RET pyim RET
3. 在 Emacs 配置文件中（比如: ~/.emacs）添加如下代码：
   #+BEGIN_EXAMPLE
   (require 'pyim)
   (require 'pyim-basedict) ; 拼音词库设置，五笔用户 *不需要* 此行设置
   (pyim-basedict-enable)   ; 拼音词库，五笔用户 *不需要* 此行设置
   (setq default-input-method "pyim")
   #+END_EXAMPLE

** 配置

*** 配置实例
对 pyim 感兴趣的同学，可以看看本人的 pyim 配置（总是适用于最新版的 pyim）:

#+BEGIN_EXAMPLE
(use-package pyim
  :ensure nil
  :demand t
  :config
  ;; 激活 basedict 拼音词库，五笔用户请继续阅读 README
  (use-package pyim-basedict
    :ensure nil
    :config (pyim-basedict-enable))

  (setq default-input-method "pyim")

  ;; 我使用全拼
  (setq pyim-default-scheme 'quanpin)

  ;; 设置 pyim 探针设置，这是 pyim 高级功能设置，可以实现 *无痛* 中英文切换 :-)
  ;; 我自己使用的中英文动态切换规则是：
  ;; 1. 光标只有在注释里面时，才可以输入中文。
  ;; 2. 光标前是汉字字符时，才能输入中文。
  ;; 3. 使用 M-j 快捷键，强制将光标前的拼音字符串转换为中文。
  (setq-default pyim-english-input-switch-functions
                '(pyim-probe-dynamic-english
                  pyim-probe-isearch-mode
                  pyim-probe-program-mode
                  pyim-probe-org-structure-template))

  (setq-default pyim-punctuation-half-width-functions
                '(pyim-probe-punctuation-line-beginning
                  pyim-probe-punctuation-after-punctuation))

  ;; 开启拼音搜索功能
  (pyim-isearch-mode 1)

  ;; 使用 pupup-el 来绘制选词框, 如果用 emacs26, 建议设置
  ;; 为 'posframe, 速度很快并且菜单不会变形，不过需要用户
  ;; 手动安装 posframe 包。
  (setq pyim-page-tooltip 'popup)

  ;; 选词框显示5个候选词
  (setq pyim-page-length 5)

  :bind
  (("M-j" . pyim-convert-string-at-point) ;与 pyim-probe-dynamic-english 配合
   ("C-;" . pyim-delete-word-from-personal-buffer)))
#+END_EXAMPLE

*** 添加词库文件
pyim 当前的默认的拼音词库是 pyim-basedict, 这个词库的词条量
8 万左右，是一个 *非常小* 的拼音词库，词条的来源有两个：

1. libpinyin 项目的内置词库
2. pyim 用户贡献的个人词库

如果 pyim-basedict 不能满足需求，用户可以使用其他方式为 pyim 添加拼音词库，
具体方式请参考 [[如何添加自定义拼音词库]] 小结。

*** 激活 pyim

#+BEGIN_EXAMPLE
(setq default-input-method "pyim")
(global-set-key (kbd "C-\\") 'toggle-input-method)
#+END_EXAMPLE

** 使用
*** 常用快捷键
| 输入法快捷键          | 功能                       |
|-----------------------+----------------------------|
| C-n 或 M-n 或 + 或 .  | 向下翻页                   |
| C-p 或 M-p 或 - 或 ,  | 向上翻页                   |
| C-f                   | 选择下一个备选词           |
| C-b                   | 选择上一个备选词           |
| SPC                   | 确定输入                   |
| RET 或 C-m            | 字母上屏                   |
| C-c                   | 取消输入                   |
| C-g                   | 取消输入并保留已输入的中文 |
| TAB                   | 模糊音调整                 |
| DEL 或 BACKSPACE      | 删除最后一个字符           |
| C-DEL 或  C-BACKSPACE | 删除最后一个拼音           |
| M-DEL 或  M-BACKSPACE | 删除最后一个拼音           |

*** 使用双拼模式
pyim 支持双拼输入模式，用户可以通过变量 `pyim-default-scheme' 来设定：

#+BEGIN_EXAMPLE
(setq pyim-default-scheme 'pyim-shuangpin)
#+END_EXAMPLE

注意：
1. pyim 支持微软双拼（microsoft-shuangpin）和小鹤双拼（xiaohe-shuangpin）。
2. 用户可以使用变量 `pyim-schemes' 添加自定义双拼方案。
3. 用户可能需要重新设置 `pyim-translate-trigger-char'。

*** 通过 pyim 来支持 rime 所有输入法

pyim 使用 emacs 动态模块：[[https://gitlab.com/liberime/liberime][liberime]]
来支持 rime, 设置方式：

1. 安裝 liberime, 见：[[https://gitlab.com/liberime/liberime/blob/master/README.org]] 。
2. 參考设置：
   #+BEGIN_EXAMPLE
   (use-package liberime
     :load-path "/path/to/liberime.[so|dll]"
     :config
     (liberime-start "/usr/share/rime-data" "~/.emacs.d/rime/")
     (liberime-select-schema "luna_pinyin_simp")
     (setq pyim-default-scheme 'rime))
   #+END_EXAMPLE
3. 使用 rime 全拼输入法的用户，也可以使用 rime-quanpin scheme,
   这个 scheme 是专门针对 rime 全拼输入法定制的，支持全拼v快捷键。
   #+BEGIN_EXAMPLE
   (setq pyim-default-scheme 'rime-quanpin)
   #+END_EXAMPLE

*** 使用五笔输入
pyim 支持五笔输入模式，用户可以通过变量 `pyim-default-scheme' 来设定：

#+BEGIN_EXAMPLE
(setq pyim-default-scheme 'wubi)
#+END_EXAMPLE

在使用五笔输入法之前，请用 pyim-dicts-manager 添加一个五笔词库，词库的格式类似：

#+BEGIN_EXAMPLE
-*- coding: utf-8-unix -*-
.aaaa 工
.aad 式
.aadk 匿
.aadn 慝 葚
.aadw 萁
.aafd 甙
.aaff 苷
.aaht 芽
.aak 戒
#+END_EXAMPLE

最简单的方式是从 melpa 中安装 pyim-wbdict 包，然后根据它的
[[https://github.com/tumashu/pyim-wbdict][README]] 来配置。

另外 Ye FeiYu 同学维护着 pyim-wbdict 的一个 fork, 里面包含着极点
五笔和清歌五笔的词库，不做发布，有兴趣的同学可以了解一下：

    https://github.com/yefeiyu/pyim-wbdict

如果用户在使用五笔输入法的过程中，忘记了某个字的五笔码，可以按 TAB
键临时切换到辅助输入法来输入，选词完成之后自动退出。辅助输入法可以
通过 `pyim-assistant-scheme' 来设置。

*** 使用仓颉输入法
pyim 支持仓颉输入法，用户可以通过变量 `pyim-default-scheme' 来设定：

#+BEGIN_EXAMPLE
(setq pyim-default-scheme 'cangjie)
#+END_EXAMPLE

在使用仓颉输入法之前，请用 pyim-dicts-manager 添加一个仓颉词库，词库的格式类似：

#+BEGIN_EXAMPLE
-*- coding: utf-8-unix -*-
@a 日
@a 曰
@aa 昌
@aa 昍
@aaa 晶
@aaa 晿
@aaah 曑
#+END_EXAMPLE

如果用户使用仓颉第五代，最简单的方式是从 melpa 中安装 pyim-cangjie5dict 包，
然后根据它的 [[https://github.com/erstern/pyim-cangjie5dict][README]] 来配置。
pyim 支持其它版本的仓颉，但需要用户自己创建词库文件。

用户可以使用命令：`pyim-search-word-code' 来查询当前选择词条的仓颉编码

*** 让选词框跟随光标
用户可以通过下面的设置让 pyim 在 *光标处* 显示一个选词框：

1. 使用 popup 包来绘制选词框 （emacs overlay 机制）
   #+BEGIN_EXAMPLE
   (setq pyim-page-tooltip 'popup)
   #+END_EXAMPLE
2. 使用 posframe 来绘制选词框
   #+BEGIN_EXAMPLE
   (setq pyim-page-tooltip 'posframe)
   #+END_EXAMPLE
   注意：pyim 不会自动安装 posframe, 用户需要手动安装这个包，

*** 调整 tooltip 选词框的显示样式
pyim 的 tooltip 选词框默认使用 *双行显示* 的样式，在一些特
殊的情况下（比如：popup 显示的菜单错位），用户可以使用 *单行显示*
的样式：

#+BEGIN_EXAMPLE
(setq pyim-page-style 'one-line)
#+END_EXAMPLE

注：用户可以添加函数 pyim-page-style:STYLENAME 来定义自己的选词框格式。

*** 设置模糊音
可以通过设置 `pyim-fuzzy-pinyin-alist' 变量来自定义模糊音。

*** 使用魔术转换器
用户可以将待选词条作 “特殊处理” 后再 “上屏”，比如 “简体转繁体” 或者
“输入中文，上屏英文” 之类的。

用户需要设置 `pyim-magic-converter', 比如：下面这个例子实现，
输入 “二呆”，“一个超级帅的小伙子” 上屏 :-)
#+BEGIN_EXAMPLE
(defun my-converter (string)
  (if (equal string "二呆")
      "“一个超级帅的小伙子”"
    string))
(setq pyim-magic-converter #'my-converter)
#+END_EXAMPLE

*** 切换全角标点与半角标点

1. 第一种方法：使用命令 `pyim-punctuation-toggle'，全局切换。
   这个命令主要用来设置变量： `pyim-punctuation-translate-p', 用户也可以
   手动设置这个变量， 比如：
   #+BEGIN_EXAMPLE
   (setq pyim-punctuation-translate-p '(yes no auto))   ;使用全角标点。
   (setq pyim-punctuation-translate-p '(no yes auto))   ;使用半角标点。
   (setq pyim-punctuation-translate-p '(auto yes no))   ;中文使用全角标点，英文使用半角标点。
   #+END_EXAMPLE
2. 第二种方法：使用命令 `pyim-punctuation-translate-at-point' 只切换光
   标处标点的样式。
3. 第三种方法：设置变量 `pyim-translate-trigger-char' ，输入变量设定的
   字符会切换光标处标点的样式。

*** 手动加词和删词

1. `pyim-create-Ncchar-word-at-point 这是一组命令，从光标前提取N个汉
   字字符组成字符串，并将其加入个人词库。
2. `pyim-translate-trigger-char' 以默认设置为例：在“我爱吃红烧肉”后输
   入“5v” 可以将“爱吃红烧肉”这个词条保存到用户个人词库。
3. `pyim-create-word-from-selection', 选择一个词条，运行这个命令后，就
   可以将这个词条添加到个人词库。
4. `pyim-delete-word' 从个人词库中删除当前高亮选择的词条。

*** pyim 高级功能
1. 根据环境自动切换到英文输入模式，使用 pyim-english-input-switch-functions 配置。
2. 根据环境自动切换到半角标点输入模式，使用 pyim-punctuation-half-width-functions 配置。

注意：上述两个功能使用不同的变量设置， *千万不要搞错* 。

**** 根据环境自动切换到英文输入模式

| 探针函数                          | 功能说明                                                                          |
|-----------------------------------+-----------------------------------------------------------------------------------|
| pyim-probe-program-mode           | 如果当前的 mode 衍生自 prog-mode，那么仅仅在字符串和 comment 中开启中文输入模式   |
|-----------------------------------+-----------------------------------------------------------------------------------|
| pyim-probe-org-speed-commands     | 解决 org-speed-commands 与 pyim 冲突问题                                          |
| pyim-probe-isearch-mode           | 使用 isearch 搜索时，强制开启英文输入模式                                         |
|                                   | 注意：想要使用这个功能，pyim-isearch-mode 必须激活                                |
|-----------------------------------+-----------------------------------------------------------------------------------|
| pyim-probe-org-structure-template | 使用 org-structure-template 时，关闭中文输入模式                                  |
|-----------------------------------+-----------------------------------------------------------------------------------|
|                                   | 1. 当前字符为中文字符时，输入下一个字符时默认开启中文输入                         |
| pyim-probe-dynamic-english        | 2. 当前字符为其他字符时，输入下一个字符时默认开启英文输入                         |
|                                   | 3. 使用命令 pyim-convert-string-at-point 可以将光标前的拼音字符串强制转换为中文。   |
|-----------------------------------+-----------------------------------------------------------------------------------|

激活方式：

#+BEGIN_EXAMPLE
(setq-default pyim-english-input-switch-functions
              '(probe-function1 probe-function2 probe-function3))
#+END_EXAMPLE

注：上述函数列表中，任意一个函数的返回值为 t 时，pyim 切换到英文输入模式。

**** 根据环境自动切换到半角标点输入模式

| 探针函数                                 | 功能说明                   |
|------------------------------------------+----------------------------|
| pyim-probe-punctuation-line-beginning    | 行首强制输入半角标点       |
|------------------------------------------+----------------------------|
| pyim-probe-punctuation-after-punctuation | 半角标点后强制输入半角标点 |
|------------------------------------------+----------------------------|

激活方式：

#+BEGIN_EXAMPLE
(setq-default pyim-punctuation-half-width-functions
              '(probe-function4 probe-function5 probe-function6))
#+END_EXAMPLE

注：上述函数列表中，任意一个函数的返回值为 t 时，pyim 切换到半角标点输入模式。

** 捐赠
您可以通过小额捐赠的方式支持 pyim 的开发工作，具体方式：

1. 通过支付宝收款账户：tumashu@163.com
2. 通过支付宝钱包扫描：

   [[file:snapshots/QR-code-for-author.jpg]]


** Tips

*** 如何将个人词条相关信息导入和导出？

1. 导入使用命令： pyim-import
2. 导出使用命令： pyim-export

*** pyim 出现错误时，如何开启 debug 模式

#+BEGIN_EXAMPLE
(setq debug-on-error t)
#+END_EXAMPLE

*** 如何查看 pyim 文档。
pyim 的文档隐藏在 comment 中，如果用户喜欢阅读 html 格式的文档，
可以查看在线文档；

  http://tumashu.github.io/pyim/

*** 将光标处的拼音或者五笔字符串转换为中文 (与 vimim 的 “点石成金” 功能类似)
#+BEGIN_EXAMPLE
(global-set-key (kbd "M-i") 'pyim-convert-string-at-point)
#+END_EXAMPLE

*** 如何添加自定义拼音词库
pyim 默认没有携带任何拼音词库，用户可以使用下面几种方式，获取
质量较好的拼音词库：

**** 第一种方式 (懒人推荐使用)

获取其他 pyim 用户的拼音词库，比如，某个同学测试 pyim
时创建了一个中文拼音词库，词条数量大约60万。

   http://tumashu.github.io/pyim-bigdict/pyim-bigdict.pyim.gz

下载上述词库后，运行 `pyim-dicts-manager' ，按照命令提示，将下载得到的词库
文件信息添加到 `pyim-dicts' 中，最后运行命令 `pyim-restart' 或者重启
emacs，这个词库使用 `utf-8-unix' 编码。

**** 第二种方式 (Windows 用户推荐使用)

使用词库转换工具将其他输入法的词库转化为pyim使用的词库：这里只介绍windows平
台下的一个词库转换软件：

1. 软件名称： imewlconverter
2. 中文名称： 深蓝词库转换
3. 下载地址： https://github.com/studyzy/imewlconverter
4. 依赖平台： Microsoft .NET Framework (>= 3.5)

使用方式：

[[file:snapshots/imewlconverter-basic.gif]]

如果生成的词库词频不合理，可以按照下面的方式处理（非常有用的功能）：

[[file:snapshots/imewlconverter-wordfreq.gif]]

生成词库后，运行 `pyim-dicts-manager' ，按照命令提示，将转换得到的词库文件的信息添加到 `pyim-dicts' 中，
完成后运行命令 `pyim-restart' 或者重启emacs。

**** 第三种方式 (Linux & Unix 用户推荐使用)
E-Neo 同学编写了一个词库转换工具: [[https://github.com/E-Neo/scel2pyim][scel2pyim]] ,
可以将一个搜狗词库转换为 pyim 词库。

1. 软件名称： scel2pyim
2. 下载地址： https://github.com/E-Neo/scel2pyim
3. 编写语言： C语言

*** 如何手动安装和管理词库
这里假设有两个词库文件：

1. /path/to/pyim-dict1.pyim
2. /path/to/pyim-dict2.pyim

在~/.emacs文件中添加如下一行配置。

#+BEGIN_EXAMPLE
(setq pyim-dicts
      '((:name "dict1" :file "/path/to/pyim-dict1.pyim")
        (:name "dict2" :file "/path/to/pyim-dict2.pyim")))
#+END_EXAMPLE

注意事项:
1. 只有 :file 是 *必须* 设置的。
2. 必须使用词库文件的绝对路径。
3. 词库文件的编码必须为 utf-8-unix，否则会出现乱码。

*** Emacs 启动时加载 pyim 词库

#+BEGIN_EXAMPLE
(add-hook 'emacs-startup-hook
          #'(lambda () (pyim-restart-1 t)))
#+END_EXAMPLE

*** 将汉字字符串转换为拼音字符串
下面两个函数可以将中文字符串转换的拼音字符串或者列表，用于 emacs-lisp
编程。

1. `pyim-hanzi2pinyin' （考虑多音字）
2. `pyim-hanzi2pinyin-simple'  （不考虑多音字）

*** 中文分词
pyim 包含了一个简单的分词函数：`pyim-cstring-split-to-list', 可以
将一个中文字符串分成一个词条列表，比如：

#+BEGIN_EXAMPLE
                  (("天安" 5 7)
我爱北京天安门 ->  ("天安门" 5 8)
                   ("北京" 3 5)
                   ("我爱" 1 3))
#+END_EXAMPLE

其中，每一个词条列表中包含三个元素，第一个元素为词条本身，第二个元素为词条
相对于字符串的起始位置，第三个元素为词条结束位置。

另一个分词函数是 `pyim-cstring-split-to-string', 这个函数将生成一个新的字符串，
在这个字符串中，词语之间用空格或者用户自定义的分隔符隔开。

注意，上述两个分词函数使用暴力匹配模式来分词，所以， *不能检测出* pyim
词库中不存在的中文词条。

*** 获取光标处的中文词条
pyim 包含了一个简单的命令：`pyim-cwords-at-point', 这个命令
可以得到光标处的 *英文* 或者 *中文* 词条的 *列表*，这个命令依赖分词函数：
`pyim-cstring-split-to-list'。

*** 让 `forward-word' 和 `back-backward’ 在中文环境下正常工作
中文词语没有强制用空格分词，所以 Emacs 内置的命令 `forward-word' 和 `backward-word'
在中文环境不能按用户预期的样子执行，而是 forward/backward “句子” ，pyim
自带的两个命令可以在中文环境下正常工作：

1. `pyim-forward-word
2. `pyim-backward-word

用户只需将其绑定到快捷键上就可以了，比如：

#+BEGIN_EXAMPLE
(global-set-key (kbd "M-f") 'pyim-forward-word)
(global-set-key (kbd "M-b") 'pyim-backward-word)
#+END_EXAMPLE

*** 为 isearch 相关命令添加拼音搜索支持
pyim 安装后，可以通过下面的设置开启拼音搜索功能：

#+BEGIN_EXAMPLE
(pyim-isearch-mode 1)
#+END_EXAMPLE

注意：这个功能有一些限制，搜索字符串中只能出现 “a-z” 和 “’”，如果有
其他字符（比如 regexp 操作符），则自动关闭拼音搜索功能。

开启这个功能后，一些 isearch 扩展有可能失效，如果遇到这种问题，
只能禁用这个 Minor-mode，然后联系 pyim 的维护者，看有没有法子实现兼容。

用户激活这个 mode 后，可以使用下面的方式 *强制关闭* isearch 搜索框中文输入
（即使在 pyim 激活的时候）。

#+BEGIN_EXAMPLE
(setq-default pyim-english-input-switch-functions
              '(pyim-probe-isearch-mode))
#+END_EXAMPLE
