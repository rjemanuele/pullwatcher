#!/bin/sh

username="$1"
owner="$2"
repo="$3"
webhook="$4"
authHeader=""

if [ "$#" -eq 5 ]; then
    twoFactorAuthToken="$5"
    authHeader="X-GitHub-OTP: ${twoFactorAuthToken}"
elif [ "$#" -ne 4 ]; then
    echo "Incorrect number of parameters"
    exit 1
fi

curl -u "$username" -H 'Content-Type: application/json' -H "${authHeader}" -X POST -d '{
  "name": "web",
  "active": true,
  "events": ["push", "issue_comment", "pull_request", "pull_request_review_comment"],
  "config": {
    "url": "'$webhook'",
    "content_type": "json"
  }
}' https://api.github.com/repos/$owner/$repo/hooks
