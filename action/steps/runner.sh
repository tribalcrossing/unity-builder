#!/usr/bin/env bash

#
# Set and display project path
#

UNITY_PROJECT_PATH="$GITHUB_WORKSPACE/$PROJECT_PATH"
echo "Using project path \"$UNITY_PROJECT_PATH\"."

#
# Set and display the artifacts path
#

echo "Using artifacts path \"$ARTIFACTS_PATH\" to save test results."
FULL_ARTIFACTS_PATH=$GITHUB_WORKSPACE/$ARTIFACTS_PATH

#
# Display custom parameters
#
echo "Using custom parameters $CUSTOM_PARAMETERS."


echo "Using build target \"$BUILD_TARGET\"."

# The following tests are 2019 mode (requires Unity 2019.2.11f1 or later)
# Reference: https://docs.unity3d.com/2019.3/Documentation/Manual/CommandLineArguments.html

#
# Display the unity version
#

echo "Using Unity version \"$UNITY_VERSION\" to run."

#
# Overall info
#

echo "#############################################"
echo "#    Install DotNet and Run Unit Test       #"
echo "#############################################"

wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
add-apt-repository universe
apt-get update
apt-get install apt-transport-https
apt-get update
apt-get install dotnet-sdk-2.1
pushd "$UNITY_PROJECT_PATH/Lit.Tests"
dotnet tool install --global Project2015To2017.Migrate2019.Tool
dotnet-migrate-2019 migrate Lit.Tests.sln
dotnet restore Lit.Tests.sln
dotnet test Lit.Tests.sln --no-restore --verbosity normal
popd

echo ""
echo "###########################"
echo "#    Artifacts folder     #"
echo "###########################"
echo ""
echo "Creating \"$FULL_ARTIFACTS_PATH\" if it does not exist."
mkdir -p $FULL_ARTIFACTS_PATH

echo ""
echo "###########################"
echo "#    Project directory    #"
echo "###########################"
echo ""
ls -alh $UNITY_PROJECT_PATH


xvfb-run --auto-servernum --server-args='-screen 0 640x480x24' \
/opt/Unity/Editor/Unity \
  -batchmode \
  -nographics \
  -logfile /dev/stdout \
  -silent-crashes \
  -buildTarget "$BUILD_TARGET" \
  -customBuildTarget "$BUILD_TARGET" \
  $CUSTOM_PARAMETERS

#
# Results
#

echo ""
echo "###########################"
echo "#    Project directory    #"
echo "###########################"
echo ""
ls -alh $UNITY_PROJECT_PATH

