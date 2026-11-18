import os
import subprocess
import sys
from importlib.machinery import SourceFileLoader
from importlib.util import module_from_spec, spec_from_loader
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parent.parent / "private-terms-guard"


def _load():
    loader = SourceFileLoader("private_terms_guard", str(SCRIPT))
    spec = spec_from_loader("private_terms_guard", loader)
    module = module_from_spec(spec)
    loader.exec_module(module)
    return module


guard = _load()
normalise = guard.normalise
load_terms = guard.load_terms
find_hits = guard.find_hits
blocked_paths = guard.blocked_paths


def git(repo, *args):
    return subprocess.run(
        ["git", "-C", str(repo), *args], check=True, capture_output=True, text=True
    ).stdout


def init_repo(path):
    path.mkdir()
    git(path, "init", "-q")
    git(path, "config", "user.email", "t@example.com")
    git(path, "config", "user.name", "t")
    git(path, "config", "commit.gpgsign", "false")


def run_guard(args, repo, terms_file, stdin=""):
    env = dict(os.environ, PRIVATE_TERMS_FILE=str(terms_file))
    return subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        cwd=str(repo),
        env=env,
        input=stdin,
        capture_output=True,
        text=True,
    )


def output(result):
    return result.stdout + result.stderr


def test_normalise_matches_number_formats():
    assert normalise("rent 1,234.00") == normalise("rent 1234") == normalise("RENT 1_234")


def test_normalise_strips_trailing_point_zero():
    assert normalise("5.0") == "5"


def test_normalise_unifies_english_and_german_decimals():
    forms = ["1,234.56", "1.234,56", "1234.56", "1234,56", "1_234.56"]
    assert len({normalise("x " + f) for f in forms}) == 1


def test_normalise_unifies_whole_amounts_across_locales():
    forms = ["1,234.00", "1.234,00", "1234", "1234,0"]
    assert len({normalise(f) for f in forms}) == 1


def test_normalise_keeps_thousands_groups_of_zeros():
    assert normalise("1,000") == "1000"


def test_german_amount_matches_english_term(tmp_path):
    (tmp_path / "terms").write_text("1234.56\n")
    terms = load_terms(tmp_path / "terms")
    assert find_hits("Miete 1.234,56 EUR", terms) == [1]


def test_find_hits_reports_line_numbers():
    assert find_hits("a\nfoo 98,765\nb", ["98765"]) == [2]


def test_missing_or_empty_list_fails_closed(tmp_path):
    with pytest.raises(SystemExit):
        load_terms(tmp_path / "absent")
    (tmp_path / "empty").write_text("\n")
    with pytest.raises(SystemExit):
        load_terms(tmp_path / "empty")


def test_list_inside_git_work_tree_is_rejected(tmp_path):
    subprocess.run(["git", "init", "-q", str(tmp_path)], check=True)
    (tmp_path / "terms").write_text("zebrafish\n")
    with pytest.raises(SystemExit):
        load_terms(tmp_path / "terms")


def test_valid_list_is_loaded_normalised(tmp_path):
    (tmp_path / "terms").write_text("Zebrafish\n\n4,321\n")
    assert load_terms(tmp_path / "terms") == ["zebrafish", "4321"]


def test_data_files_are_blocked():
    assert blocked_paths(["a/b.sqlite", "x.py", "c.numbers"]) == ["a/b.sqlite", "c.numbers"]


def test_pre_commit_blocks_staged_term(tmp_path):
    repo = tmp_path / "repo"
    init_repo(repo)
    terms = tmp_path / "terms"
    terms.write_text("4321\n")
    (repo / "notes.txt").write_text("ok\nzebrafish 4,321\n")
    git(repo, "add", "notes.txt")
    result = run_guard(["pre-commit"], repo, terms)
    assert result.returncode == 1
    assert "notes.txt:2" in output(result)
    assert "4321" not in output(result)
    assert "4,321" not in output(result)


def test_pre_commit_allows_clean_stage(tmp_path):
    repo = tmp_path / "repo"
    init_repo(repo)
    terms = tmp_path / "terms"
    terms.write_text("4321\n")
    (repo / "notes.txt").write_text("nothing here\n")
    git(repo, "add", "notes.txt")
    assert run_guard(["pre-commit"], repo, terms).returncode == 0


