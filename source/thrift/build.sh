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

# Download the dependency from S3
download_dependency $LPACKAGE "${LPACKAGE_VERSION}.tar.gz" $THIS_DIR

if needs_build_package ; then
  header $PACKAGE $PACKAGE_VERSION

  BISON_ROOT="${BUILD_DIR}"/bison-"${BISON_VERSION}"
  BOOST_ROOT="${BUILD_DIR}"/boost-"${BOOST_VERSION}"
  OPENSSL_ROOT="${BUILD_DIR}"/openssl-"${OPENSSL_VERSION}"
  ZLIB_ROOT="${BUILD_DIR}"/zlib-"${ZLIB_VERSION}"

  # We generally want to use the OpenSSL that we build in the native toolchain,
  # but for thrift 0.9.3, we cannot do this as it does NOT support openssl 1.1.1.
  # So, for thrift 0.9.3, we use the OS's version of openssl which *should* be
  # 1.0.2 something as we should only be building this on Ubuntu 16.04
  if [[ "$PRODUCTION" -eq "0" || "$OSTYPE" == "darwin"* ]]; then
    if [[ "$PACKAGE_VERSION" == "0.9.3" ]]; then
      LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/:$LD_LIBRARY_PATH
      CXXFLAGS="$CXXFLAGS -I/usr/include/x86_64-linux-gnu/"
      CFLAGS="$CFLAGS -I/usr/include/x86_64-linux-gnu/"
      LDFLAGS="$LDFLAGS -L/usr/lib/x86_64-linux-gnu/"
      OPENSSL_ARGS=
    else
      LD_LIBRARY_PATH=$OPENSSL_ROOT/lib:$LD_LIBRARY_PATH
      CXXFLAGS="$CXXFLAGS -I$BUILD_DIR/openssl-$OPENSSL_VERSION/include"
      CFLAGS="$CFLAGS -I$BUILD_DIR/openssl-$OPENSSL_VERSION/include"
      LDFLAGS="$LDFLAGS -L$BUILD_DIR/openssl-$OPENSSL_VERSION/lib"
      OPENSSL_ROOT=$BUILD_DIR/openssl-$OPENSSL_VERSION
      OPENSSL_ARGS=--with-openssl=$OPENSSL_ROOT
    fi
  else
    OPENSSL_ARGS=
  fi

  if [ -d "${PIC_LIB_PATH:-}" ]; then
    PIC_LIB_OPTIONS="--with-zlib=${PIC_LIB_PATH} "
  fi

  if [[ "$OSTYPE" == "darwin"* ]]; then
    wrap aclocal -I ./aclocal
    wrap glibtoolize --copy
    wrap autoconf
  fi

  if [[ ${SYSTEM_AUTOTOOLS} -eq 0 ]]; then
    PATH=${BUILD_DIR}/automake-${AUTOMAKE_VERSION}/bin/:$PATH
    PATH=${BUILD_DIR}/autoconf-${AUTOCONF_VERSION}/bin/:$PATH
  fi

  PATH="${BISON_ROOT}"/bin:"${PATH}" \
    PY_PREFIX="${LOCAL_INSTALL}"/python \
    wrap ./configure \
    --with-pic \
    --prefix="${LOCAL_INSTALL}" \
    --enable-tutorial=no \
    --with-c_glib=no \
    --with-php=no \
    --with-java=no \
    --with-perl=no \
    --with-erlang=no \
    --with-csharp=no \
    --with-ruby=no \
    --with-haskell=no \
    --with-erlang=no \
    --with-d=no \
    --with-boost="${BOOST_ROOT}" \
    --with-zlib="${ZLIB_ROOT}" \
    --with-nodejs=no \
    --with-lua=no \
    --with-go=no \
    --with-qt4=no \
    --with-libevent=no \
    ${PIC_LIB_OPTIONS:-} \
    ${OPENSSL_ARGS} \
    ${CONFIGURE_FLAG_BUILD_SYS}
  # The error code is zero if one or more libraries can be built. To ensure that C++
  # and python libraries are built the output should be checked.
  if ! grep -q "Building C++ Library \.* : yes" "${BUILD_LOG}"; then
    echo "Thrift cpp lib configuration failed."
    exit 1
  fi
  if ! grep -q "Building Python Library \.* : yes" "${BUILD_LOG}"; then
    echo "Thrift python lib configuration failed."
    exit 1
  fi

  wrap make install # Thrift 0.9.0 doesn't build with -j${BUILD_THREADS}
  cd contrib/fb303
  rm -f config.cache
  chmod 755 ./bootstrap.sh
  wrap ./bootstrap.sh --with-boost="${BOOST_ROOT}"
  wrap chmod 755 configure
  CPPFLAGS="-I${LOCAL_INSTALL}/include" PY_PREFIX="${LOCAL_INSTALL}"/python wrap ./configure \
    --with-boost="${BOOST_ROOT}" \
    --with-java=no --with-php=no --prefix="${LOCAL_INSTALL}" \
    --with-thriftpath="${LOCAL_INSTALL}" ${OPENSSL_ARGS}
  wrap make -j"${BUILD_THREADS}" install

  footer $PACKAGE $PACKAGE_VERSION
fi
