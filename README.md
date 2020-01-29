# Ansible Role: EJBCA + YubiHSM 2 toolset

### What this does

* Automates the installation and initial configuration of EJBCA and YubiHSM 2
  toolset with Ansible
* Describes how to configure a YubiHSM 2 device for use with PrimeKey EJBCA on
  bare-metal

## Requirements

* A physical CentOS 7 server with any GUI and `firefox` installed
* A Ubuntu 18+ instance fuctioning as an Ansible controller with `ansible` and
  `git` installed
* YubiHSM 2 USB device

## Usage

On the Ansible controller, clone the following repository to any location:

```
$ git clone https://github.com/nvr5een/ansible-role-ejbca.git
```

Edit the `hosts` file inside the repository, replacing the only IP address with
the IP address of the target CentOS 7 server:

```
$ vi ansible-role-ejbca/inventories/hosts

[rootca]
10.118.254.108 <-- replace this
```

From the controller machine, ensure the root account on the target server can be
accessed via `ssh`. When this is confirmed, the Ansible playbook can be ran.

NOTE: You will be prompted for the target server's root password when running
the Ansible playbook.

Change directories to the root of the repository:

```
$ cd ansible-role-ejbca
```

Run the Ansible playbook to install EJBCA and the YubiHSM 2 toolset:

```
$ ansible-playbook -i inventories/hosts caservers.yml -k -u root
```

Run the Ansible playbook to install EJBCA **only**:

```
$ ansible-playbook -i inventories/hosts caservers.yml -k -u root --skip-tags 'yubihsm2'
```

NOTE: Required software hosted on `sourcforge.net`, etc., is downloaded during
the installation. Time-outs are possible when software downloads are attempted
causing the installation to fail. If this happens, remove directory `/opt/jboss`
on the target server and run the Ansible playbook again.

NOTE: During installation, the Ansible playbook runs a modified version of the
EJBCA installation script shipped with the software zip archive. This output is
logged to `/opt/jboss/install.log`.

The keystore's location and password are displayed during the installation. To
view this information again, run:

```
$ ansible-playbook -i inventories/hosts caservers.yml -k -u root --tags 'result'
```

A successful installation message will be similar to below:

```
*********************************************************************
* SUCCESS                                                           *
*********************************************************************
You can now install the superadmin.p12 keystore, from
/opt/jboss/ejbca_ce_6_15_2_1/p12, in your web browser, using the password
28fe0babcf1afc8fac06221e6a39954aeca9e721, and access EJBCA at
https://localhost:8443/ejbca
```

When the installation is complete, the generated password protected keystore
needs to be imported into Firefox in order to access the EJBCA web interface at
`https://localhost:8443/ejbca`. This import is covered in the next section.

### Import p12 keystore (Firefox)

## Configure YubiHSM 2 device

This section describes how to configure a YubiHSM 2 device for use with EJBCA on
a bare-metal CentOS 7 server.

During the EJBCA installation, YubiHSM 2 tools are installed and administrative
user `jciadm` is created. It is assumed `jciadm` is logged into the GUI
environment of the previously configured CentOS 7 server to perform the manual
YubiHSM 2 configuration.

Ensure the Yubico USB device is inserted and user `jciadm` is logged in using
password `Ilikepki20`. When ready, start a terminal and run:

```
$ sudo yubihsm-connector -d
```

Open another terminal tab/window and run:

```
$ sudo yubihsm-shell
```

Once inside `yubihsm-shell`, execute the commands `connect`, `session open 1`,
then enter `password` for password when prompted as shown:

```
[jciadm@localhost]$ sudo yubihsm-shell
Using default connector URL: http://127.0.0.1:12345
yubihsm> connect
Session keepalive set up to run every 15 seconds
yubihsm> session open 1
Enter password: password
Created session 0
```

Open a third terminal tab/window and change directories to `/opt/hsm`.

For testing purposes, run `yubihsm-setup -d ejbca` with the `-d` flag to
preserve the factory preset authentication key. This allows for easy reset of
the device via `yubihsm-shell`. Drop the `-d` flag for production purposes to
ensure the factory preset key is deleted. When prompted, enter `password` for
password, `1` for number of domains, and `2` for wrap key ID as shown:

