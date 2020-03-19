# ks - Kickstart for Dogtag

Build a PKI server for bare metal.
4 components : Dogtag CA (more to come) & OCSP server, its internal database (389 DS LDAP server), openldap (publishing directory).
The internal database runs on ports 390 & 1575 (LDAPS) - see the 389ds.inf file.
Openldap runs on ports 389/636 (as usual).

## Architecture
The installation is twofold.
First, kickstart runs and builds a (systemctl) service.
Then after reboot, the service runs once.

This is necessary as some parts of the installation cannot in run in a ks environment.

## Getting Started

The kickstart needs to be called from a pki server.
Various environment variables are to be set in the postinstall.

### Prerequisites

Only tested with Fedora 31.

