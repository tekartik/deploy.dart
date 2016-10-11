#!/bin/bash

# Fast fail the script on failures.
set -e

# dartanalyzer --fatal-warnings \
dartanalyzer \
  lib/ae_deploy.dart \
  lib/fs_deploy.dart \
  lib/gs_deploy.dart \

pub run test -p vm
pub run test -p chrome,firefox
# pub run test -p content-shell -j 1
# pub run test -p firefox -j 1 --reporter expanded