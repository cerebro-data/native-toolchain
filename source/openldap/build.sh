#!/usr/bin/env bash
# Copyright 2015 Cloudera Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# cleans and rebuilds thirdparty/. The Impala build environment must be set up
# by bin/impala-config.sh before running this script.

# Exit on non-true return value
set -e
# Exit on reference to uninitialized variable
set -u

set -o pipefail

source $SOURCE_DIR/functions.sh
THIS_DIR="$( cd "$( dirname "$0" )" && pwd )"
prepare $THIS_DIR

# OpenSSL 1.1.1 support was added in OpenLDAP 2.4.45
# so we have to use the OS version to get 1.0.2 if we're building
# older releases.
# Download the dependency from S3
if [ "${OPENLDAP_VERSION}" == "2.4.25" ]; then
  download_dependency $LPACKAGE "${LPACKAGE_VERSION}.tgz" $THIS_DIR
else # 2.4.48 or greater
  download_cerebro_dependency "${LPACKAGE_VERSION}.tgz" $THIS_DIR

  OPENSSL_ROOT="${BUILD_DIR}"/openssl-"${OPENSSL_VERSION}"

  # Set these to ensure that we pick up the OpenSSL built by the toolchain
  LD_LIBRARY_PATH=$OPENSSL_ROOT/lib:$LD_LIBRARY_PATH
  CXXFLAGS="$CXXFLAGS -I$BUILD_DIR/openssl-$OPENSSL_VERSION/include"
  CFLAGS="$CFLAGS -I$BUILD_DIR/openssl-$OPENSSL_VERSION/include"
  LDFLAGS="$LDFLAGS -L$BUILD_DIR/openssl-$OPENSSL_VERSION/lib"
fi

if needs_build_package ; then
  header $PACKAGE $PACKAGE_VERSION

  wrap ./configure --enable-slapd=no --enable-static --with-pic --prefix=$LOCAL_INSTALL
  wrap make -j${BUILD_THREADS:-4} install
  wrap make -j${BUILD_THREADS:-4} depend
  wrap make -j${BUILD_THREADS:-4} install

  footer $PACKAGE $PACKAGE_VERSION
fi
