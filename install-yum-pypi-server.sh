#!/bin/bash

## 安装YUM Server

##用reposync同步YUM源到本地搭建本地YUM源服务器
##開始搭建本地yum
# 1.安裝httpd,createrepo,yum-utils
yum install httpd createrepo yum-utils -y
#将本地yum源目录软链接到http根目录
ln -s /data/yum /var/www/html
# 2.規劃建立yum源文件夾
存儲在/data/yum下
區分不同yum目錄,目录下包含适用此版本的各种源
mkdir -p /data/yum/centos 
mkdir -p /data/yum/epel 
mkdir -p /data/yum/docker 
mkdir -p /data/yum/openstack
# 3.配置外網代理vi /etc/profile(代理聯網需配)
vi /etc/profile
http_proxy=http://賬號:密碼@10.191.131.5:3128/
export http_proxy
# 4.準備官方的yum文件
# 4.1 centos源，系統自帶；為方便版本管理，最好將repo文件中的版本參數改為指定的版本
# 4.2 epel源;代理情况下默认路径无法识别；需注释掉#mirrorlist，启用baseurl,
##  并将路径更改为baseurl=http://dl.fedoraproject.org/pub/epel/7/$basearch
yum install epel-release
# 4.3 docker源
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# 5.開始同步下載包
##可以设置-r指定更新对象（yum文件中带[]的字段）
##不生成reponame名称的目录 --norepopath
reposync -r base --norepopath -p /data/yum/centos/7.3.1611/os/
reposync -r updates --norepopath -p /data/yum/centos/7.3.1611/updates/
reposync -r extras --norepopath -p /data/yum/centos/7.3.1611/extras/
reposync -r epel --norepopath -p /data/yum/epel/7/
reposync -r docker-ce --norepopath -p /data/yum/docker-ce/centos/7/
# 6.建倉（生成yum依賴關係）
createrepo -p -o /data/yum/centos/7.3.1611/os /data/yum/centos/7.3.1611/os
createrepo -p -o /data/yum/centos/7.3.1611/updates /data/yum/centos/7.3.1611/updates
createrepo -p -o /data/yum/centos/7.3.1611/extras /data/yum/centos/7.3.1611/extras
createrepo -p -o /data/yum/epel/7 /data/yum/epel/7
createrepo -p -o /data/yum/docker-ce/centos/7 /data/yum/docker-ce/centos/7

# 7.若後續還需要連網更新，可通過定時排程進行
##后续同步（-n为newest-only只更新最新的文件）
reposync  -r base --norepopath -np /data/yum/centos/7.3.1611/os/
##后续自动更新倉庫依賴使用--update参数(-o输出路径)
createrepo -p -o --update /data/yum/centos/7.3.1611/os/


## Pypi Server

#1.安装pip,bandersnatch
yum install python-pip -y
pip install bandersnatch
#2.创建pip包存储路径
mkdir -p /data/yum/pypi
#3.执行如下命令初始化，生成相应配置文件
bandersnatch mirror
#4.修改配置文件/etc/bandersnatch.conf,改为与aliyun同步
vi /etc/bandersnatch.conf 
directory = /data/yum/pypi                       # 要同步的本机目录
master = http://mirrors.aliyun.com/pypi/simple/  # 要同步的pypi仓库
workers = 10					                           # 根据服务器情况，可以开多个线程
#5.开始同步
bandersnatch mirror
#6.创建排程，定期更新
vi /etc/cron.d/bandersnatch
*/2 * * * * root bandersnatch mirror |& logger -t bandersnatch[mirror]
## http服务与yum共用，略


## Client客户端配置

#在~/.pip/pip.conf文件中添加或修改
[global]
index-url = http://10.172.114.204/yum/pypi/
[install]
trusted-host=10.172.114.204
