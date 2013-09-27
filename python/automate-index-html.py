#!/usr/bin/env python
# -*- coding: utf-8 -*-
# ================================= #
# Python script                     #
# Author: Alexei Panov              #
# e-mail: me AT elemc DOT name      #
# ================================= #

import os, os.path
from datetime import datetime
import locale

SPACES1=50
SPACES2=50

TABLE_WIDTH="100%"
MAIN_COLUMN_WIDTH="50%"
ADD_COLUMN_WIDTH="25%"

class AutoIndexHtml(object):
    def __init__(self, maindir, begindir):
        self.maindir    = maindir
        self.begindir   = begindir
        locale.setlocale(locale.LC_ALL, 'ru_RU.UTF-8')

    def __check_dir__(self):
        return os.path.exists(self.maindir)

    def _do_dir(self, realpath, printpath):
        if not os.path.exists(realpath):
            return

        index_html = """
<meta http-equiv='Content-Type' content='text/html; charset=utf-8' />
<html>
<head>
    <title>Directory Index %s</title>
</head>
<body bgcolor='white'>
<h1>Index of %s</h1>
<hr />
<a href='../'>parent directory</a>
<table width=%s border=0>
""" % (printpath, printpath, TABLE_WIDTH)
        listdir = os.listdir(realpath)
        listdir.sort()
        for content in listdir: #os.listdir(realpath):
            if (content == "index.html") or (content[0]=='.'):
                continue
            
            c_dir = os.path.join(realpath, content)
            html_str = ''
            dt = datetime.fromtimestamp(os.path.getctime(c_dir))
            s_dt = dt.strftime('%d-%B-%Y %H:%M')
            c_link = content
            s_size = '-'

            if os.path.isdir(c_dir):
                c_link = content + '/'
                if content[0] != '.':
                    self._do_dir(c_dir, os.path.join(printpath, content))
            else:
                s_size = os.path.getsize(c_dir)

            first_col = "<td width=%s><a href='%s'>%s</a></td>" % (MAIN_COLUMN_WIDTH, c_link, c_link)
            second_col  = "<td width=%s>%s</td>" % (ADD_COLUMN_WIDTH, s_dt)
            third_col   = "<td>%s</td>" % s_size

            html        = "<tr>%s\n%s\n%s\n</tr>" % (first_col, second_col, third_col)
            
            index_html += html + '\n'
        index_html += """
<!-- </pre> -->
</table>
<hr />
</body>
</html>
"""
        fih = open(os.path.join(realpath, 'index.html'), 'w')
        try:
            fih.write(index_html)
        finally:
            fih.close()

    def start(self):
        if not self.__check_dir__():
            return
        
        d = os.path.join(self.maindir, self.begindir)
        self._do_dir(d, os.path.join('/', self.begindir))

    def __del__(self):
        pass


if __name__ == '__main__':
    a = AutoIndexHtml('/home/isidabot/isida/logs', 'chatlogs')
    a.start()
