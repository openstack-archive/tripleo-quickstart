'''This module implements test that are availablein Jinja2 2.8 but missing
from 2.7 (which is what is available on EL7 linux distributions).'''


def test_equalto(value, other):
    return value == other


class TestModule(object):
    def tests(self):
        return {
            'equalto': test_equalto,
        }
