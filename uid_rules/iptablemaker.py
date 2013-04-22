#!/usr/bin/python

uids=[1,2,3,4,5,6,7,8,1000,1001,1003]

def splitter(rg, parent_name):
	n = len(rg)
	if n <= 1:
		leaf_name = "uid-leaf-" + str(rg[0])
		print "iptables -N " + leaf_name
		print "iptables -A " + parent_name + " -m owner --uid-owner " + str(rg[0]) + " -j " + leaf_name
		print
		return
	first_part = rg[:n/2] 
	second_part = rg[n/2:]
	node_name = "uid-node-" + str(rg[0]) + "-" + str(rg[-1])
	print "iptables -N " + node_name
	print "iptables -A " + parent_name + " -m owner --uid-owner " + str(rg[0]) +"-" + str(rg[-1]) + " -j ",
	print node_name
	print
	splitter(first_part, node_name)
	splitter(second_part, node_name)
	return


splitter(uids, "OUTPUT")

