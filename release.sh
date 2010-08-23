#!/bin/sh

VERSION=0.7

git branch $VERSION

git push origin $VERSION

sed 's/0.7/0.8/g' Rakefile > Rakefile

git add Rakefile

git commit -m "Updated Rakefile for next version"

