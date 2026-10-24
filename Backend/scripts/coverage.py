#!/usr/bin/env python3
"""Merges Cobertura reports (unit + integration) by file and line and enforces 100% line
coverage of hand-written code. Usage: coverage.py <out-summary.md> <report.xml>..."""
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict


def main(summary_path, reports):
    lines = defaultdict(dict)
    for report in reports:
        for cls in ET.parse(report).getroot().iter("class"):
            name = cls.get("filename")
            for line in cls.iter("line"):
                number = int(line.get("number"))
                hits = int(line.get("hits"))
                lines[name][number] = max(lines[name].get(number, 0), hits)
    total = sum(len(v) for v in lines.values())
    missed = {f: sorted(n for n, h in v.items() if h == 0) for f, v in lines.items()}
    missed = {f: v for f, v in missed.items() if v}
    covered = total - sum(len(v) for v in missed.values())
    percent = 100.0 * covered / total if total else 100.0
    with open(summary_path, "w") as out:
        out.write(f"# .NET coverage\n\nLines: {covered}/{total} ({percent:.2f}%)\n\n")
        for f, numbers in sorted(missed.items()):
            out.write(f"- {f}: {numbers}\n")
    for f, numbers in sorted(missed.items()):
        print(f"uncovered {f}: {numbers}", file=sys.stderr)
    print(f"line coverage {covered}/{total} = {percent:.2f}%")
    return 0 if not missed else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1], sys.argv[2:]))
