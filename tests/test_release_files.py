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
from __future__ import print_function
import fnmatch
import os
import subprocess
import sys

RELEASE_CONFIG_DIR = 'config/release'


def pytest_generate_tests(metafunc):
    matches = []
    if 'testdata' in metafunc.fixturenames:
        for root, dirnames, filenames in os.walk(RELEASE_CONFIG_DIR):
            for filename in fnmatch.filter(filenames, '*.yml'):
                matches.append(os.path.join(root, filename))
    metafunc.parametrize('testdata', matches)


def test_release_configs(testdata):
    cmd = ['ansible-playbook',
           '-e@%s' % testdata,
           # workaround for ansible bug which may fail to detect
           # python interpreter, so we force it to use the same
           # interpreter
           '-eansible_python_interpreter=%s' % sys.executable,
           'tests/validate-release-config.yml',
           # usually comes from extras-common role but not present here
           # so we need to pass it explicitly for molecule
           '-ewhole_disk_images=true']

    print("running: %s (from %s)" % (" " .join(cmd), os.getcwd()))
    # Workaround for STDOUT/STDERR line ordering issue:
    # https://github.com/pytest-dev/pytest/issues/5449
    p = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        universal_newlines=True)
    for line in p.stdout:
        print(line, end="")
    p.wait()
    assert p.returncode == 0
