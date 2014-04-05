#!/bin/sh

error_present=0
my_user_name="alex"
home_dir="/home/${my_user_name}"
vim_conf_repo="git@github.com:elemc/vim-conf.git"
monaco_font_url="http://repo.elemc.name/sources/Monaco_Linux.ttf"
epel_6_rurl="http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm"
epel_5_rurl="http://download.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm"

pushd_cmd="pushd"
popd_cmd="popd"

function check_command() {
    unset cmd_path
    cmd=$1
    cmd_present=`which $cmd > /dev/null 2>&1`
    if [ -z $cmd_present ]; then
        cmd_path="/usr/bin/${cmd}"
    else
        cmd_path=$cmd_present
    fi

    if [ ! -x $cmd_path ]; then
        echo "[x] Please install ${cmd}!"
        error_present=1
    fi
}

function setup_variable() {
    if [ -z $1 ]; then
        echo "$2"
    else
        echo "$1"
    fi
}

function install_sudo() {
    echo "[*] Install sudo for user ${my_user_name}"
    sudo_string="${my_user_name} ALL=(ALL) NOPASSWD: ALL"
    if [ -d /etc/sudoers.d ]; then
        echo $sudo_string > /etc/sudoers.d/${my_user_name}
    else
        echo $sudo_string >> /etc/sudoers
    fi
}

function install_elemc_repo() {
    echo "[*] Install elemc repository"
    release=`rpm -qa \*-release`
    el_release=`echo $release | grep -Ei "oracle|redhat|centos|sl"`
    repo_file=""
    if [ -z $el_release ]; then # It is Fedora
        repo_file="http://repo.elemc.name/download/elemc-repo-fedora.repo"
    else
        repo_file="http://repo.elemc.name/download/elemc-el.repo"
        echo "[*] Install epel repository"
        el_version=`echo "$el_release" | cut -d"-" -f3`
        release_url=""
        if [ $el_version -eq 6 ]; then
            release_url=$epel_6_rurl
        elif [ $el_version -eq 5 ]; then
            release_url=$epel_5_rurl
        else
            echo "[x] Don't know EL release: ${el_release}"
            unset release_url
        fi

        [ -n $release_url ] && rpm -Uvh $release_url
    fi
    $pushd_cmd /etc/yum.repos.d > /dev/null 2>&1
    curl -O $repo_file > /dev/null 2>&1
    $popd_cmd > /dev/null 2>&1
}

function install_ssh_keys() {
    echo "[*] Install ssh keys from host ${head_host}"
    scp -q -r $my_user_name@${head_host}:~/.ssh ${home_dir}
    chown -R ${my_user_name}:${my_user_name} ${home_dir}/.ssh
}

function install_vim_files() {
    echo "[*] Install vim user files from git"

    vim_files_list="vim vimrc"

    # remove old files
    for vf in $vim_files_list; do
        vft="${home_dir}/.$vf"
        [ -f "$vft" ] && rm -rf $vft
        [ -d "$vft" ] && rm -rf $vft
    done

    # create new symlinks
    for vim_d in $vim_files_list; do 
        ln -sf ${home_dir}/workspace/vim-conf/$vim_d ${home_dir}/.$vim_d; 
        echo $vim_d; 
    done

    su - alex << EOF
$pushd_cmd ${home_dir} > /dev/null 2>&1
[ ! -d workspace ] && mkdir workspace && chown -R ${my_user_name}:${my_user_name} workspace
$pushd_cmd workspace > /dev/null 2>&1
git clone ${vim_conf_repo}
$popd_cmd > /dev/null 2>&1
git clone https://github.com/gmarik/vundle.git ${home_dir}/.vim/bundle/vundle
$popd_cmd > /dev/null 2>&1
EOF
    chown -R ${my_user_name}:${my_user_name} ${home_dir}/workspace
}

function install_monaco_font() {
    echo "[*] Install Monaco font"
    if [ -f /etc/redhat-release ]; then # It is RedHat/Fedora, install rpm-package
        yum -y install gringod-monaco-linux-fonts
    else
        local_fonts_dir="${home_dir}/.local/share/fonts"
        mkdir -p $local_fonts_dir
        $pushd_cmd $local_fonts_dir > /dev/null 2>&1
        curl -s -O $monaco_font_url
        $popd_cmd > /dev/null 2>&1
        su - ${my_user_name} -c "fc-cache -fv"
    fi
}

function main() {
    head_host=$(setup_variable $1 alex-desktop)

    # Checks
    check_command git
    check_command scp
    check_command curl
    check_command fc-cache
    check_command getent

    # Check user present
    user_present=`getent passwd | grep $my_user_name`
    if [ -z $user_present ]; then
        echo "[x] User '${my_user_name}' doesn't exist."
        error_present=1
    fi

    if [ $error_present -eq 1 ]; then
        echo "Please fix error."
        exit 1
    fi

    # Install sudo
    install_sudo

    # Install elemc-repo
    if [ -f /etc/redhat-release ]; then
        install_elemc_repo
    fi    

    # Install ssh-keys (user)
    install_ssh_keys

    # Install vim (user)
    install_vim_files

    # Install monaco font
    install_monaco_font
}

main $*