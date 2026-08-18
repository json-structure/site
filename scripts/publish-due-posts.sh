#!/usr/bin/env bash

set -euo pipefail

posts_dir="${1:-_posts}"
today="${PUBLISH_DATE:-$(date +%F)}"

if [[ ! "$today" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "Invalid publication date: $today" >&2
  exit 1
fi

published=0

while IFS= read -r -d '' post; do
  filename="${post##*/}"
  filename_date="${filename:0:10}"
  front_matter_date="$(sed -n '1,/^---[[:space:]]*$/s/^date:[[:space:]]*//p' "$post" | head -n 1 | tr -d '\r')"

  if [[ ! "$filename_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    continue
  fi

  if [[ "$front_matter_date" != "$filename_date" ]]; then
    echo "Date mismatch in $post: filename=$filename_date front-matter=$front_matter_date" >&2
    exit 1
  fi

  if [[ "$front_matter_date" > "$today" ]]; then
    continue
  fi

  if ! sed -n '1,/^---[[:space:]]*$/p' "$post" | grep -q '^published:[[:space:]]*false[[:space:]]*$'; then
    continue
  fi

  awk '
    BEGIN { in_front_matter = 0; front_matter_ended = 0 }
    NR == 1 && /^---[[:space:]]*$/ { in_front_matter = 1 }
    in_front_matter && !front_matter_ended && /^published:[[:space:]]*false[[:space:]]*$/ {
      sub(/false[[:space:]]*$/, "true")
    }
    in_front_matter && NR > 1 && /^---[[:space:]]*$/ {
      front_matter_ended = 1
    }
    { print }
  ' "$post" > "$post.tmp"
  mv "$post.tmp" "$post"

  echo "Published $post"
  published=$((published + 1))
done < <(find "$posts_dir" -maxdepth 1 -type f -name '*.md' -print0 | sort -z)

echo "Published $published post(s) for $today."