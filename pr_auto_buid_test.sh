#!/bin/bash
cleanup(){                               
  rm -rf ${HOME}/rdas_build_test/lock_pr_auto_build_test # release the lock
}                                        
trap cleanup EXIT # release the lock no matter how this script exits

touch ./lock_pr_auto_build_test # set up a lock so that callers can avoid running multiple instances of this script

OWNER="comgsi"
REPO="RDASApp"
export SLURM_ACCOUNT=${1}
if [[ "${1}" == "" ]]; then
  echo "Usage: ${0}  account_name"
  exit 1
fi

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

# get the latest-merged PRs and remove the testing directory if existed
pr_test_list=( $(gh pr list --state=merged --limit 5 --repo $OWNER/$REPO | awk '{print $1;}') )
for prNumber in ${pr_test_list}; do
  rm -rf ${workdir}/${prNumber}
done

# get current open PRs and with an "test_${MACHINE_ID}" label
pr_test_list=( $(gh pr list --label test_${MACHINE_ID} --state=open --repo $OWNER/$REPO | awk '{print $1;}') )
for prNumber in ${pr_test_list}; do
  rm -rf ${workdir}/${prNumber}
  gh pr edit ${prNumber} --remove-label test_${MACHINE_ID} --add-label running_${MACHINE_ID} --repo $OWNER/$REPO &>/dev/null

  cd ${workdir}
  json_data=$(gh pr view ${prNumber} --repo ${OWNER}/${REPO} --json headRepositoryOwner,headRepository,headRefName)
  head_ref=$(echo "$json_data" | jq -r '.headRefName')
  repo_name=$(echo "$json_data" | jq -r '.headRepository.name')
  repo_owner=$(echo "$json_data" | jq -r '.headRepositoryOwner.login')
  git clone -b ${head_ref} --recursive git@github.com:${repo_owner}/${repo_name} ${prNumber} #&>${workdir}/log.clone_${prNumber}

  cd ${prNumber}
  echo -e "started build_and_test on ${MACHINE_ID} at UTC time: $(date -u)" > ./comments.txt
  ./build.sh -j16 -f &>log.build
  err=$?
  if (( ${err} == 0 )); then
    source ush/load_rdas.sh
    cd build/rrfs-test
    ctest -j8 &> ../../log.test
    err=$?
    cd ../..
  fi
  if (( ${err} == 0 )); then
    gh pr edit ${prNumber} --remove-label running_${MACHINE_ID} --add-label Passed_${MACHINE_ID} --repo $OWNER/$REPO &>/dev/null
  else
    gh pr edit ${prNumber} --remove-label running_${MACHINE_ID} --add-label Failed_${MACHINE_ID} --repo $OWNER/$REPO &>/dev/null
  fi
  echo -e "finished at UTC time: $(date -u)\n\`\`\`" >> ./comments.txt
  cat ./log.test >> ./comments.txt 
  echo -e "\`\`\`\nworkdir: ${workdir}/${prNumber}" >> ./comments.txt
  gh pr comment ${prNumber} --body-file ./comments.txt --repo $OWNER/$REPO &>/dev/null
done

# scrub old files
find ${workdir} -maxdepth 1 -mtime +30 -exec rm -rf {} \;
