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
import sys

data = json.load(open(sys.argv[1] + '/instackenv.json'))


def right_replace(source, target, substitute, times):
    return substitute.join(source.rsplit(target, times))


for node in data['nodes']:
    if 'extra' in node['name']:
        node_name = node['name']
        # NOTE: `nodes` and `network_details` dictionaries
        # vary node name by swapping the final '-' for a '_'
        corrected_name = right_replace(node_name, '-', '_', 1)
        extra_node_networks = data['network_details'][
            corrected_name]['ips'].keys()
        for network in extra_node_networks:
            if 'private' in network:
                print(data['network_details'][
                    corrected_name]['ips'][network][0]['addr'].strip())
