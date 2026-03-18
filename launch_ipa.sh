#!/bin/bash

cp -r DerivedData/Build/Products/Debug-iphoneos/BlueGecko.app /Users/jenkins/ios_app/
curl http://localhost:4723/wd/hub/status
if [ $? -eq 0 ]; then
    echo "Appium server is running."
else
    echo "Appium server is not running."
    osascript -e 'tell application "Terminal" to do script "appium --base-path /wd/hub"'
fi
cd iOS_Automation/Appium

mvn clean test
if [ $? -eq 0 ]; then
    echo "Launch Success."
else
    echo "Launch Failed."
fi
