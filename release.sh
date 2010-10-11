#!/bin/sh

VERSION=0.8

git branch $VERSION

git push origin $VERSION

sed 's/0.8/0.9/g' Rakefile > tmp-Rakefile

mv tmp-Rakefile Rakefile

git add Rakefile

git commit -m "Updated Rakefile for next version"

