#!/bin/bash
PATH=/bin:/sbin:/usr/local/bin:/usr/local/sbin:${PATH}

# Default the EDITOR to vi and the PAGER to less
EDITOR=${EDITOR:=$(which vi)}
PAGER=${PAGER:=$(which less)}

# Find the location of the git binary
GIT=$(which git 3>/dev/null)

# Check if git is installed. If it's not, or it's not in our path invoke editor as usual.
[ "$GIT" = "" ] && exec "$EDITOR" "$@" && exit

trap

read_yn() { # Return 0 for yes, 1 for no
	read -r yn
	[ "$yn" = "y" ] || [ "$yn" = "Y" ] && return 0
	[ "$yn" = "n" ] || [ "$yn" = "N" ] && return 1
	[ "$1" = "y" ] || [ "$1" = "Y" ] && [ "$yn" = "" ] && return 0
	[ "$1" = "n" ] || [ "$1" = "N" ] && [ "$yn" = "" ] && return 1
 }

is_git_file() {
	GITSTATUS=$($GIT status -s "$1" | grep -c "??")
	[ "$GITSTATUS" -ne "0" ] && return 1 # False it isn't a git file!
	return 0 # True we have git!
}

cleanup() {
	# Clean up lock file and git edits.
	rm -f "$LOCKFILE"
	return 255
}

# Check to make sure they aren't editing as root. Otherwise the changes will be checked in with the root user..
if [ "$EUID" -eq 0 ]
then
	echo "I don't think you want to edit as root. You should do it as yourself so your changes can be tracked."
	echo "Otherwise bad things will happen to you because we don't like cowboys!"
	echo
	exit 1
fi

# Check to see if default git info is set, if not set it.
GITUSERNAME=$($GIT config user.name)
if [ "$GITUSERNAME" = "" ]
then
	echo "It appears you haven't setup git before. Please answer 2 questions so I know who you are!"
	while :
	do
		echo -n "Full Name: "
		read -r name
		echo -n "Email Address: "
		read -r email
		echo -n "So you are $name <$email> ? [Y/n] "
		if read_yn y
		then
			$GIT config --global user.name "$name"
			$GIT config --global user.email "$email"
			break
		fi
	done
fi


LOCKFILE="$1.lock"
# Get lock file
if [ -f "$LOCKFILE" ]
then
	LOCKUSER=$(find "$LOCKFILE" | awk '{print $5}')
	echo "Lock file exists. Currently being edited by $LOCKUSER trying for 15 second to get the lock..."
fi

if ! lockfile -3 -r 5 "$LOCKFILE"
then
	echo "Unable to lock $1, I believe $LOCKUSER is still editing it!"
	echo "If they aren't then something went wrong and you might need to rm -f $LOCKFILE"
	exit 1
fi

trap cleanup SIGTERM SIGINT EXIT

$EDITOR "$1"

if is_git_file "$1"
then
	CHANGES="$($GIT diff --shortstat "$1")"
	if [ "$CHANGES" != "" ]
	then
		echo
		echo "$CHANGES"
		echo
		echo -n "Would you like to review the changes? [Y/n]: "
		if read_yn y
		then
			git diff "$1" | $PAGER
		fi
		echo
		echo -n "Commit changes? [Y/n]: "
		if read_yn y
		then
			echo
			echo -n "Commit comment: "
			read -r commitmsg
			git add "$1"
			git commit -m "$commitmsg"
		else
			echo
			echo "*** Staged changes have not been commited! I hope you know what you are doing? ***"
			echo "*** If you don't use 'git add $1 ; git commit -m \"A message of your changes\"'"
		fi
	fi
fi