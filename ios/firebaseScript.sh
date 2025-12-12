if [ "$CONFIGURATION" == "Debug-prestage" ] || [ "$CONFIGURATION" == "Release-prestage" ]; then
  cp Runner/prestage/GoogleService-Info.plist Runner/GoogleService-Info.plist
elif [ "$CONFIGURATION" == "Debug-stage" ] || [ "$CONFIGURATION" == "Release-stage" ]; then
  cp Runner/stage/GoogleService-Info.plist Runner/GoogleService-Info.plist
elif [ "$CONFIGURATION" == "Debug-production" ] || [ "$CONFIGURATION" == "Release-production" ]; then
  cp Runner/production/GoogleService-Info.plist Runner/GoogleService-Info.plist
fi

