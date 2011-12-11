import httplib, json, array
from gdata.tlslite.utils import keyfactory
from gdata.tlslite.utils.PyCrypto_RSAKey import PyCrypto_RSAKey

key = keyfactory.generateRSAKey(1024)
#print key.n
#print key.e

conn = httplib.HTTPConnection("localhost:8084")
conn.request("GET", "/activation/req/")
res = conn.getresponse()
js = json.loads(res.read())
n = long(js['server_n'])
e = long(js['server_e'])
uuid = js['uuid']
sts = js['sts_session']
#print js

server_key = PyCrypto_RSAKey(n=n, e=e)
msisdn = "4792662756"
put = {}
put['client_e'] = key.e
put['client_n'] = key.n
put['msisdn'] = msisdn

msg = msisdn + uuid
msg_a = array.array("B", msg.encode('utf8'))
sig = key.hashAndSign(msg_a).tostring().encode('base64')
#print sig
put['signature'] = sig

body = json.dumps(put)
print body
headers = {"Content-type": "application/json"}

conn.request("PUT", "/activation/ack/" + sts, body, headers)
res = conn.getresponse()
print res.read()
smscode = raw_input("SMS: ")
pincode = raw_input("PIN:")
pukcode = raw_input("PUK:")
print smscode, pincode, pukcode

token_clear = smscode + " " + pincode + " " + pukcode
token_a = array.array("B", token_clear)
sig = key.hashAndSign(token_a).tostring().encode('base64')
token = server_key.encrypt(token_a).tostring().encode('base64')

put = {}
put['token'] = token
put['signature'] = sig
body = json.dumps(put)
print body
conn.request("PUT", "/activation/verify/" + sts, body, headers)
res = conn.getresponse()
print res.read()
