#!/bin/bash
cd swift/reminders
xcodebuild clean build -project reminders.xcodeproj -scheme reminders CODE_SIGNING_REQUIRED=NO -destination 'platform=iOS Simulator,name=iPhone X,OS=12.1' -quiet
xcodebuild test -project reminders.xcodeproj -scheme reminders -destination 'platform=iOS Simulator,name=iPhone X,OS=12.1'  -enableCodeCoverage  YES -quiet
