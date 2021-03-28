#!/bin/bash
set -x
set -e
# Set envs
token=$(echo $GITHUB_TOKEN)
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

# fetch all tags
git fetch --all --tags

mkdir ${build_dir}
# searching for new releases
#
for i in */
do
  for v in `find $i -name "*.version.json"`
  do
    for r in `git tag`
    do
      tversion=$(cat $v | jq .version | sed -e 's/\"//g')
      version=$(echo ${i%/}-${tversion})
      if [[ "$r" != "$version" ]]
      then
        new_release+=("$i-$v")
        #PACKER_LOG=1 packer build -var-file $v ${i}${i%/}.json
        gzip ./tmp/${version}.qcow2
        mv ./tmp/${version}.qcow2.gz ${build_dir}
        rm ./tmp -rf
        text="new version for ${i%/} in version ${tversion}"
        release_id=$(curl --data "$(post_data)" "https://api.github.com/repos/$repo_full_name/releases?access_token=$token" | jq .id)
        curl --data-binary @${build_dir}/${version}.qcow2.gz -H  "Content-Type: application/octet-stream" "https://uploads.github.com/repos/$repo_full_name/releases/$release_id/assets?name=${version}.qcow2.gz&access_token=$token"
      else
        echo "$i-$v exists..."
      fi
    done
  done
done
echo "done."


