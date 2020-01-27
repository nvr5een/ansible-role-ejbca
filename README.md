# Ansible Role: EJBCA

## What this does

* Installs EJBCA and YubiHSM2 tools on CentOS 7
* Creates administrative user `jciadm` with example password `Ilikepki20`

## Requirements

A controller machine with Ansible installed. Ubuntu 18.04 with Ansible 2.5.1
works great.

## Usage

Clone this repository to your controller machine and change the IP address in
`inventories/hosts` to your taget server.

Run the following command as a normal user in the root of this repository:

```
$ ansible-playbook -i inventories/hosts caservers.yml -k -u root
```

Print result of EJBCA installation and password for `superadmin.p12` keystore by
issuing:

```
$ ansible-playbook -i inventories/hosts caservers.yml -k -u root --tags 'result'
```
