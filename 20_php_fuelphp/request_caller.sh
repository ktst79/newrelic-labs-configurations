#!/bin/bash

#export chrome='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'

echo $chrome

while :
do
    curl -X GET http://ec2-54-95-200-221.ap-northeast-1.compute.amazonaws.com:8080/nrctrl/function1
    curl -X GET http://ec2-54-95-200-221.ap-northeast-1.compute.amazonaws.com:8080/nrctrl/function2
    curl -X GET http://ec2-54-95-200-221.ap-northeast-1.compute.amazonaws.com:8080/nrctrl/function3

    sleep 10
done