#!/bin/bash
touch doing_tests_currently # if this file exists, don't run another instances of this script

OWNER="comgsi"
REPO="RDASApp"

source ./detect_machine.sh

case "${MACHINE_ID}" in
  hera)
    workdir=/scratch1/NCEPDEV/fv3-cam/rrfsbot/PRs_${REPO}
    ;;
  jet)
    workdir=/lfs5/BMC/wrfruc/rrfsbot/PRs_${REPO}
    ;;
  hercules)
    workdir=/work/noaa/wrfruc/rrfsbot/PRs_${REPO}
    ;;
  *)
    echo "Unsupported platform=${MACHINE_ID}. Exiting with error."
    exit 1
    ;;
esac
mkdir -p ${workdir}

set -x

# get current open PRs and with an "test_${MACHINE_ID}" label
pr_test_list=( $(gh pr list --lable test_${MACHINE_ID} --state=open --repo $OWNER/$REPO | awk '{print $1;}') )
for prNumber in ${pr_test_list}; do
  rm -rf ${workdir}/${prNumber}
  gh pr edit ${prNumber} --remove-label test_${MACHINE_ID} --add-label running_${MACHINE_ID}

  cd ${workdir}
  json_data=$(gh pr view ${prNumber} --repo ${OWNER}/${REPO} --json headRepositoryOwner,headRepository,headRefName)
  head_ref=$(echo "$json_data" | jq -r '.headRefName')
  repo_name=$(echo "$json_data" | jq -r '.headRepository.name')
  repo_owner=$(echo "$json_data" | jq -r '.headRepositoryOwner.login')
  git clone -b ${head_ref} --recursive git@github.com:${repo_owner}/${repo_name} ${prNumber}

  cd ${prNumber}
  ./build.sh -j16 -f 2>&1 1>log.build
  err=$?
  if (( ${err} == 0 )); then
    ush/run_rrfs_tests.sh ${account} 2>&1  1> log.test
    err=$?
  fi
  if (( ${err} == 0 )); then
    gh pr edit $pr --remove-label running_${MACHINE_ID} --add-label Passed_${MACHINE_ID}
  else
    gh pr edit $pr --remove-label running_${MACHINE_ID} --add-label Failed_${MACHINE_ID}
  fi
done

# scrub files older than 60 days
find ${workdir} -maxdepth 1 -mtime +60 -exec rm -rf {} \;
