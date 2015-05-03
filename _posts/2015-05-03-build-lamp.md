---
title: Linux 基础 —— 编译安装 LAMP 环境
author: Liao
layout: post
permalink:  /build-lamp-enviroment/
category:
tags:
  - Basic
  - LAMP
---
{% include JB/setup %}

**LAMP** 是指一组通常一起使用来运行动态网站或者服务器的自由软件名称首字母缩写：

- Linux，操作系统
- Apache， 网页服务器
- MySQL 或 MariaDB，数据库服务器
- PHP、Perl 或 Python，脚本语言

随着互联网的流行，使用这些开源软件能够方便快速的构建出一个基于 PHP，Perl 或 Python 的动态网站服务器。

本文主要讲解在 CentOS6 系统上安装 Linux, Apache, MariaDB, PHP 的足组合。 

<!--more-->

## httpd 的安装

### 编译安装 httpd 2.4
httpd 2.4 以上版本需要依赖于 1.4 版本以上的 `apr`(Apache Portable Runtime) 和 apr-util 程序。而 CentOS 6 中自带的 apr 程序版本为 1.39。因此首先需要编译安装 `apr` 和 `apr-util`。

安装之前，首先安装 `Development Tools` 和 `Server Platform Development` 两个包组，同时安装 `pcre-devel` 包，在编译 `httpd` 时需要用到。

**1. 编译安装 apr**

这里使用 apr-1.5.0 的源码包进行解压安装：

    # tar xf apr-util-1.5.2.tar.bz2 
    # cd apr-1.5.0
    # ./configure --prefix=/usr/local/apr
    # make && make install

**2. 编译安装 apr-util**

编译 `apr-util` 时，指定 `apr` 为刚刚编译安装的新版本 `apr`

    # tar xf apr-util-1.5.2.tar.bz2
    # cd apr-util-1.5.2
    # ./configure --prefix=/usr/local/apr-util --with-apr=/usr/local/apr
    # make && make install

**3. 编译安装 httpd**

`httpd 2.4` 支持将 MPM 变异成动态模块，MPM（Multi-Processing Modules）是 `httpd` 服务器处理并发请求的模型，`httpd` 支持多种模式，在 Linux 系统中，支持下面三种模式：

- **worker** MPM，服务器使用多进程多线程的模型，每个线程处理一个连接请求。

- **prefork** MPM，服务器使用多进程模型，每个进程处理一个连接请求。它比 **worker** 模型耗费更多的内存（进程较线程更加重量级），但是它更加稳定，可以放心使用非线程安全的第三方模块，且更易于调试。

- **event** MPM，使用多进程多线程模型，但是使用了异步 IO 的方式，一个线程可以响应多个连接请求。

这里，编译时注意指定刚刚编译好的新版本 `apr` 和 `apr-util`，这里我选择的 MPM 模式是 event 模式。

    # tar xf httpd-2.4.10.tar.bz2
    # cd httpd-2.4.10
    # ./configure --prefix=/usr/local/apache --sysconfdir=/etc/httpd24 --enable-so --enable-ssl --enable-cgi --enable-rewrite --with-zlib --with-pcre --with-apr=/usr/local/apr --with-apr-util=/usr/local/apr-util --enable-modules=most --enable-mpms-shared=all --with-mpm=event

