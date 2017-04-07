tripleo-repo-setup
=========

Set up yum repositories on host or in image
This Ansible role allows setting up repositories on a live host or within an image.

Requirements
------------
`libguestfs-tools-c` package is required in case of injecting repositories into an image.

Role Variables
--------------

* `repo_setup_script` - path to repositories setup script template
* `repo_setup_log` - path to repositories setup script log
* `repo_run_live`: false/true - where to run repo setup script on host (live host that playbook runs on it) (default: true)
* `repo_inject_image_path` - path to image, in case of injecting repositories into the image (default: not defined)
* `repo_cmd_before`:  - shell commands to run before repos setup
* `repo_cmd_after`: - shell commands to run after repos setup
* `libvirt_uri` - URI of libvirt in case of using virt-customize to inject repos into the image
* `repos` - dictionary or repositories to set, the keys are explained below:
* `repos.type` - file / generic / package / rpm_url
* `repos.releases` - for which releases to set up this repo, if not defined - for all releases.
                     It supports shortcut for all stable releases - '{{ stable }}'

  *File*
  ------
  Just download the repo file from URL and change some of its parameters if required.
    * `repos.filename` - filename for saving the downloaded file
    * `repos.down_url` - URL to download repo file from
    * `repos.priority` - change priority of this repo (default: not defined)

  *Generic*
  ------
  Construct repository file from various parameters and use parameters from downloaded file
  if required (for example DLRN hash).
    * `repos.filename` - filename for saving the resulting repo (mandatory)
    * `repos.reponame` - name of repository (mandatory)
    * `repos.baseurl` - base URL of the repository (mandatory)
    * `repos.hash_url` - URL of repo file in network, used for extracting trunk hash (optional)
    * `repos.priority` - priority of resulting repo (optional)
    * `repos.includepkgs` - includepkgs parameter of resulting repo (use this repo only for these packages) (optional)
    * `repos.enabled` - 0/1 whether the repo is enabled or not (default: 1 - enabled)
    * `repos.gpgcheck` - whether to check GPG keys for repo (default: 0 - don't check)

  *Package*
  ------
  Install repository from package
    * `repos.pkg_name` - package name (should be available in the installed repositories)
    * `repos.custom_cmd` - custom command to install this package (default: 'yum install -y')
    * `repos.pkg_url` - direct URL of the package to install

Dependencies
------------

No dependencies

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    ---
    - name:  Run repo setup
      hosts: undercloud
      gather_facts: no
      roles:
        - repo-setup

Settings example for repositories:

      repos:
          # Just download file
          - type: file
            filename: delorean.repo
            down_url: https://trunk.rdoproject.org/centos7-{{ release }}/current/delorean.repo

          # In case of stable release
          - type: generic
            reponame: delorean
            filename: delorean.repo
            baseurl: https://trunk.rdoproject.org/centos7-{{ release }}/current/
            hash_url: https://trunk.rdoproject.org/centos7-{{ release }}/current/delorean.repo
            priority: 20
            releases: "{{ stable }}"

          # In case of master
          - type: generic
            reponame: delorean
            filename: delorean.repo
            baseurl: https://buildlogs.centos.org/centos/7/cloud/x86_64/rdo-trunk-master-tripleo/
            hash_url: https://buildlogs.centos.org/centos/7/cloud/x86_64/rdo-trunk-master-tripleo/delorean.repo
            priority: 20
            releases:
              - master

          # In case of master
          - type: generic
            reponame: delorean-current
            filename: delorean-current.repo
            baseurl: https://trunk.rdoproject.org/centos7/current
            hash_url: https://trunk.rdoproject.org/centos7/current/delorean.repo
            priority: 10
            includepkgs:
              - diskimage-builder
              - instack
              - instack-undercloud
              - os-apply-config
              - os-collect-config
              - os-net-config
              - os-refresh-config
              - python-tripleoclient
              - openstack-tripleo-common
              - openstack-tripleo-heat-templates
              - openstack-tripleo-image-elements
              - openstack-tripleo
              - openstack-tripleo-puppet-elements
              - openstack-puppet-modules
              - openstack-tripleo-ui
              - puppet-*
            releases:
              - master

          # In case of all releases
          - type: file
            filename: delorean-deps.repo
            down_url: https://trunk.rdoproject.org/centos7-{{ release }}/delorean-deps.repo
            priority: 30

          - type: package
            pkg_name: centos-release-ceph-hammer
            custom_cmd: 'yum install -y --enablerepo=extras'
            releases:
              - liberty
              - mitaka

          - type: package
            pkg_name: centos-release-ceph-jewel
            custom_cmd: 'yum install -y --enablerepo=extras'
            releases:
              - newton
              - master

          - type: package
            pkg_url: https://rdoproject.org/repos/openstack-{{ release }}/rdo-release-{{ release }}.rpm
            releases:
              - newton


License
-------

Apache 2.0

Author Information
------------------

RDO-CI Team
