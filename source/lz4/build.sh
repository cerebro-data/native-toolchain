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

# Exit on non-true return value
set -e
# Exit on reference to uninitialized variable
set -u

set -o pipefail

source $SOURCE_DIR/functions.sh
THIS_DIR="$( cd "$( dirname "$0" )" && pwd )"
prepare $THIS_DIR

if [ "${LZ4_VERSION}" != "svn" ]; then
  download_cerebro_dependency "${LPACKAGE_VERSION}.tar.gz" $THIS_DIR
fi

if needs_build_package ; then
  header $PACKAGE $PACKAGE_VERSION
  if [ "${LZ4_VERSION}" != "svn" ]; then
    wrap make
    PREFIX=$BUILD_DIR/lz4-$LZ4_VERSION wrap make install
  else
    wrap cmake -DCMAKE_INSTALL_PREFIX=$LOCAL_INSTALL .
    wrap make -j${BUILD_THREADS:-4} install
  fi
  footer $PACKAGE $PACKAGE_VERSION
fi
