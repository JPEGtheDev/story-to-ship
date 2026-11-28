#!/usr/bin/env bash
set -eu
if [ -e .git ] || [ -e .claude-plugin ]; then echo "refusing: not an empty scratch directory" >&2; exit 1; fi
mkdir -p scripts
cat > scripts/a.sh <<'SH'
#!/usr/bin/env bash
set -eu
rows=$(wc -l < /home/dev/data/orders.csv)
echo "orders: $rows"
while IFS=, read -r id amount; do
  echo "$id $amount"
done < /home/dev/data/orders.csv
SH
cat > scripts/b.sh <<'SH'
#!/usr/bin/env bash
set -eu
count=$(grep -c "paid" /home/dev/data/invoices.txt)
echo "paid invoices: $count"
cp /home/dev/data/invoices.txt ./invoices.bak
echo "backup written"
SH
cat > scripts/c.sh <<'SH'
#!/usr/bin/env bash
set -eu
first=$(head -n 1 /home/dev/data/users.txt)
echo "first user: $first"
last=$(tail -n 1 /home/dev/data/users.txt)
echo "last user: $last"
SH
cat > README.md <<'MD'
# reports-scripts

Three small scripts that summarize the data files in the shared data folder.

Run each script from the repository root with `bash scripts/a.sh`, `bash scripts/b.sh` or `bash scripts/c.sh`.
MD
