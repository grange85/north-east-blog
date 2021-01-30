#!/bin/zsh
set -euo pipefail

echo "Deploying A Head Full of Wishes"

source _cloudfront-distribution-id

# build site
bundle exec jekyll build --config _config.yml,_config_build.yml

mkdir -p _deploy/_admin
touch _deploy/_admin/full-list.html
cat _includes/html-head.html >_deploy/_admin/full-list.html


# list images
echo '<h2 id="images">Images</h2><ul>' >>_deploy/_admin/full-list.html
find ../media/ -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.gif' \)| sed -e 's/^\.\{1,2\}\/media//g' -e 's/.*/<li><a href="https:\/\/media.fullofwishes.co.uk&">&<\/a><\/li>/' | sort >> _deploy/_admin/full-list.html
echo '</ul>' >>_deploy/_admin/full-list.html
echo "Image list created..."

# list audio
echo '<h2 id="audio">Audio</h2><ul>' >>_deploy/_admin/full-list.html
find ../media/ -type f \( -iname '*.mp3' -o -iname '*.m4a' \) | sed -e 's/^\.\{1,2\}\/media//g' -e 's/.*/<li><a href="https:\/\/media.fullofwishes.co.uk&">&<\/a><\/li>/' | sort >> _deploy/_admin/full-list.html
echo '</ul>' >>_deploy/_admin/full-list.html
echo "Audio list created..."

# list video
echo '<h2 id="videa">Video</h2><ul>' >>_deploy/_admin/full-list.html
find ../media/ -type f \( -iname '*.mov' -o -iname '*.mp4' -o -iname '*.flv' \) | sed -e 's/^\.\{1,2\}\/media//g' -e 's/.*/<li><a href="https:\/\/media.fullofwishes.co.uk&">&<\/a><\/li>/' | sort >> _deploy/_admin/full-list.html
echo '</ul>' >>_deploy/_admin/full-list.html
echo "Video list created..."


# list misc
echo '<h2 id="misc">Misc</h2><ul>' >>_deploy/_admin/full-list.html
find ../media/ -type f \( -iname '*.zip' -o -iname '*.pdf' -o -iname '*.doc' \) | sed -e 's/^\.\{1,2\}\/media//g' -e 's/.*/<li><a href="https:\/\/media.fullofwishes.co.uk&">&<\/a><\/li>/' | sort >> _deploy/_admin/full-list.html
echo '</ul>' >>_deploy/_admin/full-list.html
echo "Misc list created..."



cat _includes/html-foot.html >>_deploy/_admin/full-list.html

# upload to s3
s3cmd sync --guess-mime-type --no-mime-magic --delete-removed --exclude '.sass-cache' --exclude 's3cfg*' --exclude 'database/*' _deploy/ s3://www.fullofwishes.co.uk

# copy rss to correct location
aws s3 mv --content-type "text/xml" --metadata-directive REPLACE s3://www.fullofwishes.co.uk/feed.xml s3://www.fullofwishes.co.uk/feed 

# update the routing rules
aws s3api put-bucket-website --bucket www.fullofwishes.co.uk --website-configuration file://config/routing-rules.json

# invalidate cloudfront
aws cloudfront create-invalidation --distribution-id $CDN_DISTRIBUTION_ID --paths "/*"

# ping feedburner
curl --write-out '%{http_code}' --silent --output /dev/null "https://www.feedburner.com/fb/a/pingSubmit?bloglink=https%3A%2F%2Fwww.fullofwishes.co.uk/"


echo "A Head Full of Wishes successfully deployed."