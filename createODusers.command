#!/bin/bash
echo "Welcome to the SBEP Schools Open Directory Account Wizard!"
echo "This wizard will walk you through the process of importing a CSV file"
echo "into this program and creating Open Directory accounts based on that "
echo "info!  You need the following information in your CSV file:"
echo "First Name"
echo "Last Name"
echo "Student ID"
echo "Birth Date"
echo "Homeroom"
echo "Status"
echo "Grade"
echo "Building Code"
echo ""
read -p "Are you ready to continue? Press y for yes or n for no then press [ENTER]:" areyouready
if [[ $areyouready == "n" ]]; then
    exit 0
elif [[ $areyouready == "y" ]]; then
    echo "What is the LDAP node name (i.e. /LDAPv3/<servername/address>)"
    read ServerName
    read -s -p "Enter the diradmin password to continue (This password will not be saved):" diradminpwd
    echo ""
    logintest=$(dscl /LDAPv3/$ServerName -auth diradmin $diradminpwd)
    if [[ -n $logintest ]]; then
        echo "Login failed! Please use the diradmin password and try again."
        exit 1
    else
        echo "Login succeeded! Continuing..."
        echo "Insert path to CSV file:"
        read CSVfile
        echo "Reading Students from this file: $CSVfile"
        echo "What year did this school year start in? (ex. 2013)"
        read schoolyear
        echo "Okay, the school year started in $schoolyear."
        read -p "Please enter your e-mail address for the report of created users:" adminemail
        echo "When we are done, we will send the report to: $adminemail"
        tempfile=$(mktemp -d -t tmp)
        echo "Working in temporary folder $tempfile"
        echo "Student ID,FirstName,LastName,Building,Homeroom," > $tempfile/createdusers$(date +%Y%m%d).csv
    
    OLDIFS="$IFS"
    IFS=','
    while read FirstName LastName SID BirthDate Homeroom Status Grade BuildingCode Space
    do
        PreUserName="$LastName$FirstName"
        UserName=$(echo "$PreUserName" | sed s/[^a-zA-Z\-]/""/g | tr '[A-Z]' '[a-z]')
        pregradyear=$(expr 12 - $Grade)
        gradyear=$(expr $pregradyear + $schoolyear + 1)
        if [ $BuildingCode == $(echo "R165") ]; then
            Building="HS"
            buildinghome="hsHomes"
            homeserver="hsserver"
            homevol="PROMISE_PEGASUS"
            schoolgroup="highschool"
        elif [ $BuildingCode == $(echo "R167") ]; then
            Building="EPE"
            buildinghome="epHomes"
            homeserver="elserver"
            homevol="EL_Server_HD2"
            schoolgroup="epe"
        elif [ $BuildingCode == $(echo "R168") ]; then
            Building="SBE"
            buildinghome="sbHomes"
            homeserver="elserver"
            homevol="EL_Server_HD2"
            schoolgroup="sbe"
        fi
        echo "Validating $UserName for account creation"
        checkusername=$(dscl /LDAPv3/$ServerName -list /Users | grep "$UserName")
        isnumber='^[0-9]+$'
        if ! [[ $Grade =~ $isnumber ]]; then
            echo "The user $UserName was not be created because the user is too young."
        else
            if [[ $checkusername == $UserName ]]; then
                    echo "User $UserName Already Exists..."
                    echo "Updating User Record..."
                    if [[ $BuildingCode == $(echo "R167") ]] || [[ $BuildingCode == $(echo "R168") ]]; then
                                homedir="$buildinghome/$UserName"
                        elif [ $BuildingCode == $(echo "R165") ]; then
                                homedir="$buildinghome/$gradyear/$UserName"
                fi
                dscl -u diradmin -P $diradminpwd /LDAPv3/$ServerName -create /Users/$UserName NFSHomeDirectory "/Network/Servers/$homeserver.sbepschools.org/Volumes/$homevol/$homedir"
                if [[ $BuildingCode == $(echo "R165") ]]; then 
                        dscl -u diradmin -P $diradminpwd /LDAPv3/$ServerName -create /Users/$UserName HomeDirectory "<home_dir><url>afp://$homeserver.sbepschools.org/$buildinghome</url><path>$gradyear/$UserName</path></home_dir>"
                        else
                        dscl -u diradmin -P $diradminpwd /LDAPv3/$ServerName -create /Users/$UserName HomeDirectory "<home_dir><url>afp://$homeserver.sbepschools.org/$buildinghome</url><path>$UserName</path></home_dir>"
                fi
            else
                dscl -u diradmin -P $diradminpwd /LDAPv3/$ServerName -create /Users/$UserName
                dscl -u diradmin -P $diradminpwd /LDAPv3/$ServerName -create /Users/$UserName UserShell /bin/bash
                dscl -u diradmin -P $diradminpwd /LDAPv3/$ServerName -create /Users/$UserName RealName "$LastName, $FirstName"
                dscl -u diradmin -P $diradminpwd /LDAPv3/$ServerName -create /Users/$UserName UniqueID $SID
                dscl -u diradmin -P $diradminpwd /LDAPv3/$ServerName -passwd /Users/$UserName $SID
                dscl -u diradmin -P $diradminpwd /LDAPv3/$ServerName -create /Users/$UserName PrimaryGroupID 20
                dscl -u diradmin -P $diradminpwd /LDAPv3/$ServerName -create /Users/$UserName Keywords $Homeroom $Grade $BuildingCode $Building
                if [[ $BuildingCode == $(echo "R167") ]] || [[ $BuildingCode == $(echo "R168") ]]; then
                                homedir="$buildinghome/$UserName"
                        elif [ $BuildingCode == $(echo "R165") ]; then
                                homedir="$buildinghome/$gradyear/$UserName"
                fi
                dscl -u diradmin -P $diradminpwd /LDAPv3/$ServerName -create /Users/$UserName NFSHomeDirectory "/Network/Servers/$homeserver.sbepschools.org/Volumes/$homevol/$homedir"
                if [[ $BuildingCode == $(echo "R165") ]]; then 
                        dscl -u diradmin -P $diradminpwd /LDAPv3/$ServerName -create /Users/$UserName HomeDirectory "<home_dir><url>afp://$homeserver.sbepschools.org/$buildinghome</url><path>$gradyear/$UserName</path></home_dir>"
                        else
                        dscl -u diradmin -P $diradminpwd /LDAPv3/$ServerName -create /Users/$UserName HomeDirectory "<home_dir><url>afp://$homeserver.sbepschools.org/$buildinghome</url><path>$UserName</path></home_dir>"
                fi
		dseditgroup -o edit -n /LDAPv3/$ServerName -a $UserName -t user $schoolgroup
                pwpolicy -a diradmin -p $diradminpwd -u $UserName -setpolicy "isDisabled=1 canModifyPasswordforSelf=1"
                echo -e "$LastName, $FirstName $Building $Homeroom" >> $tempfile/createdODuser.txt
                echo -e "$SID,$FirstName,$LastName,$Building,$Homeroom," >> $tempfile/createdusers$(date +%Y%m%d).csv
                echo "Created user: $LastName, $FirstName"
            fi
        fi
    done < $CSVfile
    IFS="$OLDIFS"
    uuencode $tempfile/createdusers$(date +%Y%m%d).csv | mail -s "ODMSERVER: Report of created user accounts" $adminemail < $tempfile/createdODuser.txt
    fi
fi
exit