```
[jciadm@localhost hsm]$ sudo yubihsm-setup -d ejbca
Enter authentication password: password
Using authentication key 0x0001
Enter domains: 1
Using domains:
         One
Enter wrap key ID (0 to choose automatically): 2
Stored wrap key with ID 0x0002 on the device
```

When prompted, enter desired *number of shares* and *privacy threshold* as
shown. For testing purposes, values of `1` may be used. Key custodians should be
present to record their key share portions.

```
Enter the number of shares: 3
Enter the privacy threshold: 2

*************************************************************
* WARNING! The following shares will NOT be stored anywhere *
* Record them and store them safely if you wish to re-use   *
* the wrap key for this device in the future                *
*************************************************************
Press Enter to start recording key shares

2-1-BBN8s84zVwntlb0pjM9PrhT5Yg2WwW/YpjWmyLbAyy7swQKkZ/bCPe2VpVRbfMBumS9W+w
Have you recorded the key share? (y/n) y
2-2-CCD4eIFmrhLHNzdSBYOb0CvslB7/D4cM569zjJl7nZn/OsNbjhO8Sz4WBvF9qPSK6yU3OQ
Have you recorded the key share? (y/n) y
2-3-DDGEyk9V+Rsqorp7iUzX+j4UxuTYvt9A2NnLsHcSr/QFmHcOIruWkoScZ5KU5BPWxSPjjA
Have you recorded the key share? (y/n) y
```

Create an *application authentication key* with ID `3` following the sequence
below. When prompted to enter an *application authentication password*, provide
a unique password and record it.

```
Enter application authentication key ID (0 to choose automatically): 3
Enter application authentication key password: <'PROVIDE PASSWORD HERE'>
Stored application authentication key with ID 0x0003 on the device
Saved wrapped application authentication key to ./0x0003-authentication-key.yhw
```

Create an *audit key* with ID `4` to control access to the internal audit log.
Follow the sequence below providing a unique password when prompted:

```
Would you like to create an audit key? (y/n) y
Enter audit key ID (0 to choose automatically): 4
Enter audit authentication key password: <'PROVIDE PASSWORD HERE'>
Stored audit authentication key with ID 0x0004 on the device
Saved wrapped audit authentication key to ./0x0004-authentication-key.yhw
```

Finally, generate the *root asymmetric key* and corresponding self-signed
certificate. Enter the desired asymmetric key algorithm, key label and number of
previously configured domains as shown:

```
Previous authentication key 0x0001 *not* deleted. Make sure you know what you are doing
Supported asymmetric key algorithms:
         rsa2048
         rsa3072
         rsa4096
         ecp224
         ecp256
         ecp384
         ecp521
         ecbp256
         ecbp384
         ecbp512
         eck256
Enter asymmetric key algorithm: rsa4096
Enter key label: JCI root CA
Enter domains: 1
Using domains:
         One
Generated asymmetric keypair with ID 0x182d on the device
Stored selfsigned certificate with ID 0x182d on the device
All done
```

Configuration complete. The generated asymmetric key and self-signed attestation
certificate reside on the YubiHSM device, wrapping the public key that will
later be used by EJBCA to create the actual root CA certificate.

### Reset YubiHSM 2 device

If `yubihsm-setup` was run previously **with** the `-d` flag, exit the current
`yubihsm-shell` session (if necessary) and run a new `yubihsm-shell` session
following the sequence below:

```
yubihsm> exit
[jciadm@localhost]$ sudo yubihsm-shell
Using default connector URL: http://127.0.0.1:12345
yubihsm> connect
Session keepalive set up to run every 15 seconds
yubihsm> session open 1
Enter password: password
Created session 0
yubihsm> reset 0
Device successfully reset
```

If `yubihsm-setup` was run previously **without** the `-d` flag, remove the
YubiHSM 2 device and re-insert it, holding your finger on the metal rim for a
minimum of 10 seconds to factory reset.

## References

* https://support.yubico.com/helpdesk/attachments/2015010673207
* https://developers.yubico.com/YubiHSM2/Usage_Guides/Factory_reset.html
