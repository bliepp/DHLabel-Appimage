#!/usr/bin/env python3

import argparse
import json
import sys


def get_release_asset(release, asset_type) -> dict | None:
    for asset in release.get("assets", []):
        name = asset["name"]

        match asset_type:
            case "dhlabel":
                matches = name.lower().endswith(".exe") and "setup" in name.lower()
            case "wine":
                matches = name.endswith("-amd64.tar.xz") and "-staging-" not in name
            case _:
                raise RuntimeError("Unknown asset type: " + asset_type)

        if matches:
            return asset


def main():
    parser = argparse.ArgumentParser(
        description="Extract release asset name and download URL from GitHub release JSON."
    )

    parser.add_argument(
        "asset_type",
        choices=["dhlabel", "wine"],
        help="Type of release asset to extract.",
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

    asset = get_release_asset(release, args.asset_type)
    if not asset:
        raise RuntimeError("Matching release asset not found.")

    print(asset["name"], asset["browser_download_url"], sep="\n")


if __name__ == "__main__":
    main()
