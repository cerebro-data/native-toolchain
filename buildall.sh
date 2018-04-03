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

# The init.sh script contains all the necessary logic to setup the environment
# for the build process. This includes setting the right compiler and linker
# flags.
source ./init.sh

################################################################################
# How to add new versions to the toolchain:
#
#   * Make sure the build script is ready to build the new version.
#   * Find the libary in the list below and create new line that follows the
#     pattern: LIBRARYNAME_VERSION=Version $SOURCE_DIR/source/LIBRARYNAME/build.sh
#
#  WARNING: Once a library has been rolled out to production, it cannot be
#  removed, but only new versions can be added. Make sure that the library
#  and version you want to add works as expected.
################################################################################
################################################################################
# Boost
################################################################################
BOOST_VERSION=1.57.0 $SOURCE_DIR/source/boost/build.sh

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

# Build LLVM 3.3 with and without asserts.
# For LLVM 3.3, the default is a release build with assertions. The assertions
# are disabled by including "no-asserts" in the version string.
LLVM_VERSION=3.3-p1 $SOURCE_DIR/source/llvm/build.sh
LLVM_VERSION=3.3-no-asserts-p1 $SOURCE_DIR/source/llvm/build.sh

# Build LLVM 3.7.0 without assertions. For LLVM 3.7+, the default is a
# release build with no assertions.
PYTHON_VERSION=2.7.10 LLVM_VERSION=3.7.0 $SOURCE_DIR/source/llvm/build.sh
#PYTHON_VERSION=2.7.10 LLVM_VERSION=3.8.0 $SOURCE_DIR/source/llvm/build.sh

################################################################################
# SASL
################################################################################
if [[ ! "$OSTYPE" == "darwin"* ]]; then
  if (( BUILD_HISTORICAL )); then
    CYRUS_SASL_VERSION=2.1.23 $SOURCE_DIR/source/cyrus-sasl/build.sh
  fi
  CYRUS_SASL_VERSION=2.1.27-p1 $SOURCE_DIR/source/cyrus-sasl/build.sh
else
  CYRUS_SASL_VERSION=2.1.26 $SOURCE_DIR/source/cyrus-sasl/build.sh
fi

################################################################################
# Build libevent
################################################################################
LIBEVENT_VERSION=1.4.15 $SOURCE_DIR/source/libevent/build.sh

################################################################################
# Build OpenSSL - this is not intended for production use of Impala.
# Libraries that depend on OpenSSL will only use it if PRODUCTION=1.
################################################################################
OPENSSL_VERSION=1.0.1p $SOURCE_DIR/source/openssl/build.sh

################################################################################
# Build ZLib
################################################################################
ZLIB_VERSION=1.2.8 $SOURCE_DIR/source/zlib/build.sh

################################################################################
# Thrift
#  * depends on boost
#  * depends on libevent
################################################################################
export LIBEVENT_VERSION=1.4.15
export BOOST_VERSION=1.57.0
export ZLIB_VERSION=1.2.8
export OPENSSL_VERSION=1.0.1p

if [[ ! "$OSTYPE" == "darwin"* ]]; then
  THRIFT_VERSION=0.9.0-p4 $SOURCE_DIR/source/thrift/build.sh
else
  BOOST_VERSION=1.57.0 THRIFT_VERSION=0.9.2-p2 $SOURCE_DIR/source/thrift/build.sh
fi

export -n LIBEVENT_VERSION
export -n BOOST_VERSION
export -n ZLIB_VERSION
export -n OPENSSL_VERSION

################################################################################
# gflags
################################################################################
if (( BUILD_HISTORICAL )); then
  GFLAGS_VERSION=2.0 $SOURCE_DIR/source/gflags/build.sh
fi
GFLAGS_VERSION=2.2.1 $SOURCE_DIR/source/gflags/build.sh

################################################################################
# Build gperftools
################################################################################
if (( BUILD_HISTORICAL )); then
  GPERFTOOLS_VERSION=2.5 $SOURCE_DIR/source/gperftools/build.sh
fi
GPERFTOOLS_VERSION=2.6.1 $SOURCE_DIR/source/gperftools/build.sh

################################################################################
# Build glog
################################################################################
if (( BUILD_HISTORICAL )); then
  GFLAGS_VERSION=2.0 GLOG_VERSION=0.3.2-p1 $SOURCE_DIR/source/glog/build.sh
fi
GFLAGS_VERSION=2.2.1 GLOG_VERSION=0.3.3-p1 $SOURCE_DIR/source/glog/build.sh

################################################################################
# Build gtest
################################################################################
GTEST_VERSION=1.7.0 $SOURCE_DIR/source/gtest/build.sh

# New versions of gtest are named googletest
GOOGLETEST_VERSION=release-1.8.0 $SOURCE_DIR/source/googletest/build.sh

################################################################################
# Build cctz
################################################################################
CCTZ_VERSION=2.1 $SOURCE_DIR/source/cctz/build.sh

################################################################################
# Build Snappy
################################################################################
if (( BUILD_HISTORICAL )); then
  SNAPPY_VERSION=1.1.3 $SOURCE_DIR/source/snappy/build.sh
fi
SNAPPY_VERSION=1.1.4 $SOURCE_DIR/source/snappy/build.sh

################################################################################
# Build Lz4
################################################################################
if (( BUILD_HISTORICAL )); then
  LZ4_VERSION=svn $SOURCE_DIR/source/lz4/build.sh
fi
LZ4_VERSION=1.8.0 $SOURCE_DIR/source/lz4/build.sh

################################################################################
# Build re2
################################################################################
if (( BUILD_HISTORICAL )); then
  RE2_VERSION=20130115-p1 $SOURCE_DIR/source/re2/build.sh
fi
RE2_VERSION=2017-08-01 $SOURCE_DIR/source/re2/build.sh

################################################################################
# Build Ldap
################################################################################
OPENLDAP_VERSION=2.4.25 $SOURCE_DIR/source/openldap/build.sh

################################################################################
# Build Avro
################################################################################
if (( BUILD_HISTORICAL )); then
  AVRO_VERSION=1.7.4-p4 $SOURCE_DIR/source/avro/build.sh
fi
AVRO_VERSION=1.7.4-p6 $SOURCE_DIR/source/avro/build.sh

################################################################################
# Build Rapidjson
################################################################################
RAPIDJSON_VERSION=0.11 $SOURCE_DIR/source/rapidjson/build.sh

################################################################################
# Build BZip2
################################################################################
BZIP2_VERSION=1.0.6-p1 $SOURCE_DIR/source/bzip2/build.sh

################################################################################
# Build GDB
################################################################################
if [[ ! "$RELEASE_NAME" =~ CentOS.*5\.[[:digit:]] ]]; then
  GDB_VERSION=7.9.1 $SOURCE_DIR/source/gdb/build.sh
else
  GDB_VERSION=7.9.1 build_fake_package "gdb"
fi

################################################################################
# Build Libunwind
################################################################################
LIBUNWIND_VERSION=1.1 $SOURCE_DIR/source/libunwind/build.sh

################################################################################
# Build Breakpad
################################################################################
BREAKPAD_VERSION=20150612-p1 $SOURCE_DIR/source/breakpad/build.sh
