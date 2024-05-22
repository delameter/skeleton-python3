APP_NAME = "*PROJECT_NAME"

DATA_PACKAGE = f"{APP_NAME}.data"

# here imports should be absolute:
from PROJECT_NAME.cli.entrypoint import entrypoint as entrypoint_fn  # noqa
