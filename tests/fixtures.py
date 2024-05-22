
import pytest
from click.testing import CliRunner

from PROJECT_NAME import entrypoint


@pytest.fixture(scope="session")
def runner():
    yield CliRunner()
