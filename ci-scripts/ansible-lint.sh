#!/bin/bash

# ANSIBLE0006: Using command rather than module
# we have a few use cases where we need to use curl and rsync
SKIPLIST="ANSIBLE0006"

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
