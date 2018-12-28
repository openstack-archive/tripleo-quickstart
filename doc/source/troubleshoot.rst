==================================
Troubleshooting TripleO Quickstart
==================================

Cached files in ~/.quickstart
=============================

When running TripleO Quickstart, some files are generated and stored in
``~/.quickstart``. Those files are not cleaned up on each tool execution to
save some cycles and retain environment. It may be problematic if a bug sneaks
in one of those cached files, because consequent calls to the tool won't fix
it.  If you experience unknown errors when deploying with Quickstart, one thing
to try is to run ``quickstart.sh`` with ``-X`` option so that it regenerates
the directory.

    ./quickstart.sh -X [...any other options]

Alternatively, you can manually remove the directory before executing
``quickstart.sh``.

    rm -r ~/.quickstart
