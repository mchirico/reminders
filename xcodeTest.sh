#!/bin/bash
cd swift/reminders
xcodebuild clean build -project Reminders.xcodeproj -scheme Reminders CODE_SIGNING_REQUIRED=NO -destination 'platform=iOS Simulator,name=iPhone X,OS=12.1' -quiet
xcodebuild test -project Reminders.xcodeproj -scheme Reminders -destination 'platform=iOS Simulator,name=iPhone X,OS=12.1'  -enableCodeCoverage  YES -quiet
