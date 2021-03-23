# centos7 默认自带lua，ubuntu则需要自己安装。

# 下载lua的网址：http://www.lua.org/ftp/

# 下载，解压，进入解压后的目录:

sudo make linux test
sudo make install INSTALL_TOP=/usr/local/lua/
cd /usr/local/bin
sudo ln -s /usr/local/lua/bin/* ./

#将lua安装到 /usr/local/lua目录下。然后去/usr/local/bin目录下建立软连接。

# ok，安装完成
