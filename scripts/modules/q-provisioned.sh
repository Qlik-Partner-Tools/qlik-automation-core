# Execute any Shell scripts in ../Shared-Content/Scripts

folder=/vagrant/shared-content/scripts

if ([ -d "$folder" ] && [ "$(ls -A $folder)" ]); then
    if ls -A $folder/*.sh 1> /dev/null 2>&1; then
        echo "Executing extra custom scripts in Shared-Content/Scripts."
        for entry in "$folder"/*.sh
        do
            sh "$entry" -H || break 
        done
    else
        exit 1;
    fi
fi

echo "Server provisioning Complete."
