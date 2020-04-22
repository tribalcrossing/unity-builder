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

echo ""
echo "###########################"
echo "#    Build CSPROJ files   #"
echo "###########################"
echo ""
xvfb-run --auto-servernum --server-args='-screen 0 640x480x24' \
/opt/Unity/Editor/Unity \
  -batchmode \
  -nographics \
  -logfile ./artifacts/build_csproj_output.txt \
  -silent-crashes \
  -buildTarget "$BUILD_TARGET" \
  -customBuildTarget "$BUILD_TARGET" \
  -quit -executeMethod "UnityEditor.SyncVS.SyncSolution"


echo "############################"
echo "#    Install DotNet        #"
echo "############################"

wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
add-apt-repository universe
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
sh -c 'echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" > /etc/apt/sources.list.d/mono-official-stable.list'
apt-get update
apt-get -y -qq install dirmngr gnupg apt-transport-https ca-certificates apt-utils
apt-get -y -qq install dotnet-sdk-2.1 dotnet-sdk-3.1 mono-complete mono-devel nuget

echo ""
echo "###########################"
echo "#    Setup Project        #"
echo "###########################"
echo ""

chmod -R 777 * 
dotnet restore workspace.sln
dotnet restore Lit.Tests/Lit.Tests.sln
nuget restore . -PackagesDirectory .

chmod -R 777 * 
cd Lit.Tests
dotnet tool install --global Project2015To2017.Migrate2019.Tool
export PATH="$PATH:~/.dotnet/tools"
dotnet migrate-2019 migrate ../workspace.sln
dotnet migrate-2019 migrate ../Assembly-CSharp.csproj
dotnet migrate-2019 migrate ../Assembly-CSharp-firstpass.csproj
dotnet migrate-2019 migrate ../Assembly-CSharp-Editor.csproj
dotnet migrate-2019 migrate ../LAssembly-CSharp-Editor-firstpass.csproj
dotnet migrate-2019 migrate Lit.Tests.sln
cd ..

echo "Changing csprojs to target .NET Core 3.1."

sed -i 's/TargetFramework>net471<\/TargetFramework/TargetFramework>netcoreapp3.1<\/TargetFramework/g' Assembly-CSharp.csproj
sed -i 's/TargetFramework>net471<\/TargetFramework/TargetFramework>netcoreapp3.1<\/TargetFramework/g' Assembly-CSharp-firstpass.csproj
sed -i 's/TargetFramework>net471<\/TargetFramework/TargetFramework>netcoreapp3.1<\/TargetFramework/g' Assembly-CSharp-Editor.csproj
sed -i 's/TargetFramework>net471<\/TargetFramework/TargetFramework>netcoreapp3.1<\/TargetFramework/g' Assembly-CSharp-Editor-firstpass.csproj


echo ""
echo "###########################"
echo "#    Artifacts folder     #"
echo "###########################"
echo ""
echo "Creating \"$FULL_ARTIFACTS_PATH\" if it does not exist."
mkdir -p artifacts


echo ""
echo "###########################"
echo "#  Restore Dependencies   #"
echo "###########################"
echo ""
chmod -R 777 * 
dotnet restore Lit.Tests/Lit.Tests.sln

echo ""
echo "########################"
echo "#    Run Unit Test     #"
echo "########################"
echo ""

echo $FULL_ARTIFACTS_PATH
dotnet test Lit.Tests/Lit.Tests.sln --no-restore --logger "html;logfilename=test_result.html" --results-directory ./artifacts

TEST_RUNNER_EXIT_CODE=$?

echo ""
echo "###########################"
echo "#    Project directory    #"
echo "###########################"
echo ""
ls -alh $UNITY_PROJECT_PATH

