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
local function webhook_handler(request, response)
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
      string.gsub(
        " " .. t.comment.body .. " ",
        "[%s%p%c]([%+%-]%d+)[%s%p%c]",
        function(plus)
          local give = string.format("%s has %s'd %s's %s",
            t.sender.login,
            plus,
            t.issue.user.login,
            t.issue.html_url)
          p(give)
          c:privmsg(config.irc.channel.name, give)
        end)
    end)
  end)
end


--IRC Handler
local function irc_handler(origin, nick, msg)
  if origin == config.irc.nick then
     origin = nick
  end
  c:privmsg(origin, "This bot has nothing to say yet, see: http://github.com/rjemanuele/pullwatcher")
end


--IRC Setup
c = irc:new()
c:on("connected", function (x)
  local chan = config.irc.channel.name
  if config.irc.channel.password then
    chan = chan .. " " .. config.irc.channel.password
  end
  c:join(chan)
end)
c:on("data", function (x)
  p(":>: "..x)
end)
c:on("dataout", function (x)
  p(":<: "..x)
end)
c:on("privmsg", function (origin, nick, msg)
  if origin:sub(1,1) ~= '#' then
    irc_handler(origin, nick, msg)
  end
  local _, i =  msg:gsub("^" .. config.irc.nick .. "[%p ][ ]*", "")
  if i == 1 then
    irc_handler(origin, nick, msg)
  end
end)
c:on("notice", function (orig, msg)
  if config.irc.nick_pass and msg:find("/msg NickServ identify") then
    c:privmsg ("NickServ", "identify " .. config.irc.nick_pass)
  end
end)


--Go
server = http.createServer(webhook_handler)
c:connect(config.irc.host, config.irc.port, config.irc.user or config.irc.nick, config.irc.nick, {ssl=config.irc.ssl, sasl_auth=config.irc.sasl_auth})
server:listen(config.http.port, config.http.addr)

print(string.format("Server listening at http://%s:%d/", config.http.addr, config.http.port))
