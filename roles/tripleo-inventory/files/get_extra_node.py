#!/usr/bin/env python

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
import sys

data = json.load(open(sys.argv[1] + '/instackenv.json'))


for node_name, node_networks in data['network_details'].items():
    if 'extra' in node_name:
        for net_name, ip_data in node_networks['ips'].items():
            if 'private' in net_name:
                print(ip_data[0]['addr'].strip())
                sys.exit(0)
