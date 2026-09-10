#!/usr/bin/env python3
# Copyright © 2026 Marc Rousavy @ Margelo

"""Compile each complete Swift guide and README example as a public consumer.

Run after scripts/build-documentation.sh. No imports or declarations are added to
examples, so the compiler checks the code exactly as readers see it.
"""

from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "build/documentation-examples"
FRAMEWORK = ROOT / "build/documentation/Build/Products/Release-iphoneos/VisionCamera"


def main():
    if not (FRAMEWORK / "VisionCamera.framework/Modules/VisionCamera.swiftmodule").is_dir():
        raise SystemExit("Run scripts/build-documentation.sh before checking examples.")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    sdk = subprocess.check_output(
        ["xcrun", "--sdk", "iphoneos", "--show-sdk-path"], text=True
    ).strip()
    compiler = subprocess.check_output(["xcrun", "--find", "swiftc"], text=True).strip()
    guides = ROOT / "Sources/VisionCamera/Documentation.docc/Guides"
    paths = [*sorted(guides.glob("*.md")), ROOT / "README.md"]
    snippets = []
    skipped = []

    for path in paths:
        content = path.read_text()
        blocks = re.finditer(r"^```swift[^\n]*\n([\s\S]*?)^```[ \t]*$", content, re.M)
        for index, match in enumerate(blocks, 1):
            code = match[1]
            line = content[:match.start(1)].count("\n") + 1
            info = {"file": str(path.relative_to(ROOT)), "line": line, "index": index}
            # The installation section intentionally shows arguments inside Package(...).
            if path.name == "README.md" and code.lstrip().startswith("dependencies:"):
                skipped.append(info)
                continue
            temporary = OUTPUT / f"{path.stem}_{index}.swift"
            temporary.write_text(
                f"#sourceLocation(file: {json.dumps(str(path))}, line: {line})\n{code}"
            )
            snippets.append({**info, "temporary_file": str(temporary)})

    if not snippets:
        raise SystemExit("No Swift documentation examples were found.")

    def check(info):
        temporary = info["temporary_file"]
        command = [
            compiler, "-typecheck", "-swift-version", "5",
            "-target", "arm64-apple-ios15.1", "-sdk", sdk,
            "-F", str(FRAMEWORK),
            "-module-cache-path", str(OUTPUT / "module-cache"),
            "-module-name", "Guide_" + Path(temporary).stem, temporary,
        ]
        result = subprocess.run(command, text=True, capture_output=True)
        return {
            **info, "exit_code": result.returncode,
            "diagnostics": result.stdout + result.stderr,
        }

    with ThreadPoolExecutor(max_workers=4) as executor:
        results = list(executor.map(check, snippets))
    failed = [result for result in results if result["exit_code"] != 0]
    warnings = [result for result in results if ": warning:" in result["diagnostics"]]
    report = {"results": results, "skipped": skipped}
    (OUTPUT / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print(
        f"Documentation examples: {len(results) - len(failed)}/{len(results)} compile; "
        f"{len(skipped)} Package.swift fragment skipped."
    )
    for result in results:
        if result["diagnostics"]:
            print(result["diagnostics"])
    raise SystemExit(1 if failed or warnings else 0)


if __name__ == "__main__":
    main()
