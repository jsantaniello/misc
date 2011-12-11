import random, hashlib
import time
t = time.time()

p = long("fd7f53811d75122952df4a9c2eece4e7f611b7523cef4400c31e3f80b6512669455d402251fb593d8d58fabfc5f5ba30f6cb9b556cd7813b801d346ff26660b76b9950a5a49f9fe8047b1022c24fbba9d7feb7c61bf83b57e7c6a8a6150f04fb83f6d3c51ec3023554135a169132f675f3ae2b61d72aeff22203199dd14801c7", 16)
q = long("9760508f15230bccb292b982a2eb840bf0581cf5", 16)
g = long("f7e1a085d69b3ddecbbcab5c36b857b97994afbbfa3aea82f9574c0b3d0782675159578ebad4594fe67107108180b449167123e84c281613b7cf09328cc8a6e13c167a8b547c8d28e0a3ae1e2bb3a675916ea37f0bfa213562f1fb627a01243bcca4f1bea8519089a883dfe15ae59f06928b665e807b552564014c3bfecf492a", 16)
	
s1str = "1234"
s2str = "1234"

s1sha = hashlib.sha1()
s1sha.update(s1str)

s2sha = hashlib.sha1()
s2sha.update(s2str)

s1 = long(s1sha.hexdigest(), 16)
s2 = long(s2sha.hexdigest(), 16)

AliceID = "Alice"
BobID = "Bob"

def getSharedSecret(K):
	sha = hashlib.sha1()
	sha.update(str(K))
	return long(sha.hexdigest(), 16)

def getSHA1(g, gr, gx, signerID):
	sha = hashlib.sha1()
	sha.update(str(g))	
	sha.update(str(gr))
	sha.update(str(gx))
	sha.update(str(signerID))
	return long(sha.hexdigest(), 16)



def generateZKP(p, q, g, gx, x, signerID):
	 v = random.getrandbits(160)
	 gv = pow(g, v, p)
	 h = getSHA1(g, gv, gx, signerID)
	 ZKP = gv, (v - (x * h)) % q
	 return ZKP

def verifyZKP(p, q, g, gx, sig, signerID):
	h = getSHA1(g,sig[0],gx,signerID)
	return (gx > 0) and \
		(gx < p -1) and \
		(pow(gx, q, p) == 1) and \
		(((pow(g, sig[1], p) * pow(gx, h, p)) % p ) == sig[0])

		


# Alice's numbers
x1 = random.getrandbits(160)
x2 = random.getrandbits(160)
# Bob's numbers
x3 = random.getrandbits(160)
x4 = random.getrandbits(160)

# Alice
gx1 = pow(g, x1, p)
gx2 = pow(g, x2, p)

sigX1 = generateZKP(p,q,g,gx1,x1,AliceID)
sigX2 = generateZKP(p,q,g,gx2,x2,AliceID)

# Bob
gx3 = pow(g, x3, p)
gx4 = pow(g, x4, p)

sigX3 = generateZKP(p,q,g,gx3,x3,BobID)
sigX4 = generateZKP(p,q,g,gx4,x4,BobID)


print "************Step 1**************"
print "Alice sends to Bob: "
print "g^{x1}=" + str(gx1)
print "g^{x2}=" + str(gx2)
print "KP{x1}={" + str(sigX1[0]) + "};{" + str(sigX1[1]) + "}"
print "KP{x2}={" + str(sigX2[0]) + "};{" + str(sigX2[1]) + "}"
print

print "Bob sends to Alice: "
print "g^{x3}=" + str(gx3)
print "g^{x4}=" + str(gx4)
print "KP{x3}={" + str(sigX3[0]) + "};{" + str(sigX3[1]) + "}"
print "KP{x4}={" + str(sigX4[0]) + "};{" + str(sigX4[1]) + "}"
print

# Alice verifies Bob's ZKPs
print "Alice verifies Bob's ZKPs: " + str(verifyZKP(p,q,g,gx3,sigX3,BobID) and verifyZKP(p,q,g,gx4,sigX4,BobID) and gx4 != 1)
# Bob verifies Alice's ZKPs
print "Bob verifies Alice's ZKPs: " + str(verifyZKP(p,q,g,gx1,sigX1,AliceID) and verifyZKP(p,q,g,gx2,sigX2,AliceID) and gx2 != 1)


# Step 2: Alice sends A and Bob sends B:
print "********* STEP 2 **********"

# Alice makes A and sig
gA = (gx1 * gx3 * gx4) % p
A = pow(gA, ((x2 * s1) % q), p)
sigX2s = generateZKP(p,q,gA,A,(x2 * s1) % q, AliceID)

print "Alice sends to Bob A: " + str(A)
print "KP{x2*s}={" + str(sigX2s[0]) + "},{" + str(sigX2s[1]) + "}"
print

# Bob makes B and sig
gB = (gx3 * gx1 * gx2) % p
B = pow(gB, ((x4 * s2) % q), p)
sigX4s = generateZKP(p,q,gB,B,(x4 * s2) % q, BobID)

print "Bob sends to Alice B: " + str(B)
print "KP{x4*s}={" + str(sigX4s[0]) + "},{" + str(sigX4s[1]) + "}"
print

print "Alice verifies Bob's ZKP: " + str(verifyZKP(p,q,gB,B,sigX4s,BobID))
print "Bob verifies Alice's ZKP: " + str(verifyZKP(p,q,gA,A,sigX2s,AliceID))

# After step 2, compute the common key

Ka = getSharedSecret(pow(((pow(gx4, -(x2 * s1) % q,p)) * B), x2, p))
print "Alice computes: " + str(Ka)

Kb = getSharedSecret(pow(((pow(gx2, -(x4 * s2) % q,p)) * A), x4, p))
print "Bob computes: " + str(Kb)

print time.time() -t





