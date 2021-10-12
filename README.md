# User Management

This script is a simple tool for user management in Linux distros.

## Functionality

* Create users
* List all created users
* Lock / Unclock users
* List all locked users
* Backup user home
* Generate SSH key for exist user
* Promote user to admin
* Degrate user from admin
* Delete user
* Logging all actions in `actions.log`

## Backups

Script create `backups` catalog in the script folder and them create `tar.gz` archive with name which contains - user name and current date 

## SSH keys

Script generate 4096 RSA key for target user in `/home/<user>/.ssh` and key has name is `id_rsa_<username>`.

After SSH key was generate, script show the contents from `id_rsa_<username>.pub` file to the admin.

## Promoting / Degrating

* Promoting - User will add to `wheel` group and them will create file in `/etc/sudoers.d/<user>`
* Degrating - User will remove from `wheel` group and file `/etc/sudoers.d/<user>` will be remove

## Logging

Script has `action.log` with logged basic actions with:
* Date and Time
* User name
* Action 