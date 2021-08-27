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
# * The exact phrase '-- auto-generated' is recognized by 'unprofile.py' and by
#   this script, so either don't change it or edit both files.
# * The trailing '\n' is required.
profile_start = 'profile_start("{}") -- auto-generated\n'
profile_end = 'profile_end("{}") -- auto-generated\n'

import os, re

re_function = re.compile(r"^(local )?function ([a-zA-Z_.]+)")
cwd = os.getcwd()
for filename in os.listdir(cwd):
    if filename.endswith(".lua"):
        with open(filename, "r+t") as f:
            output_lines = []
            function_name = None
            defined = False
            comment = False
            return_indent = None
            lambda_indent = None
            for line in f:
                # Skip all comment lines
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

                # Inside a function
                if function_name is not None:
                    pos = line.find("return")
                    if pos == 0 or pos > 0 and line[0:pos].isspace() and (lambda_indent is None or pos <= lambda_indent):
                        output_lines.append(pos*" " + profile_end.format(function_name))
                        return_indent = pos
                    else:
                        if line.find("function") >= 0:
                            lambda_indent = len(line) - len(line.lstrip())
                        else:
                            pos = line.find("end")
                            if pos > 0 and return_indent is not None and pos <= return_indent:
                                return_indent = None
                            if pos > 0 and lambda_indent is not None and pos <= lambda_indent:
                                lambda_indent = None
                            elif pos == 0:
                                if return_indent is None:
                                    output_lines.append("    " + profile_end.format(function_name))
                                defined = False
                                return_indent = None
                                function_name = None

                output_lines.append(line)

                match = re_function.match(line)
                if match is not None:
                    function_name = match.group(2)
                if not defined and function_name is not None and line.find(")") >= 0:
                    output_lines.append("    " + profile_start.format(function_name))
                    defined = True
            final_output_lines = []
            held_line = None
            for line in output_lines:
                if line.find("-- auto-generated") >= 0:
                    if held_line is not None:
                        held_line = None
                    else:
                        held_line = line
                else:
                    if held_line is not None:
                        final_output_lines.append(held_line)
                        held_line = None
                    final_output_lines.append(line)
            f.seek(0)
            for line in final_output_lines:
                f.write(line)
            f.truncate()
