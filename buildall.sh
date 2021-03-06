#!/usr/bin/env bash
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

# Set up the environment configuration.
source ./init.sh
# Configure the compiler/linker flags, bootstrapping tools if necessary.
source ./init-compiler.sh

################################################################################
# How to add new versions to the toolchain:
#
#   * Make sure the build script is ready to build the new version.
#   * Find the library in the list below and create new line that follows the
#     pattern: LIBRARYNAME_VERSION=Version $SOURCE_DIR/source/LIBRARYNAME/build.sh
#
#  WARNING: Once a library has been rolled out to production, it cannot be
#  removed, but only new versions can be added. Make sure that the library
#  and version you want to add works as expected.
################################################################################
################################################################################
# Boost
################################################################################
BOOST_VERSION=1.57.0-p3 $SOURCE_DIR/source/boost/build.sh

################################################################################
# Build Python
################################################################################
if [[ ! "$OSTYPE" == "darwin"* ]]; then
  PYTHON_VERSION=2.7.11 build_fake_package "python"
  PYTHON_VERSION=2.7.10 $SOURCE_DIR/source/python/build.sh
else
  PYTHON_VERSION=2.7.10 build_fake_package "python"
fi

################################################################################
# LLVM
################################################################################
(
  export PYTHON_VERSION=2.7.10
  LLVM_VERSION=5.0.1 $SOURCE_DIR/source/llvm/build.sh
)

################################################################################
# SASL
################################################################################
if [[ ! "$OSTYPE" == "darwin"* ]]; then
  CYRUS_SASL_VERSION=2.1.27-p1 $SOURCE_DIR/source/cyrus-sasl/build.sh
else
  CYRUS_SASL_VERSION=2.1.26 $SOURCE_DIR/source/cyrus-sasl/build.sh
fi

################################################################################
# Build protobuf
################################################################################
PROTOBUF_VERSION=3.5.1 $SOURCE_DIR/source/protobuf/build.sh

################################################################################
# Build OpenSSL - this is not intended for production use of Impala.
# Libraries that depend on OpenSSL will only use it if PRODUCTION=1.
################################################################################
$SOURCE_DIR/source/openssl/build.sh

################################################################################
# Build ZLib
################################################################################
ZLIB_VERSION=1.2.11 $SOURCE_DIR/source/zlib/build.sh

################################################################################
# Build Bison
################################################################################
BISON_VERSION=3.0.4 $SOURCE_DIR/source/bison/build.sh

################################################################################
# Thrift
#  * depends on bison, boost, zlib, openssl
################################################################################
export BOOST_VERSION=1.57.0
export ZLIB_VERSION=1.2.11
export BISON_VERSION=3.0.4

if [[ ! "$OSTYPE" == "darwin"* ]]; then
  if (( BUILD_HISTORICAL )); then
    echo "Building thrift 0.9.0"
    THRIFT_VERSION=0.9.0-p11 $SOURCE_DIR/source/thrift/build.sh
    THRIFT_VERSION=0.9.3-p4 $SOURCE_DIR/source/thrift/build.sh
    echo "Building thrift 0.11.0-p2"
    THRIFT_VERSION=0.11.0-p2 $SOURCE_DIR/source/thrift/build.sh
  fi
  THRIFT_VERSION=0.11.0-p3 $SOURCE_DIR/source/thrift/build.sh
else
  BOOST_VERSION=1.57.0 THRIFT_VERSION=0.9.2-p2 $SOURCE_DIR/source/thrift/build.sh
fi

export -n BOOST_VERSION
export -n ZLIB_VERSION
export -n BISON_VERSION

################################################################################
# gflags
################################################################################
GFLAGS_VERSION=2.2.1 $SOURCE_DIR/source/gflags/build.sh

################################################################################
# Build gperftools
################################################################################
if (( BUILD_HISTORICAL )); then
  GPERFTOOLS_VERSION=2.7 $SOURCE_DIR/source/gperftools/build.sh
fi
GPERFTOOLS_VERSION=2.8 $SOURCE_DIR/source/gperftools/build.sh

################################################################################
# Build glog
################################################################################
if (( BUILD_HISTORICAL )); then
  GFLAGS_VERSION=2.2.1 GLOG_VERSION=0.3.4 $SOURCE_DIR/source/glog/build.sh
fi
GFLAGS_VERSION=2.2.1 GLOG_VERSION=0.4.0 $SOURCE_DIR/source/glog/build.sh

################################################################################
# Build gtest
################################################################################
GOOGLETEST_VERSION=release-1.8.0 $SOURCE_DIR/source/googletest/build.sh

