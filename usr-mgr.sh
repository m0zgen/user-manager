#!/bin/bash
# User manager script for Linux
# Created by Y.G.

# Envs
# ---------------------------------------------------\
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)
cd $SCRIPT_PATH

# Vars
# ---------------------------------------------------\
ME=`basename "$0"`
BACKUPS=$SCRIPT_PATH/backups
SERVER_NAME=`hostname`
SERVER_IP=$(hostname -I | cut -d' ' -f1)
LOG=$SCRIPT_PATH/actions.log

# Output messages
# ---------------------------------------------------\
RED='\033[0;91m'
GREEN='\033[0;92m'
CYAN='\033[0;96m'
YELLOW='\033[0;93m'
PURPLE='\033[0;95m'
BLUE='\033[0;94m'
BOLD='\033[1m'
WHiTE="\e[1;37m"
NC='\033[0m'

ON_SUCCESS="DONE"
ON_FAIL="FAIL"
ON_ERROR="Oops"
ON_CHECK="✓"

Info() {
  echo -en "[${1}] ${GREEN}${2}${NC}\n"
}

Warn() {
  echo -en "[${1}] ${PURPLE}${2}${NC}\n"
}

Success() {
  echo -en "[${1}] ${GREEN}${2}${NC}\n"
}

Error () {
  echo -en "[${1}] ${RED}${2}${NC}\n"
}

Splash() {
  echo -en "${WHiTE} ${1}${NC}\n"
}

space() { 
  echo -e ""
}


# Functions
# ---------------------------------------------------\

logthis() {

    echo "$(date): $(whoami) - $@" >> "$LOG"
    # "$@" 2>> "$LOG"
}

isRoot() {
    if [ $(id -u) -ne 0 ]; then
        Error "You must be root user to continue"
        exit 1
    fi
    RID=$(id -u root 2>/dev/null)
    if [ $? -ne 0 ]; then
        Error "User root no found. You should create it to continue"
        exit 1
    fi
    if [ $RID -ne 0 ]; then
        Error "User root UID not equals 0. User root must have UID 0"
        exit 1
    fi
}

