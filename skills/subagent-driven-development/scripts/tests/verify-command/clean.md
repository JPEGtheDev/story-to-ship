printf "%s\n" PASS > "$EVID"
echo done 2>&1
grep -cE "(three|[0-9]+) files" out.txt | wc -l
grep "[0-9]" out.txt
echo x >&2
echo x 2>err.log
echo x 2>>err.log
sed -n "/[0-9]/p" f | wc -l
