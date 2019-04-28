#!/bin/bash

declare -a title_array
inlist=-1
count_repeats=2

print_help () {
	printf -- "usage: \t$(basename $0) [-n \e[4mN\e[0m] [-q] [-o \e[4mFILE\e[0m] [-s \e[4mN\e[0m] [-t \e[4mN\e[0m] [-g]\n"
	printf -- "\t-n \e[4mN		\e[0mRepeat script \e[4mN\e[0m times\n"
	printf -- "\t-q		Quiet; no terminal output\n"
	printf -- "\t-o \e[4mFILE		\e[0mOutput to \e[4mFILE\e[0m\n"
	printf -- "\t-s \e[4mN		\e[0mSleep for \e[4mN\e[0m seconds after each repeat\n"
	printf -- "\t-t \e[4mN		\e[0mTruncate output to \e[4mN\e[0m fields\n"
	printf -- "\t-g		Make a graph from output\n"
}

#download and strip data from html
loop () {
	title_array=("${title_array[@]}" "$(echo "$current_page" | tr -d '\n' | egrep -o '<title.*</title>' | sed 's/<title>//' | sed 's/<\/title>//' | sed 's/ - .*$//')")
	next_entry=$(echo "$current_page" | tr -d '\n' | sed 's/\(<table class="\)/\n\1/g' | sed 's/\(<\/table>\)/\1\n/g' | sed 's/<table class=.*//' | sed 's/\(<span\)/\n\1/g' | sed 's/\(<\/span>\)/\1\n/g' | sed 's/<span.*//' | sed 's/\(<sup\)/\n\1/g' | sed 's/\(<\/sup>\)/\1\n/g' | sed 's/<sup.*//' | tr -d '\n' | egrep -o -m 1 '<p>.*</p>' | sed 's/([^()]*)[^"]//g' | sed 's/([^()]*)[^"]//g' | sed 's/<[^>]*disambig[^>]*>//g' | egrep -o '<a href="/wiki/[^>]*>[^>]*</a>' | head -n 1 | sed 's/^<a href="\/wiki\///' | sed 's/" .*$//')
	current_page=$(wget -q -O - http://en.wikipedia.org/wiki/$next_entry)
	repeat
	if [ "$qvalue" = "0" ] && [ "$count_repeats" = 2 ]; then
		print_next_item
	fi
	count_repeats=2
}

#print title of last page downloaded from Wikipedia
print_next_item () {
	#if philosophy or Wikipedia's main page are the last pages don't print arrow
	if [ "${title_array[-1]}" = "Philosophy" ]; then
		printf "\e[31m${title_array[-1]}\e[0m"
		printf ' --> '
	elif [ "${title_array[-1]}" = "Wikipedia, the free encyclopedia" ]; then
		printf "${title_array[-1]}"
	elif [ ${#title_array[@]} = 1 ]; then
		printf "\e[38;5;46m${title_array[-1]}\e[0m --> "
	else
		printf "${title_array[-1]}"
		printf ' --> '
	fi
}

#check if current page is in title_array, indicating a loop
isinlist () {
	inlist=-1
	for item in "${title_array[@]:0:${#title_array[@]}-1}"; do
		if [ "${title_array[-1]}" = "$item" ]; then
			inlist=1
			break
		elif [ "${title_array[-1]}" = "Wikipedia, the free encyclopedia" ]; then
			inlist=-2
			break
		fi
	done
}

#detect repeats, Wikipedia main page and starts over if found (main page typically occurs when script gets a disambiguation page)
repeat () {
	isinlist
	if [ $inlist -gt -1 ]; then
		if [ "$qvalue" = "0" ]; then
			printf "\e[33mRepeat detected; using next link in page\e[0m --> "
		fi
		next_entry=$(echo "$current_page" | tr -d '\n' | sed 's/\(<table class="\)/\n\1/g' | sed 's/\(<\/table>\)/\1\n/g' | sed 's/<table class=.*//' | sed 's/\(<span\)/\n\1/g' | sed 's/\(<\/span>\)/\1\n/g' | sed 's/<span.*//' | sed 's/\(<sup\)/\n\1/g' | sed 's/\(<\/sup>\)/\1\n/g' | sed 's/<sup.*//' | tr -d '\n' | egrep -o -m 1 '<p>.*</p>' | sed 's/([^()]*)[^"]//g' | sed 's/([^()]*)[^"]//g' | sed 's/<[^>]*disambig[^>]*>//g' | egrep -o '<a href="/wiki/[^>]*>[^>]*</a>' | head -n $count_repeats | tail -n 1 | sed 's/^<a href="\/wiki\///' | sed 's/" .*$//')
		current_page=$(wget -q -O - http://en.wikipedia.org/wiki/$next_entry)
		count_repeats=$((count_repeats+1))
		title_array=("${title_array[@]:0:${#title_array[@]}-1}")
		repeat
		loop
	elif [ $inlist = -2 ]; then
		if [ "$qvalue" = "0" ]; then
			printf "\e[31mSomething went horribly wrong and you're on Wikipedia's main page! Randomizing new start...\033[0m\n"
		fi
		title_array=()
		next_entry=()
		current_page=$(wget -q -O - http://en.wikipedia.org/wiki/Special:Random)
		count_repeats=3
		loop
	fi
}

#parse command line options
nvalue=1
qvalue=0
svalue=0
tvalue=0
gvalue=0
delete=1
while getopts 'n:qo:s:t:gh' option; do
	case "$option" in
		n)	nvalue=$OPTARG;;
		q)	qvalue=1;;
		o)	ovalue=$OPTARG
			delete=0;;
		s)	svalue=$OPTARG;;
		t)	tvalue=$OPTARG;;
		g)	gvalue=1;;
		h)	print_help
			exit 0;;
		?)	print_help
			exit 1;;
		*)	print_help
			exit 1;;
	esac
