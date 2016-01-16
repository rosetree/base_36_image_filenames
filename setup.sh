#!/bin/bash

if [ ! -d ~/bin ]; then
  echo "Create a ~/bin directory and make sure it is added to your PATH."
  exit 1
fi

ln -s `pwd`/base_36_image_files.rb ~/bin/base36imagefiles
