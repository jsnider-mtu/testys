#!/bin/bash
## This is the primary testy
if [ -z /tmp/testy.tmp ]; then
  touch /tmp/testy.tmp && echo "I touched the tmp testy"
else
  echo "I ain't touching it again.."
fi
