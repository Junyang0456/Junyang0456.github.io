---
title: Linux 基础 —— YUM入门
author: Liao
layout: post
permalink:  /linux-yum-tutorial/
category:
tags:
  - Basic
---
{% include JB/setup %}

这篇文章主要讲 YUM 包管理器的使用。

<!--more-->

## YUM 简介
YUM 的全称是 Yellowdog Updater, Modified，它是一个 C/S 架构的软件，能够对基于 RPM 格式的软件包进行管理，它提供了包括自动解决依赖关系，软件包的分组，软件包的升级等功能。 2013 年 7 月 10 日， yum 工具的开发者 Seth Vidal 先生因为车祸不幸去世， 我们为计算机领域失去这位专家感到惋惜。

构成一个完整的 yum 服务，需要以下部分：

1. yum 服务器上的服务仓库（存储 rpm 文件和索引文件）
2. 提供 rpm 和索引下载的网络服务（http 或者 ftp）
3. 客户端的 yum 命令行工具
4. 客户端仓库配置信息和插件扩展模块

## yum 的配置
### yum 仓库的配置
**搭建一个简单的 yum 仓库**

搭建一个简单的 yum 仓库，只需要：

- 将 rpm 软件包放在某个目录下
- 对此目录使用 createrepo 命令，对 rpm 包生成索引信息
- 使用 http 或者 ftp 将此目录提供给客户端下载

### yum 客户端配置
要使用 yum 需要在客户端配置好 yum 仓库的位置（这里的仓库可以是本地文件系统上的，也可以是远程的）。

yum 命令行使用相关的配置在 `/etc/yum.conf` 中，这里可以定义 yum 命令使用的配置，如是否使用缓存，缓存文件路径等。这个文件的设定一般不需要改动。

用于指明 yum 仓库的配置文件在 `/etc/yum.repos.d/*.repo` 中，这些文件以 `.repo` 为后缀名。
    
仓库配置的可用选项有：

    [repositoryid]
    	# 对于当前系统的yum来讲，此repositoryid用于惟一标识此repository指向，因此，其必须惟一；
    name= 
    	# 当前仓库描述信息；
    baseurl=url://path/to/repository/
    	# 指明repository的访问路径；通常为一个文件服务器上输出的某repository；url 可以是 ftp，http 或者本地文件系统的 url
    enabled={1|0}
    	此仓库是否可被使用
    gpgcheck={1|0}
    	是否对程序包做校验
    gpgkey=url://path/to/keyfile
    	指明gpgkey文件路径；
    cost=#
    	指明当前repository的访问开销，默认为1000；

下面是一个配置范例：

    [root@bogon yum.repos.d]# cat nginx.repo 
    # nginx.repo
    
    [nginx]
    name=nginx repo
    baseurl=http://nginx.org/packages/centos/6/$basearch/
    gpgcheck=0
    enabled=1

这里的 `baseurl` 中使用了 `$basearch` 变量，使得这个配置文件更具有通用性。在 `*.repo` 文件中常用的变量有：

    $releasever
    	当前 OS 发行版的主版本号，如对 CentOS 6.6 系统，这个值为 6
    $arch
     	当前系统的平台，如 i386, x86_64 等
    $basearch
    	基础平台，如 x86_64 和 amd64 平台的基础平台同为 x86_64
 
## yum 客户端命令的使用
### 仓库管理
`repolist`：列出已经配置的所有可用仓库

`yum repolist [all|enabled|disabled]`

### 缓存管理
`clean` 清理缓存

`yum clean [ packages | metadata | expire-cache | rpmdb | plugins | all ]`

`makecache` 缓存创建

`yum makecache` 将会自动连接至每一个可用仓库，下载其元数据，并将其创建为缓存。