安装完成后，为其添加 sysV 服务脚本 `/etc/rc.d/init.d/httpd24`：

	#!/bin/bash
	#
	# httpd        Startup script for the Apache HTTP Server
	#
	# chkconfig: - 85 15
	# description: The Apache HTTP Server is an efficient and 	extensible  \
	#	       server implementing the current HTTP standards.
	# processname: httpd
	# config: /etc/httpd/conf/httpd.conf
	# config: /etc/sysconfig/httpd
	# pidfile: /var/run/httpd/httpd.pid
	#
	### BEGIN INIT INFO
	# Provides: httpd
	# Required-Start: $local_fs $remote_fs $network $named
	# Required-Stop: $local_fs $remote_fs $network
	# Should-Start: distcache
	# Short-Description: start and stop Apache HTTP Server
	# Description: The Apache HTTP Server is an extensible server 
	#  implementing the current HTTP standards.
	### END INIT INFO
	
	# Source function library.
	. /etc/rc.d/init.d/functions
	
	if [ -f /etc/sysconfig/httpd ]; then
	        . /etc/sysconfig/httpd
	fi

	# Start httpd in the C locale by default.
	HTTPD_LANG=${HTTPD_LANG-"C"}
	
	# This will prevent initlog from swallowing up a pass-phrase prompt if
	# mod_ssl needs a pass-phrase from the user.
	INITLOG_ARGS=""
	
	# Set HTTPD=/usr/sbin/httpd.worker in /etc/sysconfig/httpd to use a server
	# with the thread-based "worker" MPM; BE WARNED that some modules may not
	# work correctly with a thread-based MPM; notably PHP will refuse to start.

	# Path to the apachectl script, server binary, and short-form for messages.
	apachectl=/usr/bin/apache/bin/apachectl
	httpd=${HTTPD-/usr/local/apache/bin/httpd}
	prog=httpd
	pidfile=${PIDFILE-/usr/local/apache/logs/httpd.pid}
	lockfile=${LOCKFILE-/var/lock/subsys/httpd24}
	RETVAL=0
	STOP_TIMEOUT=${STOP_TIMEOUT-10}

	# The semantics of these two functions differ from the way apachectl does
	# things -- attempting to start while running is a failure, and shutdown
	# when not running is also a failure.  So we just do it the way init scripts
	# are expected to behave here.
	start() {
        	echo -n $"Starting $prog: "
        	LANG=$HTTPD_LANG daemon --pidfile=${pidfile} $httpd $OPTIONS
        	RETVAL=$?
        	echo
        	[ $RETVAL = 0 ] && touch ${lockfile}
        	return $RETVAL
	}

	# When stopping httpd, a delay (of default 10 second) is required
	# before SIGKILLing the httpd parent; this gives enough time for the
	# httpd parent to SIGKILL any errant children.
	stop() {
		echo -n $"Stopping $prog: "
		killproc -p ${pidfile} -d ${STOP_TIMEOUT} $httpd
		RETVAL=$?
		echo
		[ $RETVAL = 0 ] && rm -f ${lockfile} ${pidfile}
	}
	reload() {
    	echo -n $"Reloading $prog: "
    	if ! LANG=$HTTPD_LANG $httpd $OPTIONS -t >&/dev/null; then
        	RETVAL=6
        	echo $"not reloading due to configuration syntax error"
        	failure $"not reloading $httpd due to configuration syntax error"
    	else
        	# Force LSB behaviour from killproc
        	LSB=1 killproc -p ${pidfile} $httpd -HUP
        	RETVAL=$?
        	if [ $RETVAL -eq 7 ]; then
            	failure $"httpd shutdown"
        	fi
    	fi
    	echo
	}

	# See how we were called.
	case "$1" in
  	start)
		start
		;;
  	stop)
		stop
		;;
  	status)
        	status -p ${pidfile} $httpd
		RETVAL=$?
		;;
  	restart)
		stop
		start
		;;
  	condrestart|try-restart)
		if status -p ${pidfile} $httpd >&/dev/null; then
			stop
			start
		fi
		;;
  	force-reload|reload)
        	reload
		;;
  	graceful|help|configtest|fullstatus)
		$apachectl $@
		RETVAL=$?
		;;
  	*)
		echo $"Usage: $prog {start|stop|restart|condrestart|try-restart|force-reload|reload|status|fullstatus|graceful|help|configtest}"
		RETVAL=2
	esac
	
	exit $RETVAL

将脚本加入启动服务列表
	
	# chmod +x /etc/init.d/httpd24
	# chkconfig --add httpd2

