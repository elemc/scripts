#!/usr/bin/env python
# -*- Python -*-
# -*- coding: utf-8 -*-
# ------------------------------------------------- #
# Python source single (add-dir-to-vim-projects.py) #
# Author: Alexei Panov <me@elemc.name>              #
# ------------------------------------------------- #
# Description: 

import os
import os.path

typical_ident = "    "
share_str = ""
home_dir = os.path.expanduser("~")


def insert_string(s):
    print(s)


def ident_count(s):
    return len(s) - len(s.strip())


def self_listdir(d):
    dirs = []
    files = []
    for o in os.listdir(d):
        fullpath = os.path.join(d, o)
        if os.path.isdir(fullpath):
            dirs.append(o)
        elif os.path.isfile(fullpath):
            files.append(o)
    dirs.sort()
    files.sort()
    return dirs + files


def format_path_str(path_str):
    new_path_str = path_str.replace(home_dir, "~")
    return new_path_str


def process_file(f, ident=""):
    insert_string("%s%s" % (ident, os.path.basename(f)))


def process_dir(d, ident=""):
    if not os.path.exists(d):
        return

    dir_name = os.path.basename(d)

    if len(ident) == 0:
        insert_string("%s=%s CD=. {" % (dir_name, format_path_str(d)))
    else:
        insert_string("%s%s=%s/ {" % (ident, dir_name, dir_name))

    new_ident = ident + typical_ident
    for f in self_listdir(d):  # os.listdir( d ):
        if f == ".git":
            continue
        o = os.path.join(d, f)
        if os.path.isdir(o):
            process_dir(o, new_ident)
        elif os.path.isfile(o):
            process_file(o, new_ident)

    print("%s}" % ident)


if __name__ == '__main__':
    current_dir = os.path.abspath(os.path.curdir)
    # print( home_dir )
    process_dir(current_dir)
