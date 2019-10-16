#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# --------------------------------------------------------------------------------------------

set -e

echo
echo "Current list of running processes:"
ps aux | less
echo

declare -r REPO_DIR=$( cd $( dirname "$0" ) && cd .. && pwd )
declare -r buildRuntimeImagesScript="$REPO_DIR/build/buildRunTimeImages.sh"
declare -r testProjectName="Oryx.RuntimeImage.Tests"

# Load all variables
source $REPO_DIR/build/__variables.sh

if [ "$1" = "skipBuildingImages" ]
then
    echo
    echo "Skipping building runtime images as argument '$1' was passed..."
else
    echo
    echo "Invoking script '$buildRuntimeImagesScript'..."
    $buildRuntimeImagesScript "$@"
fi

if [ -n "$2" ]
then
    echo
    echo "Setting environment variable 'ORYX_TEST_IMAGE_BASE' to provided value '$2'."
    export ORYX_TEST_IMAGE_BASE="$2"
fi

echo
echo "Building and running tests..."
cd "$TESTS_SRC_DIR/$testProjectName"

artifactsDir="$REPO_DIR/artifacts"
mkdir -p "$artifactsDir"
diagnosticFileLocation="$artifactsDir/$testProjectName-log.txt"

# Create a directory to capture any debug logs that MSBuild generates
msbuildDebugLogsDir="$artifactsDir/msbuildDebugLogs"
mkdir -p "$msbuildDebugLogsDir"
export MSBUILDDEBUGPATH="$msbuildDebugLogsDir"
export MSBUILDDISABLENODEREUSE=1

dotnet test \
    --diag "$diagnosticFileLocation" \
    --verbosity diag \
    --test-adapter-path:. \
    --logger:"xunit;LogFilePath=$ARTIFACTS_DIR\testResults\\$testProjectName.xml" \
    -c $BUILD_CONFIGURATION
