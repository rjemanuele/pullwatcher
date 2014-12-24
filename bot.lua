#!/usr/bin/env luvit

local table = require('table')
local Object = require('core').Object
local http = require("http")
local io = require("io")
local JSON = require('json')
local parse = require('querystring').parse
local string = require('string')
local irc = require("luvit-irc")

local server
local m

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
    p("request", request)
    p("postBuffer", postBuffer)
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
          m:sendtoall(give)
        end)
    end)
  end)
end


local BotIrc = irc:extend()

--IRC Handler
function BotIrc:irc_handler(origin, nick, msg)
  if origin == self.conf.nick then
     origin = nick
  end
  self:privmsg(origin, "This bot has nothing to say yet, see: http://github.com/rjemanuele/pullwatcher")
end


function BotIrc:initialize(conf)
  irc.initialize(self)

  self.conf = conf

  local this = self

  self:on("connected", function (x)
    local chan = conf.channel.name
    if conf.channel.password then
      chan = chan .. " " .. conf.channel.password
    end
    this:join(chan)
  end)
  self:on("data", function (x)
    p(":>: "..x)
  end)
  self:on("dataout", function (x)
    p(":<: "..x)
  end)
  self:on("privmsg", function (origin, nick, msg)
    if origin:sub(1,1) ~= '#' then
      this:irc_handler(origin, nick, msg)
    end
    local _, i =  msg:gsub("^" .. this.conf.nick .. "[%p ][ ]*", "")
    if i == 1 then
      this:irc_handler(origin, nick, msg)
    end
  end)
  self:on("notice", function (orig, msg)
    if this.conf.nick_pass and msg:find("/msg NickServ identify") then
      this:privmsg ("NickServ", "identify " .. this.conf.nick_pass)
    end
  end)
end



local MultiBot = Object:extend()

function MultiBot:initialize(conf)
  self.ircs = {}

  local i, v
  for i,v in ipairs(conf) do
    local b = BotIrc:new(v)
    table.insert(self.ircs, b)
    b:connect(v.host, v.port, v.user or v.nick, v.nick, {ssl=v.ssl, sasl_auth=v.sasl_auth})
  end
end

function MultiBot:sendtoall(msg)
  local i, v
  for i,v in ipairs(self.ircs) do
    v:privmsg (v.conf.channel.name, msg)
  end
end


process:on('error', function(err)
  p('Fatal error', err)
  process.exit(255)
end)

--Go
m = MultiBot:new(config.irc)
server = http.createServer(webhook_handler)
server:listen(config.http.port, config.http.addr)

print(string.format("Server listening at http://%s:%d/", config.http.addr, config.http.port))
