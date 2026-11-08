grep -cE "[0-9]+ files" out.txt | wc -l
grep -c "[[:digit:]]" f.txt | wc -l
grep -cE "\d+" f.txt | wc -l
grep -c "[0-9]" f.txt
