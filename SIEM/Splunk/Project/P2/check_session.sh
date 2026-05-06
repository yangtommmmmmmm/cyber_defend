#!/bin/bash

THRESOLD=9

echo "----------------------------------------------------------------------"
echo "System Session Monitor"
echo "Executed Time: $(date '+%Y-%m-%d %H-%M-%s')"
echo "----------------------------------------------------------------------"

CURRENT_USERS=$(who -u | wc -l)
echo "Total session count: $CURRENT_USERS"

if [ "$CURRENT_USERS" -gt "$THRESOLD" ]; then
    echo -e "\n\033[31m[Alerts]Please check the session counts!\033[0m"
else
    echo -e "\n\033[32m[Normal]The session counts are in safe range.\033[0m"
fi

echo "----------------------------------------------------------------------"
