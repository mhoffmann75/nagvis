 #!/bin/sh
 
#################################################################################
#       Nagvis Web Configurator 						#
#	GPL License								#
#										#
#										#
#	Web interface to configure Nagvis maps.					#
#										#
#	Drag & drop, Tooltip and shapes javascript code taken from 		#
#	http://www.walterzorn.com   						#
#										#
#################################################################################
 
# change these paths to suit your system
awk_bin="/bin/awk"
sed_bin="/bin/sed"
echo_bin="/bin/echo"
mv_bin="/bin/mv"
cat_bin="/bin/cat"
grep_bin="/bin/grep"
rm_bin="/bin/rm"


modified_properties_list=""

###########################
# modify_object_property host_name=toto^x=3^y=20 x 24
function modify_object_property()
{	
	modified_properties_list=""
	length=${#2}
	nbprop=$($echo_bin "$1" | $awk_bin -F^ '{print NF}')
	j=1
	while [ $j -le $nbprop ]
	do
		value=$($echo_bin "$1" | $awk_bin -F^ -v val="$j" '{print $val}')
		if [ "${value:0:$length+1}" == "$2=" ];then
			modified_properties_list="$modified_properties_list^$2=$3"
		else
			modified_properties_list="$modified_properties_list^$value"
		fi
		j=$[j+1]
	done
	modified_properties_list=${modified_properties_list:1:${#modified_properties_list}}
	return
}


###########################
 function modify_map()
 {
 
 	if [ "$3" == "" ];then
		return
	fi
	
	# we split the lists and store them into arrays
	declare -a lines
	lines=($($echo_bin "$2" | $awk_bin '{gsub(/,/," "); print $0}'))
		
	nb=${#lines[*]}
	max=$($cat_bin "$1" | $grep_bin -c "^define" )
	
	declare -a valx
	valx=($($echo_bin "$3" | $awk_bin '{gsub(/,/," "); print $0}'))
	
	declare -a valy
	valy=($($echo_bin "$4" | $awk_bin '{gsub(/,/," "); print $0}'))
	
	# for each element, we compute the original line, that we replace by the new computed line
	i=0
	while [ $i -lt $max ]
	do

		# we retrieve the object definition
		definition=$($cat_bin "$1" | $awk_bin -v val="$[i+1]" 'BEGIN {i=0} $1 == "define" {i=i+1; if (i == val) print}')
		
		# we retrieve the object properties
		properties=$($cat_bin "$1" | $awk_bin -v val="$[i+1]" 'BEGIN {i=0} \
							{if ($1 == "define") {i=i+1; if(i == val) {ok=1} else {ok=0};next}; \
							 if (index($0,"}") == 1) {ok=0}; \
							if (ok == 1) { ORS="^";print $0 }}')
		# we suppress the last ^
		if [ ${#properties} -gt 0 ]; then
			properties=${properties:0:${#properties}-1}
		fi	
		
		# if we are examining an object we're supposed to modify (his coordinates)
		cpt=0
		while [ $cpt -lt $nb ] && [ $i -ne ${lines[$cpt]} ]
		do
			cpt=$[cpt+1]
		done
		
		if [ $cpt -ne $nb ];then
			# we have to modify the x and y values
			modify_object_property "$properties" "x" "${valx[$cpt]}"
			properties="$modified_properties_list"
			modify_object_property "$properties" "y" "${valy[$cpt]}"
			properties="$modified_properties_list"
		fi
		
		# we write the object back to the file
		nbproperties=$($echo_bin "$properties" | $awk_bin -F^ '{print NF}')
		$echo_bin "$definition" >> "$1.tmp"
		cpt=1
		while [ $cpt -le $nbproperties ]
		do
			prop=$($echo_bin "$properties" | $awk_bin -F^ -v val="$cpt" '{print $val}')
			$echo_bin "$prop" >> "$1.tmp"
			cpt=$[cpt+1]
		done		
		$echo_bin "}" >> "$1.tmp"
		$echo_bin "" >> "$1.tmp"
		
		i=$[i+1]
	done	
		
	# we replace the old file with the new one
	$mv_bin "$1.tmp" "$1"
		
		 
 }
 

########################### 
 function modify_element()
 {
 	# we write the objects which do not change, and which are before the target object
 	$cat_bin "$1" | $awk_bin -v val="$2" 'BEGIN {i=0} $1 == "define" {i=i+1;} { if (i <= val) print}' > "$1.tmp"
	
	# we write the object
	nbproperties=$($echo_bin "$4" | $awk_bin -F^ '{print NF}')
	$echo_bin "define $3 {" >> "$1.tmp"
	cpt=1
	while [ $cpt -le $nbproperties ]
	do
		$echo_bin "$4" | $awk_bin -F^ -v val="$cpt" '{print $val}' >> "$1.tmp"
		cpt=$[cpt+1]
	done		
	$echo_bin "}" >> "$1.tmp"
	$echo_bin "" >> "$1.tmp"
	
	# we write the objects which do not change, and which are after the target object
 	$cat_bin "$1" | $awk_bin -v val="$2" 'BEGIN {i=0} $1 == "define" {i=i+1;} { if (i > val+1) print}' >> "$1.tmp"
	
	# we replace the old file with the new one
	$mv_bin "$1.tmp" "$1"
 }
 
 
 ########################### 
 function add_element()
 {
	
	# we write the object
	nbproperties=$($echo_bin "$3" | $awk_bin -F^ '{print NF}')
	$echo_bin "define $2 {" >> $1
	cpt=1
	while [ $cpt -le $nbproperties ]
	do
		$echo_bin "$3" | $awk_bin -F^ -v val="$cpt" '{print $val}' >> "$1"
		cpt=$[cpt+1]
	done		
	$echo_bin "}" >> "$1"
	$echo_bin "" >> "$1"
	
 }
 
 
 ########################### 
 function delete_element()
 {
 	# we write the objects which do not change, and which are before the target object
 	$cat_bin "$1" | $awk_bin -v val="$2" 'BEGIN {i=0} $1 == "define" {i=i+1;} { if (i <= val) print}' > "$1.tmp"
		
	# we write the objects which do not change, and which are after the target object
 	$cat_bin "$1" | $awk_bin -v val="$2" 'BEGIN {i=0} $1 == "define" {i=i+1;} { if (i > val+1) print}' >> "$1.tmp"
	
	# we replace the old file with the new one
	$mv_bin "$1.tmp" "$1"
 }
 

###########################
# MAIN SCRIPT
###########################
 if [ "$1" == "modify" ];then
 
 	modify_map "$2" "$3" "$4" "$5"

 elif [ "$1" == "add_element" ];then
 	add_element "$2" "$3" "$4"

elif [ "$1" == "modify_element" ];then
 	modify_element "$2" "$3" "$4" "$5"

elif [ "$1" == "delete_element" ];then
 	delete_element "$2" "$3"
	
elif [ "$1" == "update_config" ];then
	$echo_bin -n "$3" > "$2"
	
elif [ "$1" == "mgt_map_create" ];then
	$echo_bin "define global {" > "$2"
	$echo_bin "allowed_user=$3" >> "$2"
	$echo_bin "iconset=$4" >> "$2"
	$echo_bin "map_image=$5" >> "$2"
	$echo_bin "allowed_for_config=$6" >> "$2"
	$echo_bin "}" >> "$2"
	$echo_bin "" >> "$2"

elif [ "$1" == "mgt_map_rename" ];then
	$mv_bin "$2" "$3"

elif [ "$1" == "mgt_map_delete" ];then
	$rm_bin "$2"	

elif [ "$1" == "mgt_image_delete" ];then
	$rm_bin "$2"	
	
fi

