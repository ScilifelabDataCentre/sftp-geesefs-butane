# butane-sftp-geesefs

[Butane](https://github.com/coreos/butane/blob/main/docs/getting-started.md) configuration
(variant: fcos, version: [1.4.0](https://github.com/coreos/butane/blob/main/docs/config-fcos-v1_4.md))
for running an SFTP server on
[Fedora CoreOS](https://docs.fedoraproject.org/en-US/fedora-coreos/). For storage
[geesefs](https://github.com/yandex-cloud/geesefs) mounts S3 buckets. (One S3 bucket per user).

[Zincati](https://github.com/coreos/zincati), the agent for Fedora CoreOS auto-updates,
is configured to have a maintenance window on Sunday mornings
(see [butane-files-dir/30-updates-strategy.toml](butane-files-dir/30-updates-strategy.toml)).
If there was an update available, the VM will reboot after performing the update. After the
reboot the S3 buckets will be emptied by instances of the templated service
_empty-bucket@.service_.

## Requirements

The command-line tools

* butane
* envsubst
* scp

and some way to boot up a Fedora CoreOS computer (or VM) from an Ignition file.

## Installation

1. Install [__butane__](https://github.com/coreos/butane).
   For example on macOS `brew install butane`
2. Clone this Git repository
   ```
   git clone URL
   ```
3. Change directory
   ```
   cd butane-sftp-geesefs
   ```
4. Set the environment variable `MY_SSH_KEY` to your public SSH key.
   The command __envsubst__ will do text replacement and insert
   your public SSH key into the butane file.
   ```
   export MY_SSH_KEY="ssh-ed25519 AAAAC3Nza..."
   ```
5. Create Ignition file
   ```
   cat sftp-geesefs.butane | envsubst | butane --pretty --files-dir butane-files-dir --strict > sftp-geesefs.ign
   ```  
6. Boot up a Fedora CoreOS from the Ignitition file _sftp-geesefs.ign_

7. Copying the user configuration file _install-sftp-users.json_ to the directory
   _/srv/sftp_geesefs/install-sftp-users/trigger/_ will trigger an installation.
   The JSON format is 
   ```
   [ {
     "s3_endpoint" : "https://s3.example.com",
     "s3_bucket_name" : "some_bucket1", 
     "aws_access_key_id" : "3R9...",
     "aws_secret_access_key" : "9Bf...",
     "user" : "myuser1", 
     "ssh_authorized_keys" : "ssh-rsa AAAAB3NzaC1yc2EA..." },
   
   {
     "s3_endpoint" : "https://s3.example.com",
     "s3_bucket_name" : "some_bucket2", 
     "aws_access_key_id" : "5R2...",
     "aws_secret_access_key" : "3Be...",
     "user" : "myuser2", 
     "ssh_authorized_keys" : "ssh-rsa AAAAB3EvL..." }
   ]
   ```
   (Multiple users can be installed from the same JSON file).
   
   To copy the file, run a command similar to
   ```
   scp install-sftp-users.json root@fcos:/srv/sftp_geesefs/install-sftp-users/trigger/
   ```
   (replace _fcos_ with the IP address or hostname of the installed Fedora CoreOS computer/VM)

### Usage

```
sftp myuser1@server
```

Note, by default the server will empty the S3 buckets after a reboot.
To disable automatic emptying of the S3 bucket used by the user _myuser1_, run

```
sudo systemctl disable empty-bucket@myuser1.service
```

Reboots will for instance happen after an update by Zincati.
Zincati can be configure by adjusting/adding configuration files under
_/etc/zincati/config.d/_


### Note about POSIX compliance

Note that geesefs is not fully POSIX compliant. See [POSIX Compatibility Matrix](https://github.com/yandex-cloud/geesefs/tree/master#posix-compatibility-matrix)

