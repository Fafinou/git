#!/bin/sh

# This script installs or deletes a MediaWiki on your computer.
# It requires a web server with PHP and SQLite running. In addition, if you 
# do not have MediaWiki sources on your computer, the option 'install' 
# downloads them for you.
# Please set the CONFIGURATION VARIABLES in ./test-gitmw-lib.sh

WIKI_TEST_DIR=$(cd "$(dirname "$0")" && pwd)

if test -z "$WIKI_TEST_DIR"
then
	WIKI_TEST_DIR=.
fi

. "$WIKI_TEST_DIR"/test-gitmw-lib.sh
usage () {
        echo "Usage: "
        echo "  ./install-wiki.sh <install|delete|--help|-h>"
        echo "          install: Install a wiki on your computer."
        echo "          delete: Delete the wiki and all its pages and      content"
}


# Argument: install, delete, --help | -h
case "$1" in
	"install")
		wiki_install
		exit 0
		;;
	"delete")
		wiki_delete
		exit 0
		;;
	"--help" | "-h")
		usage
		exit 0
		;;
	*)
		echo "Invalid argument: $1"
		usage
		exit 1
		;;
esac

