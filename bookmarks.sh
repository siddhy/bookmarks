#!/bin/bash

dir_array=()

#-------------------------------------------------------------------------------
# Primitive functions
#-------------------------------------------------------------------------------
function _bm_usage () {
    cat <<EOL
- Add directory to boomarks list
    bm <directory>

- List directories
    bm

- Change to indexed directory
    bm <index>

    -s <filename> : save boomarks to file
    -l <filename> : load bookmarks from file. Default load bm.env
    -d            : delete bookmarks
    -f            : filter out directories
EOL

    return 0
}

#-------------------------------------------------------------------------------
function _bm_change_dir () {
    local dir=$1
    shift

    local array=("$@")
    local array_size=${#array[*]}

    if [[ $dir -ge $array_size ]]; then
        # Choice out of range
        echo "Incorrect choice !"
        return 1
    else
        echo "Changed dir to ${array[$dir]}"
        cd "${array[$dir]}"
        return 0
    fi

    return 0
}

#-------------------------------------------------------------------------------
function _bm_choose_dir () {
    local array=("$@")
    local array_size=${#array[*]}
    local i

    echo "Project: ${PROJECT}"
    echo "Bookmarks:"
    for ((i=0; i<${#array[*]}; i++)); do
        echo "    $i: ${array[$i]}"
    done

    # Read dir number from stdin
    echo -n "Enter choice: "
    read -a choice

    if [[ -z "$choice" ]]; then
        # Nothing input on stdin
        echo "given up..."
        return 1
    else
        _bm_change_dir $choice "${array[@]}"
        return $?
    fi
}

#-------------------------------------------------------------------------------
function _bm_filter_dir () {
    local filter=$1
    local dir_nb=${#dir_array[*]}
    local filtered_array=()

    echo "Filtering $filter"

    for ((i=0; i<$dir_nb; i++)); do
        if (echo ${dir_array[$i]} | grep -q "$filter"); then
            filtered_array[${#filtered_array[*]}]=${dir_array[$i]}
        fi
    done

    echo "${filtered_array[@]}"

    _bm_choose_dir "${filtered_array[@]}"
}

#-------------------------------------------------------------------------------
function _bm_change_dir () {
    local dir=$1
    local dir_nb=${#dir_array[*]}

    if [[ $dir -ge $dir_nb ]]; then
        # Choice out of range
        echo "Incorrect choice !"
        return 1
    else
        echo "Changed dir to ${dir_array[$dir]}"
        cd "${dir_array[$dir]}"
        return 0
    fi

    return 0
}

#-------------------------------------------------------------------------------
function _bm_add_dir () {
    echo "Adding $1"
    local dir=`readlink -f $1`
    local dir_nb=${#dir_array[*]}
    local i

    if [[ ! -d $dir ]]; then
      echo "$dir is not of type dir"
      return 1
    fi

    for ((i=0; i<$dir_nb; i++)); do
        if [[ "$dir" = "${dir_array[$i]}" ]]; then
            echo "$dir already exists in bookmark list !"
            return 1
        fi
    done

    echo "Added $dir in ${#dir_array[*]}"
    dir_array[${#dir_array[*]}]=$dir


    return 0
}

#-------------------------------------------------------------------------------
function _bm_save_env () {
    local filename=$1

    if [ -n "$filename" ]; then
        (
            echo "PROJECT=${PROJECT}"
            echo -n "dir_array=("
            for ((i=0; i<${#dir_array[*]}; ++i)); do
                echo -n "\"${dir_array[$i]}\" "
            done
            echo ")"
        ) > $filename
    fi
    return 0
}

#-------------------------------------------------------------------------------
function _bm_clear_env () {
    dir_array=()
    return 0
}

#-------------------------------------------------------------------------------
function _bm_load_env () {
    if [[ -n $1 ]]; then
        source $1
    else
        source bm.env
    fi
    return 0
}

#-------------------------------------------------------------------------------
# Main public function
#-------------------------------------------------------------------------------
function bookmarks () {
    if [[ $# -eq 0 ]]; then
        # No args
        # If no bookmarks, exit
        if [[ ${#dir_array[*]} -eq 0 ]]; then
            echo "No bookmarks !"
            return 1
        fi
        # No args : print bookmarks
        _bm_choose_dir "${dir_array[@]}"
        return $?

    else
        case $1 in
            [0-9]*)
                # Numeric arg
                # Added index in cmd line
                _bm_change_dir $1 "${dir_array[@]}"
                return $?
                ;;

            -f)
                # Filter argument
                _bm_filter_dir $2
                return $?
                ;;
            -s)
                _bm_save_env $2
                return $?
                ;;
            -d)
                _bm_clear_env
                return $?
                ;;
            -l)
                _bm_load_env $2
                return $?
                ;;
            -h)
                _bm_usage
                return $?
                ;;
            *)
                # Directory passed on cmd line
                # Add it to the array
                _bm_add_dir $1
                return $?
                ;;
        esac
    fi
}

alias bm=bookmarks
