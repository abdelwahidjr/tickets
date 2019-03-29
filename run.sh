#!/bin/bash

# colors
##################################################
NoColor='\033[0m'
Black='\033[0;30m'
DarkGray='\033[1;30m'
Red='\033[0;31m'
LightRed='\033[1;31m'
Green='\033[0;32m'
LightGreen='\033[1;32m'
Orange='\033[0;33m'
Yellow='\033[1;33m'
Blue='\033[0;34m'
LightBlue='\033[1;34m'
Purple='\033[0;35m'
LightPurple='\033[01;35m'
Cyan='\033[0;36m'
LightCyan='\033[1;36m'
LightGray='\033[0;37m'
White='\033[1;37m'

# test colors
# echo -e "${Cyan}WELCOME ${NoColor}"

##################################################
## spinner takes the pid of the process as the first argument and
#  string to display as second argument (default provided) and spins
#  until the process completes.
spinner() {
    local PROC="$1"
    local str="$2"
    local delay="0.1"
    tput civis  # hide cursor
    printf "\033[1;34m"
    while [ -d /proc/$PROC ]; do
        printf '\033[s\033[u [ / ] %s\033[u' "$str"; sleep "$delay"
        printf '\033[s\033[u [ — ] %s\033[u' "$str"; sleep "$delay"
        printf '\033[s\033[u [ \ ] %s\033[u' "$str"; sleep "$delay"
        printf '\033[s\033[u [ | ] %s\033[u' "$str"; sleep "$delay"
    done
    printf '\033[s\033[u%*s\033[u\033[0m' $((${#str}+6)) " "  # return to normal
    tput cnorm  # restore cursor
    return 0
}

## spinner with sleep
#sleep 2 & spinner $! " Loading Bash Script ... "

echo -e "${Orange}Loading Bash Script ... ${NoColor}"

##################################################

# copy ./.env && ./docker/.env
if [ ! -f ./.env ]; then
    cp .env.example .env
    ./run.sh
    elif [ ! -f ./docker/.env ]; then
    cd ./docker/ && cp env-example .env
    cd ../ && ./run.sh
fi


# include .env file
ENV_FILE_PATH='./.env'


declare -A env
declare -a options
declare -A commands
declare -a commandsNumeric
declare -a optionsForHelp


##################################################
# os detection
# ==========
machine="UNKNOWN OS"
os="$(uname -s)"
case "$os" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;; #windows
    MINGW*)     machine=MinGw;; #windows
    *)          machine="UNKNOWN:$os"
esac


##################################################
# commands
# ==========
-() {
    options[${#options[*]}]=$1
    commands[${1,,}]=$2
    commandsNumeric[${#options[*]}]=$2
    optionsForHelp[${#options[*]}]="$(tput bold)${#options[*]})$(tput sgr0) $1"
}


##################################################
# parsing .env
# ==========
loadEnv() {
   for line in $(cat ${ENV_FILE_PATH}); do
       row=$(echo "$line" | sed -e 's/="/=/' -e 's/"$//')
       IFS='=' read -ra row <<< "$row"
       if [ ! -z ${row[0]} ]; then
        env[${row[0]}]+=${row[1]}
       fi
   done
}
loadEnv

##################################################
# variables
# ==========

# project
project_name=${env['DOCKER_PROJECT_NAME']}
appurl=${env['APP_URL']}



##################################################
# database

DB_CONNECTION=${env['DB_CONNECTION']}
DB_HOST=${env['DB_HOST']}
DB_PORT=${env['DB_PORT']}
DB_DATABASE=${env['DB_DATABASE']}
DB_USERNAME=${env['DB_USERNAME']}
DB_PASSWORD=${env['DB_PASSWORD']}



db_permission="chown mysql:mysql /etc/mysql/conf.d/my.cnf && chmod 0444 /etc/mysql/conf.d/my.cnf"
recreate_db="mysql -u$DB_USERNAME -p$DB_PASSWORD -P$DB_PORT -h$DB_HOST --execute='DROP DATABASE IF EXISTS $DB_DATABASE;CREATE DATABASE $DB_DATABASE; GRANT ALL ON $DB_DATABASE.* TO $DB_USERNAME@$DB_HOST;'"

##################################################
##################################################
##################################################
# docker

containers="nginx php-fpm php-worker mysql phpmyadmin workspace"

mysql_container="${project_name}_mysql_1"

##################################################
##################################################
##################################################


c="cd ./docker"

if [ $machine == "MinGw" ] || [ $machine == "Cygwin" ]; then
    d="winpty docker-compose -p $project_name"
else
    d="docker-compose -p $project_name"
fi



# success messages
msg_workspace_check_update="echo -e \"${Yellow}checking for updates ...${NoColor}\""
msg_workspace_updated="echo -e \"${Green}server updated successfully${NoColor}\""
msg_container_start="echo -e \"${Yellow}enjoy hacking with docker containers! :) ...${NoColor}\""
msg_container_build="echo -e \"${Yellow}docker containers build in progress ...:) ...${NoColor}\""
msg_db_recreated="echo -e \"${Green}database created successfully${NoColor}\""
msg_db_failed="echo -e \"${Red}database connection failed${NoColor}\""
msg_docker_data="echo -e \"${Green}docker data deleted successfully${NoColor}\""
msg_docker_build="echo -e \"${Green}docker containers created and running successfully${NoColor}\""
msg_docker_up="echo -e \"${Yellow}docker containers up${NoColor}\""
msg_docker_down="echo -e \"${Yellow}docker containers down${NoColor}\""
msg_docker_stop="echo -e \"${Yellow}docker containers has been stopped${NoColor}\""
msg_install="echo -e \"${Yellow}app installing in progress! ...${NoColor}\""
msg_seed="echo -e \"${Yellow}seeding database! ...${NoColor}\""
msg_conn="echo -e \"${Yellow}connecting to database ...${NoColor}\""
msg_url="echo -e \"${Blue}$appurl${NoColor}\""
msg_nginx_restart="echo -e \"${Green}nginx restarted successfully ...${NoColor}\""
msg_remove_containers="echo -e \"${Green}all containers deleted successfully ...${NoColor}\""
msg_cancel="echo -e \"${Yellow}Bye!${NoColor}\""

####################################################################################################

##################################################
# check mysql is running and connected and {build project}
# ==========
#mysql_conn() {

#if [[ $(docker inspect -f {{.State.Running}} $mysql_container) == "true" ]] && [[ $(docker port $mysql_container 3306) == "0.0.0.0:3306" ]] ;then
#return 1
#else
#return 0
#fi
#}
#mysql_conn

# get mysql_conn return value
#conn_val=$?

#=========================

##################################################
# os based commands
# ==========
os_commands() {
case "$1" in
       workspace_bash)

if [ "$(uname)" == "Darwin" ]; then
    # Do something under Mac OS X platform
    echo "$d exec -u root workspace bash"

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Do something under GNU/Linux platform
    echo "$d exec -u root workspace bash"

elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
    # Do something under 32 bits Windows NT platform
    echo "$d exec workspace bash"

elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
    # Do something under 64 bits Windows NT platform
    echo "$d exec workspace bash"
else
   # Do something under unkown os
    echo "$d exec workspace bash"
fi
;;

       *)
         echo "echo \"UNKNOWN\""
esac

}


##################################################
# ==========
workspace_update() {
echo "$msg_workspace_check_update && $(os_commands "workspace_bash") -c \"apt update && apt list --upgradeable && yes | apt upgrade\" && $msg_workspace_updated"
}
##################################################
##################################################
# ==========
laravel_seed() {
echo "$(os_commands "workspace_bash") -c \"php artisan project:install\""
}
##################################################
laravel_permission() {
echo "$(os_commands "workspace_bash") -c \"chmod -R 777 storage && chmod -R 777 bootstrap/cache && php artisan storage:link \" && $msg_url"
}
##################################################
##################################################
#==========
build_project() {
echo "$msg_conn && $d exec mysql bash -c \"$db_permission\" && $msg_install && $(os_commands "workspace_bash") -c \"composer install\" && $(laravel_seed)  && $(laravel_permission)"
}

##################################################

## build single container
# docker-compose -p tickets up --build -d mysql
# docker-compose -p tickets build --no-cache mysql

## stop single container
# docker-compose -p tickets stop php-worker

##################################################



##################################################
# commands
# ==========
##################################################################################################################
- "project start"                                "$c && $d up -d $containers && $msg_docker_build && docker ps -a && $msg_container_start"
- "project build"                                "$c && $(build_project)"
- "project restart"                              "$c && $d stop && $msg_docker_stop && $d up -d $containers && $msg_docker_build && docker ps -a && $msg_container_start"
- "server update"                                "$c && $(workspace_update) && $msg_container_start"
- "docker up"                                    "$c && $d up -d $containers && $msg_docker_up"
- "docker stop"                                  "$c && $d stop && $msg_docker_stop"
- "docker down"                                  "$c && $d stop && $msg_docker_stop && $d down && $msg_docker_down"
- "docker rebuild images"                        "$c && $d stop && $msg_docker_stop && $d down && $msg_docker_down && $msg_container_build && $d up --build -d $containers && $msg_docker_build"
- "docker build images without cache"            "$c && $d stop && $msg_docker_stop && $d down && $msg_docker_down && $msg_container_build && $d build --no-cache $containers && $d up --build -d $containers && $msg_docker_build"
- "docker recreate and up"                       "$c && $d up -d --force-recreate $containers && $msg_docker_build"
- "docker pause"                                 "$c && $d pause"
- "docker resume"                                "$c && $d unpause"
- "workspace bash"                               "$c && $(os_commands "workspace_bash")"
- "workspace logs"                               "$c && $d logs -f workspace"
- "database seed"                                "$c && $(os_commands "workspace_bash") -c \"php artisan project:install\""
- "database recreate"                            "$c && $d exec mysql bash -c \"$recreate_db\" && $msg_db_recreated"
- "mysql bash"                                   "$c && $d exec mysql bash -c \"mysql -u$DB_USERNAME -p$DB_PASSWORD -P$DB_PORT -h$DB_HOST\""
- "mysql logs"                                   "$c && $d logs -f mysql"
- "restart nginx"                                "$c && $d restart nginx && $msg_nginx_restart"
- "nginx logs"                                   "$c && $d logs -f nginx"
- "redis bash"                                   "$c && $d exec redis bash"
- "laravel websockets"                           "$c && $(os_commands "workspace_bash") -c \"php artisan websockets:serve\""
- "up containers list"                           "$c && docker ps"
- "all containers list"                          "$c && docker ps -a"
- "remove docker data directory"                 "$c && $(os_commands "workspace_bash") -c \"rm -rf ./docker-data \" && $msg_docker_data"
- "exit"                                         "$msg_cancel"

##################################################################################################################

COLUMNS=120
if [ ! -z "$1" ]; then
    if [[ $1 =~ ^-?[0-9]+$ ]]; then
         eval "${commandsNumeric[${1}]}"
    else
        if [ $1 == '--help' ] || [ $1 == '-h' ]; then
            for option in "${optionsForHelp[@]}"; do
                printf "%-40s\n" "${option}"
            done | column
        else
            eval "${commands[${*,,}]}"
        fi
    fi
    exit
fi

COLUMNS=120
PS3='Please Choice Command: '
select option in "${options[@]}"
do
    eval "${commands[${option,,}]}"
    break
done

##################################################