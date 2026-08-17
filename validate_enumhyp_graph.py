#!/usr/bin/env python3
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit(f"Usage: {Path(sys.argv[0]).name} GRAPH_FILE")

path = Path(sys.argv[1])
if not path.is_file():
    raise SystemExit(f"ERROR: file not found: {path}")

lines = path.read_text(encoding="utf-8-sig").splitlines()
if not lines:
    raise SystemExit(f"ERROR: graph is empty: {path}")

try:
    vertex_count = int(lines[0].strip())
except ValueError as exc:
    raise SystemExit(f"ERROR: line 1 is not an integer: {lines[0]!r}") from exc

if vertex_count <= 0:
    raise SystemExit(f"ERROR: line 1 must be positive, got {vertex_count}")

values = []
bad = []
edge_count = 0

for line_number, raw_line in enumerate(lines[1:], start=2):
    line = raw_line.strip()
    if not line:
        continue
    edge_count += 1
    for raw_token in line.split(','):
        token = raw_token.strip()
        try:
            value = int(token)
        except ValueError:
            bad.append((line_number, token, "not an integer"))
            continue
        values.append(value)
        if value < 0 or value >= vertex_count:
            bad.append(
                (line_number, token,
                 f"outside valid range 0..{vertex_count - 1}")
            )

print(f"File: {path}")
print(f"Declared vertices: {vertex_count}")
print(f"Non-empty edges: {edge_count}")

if values:
    print(f"Observed vertex range: {min(values)}..{max(values)}")
else:
    print("Observed vertex range: none")

if not bad:
    print("VALID: the graph matches enumhyp's zero-based format.")
    raise SystemExit(0)

print(f"INVALID: {len(bad)} invalid token(s). First 20:")
for line_number, token, reason in bad[:20]:
    print(f"  line {line_number}: {token!r} ({reason})")

if values:
    minimum = min(values)
    maximum = max(values)
    if minimum >= 1 and maximum <= vertex_count and 0 not in values:
        print("Possible cause: the file appears to use one-based indices (1..N).")
        print("enumhyp requires zero-based indices (0..N-1).")
    if minimum >= 0 and maximum == vertex_count:
        print("Possible cause: the first-line vertex count is one too small.")
        print(f"For zero-based indices, it would need to be at least {maximum + 1}.")

raise SystemExit(1)
