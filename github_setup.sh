#!/bin/sh

curl -u "$1" -H "Content-Type: application/json" -X POST -d '{
  "name": "web",
  "active": true,
  "events": ["push", "issue_comment", "pull_request", "pull_request_review_comment"],
  "config": {
    "url": "http://greatsea.com:8080/",
    "content_type": "json"
  }
}' https://api.github.com/repos/$2/$3/hooks
