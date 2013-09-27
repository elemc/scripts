#!/usr/bin/env python
# -*- coding: utf-8 -*-
# ================================= #
# Python script                     #
# Author: Alexei Panov              #
# e-mail: me AT elemc DOT name      #
# ================================= #

import sys
import os

FILENAME="/var/log/messages"
SEARCH_PHRASE="pptp"

if __name__ == '__main__':
    try: # try to open fila
        f = open ( FILENAME, 'r' )
    except: # if error
        print("Error while open file")
        os._exit(1);

    for str_line in f:
        if SEARCH_PHRASE in str_line:
            print ("String line \"%s\" contains \"%s\"" % (str_line.strip(), SEARCH_PHRASE))
    
    f.close();
    os._exit(0);

