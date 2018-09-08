#!/usr/bin/env bash

set -e

echo -e '\033[1mTASK: Fetching dependencies [pub get]\033[22m'
echo -e 'pub get'
pub get

echo -e '\033[1mTASK: Dart Analyzer [analyzer]\033[22m'
echo -e 'dartanalyzer --fatal-warnings .'
dartanalyzer --fatal-warnings .

echo -e '\033[1mTASK: Dart Format [dartfmt]\033[22m'
echo -e 'dartfmt -n lib/ test/ example/'
dartfmt -n lib/ test/ example/

echo -e '\033[1mTASK: Testing [test]\033[22m'
pub run dart_coveralls report \
  --retry 2 \
  --exclude-test-files \
  --throw-on-error \
  --throw-on-connectivity-error \
  --debug test/test_all.dart