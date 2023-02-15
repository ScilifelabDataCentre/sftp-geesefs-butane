#!/bin/bash

set -o errexit
set -o nounset

cat /srv/sftp_geesefs/install-sftp-users/trigger/install-sftp-users.json | jq -r '.[]|[.user, .aws_access_key_id, .aws_secret_access_key, .s3_bucket_name, .s3_endpoint, .ssh_authorized_keys] | @tsv' |
  while IFS=$'\t' read -r user aws_access_key_id aws_secret_access_key s3_bucket_name s3_endpoint ssh_authorized_keys; do
   if [[ "$user" =~ [^a-z0-9] ]]; then
     echo "Invalid username. Restricted here to lowercase alphabet and number"
     exit 1
   fi
   if [[ "$user" == "root" ]]; then
     echo "Invalid username. Username root is not allowed"
     exit 1
   fi

   useradd "$user"
   usermod -aG sftpusers "$user"
   mkdir -p "/srv/sftp_geesefs/chroot/$user/$user"
   echo "$s3_bucket_name" > "/var/home/$user/s3_bucket_name"
   echo "$s3_endpoint" > "/var/home/$user/s3_endpoint"
   mkdir "/var/home/$user/.aws"
   chmod 700 "/var/home/$user/.aws"
   /bin/echo "[default]" > "/var/home/$user/.aws/credentials"
   /bin/echo "aws_access_key_id = $aws_access_key_id" >> "/var/home/$user/.aws/credentials"
   /bin/echo "aws_secret_access_key = $aws_secret_access_key" >> "/var/home/$user/.aws/credentials"
   chmod 700 "/var/home/$user/.aws/credentials"
   mkdir "/var/home/$user/.ssh"
   chmod 000 "/var/home/$user/.ssh"
   chown -R --reference "/home/$user" "/home/$user"
   chown --reference "/home/$user" "/srv/sftp_geesefs/chroot/$user/$user"
   /bin/echo "$ssh_authorized_keys" > "/etc/ssh/extra_authorized_keys/$user"
   chmod 600 "/etc/ssh/extra_authorized_keys/$user"
   setfacl -m "u:$user:r--" "/etc/ssh/extra_authorized_keys/$user"
   systemctl enable geesefs@$user.service
   systemctl start  geesefs@$user.service
   systemctl enable empty-bucket@$user.service
  done

completefile=$(mktemp /srv/sftp_geesefs/install-sftp-users/completed/install-sftp-users.json.XXXXXX)
mv /srv/sftp_geesefs/install-sftp-users/trigger/install-sftp-users.json $completefile
