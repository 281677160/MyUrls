#!/bin/bash

if [[ ! "$USER" == "root" ]]; then
  echo
  echo -e "\033[31m 警告：请使用root用户操作!~~ \033[0m"
  exit 1
fi

export arch=$(arch)
if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
  ARCH_PRINT="linux64"
  ARCH_PRINT2="amd64"
  MYURLS_ARCH="myurls-linux-amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
  ARCH_PRINT="aarch64"
  ARCH_PRINT2="arm64"
  MYURLS_ARCH="myurls-linux-arm64"
else
  echo -e "\033[31m 不支持此系统,只支持x86_64和arm64的系统 \033[0m"
  exit 1
fi

if [[ "$(. /etc/os-release && echo "$ID")" == "ubuntu" ]]; then
  echo -e "\033[32m ${ARCH_PRINT}_ubuntu \033[0m"
elif [[ "$(. /etc/os-release && echo "$ID")" == "debian" ]]; then
  echo -e "\033[32m ${ARCH_PRINT}_debian \033[0m"
else
   echo -e "\033[31m 不支持该系统,只支持ubuntu和debian系统 \033[0m"
   exit 1
fi

apt-get update -y
apt-get install -y socat curl wget git sudo

if [[ `go version |grep -c "go1.20.3"` == '0' ]]; then
  sodu apt-get remove -y golang-go
  sodu apt-get remove -y --auto-remove golang-go
  sodu rm -rf /usr/local/go
  sodu rm -rf /usr/bin/go
  wget -c https://go.dev/dl/go1.20.3.linux-${ARCH_PRINT2}.tar.gz -O /root/go1.20.3.linux-${ARCH_PRINT2}.tar.gz
  if [[ $? -ne 0 ]];then
    wget -c https://golang.google.cn/dl/go1.20.3.linux-${ARCH_PRINT2}.tar.gz -O /root/go1.20.3.linux-${ARCH_PRINT2}.tar.gz
  fi
  sodu tar -zxvf /root/go1.20.3.linux-${ARCH_PRINT2}.tar.gz -C /usr/local/
  sed -i '/usr\/local\/go\/bin/d' "/etc/profile"
  echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile
  source /etc/profile
  go env -w GOPROXY=https://proxy.golang.com.cn,direct
  go env -w GOPRIVATE=git.mycompany.com,github.com/my/private
fi

sodu apt-get install -y gcc automake autoconf libtool make

if [[ `go version |grep -c "go1.20.3"` -ge '1' ]]; then
  rm -rf /root/go1.20.3.linux-${ARCH_PRINT2}.tar.gz
else
  rm -rf /usr/local/go
  echo "go环境部署失败"
  exit 1
fi

[[ -d "/root/MyUrls" ]] && sudo rm -rf /root/MyUrls
git clone https://ghproxy.com/https://github.com/CareyWang/MyUrls /root/MyUrls
if [[ $? -ne 0 ]];then
  echo -e "\033[31m MyUrls源码下载失败，请检查网络 \033[0m"
  exit 1
else
  chmod -R 775 /root/MyUrls
fi

echo
echo -e "\033[33m 开始编译MyUrls \033[0m"
echo
sleep 3

cd /root/MyUrls
make install
if [[ $? -ne 0 ]];then
  echo -e "\033[31m 编译MyUrls失败 \033[0m"
  exit 1
fi
make all
if [[ $? -ne 0 ]];then
  echo -e "\033[31m 编译MyUrls失败 \033[0m"
  exit 1
fi
if [[ -f "/root/MyUrls/build/${MYURLS_ARCH}" ]]; then
  mkdir -p /root/MyUrls/myurls
  cp -Rf /root/MyUrls/public /root/MyUrls/myurls/public
  mv -f /root/MyUrls/build/${MYURLS_ARCH} /root/MyUrls/myurls/${MYURLS_ARCH}
  tar -czvf ${MYURLS_ARCH}.tar.gz myurls
  rm -rf /root/MyUrls/build/*
  mv -f ${MYURLS_ARCH}.tar.gz build/${MYURLS_ARCH}.tar.gz
  rm -rf /root/MyUrls/myurls
else
  echo -e "\033[31m 编译MyUrls失败 \033[0m"
fi
if [[ -f "/root/MyUrls/build/${MYURLS_ARCH}.tar.gz" ]]; then
  echo
  echo -e "\033[32m [ ${MYURLS_ARCH} ]编译完成 \033[0m"
  echo
  echo -e "\033[32m 已存放在[/root/MyUrls/build]文件夹里面 \033[0m"
  echo
fi
