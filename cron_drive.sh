#!/bin/bash

if [[ -f ${HOME}/rdas_build_test/lock_pr_auto_build_test ]]; then
  ###echo "pass" > ${HOME}/pass.txt # for debugging
  exit 0
fi

### build and test
if [[ -e /etc/profile.d/modules.sh ]]; then
  source /etc/profile.d/modules.sh
fi
### module list > ${HOME}/module.txt # for debugging
source ${HOME}/.bashrc
cd ${HOME}/rdas_build_test
source ./detect_machine.sh
case "${MACHINE_ID}" in
  hera)
    ACCT=fv3-cam
    ;;
  jet)
    ACCT=nrtrr
    ;;
  hercules)
    ACCT=rtrr
    ;;
  *)
    echo "Unsupported platform=${MACHINE_ID}. Exiting with error."
    exit 1
    ;;
esac
./pr_auto_buid_test.sh ${ACCT}
