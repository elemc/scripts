in_username = 'zajohuz@rainmail.biz'
in_password = '1q2w3e'


from mechanize import Browser
import re

URL_PATH = 'https://ss.zadarma.com/'
USER_FIELD = 'email'
PASS_FIELD = 'password'

out_balance = 0.0
browser = Browser()

browser.open( URL_PATH )

browser.select_form( nr=0 )
browser.form[USER_FIELD]        = in_username
browser.form[PASS_FIELD]        = in_password
browser.submit()

browser.open( URL_PATH )

response = browser.response()
html = response.read()
browser.close()

f1 = re.search( r'>\$(.*)</a></span>', html )
if f1 is not None:
    balance_string = f1.groups()[0]
    print(balance_string)
    out_balance = float( balance_string )


print( out_balance )
