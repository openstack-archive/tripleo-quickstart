#!/usr/bin/python

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


import json
import os

from distutils.version import LooseVersion
from keystoneauth1.identity import v3
from keystoneauth1 import session
from novaclient import __version__ as nc_version
from novaclient import client
from urlparse import urljoin

# We can remove this logic when newton (novaclient 6) is EOL
if LooseVersion(nc_version) <= LooseVersion("6.0.2"):
    nova = client.Client(2,
                         os.environ.get("OS_USERNAME"),
                         os.environ.get("OS_PASSWORD"),
                         os.environ.get("OS_TENANT_NAME"),
                         auth_url=os.environ.get("OS_AUTH_URL"))
else:
    auth_url = os.environ["OS_AUTH_URL"]
    if os.environ.get("OS_IDENTITY_API_VERSION") == "3":
        if 'v3' not in auth_url:
            auth_url = urljoin(auth_url, 'v3')
    username = os.environ.get("OS_USERNAME")
    password = os.environ.get("OS_PASSWORD")
    project_name = os.environ.get("OS_TENANT_NAME",
                                  os.environ.get("OS_PROJECT_NAME"))
    user_domain_name = os.environ.get("OS_USER_DOMAIN_NAME")
    project_domain_name = os.environ.get("OS_PROJECT_DOMAIN_NAME")

    auth = v3.Password(auth_url=auth_url,
                       username=username,
                       password=password,
                       project_name=project_name,
                       user_domain_name=user_domain_name,
                       project_domain_name=project_domain_name,
                       )
    session = session.Session(auth=auth, verify=False)
    nova = client.Client(2, session=session)

oc_servers = {server.name: server.networks['ctlplane'][0]
              for server in nova.servers.list()
              if server.networks.get('ctlplane')}
print(json.dumps(oc_servers, indent=4))
