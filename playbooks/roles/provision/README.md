## Provisioning

In your playbook:

    - hosts: localhost
      roles:
        - provision/local

    - hosts: virthost
      roles:
        - provision/remote

    - hosts: localhost
      roles:
        - rebuild-inventory

On the command line:

    ansible-playbook playbook.yml -e virthost=my.target.host

## Cleaning up

In your playbook:

    - hosts: virthost
      roles:
        - provision/cleanup

On the command line:

    ansible-playbook playbook.yml -i ~/.quickstart/hosts \
      -e ansible_user=root