### 程序包查看
`yum list [all]` 查看所有仓库的可用软件包，还可以跟上包名查看特定的软件包，包名可以使用通配符匹配，如列出所有以 `zlib` 开头的软件包：

	[root@bogon ~]# yum list zlib*
	Loaded plugins: downloadonly, fastestmirror, refresh-packagekit, security
	Loading mirror speeds from cached hostfile
	base                                                                                                 | 3.7 kB     00:00     
	extras                                                                                               | 3.4 kB     00:00     
	Installed Packages
	zlib.x86_64                                  1.2.3-29.el6                           @anaconda-CentOS-201410241409.x86_64/6.6
	Available Packages
	zlib.i686                                    1.2.3-29.el6                           base                                    
	zlib-devel.i686                              1.2.3-29.el6                           base                                    
	zlib-devel.x86_64                            1.2.3-29.el6                           base                                    
	zlib-static.x86_64                           1.2.3-29.el6                           base

可以单独查看所有已安装，可升级，可用软件包，使用

`yum list {available|updates|installed|extras|obsoletes} [glob_exp1] [...]`

查看软件包组，使用 `grouplist`

`yum grouplist [glob_exp]`

### 程序包安装
安装使用 `install` 子命令，并跟上需要安装的包名

`yum install package1 [package2] [...]`

例如，安装 `mysql-server` 软件包：

`yum install mysql-server`

在安装过程中，程序会交互式的提示是否确认安装，需要按 `y` 进行确认，如果需要不提示，可以使用 `-y` 选项，如 `yum -y install mysql-server`

如果一个软件包有多个版本可用，yum 默认安装最新的那个，如果向指定版本，那么在包名后跟上想要安装的版本号

`yum install PACKAGE-VERSION`

### 重新安装
重新安装使用 `reinstall`，其使用方式和 `install` 相同。

### 程序包升级
软件包的升级使用 `update` 子命令，并接上需要升级的包名

`yum update [package1] [package2] [...]`

### 程序包降级
软件包降级使用 `downgrade` 子命令，并跟上需要降级的包名

`yum downgrade package1 [package2] [...]`

### 检查可用升级
使用 `yum check-update` 检查有哪些包可以升级

### 卸载
卸载使用 `remove` 子命令

`yum remove package1 [package2] [...]` 

如果一个软件包被其他软件包依赖，那么卸载它的时候依赖此软件包的其他软件包也将被卸载。卸载也可以使用 `-y` 表示非交互式模式。

### 查询
查询软件包的概要信息，使用 `info` 子命令

`yum info PACKAGE`

在软件包的包名和概要中搜索某个关键字，使用  `search` 子命令。

`yum search KEYWORD`

查询某个文件由哪个软件包所安装生成，使用 `provides` 子命令，如查询 `/usr/bin/passwd` 有哪个软件包所生成：

    [root@bogon ~]# yum provides /usr/bin/passwd
    Loaded plugins: downloadonly, fastestmirror, refresh-packagekit, security
    Loading mirror speeds from cached hostfile
    passwd-0.77-4.el6_2.2.x86_64 : An utility for setting or changing passwords using PAM
    Repo: base
    Matched from:
    Filename: /usr/bin/passwd

查询的文件还可以使用通配符进行通配。

### 安装或升级本地的软件包
安装本地软件包使用 `localinstall` 子命令，也可以直接使用 `install` 子命令，安装本地软件包指定的软件包的文件名。

### 包租管理
列出所有包组：`grouplist`

显示指定包组详情：`groupinfo group1 [...]`

安装包组：`groupinstall`

卸载：`groupremove`

升级：`groupupdate` 

这些子命令的用法和安装普通软件包时的用法是相同的。安装包租是也可以使用 `install`，`remove` 或 `update` 来管理，如安装 `Development tools` 软件包：

`yum install @Development tools`

### yum 命令的可用选项
`-y` ：自动在交互式回答 "yes"

`--disablerepo=`：临时禁用在配置文件中配置并启动的某仓库

`--enablerepo=`：临时启用指定的某仓库

`--nogpgcheck=`：禁止做包校验

### yum 插件
yum 还能够支持插件的安装，能够扩展 yum 的功能，这里列举 `yum-downloadonly` 插件，这个插件的功能是使用 yum 下载一个 rpm 包到某个目录中而不安装它。

下载插件：

`yum install yum-downloadonly`

使用 `--downloadonly` 选项来下载 rpm 包而不安装：

`yum install --downloadonly --downloaddir=<directory> <package>`


