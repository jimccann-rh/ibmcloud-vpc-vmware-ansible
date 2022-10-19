#!/usr/bin/env python3

import ipaddress, sys
firstarg=sys.argv[1]
from ipaddress import IPv4Interface

ifc = IPv4Interface(firstarg)
print(ifc.ip + 1)
