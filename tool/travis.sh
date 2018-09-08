#!/usr/bin/env bash

pub run dart_coveralls report \
  --retry 2 \
  --exclude-test-files \
  --throw-on-error \
  --throw-on-connectivity-error \
  --debug test/test_all.dart