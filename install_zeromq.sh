#!/bin/sh
set -ex
ZEROMQ_RELEASE="4.1.0"
RC="-rc1"
curl -O http://download.zeromq.org/zeromq-$ZEROMQ_RELEASE$RC.tar.gz
tar xzf zeromq-$ZEROMQ_RELEASE$RC.tar.gz
cd zeromq-$ZEROMQ_RELEASE/
./configure
make check
sudo make install
sudo ldconfig
