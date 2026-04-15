if [[ "$CONFIGURATION" == *-prestage ]]; then
  cp Runner/prestage/GoogleService-Info.plist Runner/GoogleService-Info.plist
elif [[ "$CONFIGURATION" == *-stage ]]; then
  cp Runner/stage/GoogleService-Info.plist Runner/GoogleService-Info.plist
elif [[ "$CONFIGURATION" == *-production ]]; then
  cp Runner/production/GoogleService-Info.plist Runner/GoogleService-Info.plist
fi