## MariaDB 的安装
为了简便起见，这里使用通用二进制版本的 MariaDB，并且将数据库与 Web 服务器进行分离部署。在另外一台 Linux 上，下载通用二进制的 MariaDB 安装包并安装

	# mkdir -p /data/mydata /etc/mysql
	# tar xf mariadb-5.5.43-linux-x86_64.tar.gz -C /usr/local/
	# cd /usr/local/
	# ln -s mariadb-5.5.43-linux-x86_64/ mysql

添加用户，初始化授权表，并赋予权限

	# useradd -r -s /sbin/nologin mysql
	# cd mysql/
	# scripts/mysql_install_db --user=mysql --datadir=/data/mydata/
	# chown -R root:mysql /usr/local/mysql/
	# chown -R mysql:mysql /data/mydata/

添加 sysV 服务脚本和配置文件

	# cd /usr/local/mysql
	# cp support-files/mysql.server /etc/init.d/mysqld
	# chmod +x /etc/init.d/mysqld
	# ckconfig --add mysqld
	# cp support-files/my-large.cnf /etc/mysql/my.cnf

在 `/etc/mysql/my.cnf` 中添加

	datadir = /data/mydata

添加 PATH 环境变量，在 `/etc/profile.d/mysql.sh` 中写入
	
	export PATH=$PATH:/usr/local/mysql/bin

启动服务
	
	# service mysqld start
	
## PHP 的安装
### PHP 与 Apache
Apache 是一个 Web 服务器，它只能处理和响应静态的资源，如图片，HTML 文档等等。而对于使用脚本语言编写的 PHP 程序，在客户端请求时，需要将请求的参数传递给此程序并将其运行，最后将结果返回至客户端。

为了让 Web 服务器能够处理动态页面的请求，可以有三种方法：

1. 使用 CGI 协议，Web 服务器通过 CGI 协议将请求转发至程序的解释器（脚本语言），解释器将运行结果返回 Web 服务器，随后解释器销毁。

2. 将运行和处理动态页面程序的功能做成 Web 服务器的模块，使得 Web 服务器可以调用自身的模块来处理动态页面，即动态程序由 Web 服务器来负责运行和处理。

3. FastCGI模式，使用专门的动态程序服务器，Web 服务器将动态页面的请求转发至应用程序服务器，应用程序服务器将结果响应至 Web 服务器。动态程序的运行由专门的应用程序服务器来负责处理，通常会预先生成多个进程用于等待处理请求。这避免了 CGI 模式下，解释器进程不断被生成和销毁的缺点。同时 Web 服务器和应用程序服务器也可以用分开部署。

PHP 与 Apche 结合的常用方式是编译 Apache 的 PHP 处理模块，让 Apache 自己处理 PHP 程序，或者使用专门的 PHP 应用程序服务器 php-fpm，由它来负责处理 PHP 程序。

### 将 PHP 编译成 httpd 的模块
将 PHP 编译成 httpd 的模块时，需要指定使用 apxs2 来将其编译成 httpd 的模块。需要注意，如果 httpd 使用 prefork MPM，则 PHP 编译成为 `libphp5.so` 模块，如果 httpd 使用 worker 或 event MPM，则 PHP 编译成为 zts 模块。

编译之前，安装好开发包组，并安装 `libxml2-devel`，`bzip2-devel` 和 `libmcrypt-devel` 。

	# tar xf php-5.4.40.tar.bz2
	# cd php-5.4.40
	# ./configure --prefix=/usr/local/php --with-mysql --with-openssl --with-mysqli --enable-mbstring --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml  --enable-sockets --with-apxs2=/usr/local/apache/bin/apxs --with-mcrypt  --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d --with-bz2  --enable-maintainer-zts
	# make && make install

为 PHP 提供配置文件

	# mkdir /etc/php.d
	# cp php.ini-production /etc/php.ini

