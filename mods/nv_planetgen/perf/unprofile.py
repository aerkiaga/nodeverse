#!/usr/bin/env python3

# This is a Python script
# When run from the command-line, it undoes any changes performed by
# 'profile.py' on Lua files in the current directory. By default, it recognizes
# lines with the phrase '-- auto-generated' and deletes them.

# You can run it by entering the directory you want to apply it on (in this
# case, the top directory for the mod) and running: 'python3 perf/unprofile.py'

import os, re

re_function = re.compile(r"function (\w+)")
re_end = re.compile(r"end$")
cwd = os.getcwd()
for filename in os.listdir(cwd):
    if filename.endswith(".lua"):
        with open(filename, "r+t") as f:
            output_lines = []
            for line in f:
                if line.find("-- auto-generated") >= 0:
                    continue
                output_lines.append(line)
            f.seek(0)
            for line in output_lines:
                f.write(line)
            f.truncate()