################################################################################
# Build cctz
################################################################################
if (( BUILD_HISTORICAL )); then
  CCTZ_VERSION=2.1 $SOURCE_DIR/source/cctz/build.sh
fi
CCTZ_VERSION=2.3 $SOURCE_DIR/source/cctz/build.sh

################################################################################
# Build Snappy
################################################################################
if (( BUILD_HISTORICAL )); then
  SNAPPY_VERSION=1.1.4 $SOURCE_DIR/source/snappy/build.sh
fi
SNAPPY_VERSION=1.1.8 $SOURCE_DIR/source/snappy/build.sh

################################################################################
# Build Lz4
################################################################################
if (( BUILD_HISTORICAL )); then
  LZ4_VERSION=1.8.3 $SOURCE_DIR/source/lz4/build.sh
fi
LZ4_VERSION=1.9.2 $SOURCE_DIR/source/lz4/build.sh

################################################################################
# Build ZSTD
################################################################################
if (( BUILD_HISTORICAL )); then
  ZSTD_VERSION=1.3.8 $SOURCE_DIR/source/zstd/build.sh
  ZSTD_VERSION=1.4.3 $SOURCE_DIR/source/zstd/build.sh
fi
ZSTD_VERSION=1.4.5 $SOURCE_DIR/source/zstd/build.sh

################################################################################
# Build re2
################################################################################
if (( BUILD_HISTORICAL )); then
  RE2_VERSION=2017-08-01 $SOURCE_DIR/source/re2/build.sh
  RE2_VERSION=20190301 $SOURCE_DIR/source/re2/build.sh
fi
RE2_VERSION=2020-08-01 $SOURCE_DIR/source/re2/build.sh

################################################################################
# Build Ldap
################################################################################
# Build the older version *ONLY* on older OSes (e.g. Ubuntu 16.04)
if (( BUILD_HISTORICAL )); then
  OPENLDAP_VERSION=2.4.25 $SOURCE_DIR/source/openldap/build.sh
  OPENLDAP_VERSION=2.4.48 $SOURCE_DIR/source/openldap/build.sh
  # We need to wipe out the soure directory so that configuration is run again.
  # this is only needed because we're building 2.4.48 twice
  echo "ls: `ls $SOURCE_DIR/source/openldap`"
  echo "running rm -rf $SOURCE_DIR/source/openldap/openldap-2.4.48"
  rm -rf $SOURCE_DIR/source/openldap/openldap-2.4.48
fi
OPENLDAP_VERSION=2.4.48-p1 $SOURCE_DIR/source/openldap/build.sh

################################################################################
# Build Avro
################################################################################
if (( BUILD_HISTORICAL )); then
  AVRO_VERSION=1.7.4-p6 $SOURCE_DIR/source/avro/build.sh
  AVRO_VERSION=1.7.4-p7 $SOURCE_DIR/source/avro/build.sh
fi
AVRO_VERSION=1.7.4-p8 $SOURCE_DIR/source/avro/build.sh

################################################################################
# Build Rapidjson
################################################################################
RAPIDJSON_VERSION=1.1.0 $SOURCE_DIR/source/rapidjson/build.sh

################################################################################
# Build BZip2
################################################################################
BZIP2_VERSION=1.0.6-p1 $SOURCE_DIR/source/bzip2/build.sh

################################################################################
# Build GDB
################################################################################
if (( BUILD_HISTORICAL )); then
  GDB_VERSION=7.9.1 $SOURCE_DIR/source/gdb/build.sh
fi
GDB_VERSION=8.3.1 $SOURCE_DIR/source/gdb/build.sh

################################################################################
# Build Libunwind
################################################################################
LIBUNWIND_VERSION=1.1 $SOURCE_DIR/source/libunwind/build.sh

################################################################################
# Build Breakpad
################################################################################
BREAKPAD_VERSION=97a98836768f8f0154f8f86e5e14c2bb7e74132e $SOURCE_DIR/source/breakpad/build.sh

################################################################################
# Build ORC
################################################################################
(
  export LZ4_VERSION=1.9.2
  export PROTOBUF_VERSION=3.5.1
  export SNAPPY_VERSION=1.1.8
  export ZLIB_VERSION=1.2.11
  export GOOGLETEST_VERSION=release-1.8.0
  ORC_VERSION=1.6.2-p7 $SOURCE_DIR/source/orc/build.sh
)

echo "#######################################################################"
echo " All Done"
echo "#######################################################################"
