#!/usr/bin/env bash

workdir=$(cd $(dirname $0);pwd)
cd $workdir

package_base_name='rke2-deploy'

function make_bin() {
  rm -rf ${package_base_name}-*.bin*
  [ -z $BUILD_NUMBER ] && BUILD_NUMBER=0
  [ -z $GIT_BRANCH ] && GIT_BRANCH="null"

  # master or bugfix
  if [[ "$GIT_BRANCH" =~ "master" ]];then
     BRANCH_FLAG=999
  else
     BRANCH_FLAG=${GIT_BRANCH##*.}
  fi
  
  if [ -z $BUILD_NUMBER ];then BUILD_NUMBER=0; fi
  BIG_NUMBER="7"
  SMALL_NUMBER=$BRANCH_FLAG
  ver=$BIG_NUMBER.$SMALL_NUMBER.$BUILD_NUMBER
  export ver

  chmod +x ${workdir}/makeself.sh
  ${workdir}/makeself/makeself.sh --gzip src $package_base_name-$ver.bin $package_base_name ./setup.sh
  echo "make rke2-deploy bin completed: $package_base_name-$ver.bin"
}

make_bin