编辑 httpd 配置文件，以支持 php 格式的文件，在 `/etc/httpd24/httpd.conf` 中添加：

	AddType application/x-httpd-php .php
	AddType application/x-httpd-php-source .phps

修改 DirectoryIndex
	
	DirectoryIndex    index.php  index.html

测试 PHP 是否能够工作正常，在数据库中添加一个用户，用于测试

	MariaDB [(none)]> GRANT ALL ON *.* TO 'phpuser'@‘10.10.0.1’ IDENTIFIED BY 'phppass';
	MariaDB [(none)]> FLUSH PRIVILEGES;

在 httpd 服务器建立一个测试页面，如下：

	<?php
    	$conn = mysql_connect('10.10.0.2','phpuser','phppass');
    	if ($conn)
	    	echo "OK";
    	else
	    	echo "Fail";
	    
    	mysql_close();
	?>

重启 httpd 服务，如果显示 OK，则说明模块式的 LAMP 环境安装正常。

## 安装 xcache，为 PHP 加速
xcache 能够让 PHP 解释器进程编译的 opcode 缓存起来，并且在多个解释器进程之间共享，下一编译时就可以直接使用，因而可以起到为 PHP 加速的功能。

安装 xcache

	# tar xf xcache-3.1.0.tar.bz2
	# cd xcache-3.1.0
	# /usr/local/php/bin/phpize 
	# ./configure --enable-xcache --with-php-config=/usr/local/php/bin/php-config
	# make && make install

将源码目录下的 `xcache.ini` 复制到 `/etc/php.d/` 中

安装完成后，会出现下面的行

	Installing shared extensions:     /usr/local/php/lib/php/extensions/no-debug-zts-20100525/

编辑 `/etc/php.d/xcache.ini`，修改 extension 中的行为刚刚的地址

	extension = /usr/local/php/lib/php/extensions/no-debug-zts-20100525/xcache.so

重启 httpd 服务，重载配置文件即可，然后可以使用 `phpinfo()` 测试页面查看 xcache 是否生效

### 将 PHP 编译成 fastCGI 模式
编译 PHP 为 FastCGI 模式时，将使用 php-fpm 这个守护进程作为 php 程序的解释程序，因此 PHP 可以和 Web 服务器分离部署，也可以部署在一台机器上。

使用 `--enable-fpm` 就可以以 fpm 模式编译 PHP

	# ./configure --prefix=/usr/local/php5 --with-mysql --with-openssl --with-mysqli --enable-mbstring --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml  --enable-sockets --enable-fpm --with-mcrypt  --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d --with-bz2
	# make && make install

编译好后，为 php 提供配置文件

	# mkdir /etc/php.d
	# cp php.ini-production /etc/php.ini

为 php-fpm 提供启动脚本

	# cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
	# chmod +x /etc/init.d/php-fpm

修改 php-fpm 的配置文件，因为这里把它与 Web 服务器分离部署了，因此需要配置其监听的 IP 地址

	# cd /usr/local/php5/etc/
	# cp php-fpm.conf.default php-fpm.conf
	# chkconfig --add php-fpm

修改 `php-fpm.conf` 中的 listen 选项：

	listen = 10.10.0.2:9000

启动 php-fpm 服务即可。

为了让 Web 服务器将 php 网页的请求转发到 PHP 程序服务器，在 http.conf 中的中心主机或虚拟主机中添加下面的反向代理条目即可

  	ProxyRequests Off
 	ProxyPassMatch ^/(.*\.php)$ fcgi://10.10.0.2:9000/PATH/TO/DOCUMENT_ROOT/$1

## 在 LAMP 环境中测试使用虚拟主机
在上面的模块式 LAMP 环境中，创建两个虚拟主机，并分别安装 discuz 和 phpmyadmin 这两个 PHP 程序。

在 `/etc/httpd24/httpd.conf` 中，关闭中心主机的 `DocumentRoot` 选项，开启下面行，使用虚拟主机：

	# Virtual hosts
	Include /etc/httpd24/extra/httpd-vhosts.conf

