#!/bin/bash

if [ $AUDITWHEEL_ARCH == "x86_64" ]; then
    yum install -y mbedtls-devel zlib-devel
elif [ $AUDITWHEEL_ARCH == "i686" ]; then
    yum install -y mbedtls-devel zlib-devel
elif [ $AUDITWHEEL_ARCH == "s390x" ]; then
    yum install -y mbedtls-devel zlib-devel
elif [ $AUDITWHEEL_ARCH == "aarch64" ]; then
    yum install -y wget
    wget https://download-ib01.fedoraproject.org/pub/epel/testing/7/aarch64/Packages/m/mbedtls-2.7.12-1.el7.aarch64.rpm
    rpm -Uvh ./mbedtls-2.7.12-1.el7.aarch64.rpm
    wget https://download-ib01.fedoraproject.org/pub/epel/testing/7/aarch64/Packages/m/mbedtls-devel-2.7.12-1.el7.aarch64.rpm
    rpm -Uvh ./mbedtls-devel-2.7.12-1.el7.aarch64.rpm
fi
