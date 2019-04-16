# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
import logging
import os
import subprocess

import docker


client = docker.from_env(timeout=5)
if not client.ping():
    raise Exception("Failed to ping docker server.")

try:
    import selinux  # noqa
except Exception as e:
    logging.error(
        "It appears that you are trying to use "
        "molecule with a Python interpreter that does not have the libselinux "
        "python bindings installed. These can only be installed using your "
        "distro package manager and are specific to each python version. "
        "Common package names: libselinux-python python2-libselinux "
        "python3-libselinux")
    raise e


def pytest_generate_tests(metafunc):
    # detects all molecule scenarios inside the project
    matches = []
    for filename in subprocess.check_output(
            "find . -path '*/.*' -prune -o -name 'molecule.yml' -print",
            shell=True, universal_newlines=True).split():
        role_path = os.path.abspath(os.path.join(filename, os.pardir))
        x = os.path.basename(role_path)
        role_path = os.path.abspath(os.path.join(role_path,
                                                 os.pardir,
                                                 os.pardir))
        matches.append([role_path, x])
    metafunc.parametrize('testdata', matches)


def test_molecule(testdata):
    cwd, scenario = testdata
    cmd = ['python', '-m', 'molecule', 'test', '-s', scenario]
    print("running: %s (from %s)" % (" " .join(cmd), cwd))
    r = subprocess.call(cmd, cwd=cwd)
    assert r == 0
