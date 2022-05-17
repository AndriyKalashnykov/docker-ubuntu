#!/bin/bash

# set -x

export TMP_DIR=/tmp
export LOCAL_DIR=/usr/local
export BIN_DIR=$LOCAL_DIR/bin
export TGZ_EXT=.tgz
export TAR_GZ_EXT=.tar.gz

getHost(){

    OS=$(echo $(uname))
    OS_LC=$(echo $(uname) | awk '{print tolower($0)}')
	ARCH_ORIG=$(uname -m) ;

	case "$ARCH_ORIG" in

	"amd64")  ARCH="amd64"
	    ;;
	"x86_64") ARCH="amd64"
	    ;;
	"i386")   ARCH="386"
	    ;;
	"386")    ARCH="386"
	   ;;
	*)        ARCH="NONE"
	   ;;
	esac
}

main(){
    getHost ;

    # echo "ARCH: $ARCH" ;
	# echo "OS: $OS" ;
	# echo "OS_LC: $OS_LC" ;
}

main