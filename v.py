from string import ascii_uppercase as letters

vs = {}
for i in range(len(letters)):
    vs[letters[i]] = letters[i:] + letters[:i]

cipher = "SANTANIELLO"

msg = "IWROTEAPROGRAMTODOTHEENCRYPTION"

longcipher = cipher * ((len(msg) / len(cipher)) + 1)

i = 0
for k in longcipher[:len(msg)]:
    print letters[vs[k].find(msg[i])],
    i += 1





