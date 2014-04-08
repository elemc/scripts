#!/bin/sh

error_present=0

my_user_name="alex"
home_dir="/home/${my_user_name}"
vim_conf_repo="git@github.com:elemc/vim-conf.git"
monaco_font_url="http://repo.elemc.name/download/sources/Monaco_Linux.ttf"
smb_conf_url="http://repo.elemc.name/download/sources/smb.conf"
epel_6_rurl="http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm"
epel_5_rurl="http://download.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm"

pushd_cmd="pushd"
popd_cmd="popd"
curl_cmd="curl -s"
pkg_install_debian="apt-get -y -q=2 install"
pkg_install_yum="yum -y -q install"
pkg_install_suse="zypper -n -q install"

function what_is_distro() {
    if   [ -f /etc/os-release ]; then
        distr_name=`grep -E "^ID=\W*" /etc/os-release| cut -d "=" -f 2`
        echo $distr_name
        return 0
    elif [ -f /etc/redhat-release ]; then
        release=`rpm -qa \*-release`
        el_release=`echo $release | grep -Ei "oracle|redhat|centos|sl"`
        if [ -z "$el_release" ]; then
            echo "fedora"
        else
            echo "el"
        fi
        return 0
    elif [ -f /etc/debian_version ]; then
        echo "debian"
        return 0
    elif [ -f /etc/SuSE-release ]; then
        echo "suse"
        return 0
    elif [ -f /etc/slackware-version ]; then
        echo "slackware"
        return 0
    fi

    echo "unknown"
}

function get_package_name_by_cmd() {    
    if   [ "$linux_distr" == "fedora" ] || [ "$linux_distr" == "el" ]; then
        echo $1
    elif [ "$linux_distr" == "debian" ] || [ "$linux_distr" == "ubuntu" ]; then
        package=`apt-file -Fl search $1`
        echo $package
    elif [ "$linux_distr" == "opensuse" ]; then
        package=`LANG=C zypper -x search -f $1 | grep -oP "name=\"(.*)\"" | cut -d " " -f 1 | cut -d "=" -f 2 | sed "s/\"//g"`
        echo $package
    fi
}

function install_files() {
    commands=$1

    if   [ "$linux_distr" == "fedora" ] || [ "$linux_distr" == "el" ]; then
        $pkg_install_yum $commands || error_present=1
    elif [ "$linux_distr" == "debian" ] || [ "$linux_distr" == "ubuntu" ]; then
        packages=""
        for cmd in $commands; do
            pkg=$(get_package_name_by_cmd $cmd)
            packages="$packages $pkg" 
        done
        $pkg_install_debian $packages > /dev/null 2>&1 || error_present=1
    elif [ "$linux_distr" == "slackware" ]; then
        slackpkg install $packages || error_present=1
    elif [ "$linux_distr" == "opensuse" ]; then
        packages=""
        for cmd in $commands; do
            pkg=$(get_package_name_by_cmd $cmd)
            packages="$packages $pkg" 
        done
        $pkg_install_suse $packages || error_present=1
    fi  
}

function check_command() {
    cmd=$1

    if [ ! -x $cmd ]; then
        install_files $cmd        
    fi

    if [ $error_present -eq 1 ]; then
        echo "[X] Error. Command $cmd not found and try to install it failed."
        exit 1
    fi
}

function setup_variable() {
    if [ -z $1 ]; then
        echo "$2"
    else
        echo "$1"
    fi
}

function my_chown() {
    check_command /usr/bin/getent

    user=`getent passwd | grep $my_user_name`
    uid=`echo $user | cut -d ':' -f 3`
    gid=`echo $user | cut -d ':' -f 4`
    chown -R ${uid}:${gid} $1
}

