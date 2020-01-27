#!/bin/bash

d=/opt/hsm/yubihsm2-sdk
t=$(date +%Y-%m-%d_%H:%M:%S)

echo ""
echo "#########################"
echo "## $t ##"
echo "#########################"
echo ""

if ! rpm -q yubihsm-shell; then
  yum install -y "$d"/yubihsm-shell*
fi

if ! rpm -q yubihsm-connector; then
  yum install -y "$d"/yubihsm-connector*
fi

if ! rpm -q yubihsm-devel; then
  yum install -y "$d"/yubihsm-devel*
fi

if ! rpm -q yubihsm-setup; then
  yum install -y "$d"/yubihsm-setup*
fi
