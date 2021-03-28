#!/bin/bash

# Set envs
token=$(git config --global github.token)
branch=$(git rev-parse --abbrev-ref HEAD)
repo_full_name=$(git config --get remote.origin.url | sed 's/.*:\/\/github.com\///;s/.git$//')
build_dir="./build"
declare -a new_release

post_data()
{
  cat <<EOF
{
  "tag_name": "$version",
  "target_commitish": "$branch",
  "name": "$version",
  "body": "$text",
  "draft": false,
  "prerelease": false
}
EOF
}

# Install deps
set -e
sudo apt update
sudo apt install qemu qmu-system -y

# searching for new releases
#
for i in */
do
  for v in `find $i -name "*.version.json"`
  do
    for r in `git tag`
    do
      if [ "$r" -ne "$i-$v" ]
      then
        new_release+=("$i-$v")
        PACKER_LOG=1 packer build -var-file $v ${i}${i%/}.json
        version="$i-$v"
        text="new version for $i in version $v"
        release_id=$(curl --data "$(post_data)"
        "https://api.github.com/repos/$repo_full_name/releases?access_token=$token"
      | jq uploader.id )
        curl --data-binary @./build/$i-$v.qcow2.gz -H  "Content-Type:
        application/octet-stream"
        "https://uploads.github.com/repos/$repo_full_name/releases/$release_id/assets?name=$i-$v.qcow2.gz&access_token=$token"
      else
        echo "$i-$v exists..."
      fi
    done
  done
done
echo "done."


