# rdas_build_test

```
git clone https://github.com/rrfsx/rdas_build_test.git
cd rdas_build_test
./build_test.sh guoqing-noaa hotfix rtrr
```
The usage of build_test.sh is as follows:
`./build_test.sh github_name branch_name account_name`  

In the above example, `guoqing-noaa` is the github account name, `hotfix` is the branch name and `rtrr` is the slurm account to be used.  
So we are trying to test the `hotfix` branch of the `guoqing-noaa/RDASApp` repository here.   

_NOTE: One only needs to clone rdas_build_test once and can use it to test different forks/branches._
