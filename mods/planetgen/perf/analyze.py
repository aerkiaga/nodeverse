#!/usr/bin/env python3

# This is a Python script
# It parses performance events from stdin and generates a readable performance
# summary in table format. This table has the following columns:
#   NAME    Name of the profiled function
#   COUNT   Number of calls made to this function during profiling
#   AVERAGE Average time spent inside the function on each call
#   TOTAL   Total time spent inside the function
#   ...     Log chart of TOTAL

# In order to record and display performance data, run (from the mod top-level
# directory): 'minetest 2>&1 | python3 perf/analyze.py', and then play a game
# with the profiling-enabled mod.

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
