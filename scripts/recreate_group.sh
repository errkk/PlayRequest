#!/bin/sh
echo "Recreating group with all available players"
bin/pr rpc "PR.SonosHouseholds.GroupManager.recreate_group"
