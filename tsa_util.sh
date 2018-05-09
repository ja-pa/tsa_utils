#!/bin/sh
#https://www.freetsa.org

CACERT_FILE=cacert.pem
TSACRT_FILE=tsa.crt

make_stamp()
{
	in_file="$1"
	out_query=$in_file.tsq
	out_stamp=$in_file.tsr
	openssl ts -query -data $in_file -no_nonce -sha512 -out $out_query
	curl -H "Content-Type: application/timestamp-query" --data-binary "@$out_query" https://freetsa.org/tsr > $out_stamp
}

verify_stamp()
{
	in_file="$1"
	query_file=$in_file.tsq
	stamp_file=$inf_file.tsr
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
	echo "--stamp  <file> # make timestamp of file"
	echo "--verify <file> # verify file timestamp"
	echo "--info   <file> # info about file timestamp"
	echo "--help"
}


case "$1" in
--stamp)
	make_stamp $2
;;
--verify)
	verify_stamp $2
;;

--info)
	show_info $2
;;
#--search-log)
#	search_log $2
#;;
--help|*)
	print_help
;;
esac

