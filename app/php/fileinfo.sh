# php5.3开始，php安装包中默认是包含fileinfo扩展的
# 所以解压php-7.3.10.tar.gz，进入解压后的目录，在ext目录下，找到fileinfo扩展，复制到/usr/local/src目录下，然后开始安装

sudo cp -r fileinfo/ /usr/local/src/
cd /usr/local/src/fileinfo/
sudo /usr/local/php/bin/phpize
sudo ./configure --with-php-config=/usr/local/php/bin/php-config
sudo make && sudo make install

# 安装完成，下面是开启扩展
cd /usr/local/php/etc/php.d/
sudo vim fileinfo.ini

# 将 `extension=fileinfo.so` 写入fileinfo.ini文件，然后保存退出即可

# extension_loaded
# 使用 extension_loaded 函数可以查看扩展是否开启，新建demo.php文件

#  ```
#  if (extension_loaded('fileinfo')) {
#      echo 'yes';
#  }else {
#      echo 'no';
#  }
#  ```

# 奇怪的是，通过浏览器访问这个文件，返回的是 no，而使用php命令访问这个文件$(php demo.php)返回的是yes
# 这个是因为，没有重启php-fpm，如果使用easyswoole等常驻内存的框架，就不存在这个问题了
