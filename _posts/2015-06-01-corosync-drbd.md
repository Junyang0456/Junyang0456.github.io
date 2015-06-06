---
title: 使用 corosync + drbd 构建高可用 MySQL 集群
author: Liao
layout: post
permalink:  /corosync-drbd/
category:
tags:
  - drbd
  - corosync
  - HA
---
{% include JB/setup %}

corosync 是一个提供 Messaging Layer 的高可用集群软件，通常与 pacemaker（CRM） 结合一起使用。DRBD 的全称是 Distrubuted Replicated Block Device，它能够基于 TCP/IP，将两个节点的某个磁盘进行按位镜像。DRBD 工作在内核中，它的工作方式如下：

<!--more-->

![](/images/corosync-drbd/drbd.gif)

一旦用户空间的进程请求向 DRBD 设备写入或修改数据，DRBD 会捕获这份数据，将数据一分为二，一份写入本地磁盘，另一份通过网络发送至 peer 节点。

### DRBD 的模型

**主从**

- primary：可执行读、写操作
- secondary：备用节点不能挂载文件系统



**双主**

- 使用高可用集群服务
- 使用集群文件系统
- 基于 DLM（Distributed Lock Manager）实现锁

使用主从模型时，主从角色可以切换，必须先卸载主，将主设为从，再讲从设置为主并挂载。将 DRBD 定义为高可用资源运行在两个节点上，可以实现主从之间的自动切换。

**DRBD 数据传输**

**数据同步协议**
	A: Async, 异步  数据一旦从网络发送就返回成功
	B：semi sync, 半同步  数据被发送至peer节点的TCP/IP协议栈就返回成功
	C：sync, 同步  数据被peer节点写入磁盘后返回成功
	一般使用C模型

**数据传输**

DRBD 使用 TCP/IP 进行数据传输，即使使用 IDE 硬盘，速率也有 138MB/s，比千兆网的速度还要快，因此不能指望 DRDB 有很好的性能。且当使用TCP/IP 传输数据时，如果数据量很大，为了防止数据流将网络带宽占满而干扰其他服务，需要限制 DRBD 的使用带宽，这样又会影响 DRBD 的性能。再加上为了防止数据报文被窃取，对数据进行加密，又会再次影响 DRBD 的性能。

## 配置 corosync + DRBD

首先配置好两台主机的主机名，时间同步，密钥互信。本实验的两台主机为：

	node1	10.10.0.1
	node2	10.10.0.2

### 安装 DRBD
DRBD 也是两段式的，其核心功能工作在内核中，管理工具工作在用户空间。由于 DRBD 在 2.6.33 之后才被纳入内核，因此需要手动安装 DRBD 管理工具和其内核补丁包。

	drbd84-utils-8.9.1-1.el6.elrepo.x86_64.rpm   用户空间管理程序
	kmod-drbd84-8.4.5-504.1.el6.x86_64.rpm       内核补丁

### 创建一个分区用于 DRBD
在两台节点上，各创建一个分区供 DRBD 使用，不需要格式化，两节点的分区大小应该相同，这里使用 3GB 大小的分区，在两个节点上都是 `/dev/sda3`。

### 安装 MySQL 数据库

在主节点上挂载磁盘，安装数据库，初始化数据库时将数据文件指定为 DRBD 所在磁盘，同时备节点也安装数据库，但不需要初始化数据库。注意，两个节点的 mysql 用户 UID 应该相同。安装完成后，停止 MySQL 服务。

### 修改 DRBD 配置
DRBD 的配置主要有：

	/etc/drbd.conf
	/etc/drbd.d/global_common.conf

修改 `/etc/drbd.d/gloabal_coomon.conf`，主要增加下面几项：

	global {
        usage-count no;    关闭用户调研
	}
	common {
        protocol C;                        使用同步模式

        disk {
                on-io-error detach;        故障时拆除磁盘
        }

        net {
                cram-hmac-alg "sha1";        数据传输的 hmac 算法
                shared-secret "mydrbdkey";   密钥
        }

        syncer {
                rate 900M;               限制最大速率，防止把带宽占满
        }
	}

创建 `/etc/drbd.d/storage.res` ，定义一个资源：

	resource storage {
	  device	/dev/drbd0;
	  disk		/dev/sda3;
	  meta-disk	internal;
	  on node1 {
	    address	10.10.0.1:7789;
	  }
	  on node2 {
	    address	10.10.0.2:7789;
	  }
	}

