#!/bin/sh
set -ex
CZMQ_RELEASE="3.0.0"
RC="-rc1"
curl -O http://download.zeromq.org/czmq-$CZMQ_RELEASE$RC.tar.gz
tar xzf czmq-$CZMQ_RELEASE$RC.tar.gz
cd czmq-$CZMQ_RELEASE/
./configure
make check
sudo make install
sudo ldconfig
