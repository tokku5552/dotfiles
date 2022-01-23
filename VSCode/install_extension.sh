#!/bin/bash

cat ./extensions | while read line;
do
    code --install-extension $line
done
