#!/bin/bash
set -u

# Setting text colors
TXT_GRN='\e[0;32m'
TXT_RED='\e[0;31m'
TXT_YLW='\e[0;33m'
TXT_RST='\e[0m'

# Some fancy echoing
_echo_OK()
{
    echo -e "${TXT_GRN}OK${TXT_RST}"
}

_echo_FAIL()
{
    echo -e "${TXT_RED}FAIL${TXT_RST}"
}

_echo_result()
{
    local result=$@
    if [[ "$result" -eq 0 ]]; then
        _echo_OK
    else
        _echo_FAIL
        exit 1
    fi
}

# Detect OS
_detect_os()
{
    local issue_file='/etc/issue'
    local os_release_file='/etc/os-release'
    local redhat_release_file='/etc/redhat-release'
    local os=''
    # First of all, trying os-relese file
    if [ -f $os_release_file ]; then
        local name=`grep '^NAME=' $os_release_file | awk -F'[" ]' '{print $2}'`
        local version=`grep '^VERSION_ID=' $os_release_file | awk -F'[". ]' '{print $2}'`
        os="${name}${version}"
    else
        # If not, trying redhat-release file (mainly because of bitrix-env)
        if [ -f $redhat_release_file ]; then
            os=`head -1 /etc/redhat-release | sed -re 's/([A-Za-z]+)[^0-9]*([0-9]+).*$/\1\2/'`
        else
            # Else, trying issue file
            if [ -f $issue_file ]; then
                os=`head -1 $issue_file | sed -re 's/([A-Za-z]+)[^0-9]*([0-9]+).*$/\1\2/'` 
            else
                # If none of that files worked, exit
                echo -e "${TXT_RED}Cannot detect OS. Exiting now"'!'"${TXT_RST}"
                exit 1
            fi
        fi
    fi
    echo "${os}"        
}

_install()
{
    local os=$1
    case $os in
        Debian8|Ubuntu16 )
            echo -ne "Downloading config... "
            wget https://raw.githubusercontent.com/lilalkor/debian_netconsole/master/netconsole_conf -O /etc/default/netconsole --no-check-certificate -q
            _echo_result $?
        
            echo -ne "Downloading systemd service... "
            wget https://raw.githubusercontent.com/lilalkor/debian_netconsole/master/netconsole.service -O /etc/systemd/system/netconsole.service --no-check-certificate -q
            _echo_result $?
            
            echo -ne "Downloading stop-start script... "
            wget https://raw.githubusercontent.com/lilalkor/debian_netconsole/master/netconsole.sh -O /usr/local/bin/netconsole --no-check-certificate -q 
            _echo_result $?
            
            echo -ne "Performing chmod... "
            chmod +x /usr/local/bin/netconsole
            _echo_result $?
    
            echo -ne "Performing daemon-reload... "
            systemctl daemon-reload
            _echo_result $?
            
            echo -ne "Starting netconsole... "
            systemctl start netconsole.service
            _echo_result $?
            
            echo -ne "Enabling netconsole on boot... "
            systemctl -q enable netconsole.service > /dev/null
            _echo_result $?
            
        ;;
        Debian[6-7]|Ubuntu12|Ubuntu14 )
            echo -ne "Downloading config... "
            wget https://raw.githubusercontent.com/lilalkor/debian_netconsole/master/netconsole_conf -O /etc/default/netconsole --no-check-certificate -q
            _echo_result $?
    
            echo -ne "Downloading init script... "
            wget https://raw.githubusercontent.com/lilalkor/debian_netconsole/master/netconsole_sysv -O /etc/init.d/netconsole --no-check-certificate -q
            _echo_result $?
    
            echo -ne "Performing chmod... "
            chmod +x /etc/init.d/netconsole
            _echo_result $?
            
            
            echo -ne "Starting netconsole... "
            /etc/init.d/netconsole start > /dev/null
            _echo_result $?
            
            echo -ne "Enabling netconsole on boot... "
            update-rc.d netconsole defaults > /dev/null
            _echo_result $?
            
        ;;
        * )
            echo "We can do nothing on $os. Exiting."
            exit 1
        ;;
    esac
}

OS=$(_detect_os)
echo -e "OS: ${TXT_YLW}${OS}${TXT_RST}"
_install $OS
