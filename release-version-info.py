#!/usr/bin/env python3

import argparse
import json
import sys


def main():
    parser = argparse.ArgumentParser(
        description="Extract release asset name and download URL from GitHub release JSON."
    )

    parser.add_argument(
        "metadata_path",
        help="Path to release JSON file or '-' to read from stdin. Default: '-' (stdin).",
        default="-",
        nargs="?",
    )

    args = parser.parse_args()

    if args.metadata_path == "-":
        release = json.loads(sys.stdin.read())
    else:
        with open(args.metadata_path, encoding="utf-8") as metadata_file:
            release = json.load(metadata_file)

    print(release["tag_name"])


if __name__ == "__main__":
    main()