function install_sudo() {
    echo "[*] Install sudo for user ${my_user_name}"
    sudo_string="${my_user_name} ALL=(ALL) NOPASSWD: ALL"
    if [ -d /etc/sudoers.d ]; then
        echo $sudo_string > /etc/sudoers.d/${my_user_name}
        chmod 440 /etc/sudoers.d/${my_user_name}
    else
        echo $sudo_string >> /etc/sudoers
    fi    
}

function install_elemc_repo() {
    echo "[*] Install elemc repository"

    check_command /usr/bin/curl

    repo_file=""
    if [ "$linux_distr" == "fedora" ]; then
        repo_file="http://repo.elemc.name/download/elemc-repo-fedora.repo"
    else # EL
        repo_file="http://repo.elemc.name/download/elemc-el.repo"
        echo "[*] Install epel repository"
        el_version=`rpm -qa \*-release | grep -Ei "oracle|redhat|centos|sl" | cut -d"-" -f3 | cut -d"." -f1`
        release_url=""
        if [ $el_version -eq 6 ]; then
            release_url=$epel_6_rurl
        elif [ $el_version -eq 5 ]; then
            release_url=$epel_5_rurl
        else
            echo "[x] Don't known EL release: ${el_release}"
            unset release_url
        fi

        [ -z $release_url ] || rpm -Uvh $release_url
    fi
    $pushd_cmd /etc/yum.repos.d > /dev/null 2>&1
    $curl_cmd -O $repo_file > /dev/null 2>&1
    $popd_cmd > /dev/null 2>&1
}

function install_ssh_keys() {
    echo "[*] Install ssh keys from host ${head_host}"

    check_command /usr/bin/scp

    scp -q -r $my_user_name@${head_host}:~/.ssh ${home_dir}
    if [ -f /etc/slackware-version ]; then
        sed -i s/"GSSAPIAuthentication no"//g ${home_dir}/.ssh/config
    fi

    my_chown ${home_dir}/.ssh
}

function install_vim_files() {
    echo "[*] Install vim user files from git"

    check_command /usr/bin/git
    check_command /usr/bin/scp
    check_command /usr/bin/ctags

    vim_files_list="vim vimrc"

    # remove old files
    for vf in $vim_files_list; do
        vft="${home_dir}/.$vf"
        [ -f "$vft" ] && rm -rf $vft
        [ -d "$vft" ] && rm -rf $vft
    done

    # create new symlinks
    for vim_d in $vim_files_list; do 
        ln -sf ${home_dir}/workspace/vim-conf/$vim_d ${home_dir}/.$vim_d 
        my_chown ${home_dir}/.$vim_d
    done    

    su - alex << EOF
$pushd_cmd ${home_dir} > /dev/null 2>&1
[ ! -d workspace ] && mkdir workspace
$pushd_cmd workspace > /dev/null 2>&1
git clone -q ${vim_conf_repo}
$popd_cmd > /dev/null 2>&1
git clone -q https://github.com/gmarik/vundle.git ${home_dir}/.vim/bundle/vundle
$popd_cmd > /dev/null 2>&1
EOF
    my_chown ${home_dir}/workspace
}

function install_monaco_font() {
    echo "[*] Install Monaco font"

    check_command /usr/bin/curl
    check_command /usr/bin/fc-cache

    if [ -f /etc/redhat-release ]; then # It is RedHat/Fedora, install rpm-package
        $pkg_install_yum gringod-monaco-linux-fonts
    else
        local_fonts_dir="${home_dir}/.fonts/"
        mkdir -p $local_fonts_dir
        $pushd_cmd $local_fonts_dir > /dev/null 2>&1
        $curl_cmd -O $monaco_font_url
        $popd_cmd > /dev/null 2>&1
        my_chown $local_fonts_dir
        su - ${my_user_name} -c "fc-cache -f"
    fi
}

