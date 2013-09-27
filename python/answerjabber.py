#!/usr/bin/env python
# -*- coding: utf-8 -*-
# =========================================== #
# Python script to sort and move RPM packages #
# Author: Alexei Panov                        #
# e-mail: elemc AT atisserv DOT ru            #
# =========================================== #

from sleekxmpp import ClientXMPP
from sleekxmpp.exceptions import IqError, IqTimeout
import sys
import os
import logging

class AnswerJabber(ClientXMPP):
    def __init__(self, jid, password, answer="We are not available."):
        ClientXMPP.__init__(self, jid, password)
        self.add_event_handler("session_start", self.session_start)
        self.add_event_handler("message", self.message)
        self.aanswer = answer

    def session_start(self, event):
        self.send_presence()
        self.get_roster()


    def message(self, msg):
        if msg['type'] in ('chat', 'normal'):
            msg.reply(self.aanswer).send()

if __name__ == '__main__':

    if len(sys.argv) < 4:
        print("Use this %s jid password answer-message")
        os._exit( 1 )


    jid = sys.argv[1]
    pwd = sys.argv[2]
    msg = sys.argv[3]

    logging.basicConfig(level=logging.DEBUG,
                        format='%(levelname)-8s %(message)s')

    xmpp = AnswerJabber(jid, pwd, msg)
    xmpp.connect()
    xmpp.process(block=True)

