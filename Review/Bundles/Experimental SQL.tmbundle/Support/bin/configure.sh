"$DIALOG" -d'{sqlConnections = ( { title = "untitled"; serverType = MySQL; hostName = localhost; } ); }' -n'{ SQL_New_Connection = { title = "untitled"; serverType = MySQL; hostName = localhost; }; }' -p{} "${TM_BUNDLE_SUPPORT}/nibs/connections.nib" &>/dev/console &