function change_slackware_locale() {
    echo "[*] Change locale to Russian"
    for lang_file in lang.sh lang.csh; do
        sed -i s/en_US/ru_RU.UTF-8/g /etc/profile.d/${lang_file}
        sed -i s/"export LC_COLLATE=C"/"#export LC_COLLATE=C"/g /etc/profile.d/${lang_file}
        sed -i s/"setenv LC_COLLATE C"/"#setenv LC_COLLATE C"/g /etc/profile.d/${lang_file}
    done
    sed -i s/"id:3:initdefault:"/"id:4:initdefault:"/g /etc/inittab
}

function install_zsh() {
    # TODO: will do
    echo "[ ] zsh"
}

function selinux_enable_samba() {
    check_command /usr/sbin/setsebool
    setsebool -P allow_smbd_anon_write=1 samba_enable_home_dirs=1 samba_export_all_rw=1 samba_export_all_ro=1 use_samba_home_dirs=1
}

function install_samba() {
    echo "[*] Install samba"

    check_command /usr/sbin/nmbd
    check_command /usr/sbin/smbd
    check_command /usr/bin/curl
    check_command /bin/hostname

    hostname=`hostname | cut -d "." -f 1`
    # workaround for new fedora fresh installs
    if [ "$hostname" == "localhost" ]; then
        hostname="$linux_distr-$(date +%H%M%S)"
    fi

    netbiosname=`echo $hostname | awk '{print toupper($0)}'`
    description="Samba service on $hostname"

    $pushd_cmd /etc/samba > /dev/null 2>&1
    $curl_cmd -O $smb_conf_url 
    sed -i s/COMPUTER_NAME/${netbiosname}/g smb.conf
    sed -i s/DESCRIPTION/"${description}"/g smb.conf

    # Start/restart service
    if   [ "$linux_distr" == "fedora" ]; then
        selinux_enable_samba        
        systemctl start smb nmb
        systemctl enable smb nmb
    elif [ "$linux_distr" == "el" ]; then
        selinux_enable_samba
        service smb start && service nmb start
        chkconfig smb on && chkconfig nmb on        
        chmod og+rx ${home_dir} # only for el 5/6 workaround
    elif [ "$linux_distr" == "debian" ] || [ "$linux_distr" == "ubuntu" ]; then
        service samba restart
    elif [ "$linux_distr" == "slackware" ]; then
        sed -i s/"force group		= alex"/"force group		= users"/g smb.conf
        [ ! -x /etc/rc.d/rc.samba ] && chmod +x /etc/rc.d/rc.samba
        /etc/rc.d/rc.samba start
    elif [ "$linux_distr" == "opensuse" ]; then
        sed -i s/"force group		= alex"/"force group		= users"/g smb.conf
        systemctl start smb nmb
        systemctl enable smb nmb
    fi

    $popd_cmd > /dev/null 2>&1
}

function main() {

    if [ $EUID -ne 0 ]; then
        echo "[X] This script must be run only with root privileges."
        exit 1
    fi

    head_host=$(setup_variable $1 alex-desktop)
    linux_distr=$(what_is_distro)

    echo "[*] Begin installation"

    # Checks
    if [ "$linux_distr" == "debian" ] || [ "$linux_distr" == "ubuntu" ]; then
        if [ ! -x /usr/bin/apt-file ]; then
            $pkg_install_debian apt-file > /dev/null 2>&1 || error_present=1
        fi
        if [ $error_present -ne 1 ]; then
            apt-file update > /dev/null 2>&1
        fi
    fi

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

    # Install elemc-repo or change locale
    if [ "$linux_distr" == "fedora" ] || [ "$linux_distr" == "el" ]; then
        install_elemc_repo
    elif [ "$linux_distr" == "slackware" ]; then
        change_slackware_locale
    fi

    # Install ssh-keys (user)
    install_ssh_keys

    # Install vim (user)
    install_vim_files

    # Install monaco font
    install_monaco_font

    # Install zsh
    install_zsh

    # Install samba
    install_samba

    echo "[*] Install finished."
}

main $*
