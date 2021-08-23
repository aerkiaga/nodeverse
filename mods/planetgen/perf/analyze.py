#!/usr/bin/env python3

import sys, re, math

re_line = re.compile(r"(\w+) (\d+)")

data = {}

def time_format(n):
    r = None
    if n > 0.5e+6:
        r = "{:.2f} s".format(n/1e+6)
    elif n > 0.5e+3:
        r = "{:.2f} ms".format(n/1e+3)
    else:
        r = "{:.2f} us".format(n)
    return r

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
print("NAME" + (32-4)*" " + "COUNT" + (12-5)*" " +\
"AVERAGE" + (12-7)*" " + "TOTAL" + (12-5)*" " + "...")
data = sorted(data.items(), key=lambda x: x[1]["total"], reverse=True)
for name, stats in data:
    print("{:<32s}{:<12d}{:<12s}{:<12s}{:s}".format(name, stats["count"],\
    time_format(stats["total"]/stats["count"]), time_format(stats["total"]),
    math.floor(math.log2(stats["total"]))*"#"))
