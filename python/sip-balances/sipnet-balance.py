#!/usr/bin/env python
# -*- coding: utf-8 -*-
# -*- Python -*-
# ---------------------------------------- #
# Python source single (sipnet-balance.py) #
# Author: Alexei Panov <me@elemc.name>     #
# ---------------------------------------- #
# Description: 

import sys, os
import re

try:
    from mechanize import Browser
except:
    print("Please install python-mechanize package.")
    os._exit( os.EX_UNAVAILABLE )

def get_float( balance_string ):
    f = re.search( r'([-+]?)(\d+).(\d+)&nbsp;', balance_string )
    if f is None:
        return 0.0
    nums = f.groups()
    result = float( "%s%s.%s" % ( nums ) )
    return result

def html_filter( html ):
    f = re.search(r'<div>(.*)y.e.(.*)</div>', html)
    if f is None:
        return ""
    result = f.groups()[0]
    return result

def get_balance( username, password ):

    balance = 0.0
    browser = Browser()

    try:
        browser.open( "http://sipnet.ru" )
    except:
        return balance

    browser.select_form( nr=0 )
    browser.form['Name']        = username
    browser.form['Password']    = password
    browser.submit()

    response = browser.response()
    html = response.read()
    browser.close()

    balance_string = html_filter( html )
    result = get_float( balance_string )

    return result

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print( "Please use this as %s <username> <password>" % sys.argv[0] )
        os._exit( os.EX_NOINPUT )

    username = sys.argv[1]
    password = sys.argv[2]

    result = get_balance( username, password )
    print(result)
