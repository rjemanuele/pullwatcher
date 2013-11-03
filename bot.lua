#!/usr/bin/env luvit

local http = require("http")
local io = require("io")
local JSON = require('json')
local parse = require('querystring').parse
local string = require('string')
local irc = require("luvit-irc")

local server
local c

--Configure
local argv = require('luvit-options')
  .usage("Usage: ./bot.lua ....")
  .describe("c", "config file location")
  .alias({["c"]="config"})
  .demand({'c'})
  .argv("c:")

if not argv.args.c then
  process.exit(1)
end

local config = {}
local f = io.open(argv.args.c, "r")
if f ~= nil then
  local content = f:read("*all")
  f:close()
  config = JSON.parse(content)
end


--Hook Handler
local function handler(request, response)
  local postBuffer = ''
  request:on('data', function(chunk)
    postBuffer = postBuffer .. chunk
  end)
  request:on('end', function()
    response:write("Hello")
    response:finish()
    local t = ''
    --p("request", request)
    --p("postBuffer", postBuffer)
    ret, error = pcall(function()
       t = JSON.parse(postBuffer)
       --p("final", t)
       --p(t.comment.body)
       local plus, count
       plus, count = string.gsub(t.comment.body, ".*([%+%-]%d+).*", "%1")
       --p("ret", plus, count)
       if count > 0 then
         local give = string.format("%s has given %s a %s",
           t.sender.login,
	   t.issue.html_url,
	   plus)
	   p(give)
	 c:privmsg (config.irc.channel.name, give)
	end
    end)
  end)
end

--IRC Setup
c = irc.new ()
c:on ("connected", function (x)
  p("connected bot")
  c:join(config.irc.channel.name .. " " .. config.irc.channel.password)
end)
c:on ("data", function (x)
  p("::: "..x)
end)
c:on ("privmsg", function (nick, msg)
  if nick:sub(1,1) ~= '#' or msg:find("^" .. config.irc.nick .. "[%p ]") then
    c:privmsg (nick, "This bot has nothing to say yet, see: http://github.com/rjemanuele/pullwatcher")
  end
end)

--Go
server = http.createServer(handler)

c:connect (config.irc.host, config.irc.port, config.irc.nick, {ssl=config.irc.ssl})
server:listen(config.http.port, config.http.addr)

print(string.format("Server listening at http://%s:%d/", config.http.addr, config.http.port))
