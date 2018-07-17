# Execute any Shell scripts in ../Shared-Content/Scripts

echo "Executing extra custom scripts in Shared-Content/Scripts."

folder=/vagrant/shared-content/scripts

if ([ -d "$folder" ] && [ "$(ls -A $folder)" ]); then
    for entry in "$folder"/*.sh
    do
        sh "$entry" -H || break 
    done
fi

echo "Server provisioning Complete."