# -----------------------------------------------------------------------------
# *PROJECT_NAME [*PROJECT_DESCRIPTION]
# (C) 2022 A. Shavykin <0.delameter@gmail.com>
# -----------------------------------------------------------------------------
"""
SYNOPSIS
    project_name --help

Prints out this help.

ARGUMENTS
  No.
"""
import sys

from pytermor import Styles
from pytermor.render import print_exception


# noinspection PyMethodMayBeStatic
class App:
    def run(self):
        try:
            self._entrypoint()
        except Exception as e:
            print_exception(e, file=sys.stderr)
            self._exit(1)
        self._exit(0)

    def _entrypoint(self):
        if {'-h', '--help'}.intersection(sys.argv):
            self._print_usage()
            return

        self._parse_args()
        raise NotImplementedError("в пизду")

    def _parse_args(self):
        pass

    def _print_usage(self):
        print(__doc__)

    def _print_error(self):
        print(Styles.ERROR.render('[ERR]'))

    def _exit(self, code: int):
        print()
        exit(code)


if __name__ == '__main__':
    App().run()
