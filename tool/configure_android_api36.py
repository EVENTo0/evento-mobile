"""Pin the generated Android wrapper; fail if Flutter changes its template."""

from pathlib import Path
import re
import sys


def configure(source: str) -> str:
    for key in ("compileSdk", "targetSdk"):
        pattern = rf"(?m)^(\s*{key}\s*=\s*)(?:flutter\.{key}Version|\d+)(\s*(?://[^\n]*)?)$"
        source, count = re.subn(pattern, rf"\g<1>36\g<2>", source)
        if count != 1:
            raise ValueError(f"Expected exactly one {key} assignment; found {count}")
    return source


if __name__ == "__main__":
    path = Path(sys.argv[1] if len(sys.argv) > 1 else "android/app/build.gradle.kts")
    result = configure(path.read_text())
    path.write_text(result)
    print("Generated Android wrapper: compileSdk=36, targetSdk=36")
