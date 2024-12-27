#!/usr/bin/env bash

workdir=$(cd $(dirname $0);pwd)
cd $workdir
package_base_name='rke2-deploy'

if [ -z $BUILD_NUMBER ] || [ -z $JOB_NAME ] || [ -z $GIT_BRANCH ]; then
   echo "Not in jenkins!"
   echo "debug use follow"
   echo "export BUILD_NUMBER=0; export JOB_NAME=$package_base_name; export GIT_BRANCH=master"
   exit -1
fi

# master or bugfix
if [[ "$GIT_BRANCH" =~ "master" ]];then
   BRANCH_FLAG=999
else
   BRANCH_FLAG=${GIT_BRANCH##*.}
fi

BIG_NUMBER="7"
SMALL_NUMBER=$BRANCH_FLAG
ver=$BIG_NUMBER.$SMALL_NUMBER.$BUILD_NUMBER
export ver

package_new_name="$package_base_name-$ver.bin"

IDENTITY=fileserver@192.222.1.150
FILEDIR=/var/lib/astute/fileserver/jenkins/jenkins1/production-kolla/$JOB_NAME/x86_64
md5sum $package_new_name >> ${package_new_name}.md5
ssh $IDENTITY mkdir -p $FILEDIR/$BUILD_NUMBER
scp $package_new_name ${package_new_name}.md5 $IDENTITY:$FILEDIR/$BUILD_NUMBER/
ssh $IDENTITY "rm -rf $FILEDIR/latest;ln -sf $FILEDIR/$BUILD_NUMBER $FILEDIR/latest"
