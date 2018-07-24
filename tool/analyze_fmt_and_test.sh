#!/bin/bash

# Fast fail the script on failures.
set -xe

dartfmt -w bin lib test
dartanalyzer --fatal-warnings bin lib test

pub run test -p vm
pub run build_runner test