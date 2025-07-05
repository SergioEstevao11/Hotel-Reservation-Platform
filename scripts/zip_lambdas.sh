#!/bin/bash

cd lambdas

for dir in */ ; do
  dirname="${dir%/}"  # remove trailing slash
  (cd "$dirname" && zip -r "${dirname}_handler.zip" .)
done
