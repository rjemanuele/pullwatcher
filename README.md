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

ToDo
----

* Add an IRC side interface
  * Map IRC users to GitHub users
  * Store that data in an sqlite3 db
* Add package info
