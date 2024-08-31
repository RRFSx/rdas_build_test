#!/bin/bash

github=$1
branch=$2
account=$3

if [[ -z "${github}" ]] || [[ -z "${branch}"  ]] || [[ -z "${account}"  ]]; then
  echo "Usage: $0 github_name branch_name account_name"
  exit
fi

repo="https://github.com/${github}/RDASApp"

set -x
rm -rf RDASApp  # start from a fresh copy
git clone --recursive -b ${branch} ${repo}
cd RDASApp
./build.sh
ush/run_rrfs_tests.sh ${account}
