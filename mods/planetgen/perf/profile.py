#!/usr/bin/env python3

# This is a Python script
# When run from the command-line, it automatically adds profiling statements to
# all Lua scripts in the current directory. By default, they are added at the
# start and end of all named functions in the global scope. In reality, it
# relies on indentation to identify blocks, and will not act on lines with
# comments, so it is coding-style-specific.

# You can run it by entering the directory you want to apply it on (in this
# case, the top directory for the mod) and running: 'python3 perf/profile.py'

# The inserted lines can be set to other values, but remember:
# * There can be at most one '{}', that will be replaced with the function name.
# * The exact phrase '-- auto-generated' is recognized by 'unprofile.py', so
#   either don't change it or edit that file.
# * The trailing '\n' is required.
profile_start = '    profile_start("{}") -- auto-generated\n'
profile_end = '    profile_end("{}") -- auto-generated\n'

import os, re

re_function = re.compile(r"^function (\w+)")
re_end = re.compile(r"^end$")
cwd = os.getcwd()
for filename in os.listdir(cwd):
    if filename.endswith(".lua"):
        with open(filename, "r+t") as f:
            output_lines = []
            function_name = None
            defined = False
            comment = False
            for line in f:
                if comment:
                    if line.find("]]") >= 0:
                        comment = False
                    output_lines.append(line)
                    continue
                if line.find("--") >= 0:
                    output_lines.append(line)
                    continue
                if line.find("--[[") >= 0:
                    comment = True
                    output_lines.append(line)
                    continue

                match = re_end.match(line)
                if defined and match is not None:
                    output_lines.append(profile_end.format(function_name))
                    defined = False
                    function_name = None

                output_lines.append(line)

                match = re_function.match(line)
                if match is not None:
                    function_name = match.group(1)
                if not defined and function_name is not None and line.find(")") >= 0:
                    output_lines.append(profile_start.format(function_name))
                    defined = True
            f.seek(0)
            for line in output_lines:
                f.write(line)
            f.truncate()
