: ${OPT_WORKDIR:=$HOME/.quickstart}

#ssh config
: ${SSH_CONFIG=$OPT_WORKDIR/ssh.config.ansible}
: ${ANSIBLE_SSH_ARGS="-F ${SSH_CONFIG}"}
