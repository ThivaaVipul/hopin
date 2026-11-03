import subprocess
from pathlib import Path

import pytest

import next_release


def git(repo: Path, *args: str) -> None:
    identity = ["-c", "user.name=Test", "-c", "user.email=test@example.com"]
    subprocess.run(
        ["git", *identity, "-c", "commit.gpgsign=false", *args],
        cwd=repo,
        check=True,
        capture_output=True,
    )


def commit(repo: Path, path: str, message: str) -> None:
    target = repo / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(message, encoding="utf-8")
    git(repo, "add", path)
    git(repo, "commit", "-m", message)


@pytest.fixture
def repo(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    git(tmp_path, "init", "-b", "main")
    monkeypatch.chdir(tmp_path)
    return tmp_path


def test_only_commits_that_change_the_app_count(repo: Path) -> None:
    commit(repo, "app/pubspec.yaml", "chore: set up the project")
    commit(repo, "firebase/firestore.rules", "feat(rules): members read their books")
    commit(repo, "app/lib/home.dart", "fix(app): show the month")

    subjects = [commit.subject for commit in next_release.commits_since(None)]

    assert subjects == ["show the month", "set up the project"]


def test_counts_from_the_last_release_tag(repo: Path) -> None:
    commit(repo, "app/pubspec.yaml", "feat(app): first screen")
    git(repo, "tag", "v0.1.0")
    commit(repo, "app/lib/home.dart", "feat(app): the month")
    commit(repo, "tools/backup/backup.ts", "fix(backup): receipts")

    subjects = [commit.subject for commit in next_release.commits_since("0.1.0")]

    assert subjects == ["the month"]
