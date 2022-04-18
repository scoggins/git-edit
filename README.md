# git-edit.sh

This script is designed to be used by people who aren't as familiar with git, but need to edit files that are under git control.

The script can be renamed to edit or git-edit. The script performs the following if the file is a git controled file:

1. If the file being edited is under git control, then we check to see if this person editing the file has configured their config user.name and user.email values. If they are not set, we'll prompt them to configure that.
2. The file is then edited using the EDITOR variable (defaults to vi if not set), once they save and exit the file, prompts to show a diff of the changes to the file, then prompts if they would like to commit those changes, then prompts for a commit message.

It was designed to help other admins who don't know much about git to be able to edit files with out having to remember lots of git commands.

