#!/usr/bin/env bash

# wget "https://github.com/sharkdp/pastel/releases/download/v0.8.0/pastel_0.8.0_amd64.deb"
# sudo dpkg -i pastel_0.8.0_amd64.deb

SIMPLE_ICONS_URL='https://raw.githubusercontent.com/simple-icons/simple-icons/develop/_data/simple-icons.json'

function getIcons() {
  curl "$SIMPLE_ICONS_URL" | jq -rc '.icons[]'
}

function processIcon() {
  local COLOR_BG;
  local COLOR_BG_BRIGHTNESS;
  local COLOR_PICKED;

  COLOR_BG="$(echo "$@" | jq -rc '.hex')"
  COLOR_BG_BRIGHTNESS="$(pastel -f format brightness "$COLOR_BG" | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g")"

  if [ "$(bc <<< "$COLOR_BG_BRIGHTNESS >= 0.6")" = "1" ]; then
    COLOR_PICKED='000000'
  else
    COLOR_PICKED='FFFFFF'
  fi

  echo "$@" | jq -rc "{ schemaVersion: 1, style: \"flat-square\", label: \"\", message: .title, color: .hex, namedLogo: .title, logoColor: \"$COLOR_PICKED\" }"
}

function saveIconJson() {
  echo "$@" > "./badges/json/$(echo "$@" | jq -r '.message' | sed -e 's/\(.*\)/\L\1/' | sed -e 's/\s/-/g').json"
}

function appendToReadme() {
  local FILENAME
  local TITLE
  local MARKDOWN_JSON
  local MARKDOWN_IMG
  local MARKDOWN

  FILENAME="$(echo "$@" | jq -r '.message' | sed -e 's/\(.*\)/\L\1/' | sed -e 's/\s/-/g').json"
  TITLE="$(echo "$@" | jq -r '.message')"
  MARKDOWN_JSON="https://raw.githubusercontent.com/d3riva/d3riva/master/badges/json/$FILENAME"
  MARKDOWN_IMG="https://img.shields.io/endpoint?url=$MARKDOWN_JSON"
  MARKDOWN="![$TITLE]($MARKDOWN_IMG)"

  cat <<EOF >> ./badges/README.md
$MARKDOWN
\`\`\`markdown
$MARKDOWN
\`\`\`
\`\`\`markdown
$MARKDOWN_IMG
\`\`\`
\`\`\`markdown
$MARKDOWN_JSON
\`\`\`
EOF
}

function processIcons() {
  local DATA
  getIcons | while IFS=$'\n' read -r icon; do
    DATA="$(processIcon "$icon")"
    saveIconJson "$DATA"
    appendToReadme "$DATA"
  done
}

mkdir -p ./badges/json
touch ./badges/README.md
cat /dev/null > ./badges/README.md

processIcons
