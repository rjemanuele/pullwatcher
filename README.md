pullwatcher
===========

A bot to watch pull request votes on Github and report them to IRC using Luvit-IRC

Anytime someone commnets on a watched repo's PR with a +1, -1, or any other +/-number it will be reported on the channel specified in the config.

Running
-------

./bot.lua -c your_config_file

Configuration
-------------

See the example config.json

Note that you connect to multiple IRC networks.

Watching a new repo
-------------------

To get the bot to watch a new github repo, simply run:
```
./github_setup.sh [your-github-username] [repo-owner] [repo-name] [server]:[port]
```

This will configure a github webhook that posts new PR events to the bot.

ToDo
----

* Add an IRC side interface
  * Map IRC users to GitHub users
  * Store that data in an sqlite3 db
* Add package info
