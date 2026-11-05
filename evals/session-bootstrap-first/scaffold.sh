set -eu
mkdir -p src
printf '# Receipt Tool\n\nThis tool reads receipts and prints a summery of the totals.\n' > README.md
printf 'print("ok")\n' > src/app.py
