#!/bin/sh
# Decode base64 if needed, then fix common iCalendar issues
if base64 -D "$1" 2>/dev/null | grep -q "BEGIN:VCALENDAR"; then
  base64 -D "$1" > /tmp/fixed.ics
else
  cp "$1" /tmp/fixed.ics
fi
# Ensure METHOD:PUBLISH (Apple Calendar requirement)
sed -i '' 's/METHOD:REQUEST/METHOD:PUBLISH/g' /tmp/fixed.ics
# Open in Calendar
open -a Calendar /tmp/fixed.ics
