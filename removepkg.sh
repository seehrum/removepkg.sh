#!/bin/bash

# Script to manage package removal for Linux Mint 21.3 "Virginia" - Xfce Edition

check_packages_file() {
    if [[ ! -f "packages.list" ]]; then
        echo "Error: The file 'packages.list' does not exist."
        echo "Please run '$0 -l' to generate this file."
        exit 1
    fi
}

generate_package_list() {
	dpkg -l | awk '/ii/ { info = $5; for (i = 6; i <= NF; i++) info = info " " $i; package = "\"" "#" $2 "\""; printf "%-45s # %-5s - %s\n", package, $4, info; }' > packages.list
	echo "Package list created: packages.list"
}

# Ensure the script is run with superuser privileges
if [[ $(id -u) -ne 0 ]]; then
    echo "This script needs to be run as root."
    exit 1
fi

# Function to read and prepare packages for removal
read_packages() {
    check_packages_file
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "Error: Package file does not exist."
        exit 2
    fi

    mapfile -t packages < "$file"
    local packages_to_remove=()

    for package in "${packages[@]}"; do
        local clean_package=$(echo "$package" | sed 's/^"//; s/" .*$//; /^#/d')
        if [[ -n "$clean_package" ]]; then
            packages_to_remove+=("$clean_package")
        fi
    done

    echo "${packages_to_remove[@]}"
}

# Function to remove packages
remove_packages() {
    check_packages_file
    local packages_to_remove=($(read_packages "packages.list"))

    if [[ ${#packages_to_remove[@]} -eq 0 ]]; then
        echo "No packages to remove."
        return
    fi

    echo "Removing the following packages: ${packages_to_remove[*]}"
    sudo apt-get remove --purge "${packages_to_remove[@]}"
}

# Function to list packages scheduled for removal
list_packages() {
    check_packages_file
    echo "Packages scheduled for removal:"
    local packages_to_list=($(read_packages "packages.list"))
    printf '%s\n' "${packages_to_list[@]}"
}

# Help function
show_help() {
    echo "Usage: $0 [OPTION]"
    echo "Manage package removal on Linux Mint 21.3 'Virginia' - Xfce Edition."
    echo ""
    echo "Options:"
    echo "  -r  Display a list of packages marked for removal (active in packages.list)"
    echo "  -l  Rebuild the packages.list list from currently installed packages"
    echo "  -h  Display this help message and exit"
    echo ""
    echo "Instructions to remove a package:"
    echo "  1. Edit the packages.list file and uncomment the package you want to remove."
    echo "     This is done by removing the '#' character at the beginning of the package line."
    echo "  2. Run the script with no options to proceed with the removal of the uncommented packages."
    echo ""
    echo "Examples:"
    echo "  $0 -r  Displays a list of packages that are set to be removed (not commented)."
    echo "  $0 -l  Generates a new packages.list file with currently installed packages, marking them as commented."
    echo "  $0     Executes the removal of all uncommented packages in the packages.list file."
    exit 0
}


# Main execution block
case "$1" in
    -r)
        list_packages
        ;;
    -l) generate_package_list
        ;;
    -h|--help)
        show_help
        ;;
    *)
        remove_packages
        ;;
esac

exit 0
