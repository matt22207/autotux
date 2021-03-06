#!/bin/bash

function appendLineToFile() {
    echo "appending : [ $1 ] to $2"
    if ! ${SUDO} cat "$2" | grep "$1"; then
        echo "$1" | ${SUDO} tee -a $2
    else 
        echo "-- No changes needed"
    fi
}

function replaceLineInFile() {
    echo "replacing : [ $1 ] with [ $2 ] in $3"
    if ${SUDO} cat "$3" | grep "$1"; then    
        ${SUDO} sed -i "s/^$1/$2/" "$3"
    else 
        echo "-- No changes needed"
    fi
}

function uncommmentLineInFile() {
    replaceLineInFile "#$1" "$1" "$2"
}

function commmentLineInFile() {
    replaceLineInFile "$1" "#$1" "$2"
}