done

#check to see if output exists; if yes: make new output
checkoutput () {
	declare -i count=1

	if [ ! $ovalue  ]; then
		ovalue="output.csv"
	fi

	filename=$(echo $ovalue | cut -f 1 -d '.')
	filetype=$(echo $ovalue | cut -f 2 -d '.')

	while [ -e $filename$count.$filetype ]; do
			count=$count+1
	done

	if [ $ovalue ] && [ -e $ovalue ]; then	
		ovalue="$filename$count.$filetype"
	fi
}

#main loop
checkoutput
for (( i=1; i<=$nvalue; i++ )); do
	current_page=$(wget -q -O - http://en.wikipedia.org/wiki/Special:Random)
	loop
	while [ "${title_array[-1]}" != 'Philosophy' ]; do
		loop
	done
	if [ "$qvalue" = "0" ]; then
		printf "${#title_array[@]} pages visited\n"
	fi
	if [ "$ovalue" ]; then
		printf "${#title_array[@]}" >> $ovalue
		printf ",%s" "${title_array[@]}" >> $ovalue
		echo >> $ovalue
	fi

	title_array=()
	
	#stop looping if at final loop
	if [ "$i" = "$nvalue" ]; then
		totalpages=$(cat "$ovalue" | cut -d ',' -f 2- | egrep -o ',[^ ]' | wc -l)
		average=$(printf %.2f $(echo "($totalpages+$nvalue)/$nvalue" | bc -l))
		min=$(cat "$ovalue" | sort -n -k 1 | head -n 1 | cut -d ',' -f 1)
		minpath=$(cat "$ovalue" | sort -n -k 1 | head -n 1 | cut -d ',' -f 2- | sed -r 's/,([^ ])/, \1/g')
		max=$(cat "$ovalue" | sort -n -k 1 | tail -n 1 | cut -d ',' -f 1)
		maxpath=$(cat "$ovalue" | sort -n -k 1 | tail -n 1 | cut -d ',' -f 2- | sed -r 's/,([^ ])/, \1/g')
		#truncate page lists if truncate option set
		if [ "$tvalue" != "0" ]; then
			cut_numbers=$(cat $ovalue | cut -f 1 -d ',')
			cut_trunc=$(cat $ovalue | rev | cut -f "1-$tvalue" -d ',' | rev)
			$(paste -d ',' <(echo "$cut_numbers") <(echo "$cut_trunc") > "trunc_$ovalue")
			mv trunc_$ovalue $ovalue
		fi
		#call python graphing script if -g option present
		if [ "$gvalue" = "1" ]; then
			if [ $(command -v dot) ]; then
				python3 csvtodot.py $ovalue
			else
				echo 'Graphviz not found, try: "sudo apt install graphviz" or fix environment variable to dot.'
			fi
		fi	
	fi
	sleep $svalue
done

if [ "$qvalue" = "0" ] && [ "$nvalue" \> "1" ]; then
	printf "\n\e[4mAverage number of pages\e[0m: $average\n"

	printf "\e[4mMinimum number of pages\e[0m: $min\n"
	printf "$minpath\n\n"

	printf "\e[4mMaximum number of pages\e[0m: $max\n"
	printf "$maxpath\n"
fi

if [ "$delete" = "1" ]; then
	rm $ovalue
	if [ -e ${ovalue%.*} ]; then
		rm ${ovalue%.*}
	fi
fi
