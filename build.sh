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

export SOURCE_DIR="$( cd "$( dirname "$0" )" && pwd )"
# The init.sh script contains all the necessary logic to setup the environment
# for the build process. This includes setting the right compiler and linker
# flags.
source ./init.sh

source ./init-compiler.sh

function build() {
  echo "Requesting build of $1 $2"
  PACKAGE=`echo "$1" | awk '{print toupper($0)}'`
  if [ "$PACKAGE" == "THRIFT" ]; then
    echo "Building thrift"
    export BOOST_VERSION=1.57.0
    export ZLIB_VERSION=1.2.11
    export OPENSSL_VERSION=1.1.1
    export BISON_VERSION=3.0.4
  else
    echo "Building not thrift"
  fi
  # Replace potential - with _
  PACKAGE="${PACKAGE//-/_}"
  VAR_NAME="${PACKAGE}_VERSION"
  VAR_PACKAGE="BUILD_${PACKAGE}"
  export $VAR_NAME=$2
  export BUILD_ALL=0
  export $VAR_PACKAGE=1
  $SOURCE_DIR/source/$1/build.sh

  if [ "$PACKAGE" == "THRIFT" ]; then
    echo "Building thrift"
    export BOOST_VERSION=1.57.0
    export ZLIB_VERSION=1.2.11
    export OPENSSL_VERSION=1.1.1
    export BISON_VERSION=3.0.4
  fi
}

# Check that command line arguments were passed correctly.
if [ "$#" == "0" ]; then
  echo "Usage $0 package1 version1 [package2 version2 ...]"
  echo "      Builds on ore more packages identified by package_name"
  echo "      and version identifier."
  echo ""
  false
fi

while (( "$#" )); do
  package=$1
  shift
  if [ "$#" == "0" ]; then
    echo "Version not found for ${package}."
    false
  fi
  version=$1
  shift
  build $package $version
done
