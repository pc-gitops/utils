#!/bin/bash

# Utility to gofmt, goimports and test a package
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)

if [ -z "$1" ] ; then
	echo "please specify a package"
	exit 1
fi

package_name="$1"

if [ ! -d "$package_name" ] ; then
	echo "package: $package_name does not exist"
	exit 1
fi
TOP=`git rev-parse --show-toplevel`
make -C $TOP/$package_name --makefile=$TOP/makefile.mk gofmt
make -C $TOP/$package_name --makefile=$TOP/makefile.mk goimports
make -C $TOP/$package_name --makefile=$TOP/makefile.mk clean
make -C $TOP/$package_name --makefile=$TOP/makefile.mk