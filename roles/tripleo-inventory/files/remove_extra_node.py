#!/usr/bin/python
# Copyright 2019 Red Hat Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

import json
import sys

with open(sys.argv[1] + "/instackenv.json") as f:
    j = json.load(f)
with open(sys.argv[1] + "/instackenv.original.json", "w") as f:
    json.dump(j, f, sort_keys=True, indent=4, separators=(',', ': '))
for k in list(j):
    for el in list(j[k]):
        if 'extra' in el:
            j[k].pop(el)
        elif (isinstance(el, dict) and 'extra' in el.get('name')):
            j[k].remove(el)
with open(sys.argv[1] + "/instackenv.json", "w") as f:
    json.dump(j, f, sort_keys=True, indent=4, separators=(',', ': '))