在两节点间同步所有的 DRBD 配置文件。在两节点上分别初始化资源：

	drbdadm create-md storage

在两节点上启动服务：

	service drbd start

查看启动状态：

	# drbd-overview
	 0:storage/0  Connected Secondary/Secondary Inconsistent/Inconsistent

此时两个节点都处于 Secondary 状态，将其中一个节点设为 Primary，在要设置的节点上执行：

	# drbdadm primary --force storage

此时查看状态，两个节点的磁盘将进行按位同步：

	# drbd-overview
	 0:storage/0  SyncSource Primary/Secondary UpToDate/Inconsistent
		[>...................] sync'ed:  8.5% (2893492/3155636)K

等待同步完成后，就可以对 drbd 磁盘进行格式化挂载使用了。

### 配置 DRBD 为高可用资源

配置之前，先将 DRBD 磁盘卸载，并停止 drbd 服务。

安装 corosync 和 pacemaker，CentOS6 的 EPEL 源中有提供相应的包：

	yum -y install corosync pacemaker crmsh

复制 `/etc/corosync/corosync.conf.example` 为 `/etc/corosync/corosync.conf` ，修改下面的内容：

	bindnetaddr: 10.10.0.0            # 监听的网络地址

增加 pacemaker 的条目：

	service {
		ver: 0
		name: pacemaker
	}

使用 `corosync-keygen` 生成密钥

	# corosync-keygen

此时，可能需要生成随机数，可以使用 `cat /dev/urandom > test` 快速生成。

复制配置文件至对端节点，注意保留权限。

	# scp -p authkey corosync.conf node2:/etc/corosync/

启动 corosync

	# /etc/init.d/corosync start
	# ssh node2 /etc/init.d/corosync start

查看集群运行状态

	# crm status

**为 Primary 节点配置自动挂载的 DRBD 集群服务**

首先进入 crm 篇配置模式

	crm configure

配置 DRBD 资源

	primitive mysqldrbd ocf:linbit:drbd \
        params drbd_resource=storage \
        op monitor role=Master interval=20s timeout=20s \
        op monitor role=Slave interval=10s timeout=20s \
        op start timeout=240s interval=0 \
        op stop timeout=100s interval=0 \
        op demote timeout=90s interval=0 \
        op promote timeout=90s interval=0

将其配置为主从类型

	ms ms_mysqldrbd mysqldrbd \
        meta clone-max=2 clone-node-max=1 master-max=1 master-node-max=1 notify=true

配置 IP，文件系统和 mysqld 服务

	primitive mydata Filesystem \
        params device="/dev/drbd0" directory="/data" fstype=ext4 \
        op monitor interval=20s timeout=40s \
        op start timeout=60s interval=0 \
        op stop timeout=60s interval=0 \
        meta target-role=Stopped
	primitive myip IPaddr \
        params ip=10.0.0.50 \
        op monitor interval=10s timeout=20s \
        meta target-role=Stopped
	primitive myserver lsb:mysqld \
        op monitor interval=20s timeout=20s \
        meta target-role=Stopped

将 IP，文件系统，mysql 服务按次序定义为资源组

	group myservice myip mydata myserver

定义资源组和 DRBD 主节点的排列约束

	colocation myservice_with_ms_mysqldrbd_master inf: myservice ms_mysqldrbd:Master

提交修改

	commit

这样 MySQL 服务就能做到在磁盘损坏或主机故障后偶自动转移 DRBD 主节点，VIP 地址，MySQL 服务等资源。

### 总结
DRBD + corosync/pacemaker + MySQL 不失为一种构建 MySQL 高可用的方案，甚至 MySQL 官方官文中也推荐使用 DRBD 构建 MySQL 高可用集群。

但是这种方案的缺点也很明显，DRBD，corosync 这些软件的使用并不广泛，网上文档较少，出现问题后很难排查错误。集群如果出现脑裂，很可能导致文件损坏（因此生产系统一定要使用 STONITH 设备）。DRBD 通过网络传输数据，这必然导致传输效率不高，这可能会严重影响 MySQL 数据库的性能。

DRBD 还可以配置集群文件系统 + 分布式事务锁构建双主模型的 DRDB 集群，这样一来，除了 VIP 之外的其余资源都可以运行在每个节点上，实现 MySQL 高可用时只需要将故障节点的 VIP 转移就能完成资源的转移。但是这个方案的实施也是较为复杂的。因此本文仅供实验目的，对高可用集群和 DRBD 没有一定的研究不建议在生产环境使用 DRBD 集群。



