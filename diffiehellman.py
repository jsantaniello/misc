import random, hashlib

p = long("fd7f53811d75122952df4a9c2eece4e7f611b7523cef4400c31e3f80b6512669455d402251fb593d8d58fabfc5f5ba30f6cb9b556cd7813b801d346ff26660b76b9950a5a49f9fe8047b1022c24fbba9d7feb7c61bf83b57e7c6a8a6150f04fb83f6d3c51ec3023554135a169132f675f3ae2b61d72aeff22203199dd14801c7", 16)
g = long("f7e1a085d69b3ddecbbcab5c36b857b97994afbbfa3aea82f9574c0b3d0782675159578ebad4594fe67107108180b449167123e84c281613b7cf09328cc8a6e13c167a8b547c8d28e0a3ae1e2bb3a675916ea37f0bfa213562f1fb627a01243bcca4f1bea8519089a883dfe15ae59f06928b665e807b552564014c3bfecf492a", 16)
q = long("9760508f15230bccb292b982a2eb840bf0581cf5", 16)

g = 2L

# Alice
x = random.getrandbits(8)
gx = pow(g, x)
# Bob
y = random.getrandbits(8)
gy = pow(g, y)

Ka = pow(gy, x) % q
Kb = pow(gx, y) % q
print Kb
print (Ka == Kb)
print hashlib.md5(str(Kb)).hexdigest()
print hashlib.md5(str(Ka)).hexdigest()



