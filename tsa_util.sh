#!/bin/sh
# https://www.freetsa.org

CACERT_FILE=cacert.pem
TSACRT_FILE=tsa.crt
SERVER_URL=https://freetsa.org/tsr

print_debug()
{
	echo $1
}

print_error()
{
	echo $1
}

make_stamp()
{
	in_file="$1"
	out_query=$in_file.tsq
	out_stamp=$in_file.tsr

	print_debug "Creating query file $out_query and requesting timestamp from server"
	openssl ts -query -data $in_file -no_nonce -sha512 -out $out_query
	curl -H "Content-Type: application/timestamp-query" --data-binary "@$out_query" $SERVER_URL > $out_stamp
	print_debug "Done. Time stamp is in file $out_stamp"
}

verify_stamp()
{
	in_file="$1"
	query_file=$in_file.tsq
	stamp_file=$in_file.tsr

	is_query=$(basename $in_file .tsq)
	is_stamp=$(basename $in_file .tsr)

	if [ "$is_stamp" != "$in_file" ] || [ "$is_query" != "$in_file" ];then
		print_error "Warning! File should be source file. Not tsq or tsr file !"
	fi

	if [ ! -f $query_file ] || [ ! -f $stamp_file ]; then
		print_error "Error file $query_file or $stamp_file does not exists."
		exit 1
	fi

	print_debug "Verifing files $query_file and $stamp_file"
	openssl ts -verify -in "$stamp_file" -queryfile "$query_file" -CAfile $CACERT_FILE -untrusted $TSACRT_FILE
}

search_log()
{
	#doesn't work !!! experimental
	in_file=$1
	file_hash=$(sha512sum $in_file|awk '{print $1}')
	echo $file_hash
	curl -s https://freetsa.org/logs.gz | gunzip -c | grep -i $file_hash
}

show_info()
{

	in_stamp="$1"
	openssl ts -reply -in $in_stamp -text
}

print_help()
{
	echo "Help"
	echo "-------------------"
	echo "-s|--stamp  <file> # make timestamp of file"
	echo "-v|--verify <file> # verify file timestamp"
	echo "-i|--info   <file> # info about file timestamp"
	echo "-h|--help"
}

while [[ $# -gt 0 ]]
do
key="$1"
case "$key" in
-s|--stamp)
	make_stamp $2
	shift
	shift
;;
-v|--verify)
	verify_stamp $2
	shift
	shift
;;
-i|--info)
	show_info $2
	shift
	shift
;;
#--search-log)
#	search_log $2
#;;
--help|*)
	print_help
	shift
;;
esac

done
