#!/bin/bash
set -ex

cat $1|sed 's,$,\\n,'|tr -d '\n'
