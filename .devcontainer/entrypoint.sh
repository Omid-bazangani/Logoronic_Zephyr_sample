#!/bin/bash
set -e

# The project lives on a Windows host filesystem and is bind-mounted into the
# container, so scripts can be checked out with CRLF line endings depending on
# the host's git/editor settings. A CRLF shebang line breaks execution under
# Linux bash. Normalize every *.sh file in the workspace on each container
# start so this self-heals for build.sh, flash.sh, and any scripts added later.
if [ -d "$WORKSPACE_DIR" ]; then
    find "$WORKSPACE_DIR" -path '*/.git' -prune -o -type f -name '*.sh' -print \
        -exec sed -i 's/\r$//' {} +
fi

exec "$@"
