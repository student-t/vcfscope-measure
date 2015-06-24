#!/bin/bash
set -x -e -o pipefail

function dxlogin {
  source $HOME/dx-toolkit/environment
  dx login --noprojects --token=${bamboo_DX_TOKEN}
}

# Deploy, but do not publish an app, for testing
function build_smoketest_app {
  dx build . --version smoketest --app --yes
}

# Deploy and publish an app. This is irreversible (but the release can be deprecated).
function publish_app {
  if [[ -n "${VERSION}" ]]; then
    dx build . --version ${VERSION} --app --publish --yes
  else
    echo >&2 "Error, $$VERSION not set. Looks like you are trying to deploy from a build agent"
    exit 1
  fi
}

# Run a basic test of a deployed app.
function run_smoketest {
  vcfgz=project-Bf525x80YY8XZbFV8kJ50y2f:file-Bf54Jy80YY8Yp7x971x7zv7Z
  region=project-Bf525x80YY8XZbFV8kJ50y2f:file-Bf548200YY8k4XzZZ5FyJFJZ
  jobid=$(dx run app-kccg-validation-reporter/smoketest -ivcfgz=$vcfgz -iregion=$region -iextended=true --yes --brief)

  #
  # consistent to all applets
  #
  # returns non-0 if there's a problem.
  dx watch -q --no-job-info  -f '{msg}' ${jobid}
  dx describe ${jobid}

  echo -n "Total job price: "
  dx describe --json ${jobid} | jq .totalPrice
}


if [[ $1 = "smoketest" ]]; then 
  dxlogin
  build_smoketest_app
  run_smoketest
elif [[ $1 = "publish" ]]; then
  dxlogin
  publish_app
fi
