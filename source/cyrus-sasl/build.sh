#!/usr/bin/env bash
# Copyright 2012 Cloudera Inc.
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

if needs_build_package ; then
  header $PACKAGE $PACKAGE_VERSION

  WITH_FRAMEWORKS=
  if [[ "$OSTYPE" == "darwin"* ]]; then
    WITH_FRAMEWORKS=--disable-macos-framework
  fi

  # Disable everything except those protocols needed -- currently just Kerberos.
  # Sasl does not have a --with-pic configuration.
  CFLAGS="$CFLAGS -fPIC -DPIC" CXXFLAGS="$CXXFLAGS -fPIC -DPIC" wrap ./configure \
    --disable-sql --disable-otp --disable-ldap --disable-digest --with-saslauthd=no \
    --prefix=$LOCAL_INSTALL --enable-static --enable-staticdlopen $WITH_FRAMEWORKS
  # the first time you do a make it fails, build again.
  wrap make || /bin/true
  wrap make -j${BUILD_THREADS:-4}
  wrap make install

  footer $PACKAGE $PACKAGE_VERSION
fi