编辑 `/etc/httpd24/extra/httpd-vhost.conf` 

	<VirtualHost *:80>
    	DocumentRoot "/web/htdocs/www.forum.com
	DirectoryIndex index.php index.html
    	ServerName www.forum.com
    	ErrorLog "logs/www.forum.com-error_log"
    	CustomLog "logs/www.forum.com-access_log" combined
    	<Directory "/web/htdocs/www.forum.com">
        	Options none
        	AllowOverride none
        	Require all granted
    	</Directory>
	</VirtualHost>

	<VirtualHost *:80>
    	DocumentRoot "/web/htdocs/www.pma.com
	DirectoryIndex index.php index.html
    	ServerName www.pma.com
    	ErrorLog "logs/www.pma.com-error_log"
    	CustomLog "logs/www.pma.com-access_log" combined
    	<Directory "/web/htdocs/www.pma.com">
        	Options none
        	AllowOverride none
        	Require all granted
    	</Directory>
	</VirtualHost>

重启 httpd 服务。

将 `Discuz` 和 `phpmyadmin` 的源代码分别解压至 `/web/htdocs/www.forum.com/` 和 `/web/htdocs/www.pma.com/` 目录中

在 Windows 中配置 hosts 文件解析这两个域名，用浏览器访问
`http://www.forum.com`:

![](/images/build-lamp/discuz_1.png)

点击下一步，将网站目录中的文件权限设置正确：

![](/images/build-lamp/discuz_2.png)

点击下一步，按要求填入连入数据库的账户，并在数据库中创建 `ultrax` 这个数据库，之后点击下一步

![](/images/build-lamp/discuz_3.png)

Discuz 论坛安装好了。

</br>

由于数据库和 phpmyadmin 不再同一台机器上，需要额外配置。

在 phpmyadmin 的根目录中，复制 `config-sample.inc.php` 为 `config.inc.php` ，修改如下的行：

	$cfg['Servers'][$i]['host'] = '10.10.0.2';

用浏览器访问 `http://www.pma.com`

![](/images/build-lamp/pma_1.png)

填入帐号密码后，即可访问

![](/images/build-lamp/pma_2.png)

**为 phpmyadmin 添加 SSl 支持**

在 `/etc/httpd24/httpd.conf` 中取消下面的注释：

	Include /etc/httpd24/extra/httpd-ssl.conf
	LoadModule ssl_module modules/mod_ssl.so
	LoadModule socache_shmcb_module modules/mod_socache_shmcb.so

编辑 `/etc/httpd24/extra/httpd-ssl.conf` ，修改下面几项配置：

	<VirtualHost *_:443>
	DocumentRoot "/web/htdocs/www.pma.com/"
	ServerName www.pma.com
	SSLCertificateFile "/etc/httpd24/httpd.crt"
	SSLCertificateKeyFile "/etc/httpd24/httpd.key"

其中 httpd.crt 为服务器的证书，httpd.key 为服务器的私钥，生成证书的方法可以参考[这里](http://liaoph.com/encrytion-and-openssl/)

并在虚拟主机中添加下面几行，以允许访问

	<Directory "/web/htdocs/www.pma.com/">
		Options none
		AllowOverride none
		Require all granted
	</Directory> 

之后重启 httpd 服务。

![](/images/build-lamp/pma_3.png)

已经可以通过 HTTPs 访问了。

**注意**

如果使用 fpm 模式，并且 php-fpm 服务器和 Web 服务器部署在分离的两台机器上，那么 php 动态文件需要放置在 php-fpm 服务器上，静态文件则需要放置在 Web 服务器上。如果网站允许用户上传图片等内容，那么这些文件可能由 PHP 保存至 php-fpm 服务器上，而用户访问这些文件需要由 Web 服务器进行处理，因此保存用户上传文件的目录也应该在两天服务器之间进行共享或同步。