def test_pre_commit_blocks_data_file(tmp_path):
    repo = tmp_path / "repo"
    init_repo(repo)
    terms = tmp_path / "terms"
    terms.write_text("4321\n")
    (repo / "x.sqlite").write_text("harmless\n")
    git(repo, "add", "-f", "x.sqlite")
    assert run_guard(["pre-commit"], repo, terms).returncode == 1


def test_commit_msg_blocks_term(tmp_path):
    repo = tmp_path / "repo"
    init_repo(repo)
    terms = tmp_path / "terms"
    terms.write_text("zebrafish\n")
    msg = tmp_path / "MSG"
    msg.write_text("add Zebrafish report\n")
    result = run_guard(["commit-msg", str(msg)], repo, terms)
    assert result.returncode == 1
    assert "zebrafish" not in output(result).lower()


def test_pre_push_blocks_unpushed_commit(tmp_path):
    repo = tmp_path / "repo"
    init_repo(repo)
    terms = tmp_path / "terms"
    terms.write_text("zebrafish\n")
    (repo / "a.txt").write_text("zebrafish\n")
    git(repo, "add", "a.txt")
    git(repo, "commit", "-q", "-m", "add a")
    sha = git(repo, "rev-parse", "HEAD").strip()
    line = "refs/heads/main %s refs/heads/main %s\n" % (sha, "0" * 40)
    result = run_guard(["pre-push"], repo, terms, stdin=line)
    assert result.returncode == 1
    assert "zebrafish" not in output(result).lower()


def test_pre_push_allows_clean_commit(tmp_path):
    repo = tmp_path / "repo"
    init_repo(repo)
    terms = tmp_path / "terms"
    terms.write_text("zebrafish\n")
    (repo / "a.txt").write_text("clean\n")
    git(repo, "add", "a.txt")
    git(repo, "commit", "-q", "-m", "add a")
    sha = git(repo, "rev-parse", "HEAD").strip()
    line = "refs/heads/main %s refs/heads/main %s\n" % (sha, "0" * 40)
    assert run_guard(["pre-push"], repo, terms, stdin=line).returncode == 0


def test_empty_list_blocks_with_message(tmp_path):
    repo = tmp_path / "repo"
    init_repo(repo)
    terms = tmp_path / "terms"
    terms.write_text("")
    result = run_guard(["pre-commit"], repo, terms)
    assert result.returncode == 1
    assert "term list is empty" in output(result)


def test_pre_commit_blocks_added_line_that_looks_like_a_file_header(tmp_path):
    repo = tmp_path / "repo"
    init_repo(repo)
    terms = tmp_path / "terms"
    terms.write_text("zebrafish\n")
    (repo / "notes.txt").write_text("ok\n++ zebrafish here\n")
    git(repo, "add", "notes.txt")
    result = run_guard(["pre-commit"], repo, terms)
    assert result.returncode == 1
    assert "zebrafish" not in output(result).lower()


def test_pre_commit_does_not_print_term_bearing_path(tmp_path):
    repo = tmp_path / "repo"
    init_repo(repo)
    terms = tmp_path / "terms"
    terms.write_text("zebrafish\n")
    (repo / "my zebrafish.txt").write_text("zebrafish\n")
    git(repo, "add", "my zebrafish.txt")
    result = run_guard(["pre-commit"], repo, terms)
    assert result.returncode == 1
    assert "zebrafish" not in output(result).lower()


def test_pre_commit_blocks_term_in_file_name_with_clean_content(tmp_path):
    repo = tmp_path / "repo"
    init_repo(repo)
    terms = tmp_path / "terms"
    terms.write_text("zebrafish\n")
    (repo / "my zebrafish.txt").write_text("nothing\n")
    git(repo, "add", "my zebrafish.txt")
    result = run_guard(["pre-commit"], repo, terms)
    assert result.returncode == 1
    assert "zebrafish" not in output(result).lower()
    assert "file name" in output(result)


def test_pre_push_blocks_term_in_file_name_with_clean_content(tmp_path):
    repo = tmp_path / "repo"
    init_repo(repo)
    terms = tmp_path / "terms"
    terms.write_text("zebrafish\n")
    (repo / "zebrafish.txt").write_text("clean\n")
    git(repo, "add", "zebrafish.txt")
    git(repo, "commit", "-q", "-m", "add a")
    sha = git(repo, "rev-parse", "HEAD").strip()
    line = "refs/heads/main %s refs/heads/main %s\n" % (sha, "0" * 40)
    result = run_guard(["pre-push"], repo, terms, stdin=line)
    assert result.returncode == 1
    assert "file name" in output(result)
