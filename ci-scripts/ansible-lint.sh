#!/bin/bash

# ANSIBLE0006: Using command rather than module
#   we have a few use cases where we need to use curl and rsync
# ANSIBLE0016: Tasks that run when changed should likely be handlers
#   this requires refactoring roles, skipping for now
SKIPLIST="ANSIBLE0006,ANSIBLE0016"

# lint the playbooks separately to avoid linting the roles multiple times
pushd playbooks
find . -type f -regex '.*\.y[a]?ml' -print0 | xargs -0 ansible-lint -x $SKIPLIST || lint_error=1
popd

# lint all the possible roles
find ./roles -type d -print0 | xargs -0 ansible-lint -x $SKIPLIST || lint_error=1

# exit with 1 if we had any error so far
if [[ -n "$lint_error" ]]; then
    exit 1;
fi
