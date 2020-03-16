# ks - Kickstart for Dogtag

Build a PKI server for bare metal.
3 components : Dogtag CA (more to come), its internal database (389 DS LDAP server), openldap (publishing directory).
The internal database runs on ports 390 & 1575 (LDAPS) - see the 389ds.inf file.
Openldap runs on ports 389/636 (as usual).


## Getting Started

The kickstart needs to be alled from a pki server.
Various environment variables are to be set in the postinstall.

### Prerequisites

Only tested with Fedora 31.

