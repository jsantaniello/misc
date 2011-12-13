import random, hashlib

q = long("9760508f15230bccb292b982a2eb840bf0581cf5", 16)
g = 2L

# Alice
x = random.getrandbits(8)
gx = pow(g, x)
# Bob
y = random.getrandbits(8)
gy = pow(g, y)

#print gx
#print gy

Ka = pow(gy, x) % q
Kb = pow(gx, y) % q
print (Ka == Kb)
print hashlib.md5(str(Kb)).hexdigest()
print hashlib.md5(str(Ka)).hexdigest()


