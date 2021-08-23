#!/usr/bin/env python3

import sys, re

re_line = re.compile(r"(\w+) (\d+)")

data = {}

for line in sys.stdin:
    match = re_line.match(line)
    if match is not None:
        name = match.group(1)
        time = int(match.group(2))
        if name not in data:
            data[name] = {
                "count" : 0,
                "total" : 0,
            }
        data[name]["count"] += 1
        data[name]["total"] += time
print("NAME" + (32-4)*" " + "COUNT" + (12-5)*" " + "TOTAL")
for name, stats in data.items():
    print("{:<32s}{:<12d}{:d}".format(name, stats["count"], stats["total"]))