# Yes / No confirmation
confirm() {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

check_bkp_folder() {
    if [[ ! -d "$BACKUPS" ]]; then
        mkdir -p $BACKUPS
    fi
}

gen_pass() {
  local l=$1
  [ "$l" == "" ] && l=9
  tr -dc A-Za-z0-9 < /dev/urandom | head -c ${l} | xargs
}

create_user() {

    space
    read -p "Enter user name: " user

    if id -u "$user" >/dev/null 2>&1; then
        Error "Error" "User $user exists. Try to set another user name."
    else
        Info "Info" "User $user will be create.."

        local pass=$(gen_pass)
        
        if confirm "Promote user to admin? (y/n or enter for n)"; then
            useradd -m -s /bin/bash -G wheel ${user}
        else
            useradd -m -s /bin/bash ${user}
        fi

        # set password
        echo "$user:$pass" | chpasswd

        Info "Info" "User created. Name: $user. Password: $pass"
        logthis "User created. Name: $user. Password: $pass"

    fi
    space

}

list_users() {
    space
    Info "Info" "List of /bin/bash users: "
    # grep 'bash' /etc/passwd | cut -d: -f1
    users=$(awk -F: '$7=="/bin/bash" { print $1}' /etc/passwd)
    for user in $users
    do
        echo "User: $user , $(id $user | cut -d " " -f 1)"
    done
    space
}

reset_password() {
    space
    while :
    do
        read -p "Enter user name: " user
        if id $user &> /etc/null 
        then
            
            if confirm "Generate password automatically? (y/n or enter for n)"; then
                local pass=$(gen_pass)
                echo "$user:$pass" | chpasswd
                Info "Info" "Password changed. Name: $user. Password: $pass"
                logthis "Password changed. Name: $user. Password: $pass"
            else
                read -p "Enter passwords: " password
                echo "$password" | passwd --stdin $user
                Info "Info" "Password changed. Name: $user. Password: $password"
                logthis "Password changed. Name: $user. Password: $password"
            fi
            space
            return 0
        else
            Error "Error" "User $user does not found!"
            space
        fi
    done

}

lock_user() {
    
    space
    while :
    do
        read -p "Enter user name: " user
        if [ -z $user ]
        then
            Error "Error" "Username can't be empty"
        else
            if id $user &> /etc/null
            then
                passwd -l $user
                Info "Info" "User $user locked"
                logthis "User $user locked"
                space
                return 0
            else
                Error "Error" "User $user does not found!"
                space
            fi
        fi
    done
}

unlock_user() {
    space
    while :
    do
        read -p "Enter user name: " user
        if [ -z $user ]
        then
            Error "Error" "Username can't be empty"
        else
            if id $user &> /etc/null
            then

                local locked=$(cat /etc/shadow | grep $user | grep !)

                if [[ -z $locked ]]; then
                    Info "Info" "User $user not locked"
                else
                    passwd -u $user
                    Info "Info" "User $user unlocked"
                    logthis "User $user unlocked"
                fi
                space
                return 0
            else
                Error "Error" "User $user does not found!"
                space
            fi
        fi
    done
}

list_locked_users() {
    cat /etc/shadow | grep '!'
}

backup_user() {
    space
    while :
    do
        read -p "Enter user name: " user
        if [ -z $user ]
        then
            Error "Error" "Username can't be empty"
        else
            if id $user &> /etc/null
            then
                check_bkp_folder
                homedir=$(grep ${user}: /etc/passwd | cut -d ":" -f 6)
                Info "Info" "Home directory for $user is $homedir "
                Info "Info" "Creating..."
                ts=$(date +%F)
                tar -zcvf $BACKUPS/${user}-${ts}.tar.gz $homedir
                Info "Info" "Backup for $user created with name ${user}-${ts}.tar.gz"
                space
                return 0
            else
                Error "Error" "User $user does not found!"
                space
                return 1
            fi
        fi
    done
}

generate_ssh_key() {
    space
    while :
    do
        read -p "Enter user name: " user
        if [ -z $user ]
        then
            Error "Error" "Username can't be empty"
        else
            if id $user &> /etc/null
            then
                local sshf="/home/$user/.ssh"
                if [[ ! -d "$sshf" ]]; then
                    mkdir -p $sshf
                    chown $user:$user $sshf
                    chmod 700 $sshf
                fi

                su - $user -c "ssh-keygen -t rsa -b 4096 -C '${user}@local' -f ~/.ssh/id_rsa_${user} -N ''"
                logthis "User $user ssh key is created - id_rsa_$user"
                return 0
            else
                Error "Error" "User $user does not found!"
                space
                return 1
            fi
        fi
    done
}

delete_user() {
    space
    while :
    do
        read -p "Enter user name: " user
        if [ -z $user ]
        then
            Error "Error" "Username can't be empty"
        else
            if id $user &> /etc/null
            then
                
                return 0
            else
                Error "Error" "User $user does not found!"
                space
                return 1
            fi
        fi
    done
}

# Actions
# ---------------------------------------------------\
isRoot



# User menu rotator
  while true
    do
        PS3='Please enter your choice: '
        options=(
        "Create new user"
        "List users"
        "Reset password for user"
        "Lock user"
        "Unlock user"
        "List all locked users"
        "Backup user"
        "Generate SSH key for user"
        "Promote user to admin"
        "Delete user"
        "Quit"
        )
        select opt in "${options[@]}"
        do
         case $opt in
            "Create new user")
                create_user
                break
                ;;
            "List users")
                list_users
                break
                ;;
            "Reset password for user")
                reset_password
                break
                ;;
            "Lock user")
                lock_user
                break
                ;;
            "Unlock user")
                unlock_user
                break
                ;;
            "List all locked users")
                list_locked_users
                break
                ;;
            "Backup user")
                backup_user
                break
                ;;
            "Generate SSH key for user")
                generate_ssh_key
                break
                ;;     
            "Delete user")
                echo "Delete user"
                break
                ;;
            "Promote user to admin")
                 echo "Promote user to admin"
                 break
             ;;
            "Quit")
                 Info "Exit" "Bye"
                 exit
             ;;
            *) echo invalid option;;
         esac
    done
   done