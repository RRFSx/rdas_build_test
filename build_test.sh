#!/bin/bash

fork=$1
branch=$2
account=$3

if [[ -z "${fork}" ]] || [[ -z "${branch}"  ]] || [[ -z "${account}"  ]]; then
  echo "Usage: ${0} fork_name branch_name account_name"
  exit
fi

repo="https://github.com/${fork}/RDASApp"

set -x
rm -rf RDASApp  # start from a fresh copy
git clone --recursive -b ${branch} ${repo}
cd RDASApp
./build.sh
ush/run_rrfs_test.sh ${account}
