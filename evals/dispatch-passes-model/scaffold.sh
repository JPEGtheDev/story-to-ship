set -eu
mkdir -p api web docs scripts
for d in api web docs scripts; do
  printf 'x\n' > "$d/README.txt"
done
