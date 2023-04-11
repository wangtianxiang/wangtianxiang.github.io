#!/bin/bash

usage(){
    echo "
Automatically create a convenient docker container development environment and
share git config, ssh config, homepath/work folder with host.
Create and setup container:
    ./docker_dev_env.sh -cs -i image_name -n container_name -p port
Only create container:
    ./docker_dev_env.sh -c -i image_name -n container_name -p port
Setup container:
        ./docker_dev_env.sh -s -n container_name
Options:
    -i  Docker image name,contain version
    -n  Docker contanier name
    -p  Publish container's 22 port to the host
    -c  Create container
    -s  Setup container
    -h  Display this help and exit
"
}

get_passwd(){
    username=$1
    while true; do
        echo "Enter a password $username: " >&2
        read -s password
        echo "Retype a password $username : " >&2
        read -s password2
        if [ $password == $password2 ];
        then
            echo $password
            break
        else
            echo "You have entered different passwords. Try again.."
        fi
    done
}

main(){

    create_constainer=0
    setup_container=0
    image_name=''
    container_name=''
    port=''

    while getopts "i:n:p:sch" arg
    do 
        case $arg in 
            c)
                create_constainer=1
                ;;
            s)
                setup_container=1
                ;;
            i)
                image_name="$OPTARG"
                ;;
            n)
                container_name="$OPTARG"
                ;;
            p)
                port="$OPTARG"
                ;;
            h)
                usage
                exit
                ;;
            ?)
                echo "unregistered argument"
                usage
                exit
                ;;
        esac
    done 

    if [ $create_constainer == "1" ]
    then
        if [ -z "$image_name" ]
        then
            read -p "Docker image name:" image_name
        fi

        if [ -z "$container_name" ]
        then
            read -p "Docker contanier name:" contanier_name
        fi

        if [ -z "$port" ]
        then
            read -p "Publish container's 22 port to the host:" port
        fi
        
        # Generate shared folder if folder not exist
        mkdir -p ${HOME}/work
        mkdir -p ${HOME}/.ssh
        [[ -f ${HOME}/.gitconfig ]] || touch ${HOME}/.gitconfig

        docker_run_cmd="docker run --gpus all --cap-add=SYS_ADMIN --name $container_name \
            --hostname $container_name  -v ${HOME}/work:${HOME}/work \
            -v ${HOME}/.gitconfig:${HOME}/.gitconfig -v ${HOME}/.ssh:${HOME}/.ssh"

        if [ -n "$port" ]
        then
            docker_run_cmd="$docker_run_cmd -p $port:22 "
        fi
        docker_run_cmd="$docker_run_cmd -itd $image_name"

        echo $docker_run_cmd
        eval $docker_run_cmd
    fi

    if [ $setup_container == "1" ]
    then
        # get username,uid,groupname,gid
        id_string=$(id)
        regex='uid=([0-9]+)\(([^\)]+)\)\sgid=([0-9]+)\(([^\)]+)\)'
        [[ $id_string =~ $regex ]]

        uid=${BASH_REMATCH[1]}
        uname=${BASH_REMATCH[2]}
        gid=${BASH_REMATCH[3]}
        gname=${BASH_REMATCH[4]}

        echo $uname

        echo "Setting container root and $uname password"
        echo "Enter the Enter key without setting the password"
        root_passwd=$(get_passwd "root")
        user_passwd=$(get_passwd $uname)

        setup_cmd="apt update && apt install -y vim git sudo && "
        if [ -n $root_passwd ]
        then
            setup_cmd="$setup_cmd echo -e \"$root_passwd\\n$root_passwd\" | passwd && "
        fi

        setup_cmd="$setup_cmd groupadd -g $gid $gname && \
        useradd -d $HOME -s /bin/bash -g $gid -u $uid $uname && "

        if [ -n $user_passwd ]
        then
            setup_cmd="$setup_cmd echo -e \"$user_passwd\\n$user_passwd\" | passwd $uname && "
        fi

        setup_cmd="$setup_cmd usermod -a -G sudo $uname && \
        cp -r /etc/skel/. $HOME && \
        chown $uname:$gname $HOME $HOME/.bashrc $HOME/.bash_logout $HOME/.profile"
        
        docker exec $container_name /bin/bash -c "$setup_cmd"
    fi

    if [ $create_constainer == "0" ] && [ $setup_container == "0" ]
    then
        echo "Either -s, -c option must be set!"
    fi
}


main $@
