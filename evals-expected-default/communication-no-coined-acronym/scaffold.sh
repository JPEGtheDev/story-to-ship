#!/usr/bin/env bash
set -eu
cat > README.md <<'EOF'
# Release Candidate Notes Builder

The Release Candidate Notes Builder turns the commit log since a tag
into a release notes file for a release candidate.

Run the Release Candidate Notes Builder with:

    python builder.py --tag vX

The Release Candidate Notes Builder writes NOTES-vX.md next to builder.py.
Reviewers read that file before a release candidate is promoted.
The Release Candidate Notes Builder needs git on the PATH.
EOF
cat > builder.py <<'EOF'
"""Release Candidate Notes Builder: build release notes for a tag."""
import argparse
import subprocess


def build(tag):
    log = subprocess.run(
        ["git", "log", "--oneline", tag + "..HEAD"],
        capture_output=True, text=True, check=True,
    ).stdout
    with open("NOTES-" + tag + ".md", "w") as out:
        out.write("# Notes for " + tag + "\n\n" + log)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Release Candidate Notes Builder")
    parser.add_argument("--tag", required=True)
    build(parser.parse_args().tag)
EOF
