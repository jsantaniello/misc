#!/bin/bash
iptables-save | grep -v uid- | iptables-restore
