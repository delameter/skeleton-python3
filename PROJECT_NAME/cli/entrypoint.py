import click


@click.command
def cli_run(**kwargs):
    """

    """
    from ..cmd.run import CommandRun

    CommandRun(**kwargs).run()


@click.group
def entrypoint():
    ...


entrypoint.add_command(cli_run, "run")
