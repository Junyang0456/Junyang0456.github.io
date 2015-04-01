---
title: Linux 基础 —— Grep 和正则表达式
author: Liao
layout: post
permalink:  /linux-basic-grep/
category:
tags:
  - Basic
---
{% include JB/setup %}

最近开始参加马哥 Linux 培训，这里记录下来学习的笔记和心得。

这篇文章主要讲 grep 工具和正则表达式。

<!--more-->

## Grep 是什么

grep 的全称是 Global Regular Expression Print，它是 Linux 中一个用来进行对文本内容进行搜索和匹配的命令行工具，grep 支持正则表达式，学好 grep 也是学好 awk, sed 等工具的前提。

![](/images/grep.png)

在 Linux 中最流行的 grep 版本是 GNU grep，实际上 grep 共有三个相关的命令。

grep 命令使用 [GNU Basic Regular Expressions syntax 基本正则表达式](http://www.regular-expressions.info/gnu.html#bre)进行匹配。

egrep 命令相当于 `grep -E` ，使用[GNU Extended Regular Expressions syntax 扩展正则表达式](http://www.regular-expressions.info/gnu.html#ere)进行匹配。

fgrep 命令相当于 `grep -F` ，不使用任何正则表达式，直接进行字符串匹配。

![](/images/hello-world/hello-world.png)

## Grep 命令的语法

	grep [OPTIONS] PATTERN [FILE...]
	
		--color：对匹配的字符串着色打印
		-o：只显示被模式匹配到的内容
		-c：打印出匹配到字符串的行数
	 	-i：ignore case，不区分字符大小写
	 	-v：显示不能够被模式匹配到的行
	 	-E：使用扩展的正则表达式
		-n：打印出匹配字符串的在文件中的行号
		-R, -r：递归所有文件夹中的每一个文件
		-l：打印出含有匹配字符串的文件名，而不是匹配的内容
		-L：打印出没有包含匹配字符串的文件名，与 -l 选项相反
		-H：对每个匹配的字符串打印出字符串所在的文件名
		-h：不打印匹配字符串所在文件的文件名
	 	-A N：打印匹配字符串的同时打印匹配字符串所有行的前 N 行
	 	-B N：打印匹配字符串的同时打印匹配字符串所在行的后 N 行
	 	-C N：打印匹配字符串的同时打印匹配字符串所在行的前 N 行 和 后 N 行
		--exclude=GLOB：跳过 GLOB 匹配的文件名进行搜索
		--exclude-dir=DIR：在递归搜索时跳过 DIR 指定的文件夹
		注意： grep 是以行为单位进行匹配的，因此如果一个字符串跨越了多行将不能被匹配，使用 -c 选项的统计结果也是行数

## 范例
打印出匹配的行号

	[root@localhost ~]# grep -n "root" /etc/passwd
	1:root:x:0:0:root:/root:/bin/bash
	11:operator:x:11:0:operator:/root:/sbin/nologin

仅打印匹配的字符串本身

	[root@localhost ~]# grep -o "root" /etc/passwd
	root
	root
	root
	root

仅打印匹配到字符串的文件名

	[root@localhost ~]# grep -l "root" /etc/passwd /etc/group /etc/profile
	/etc/passwd
	/etc/group

不区分大小写匹配

	[root@localhost ~]# grep -i "RoOt" /etc/passwd
	root:x:0:0:root:/root:/bin/bash
	operator:x:11:0:operator:/root:/sbin/nologin

同时打印出匹配字符串所在行的后三行

	[root@localhost ~]# grep -A 3 -i "ROOT" /etc/passwd
	root:x:0:0:root:/root:/bin/bash
	bin:x:1:1:bin:/bin:/sbin/nologin
	daemon:x:2:2:daemon:/sbin:/sbin/nologin
	adm:x:3:4:adm:/var/adm:/sbin/nologin
	--
	operator:x:11:0:operator:/root:/sbin/nologin
	games:x:12:100:games:/usr/games:/sbin/nologin
	gopher:x:13:30:gopher:/var/gopher:/sbin/nologin
	ftp:x:14:50:FTP User:/var/ftp:/sbin/nologin

# 正则表达式
在对字符串进行匹配时，直接使用字符串进行匹配固然可行，但是在对复杂的或是按某种规律变化的字符串进行匹配时，直接使用字符串匹配的效率将非常低下。

正则表达式定义了一系列的元字符，定位符等，使用这些特殊字符组成成一种模式，能够匹配更复杂的字符串。

基本正则表达式元字符：	

**字符匹配**：

`. `：匹配任意单个字符

`[]`：匹配指定范围内的任意单个字符

`[^]`：匹配指定范围外的任意单个字符

`[0-9]`：匹配数组 0-9 的任意一个

`[[:digit:]]`：匹配任意单个数字

`[[:lower:]]`：匹配任意单个小写字母

`[[:upper:]]`： 匹配任意单个大写字母

`[[:space:]]`：匹配任意单个空白字符

`[[:punct:]]`：匹配任意单个标点符号

`[[:alpha:]]`：匹配任意单个英文字母

`[[:alnum:]]`：匹配任意单个字母或数字

**次数匹配**：在期望匹配的字符后面提供一个控制符，用于表达匹配其前面字符指定的次数

`*` : 匹配前面的字符任意次

`.* `：匹配任意次 `.`，即匹配任意长度的任意字符

`?` ：匹配前面的字符 0 次或者 1 次

`+` ： 匹配前面的字符 1 次或多次

`{m}`：匹配前面的字符 m 次

`{m,n}`：匹配前面的字符至少 m 次，至多 n 次

`{m,}`：匹配前面的字符至少 m 次

`{,n}`：匹配前面的字符至多 n 次

**位置锚定**：

`^`：匹配行首

`$`：匹配行尾

`\< 或 \b`：匹配词首

`\> 或 \b`：匹配词尾

**分组**：

可以使用括号将一组字符括起来，表示这一组字符被当作一个整体，还可以使用 \1, \2 对前面括号匹配所匹配的字符串进行引用。

基本正则表达式和扩展正则表达式的区别在于，基本正则表达式中很多元字符需要先使用 `\` 进行转义，为了方便，在使用正则表达式时建议直接使用 `egrep` 或者 `grep -E`，以免使用过多的转义符。

**示例**： 

这里使用一个示例文件进行演示：

    [root@localhost ~]# cat mysampledata.txt 
    Fred apples 20
    Susy oranges 5
    Mark watermellons 12
    Robert pears 4
    Terry oranges 9
    Lisa peaches 7
    Susy oranges 12
    Mark grapes 39
    Anne mangoes 7
    Greg pineapples 3
    Oliver rockmellons 2
    Betty limes 14

这里演示了次数匹配 `{}` 的用法

    [root@localhost ~]# egrep '[aeiou]{2,}' mysampledata.txt
    Robert pears 4
    Lisa peaches 7
    Anne mangoes 7
    Greg pineapples 3

`+` 表示能够匹配前面的字符 1 次或多次

    [root@localhost ~]# egrep '2.+' mysampledata.txt
    Fred apples 20

匹配 "2" 在行尾的行

    [root@localhost ~]# egrep '2$' mysampledata.txt
    Mark watermellons 12
    Susy oranges 12
    Oliver rockmellons 2

匹配 "or" 或 "go" 或 "is" 字符串
  
    [root@localhost ~]# egrep 'or|is|go' mysampledata.txt
    Susy oranges 5
    Terry oranges 9
    Lisa peaches 7
    Susy oranges 12
    Anne mangoes 7

匹配以 A - K 中任意字符开头的行

    [root@localhost ~]# egrep '^[A-K]' mysampledata.txt
    Fred apples 20
    Anne mangoes 7
    Greg pineapples 3
    Betty limes 14

**几个复杂的例子**

使用 echo 输出一个绝对路径，使用 grep 去除其基名：

    echo "/etc/sysconfig/" | grep -E -o  "[[:alnum:]]+/?$" | tr -d '/'

写一个模式，能匹配合理的IP地址

    egrep "\<([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-3][0-9])\>\.(\<([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\>\.){2}\<([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\>"