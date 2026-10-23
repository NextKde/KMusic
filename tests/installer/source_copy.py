"""Prepare an isolated CI source tree without changing tracked symlink types."""
import shutil


def copy_checkout(source, destination):
    return shutil.copytree(source, destination, symlinks=True,
                           ignore=shutil.ignore_patterns('results', 'kos-tests', 'build', '.task', '__pycache__'))
