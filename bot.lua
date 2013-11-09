#!/usr/bin/env luvit

local http = require("http")
local io = require("io")
local JSON = require('json')
local parse = require('querystring').parse
local string = require('string')
local irc = require("luvit-irc")

local server
local nickmap = {}
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


function split(str, delim, maxNb)
  -- Eliminate bad cases...
  if string.find(str, delim) == nil then
    return { str }
  end
  if maxNb == nil or maxNb < 1 then
    maxNb = 0    -- No limit
  end
  local result = {}
  local pat = "(.-)" .. delim .. "()"
  local nb = 0
  local lastPos
  for part, pos in string.gmatch(str, pat) do
    nb = nb + 1
    result[nb] = part
    lastPos = pos
    if nb == maxNb then break end
  end
  -- Handle the last field
  if nb ~= maxNb then
    result[nb + 1] = string.sub(str, lastPos)
  end
  return result
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
      local plus, count
      plus, count = string.gsub(t.comment.body, ".*([%+%-]%d+).*", "%1")
      --p("ret", plus, count)
      if count > 0 then
        local give = string.format("%s has %s'd %s's %s",
          nickmap[t.sender.login] or t.sender.login,
          plus,
          nickmap[t.issue.user.login] or t.issue.user.login,
          t.issue.html_url)
          p(give)
        c:privmsg(config.irc.channel.name, give)
      end
    end)
  end)
end


local commands = {}

commands["help"] = function(origin, nick, tokens)
  c:privmsg(origin, "Commands:")
  c:privmsg(origin, "map <username>; Map a Github username to the current nick")
  c:privmsg(origin, "about; see: http://github.com/rjemanuele/pullwatcher")
end

commands["map"] = function(origin, nick, tokens)
  nickmap[tokens[2]] = nick
  c:privmsg(origin, string.format("Nick: %s mapped to Github: %s", nick, tokens[2]))
end

commands["about"] = commands["help"]

--IRC Handler
local function irc_handler(origin, nick, msg)
  if origin == config.irc.nick then
     origin = nick
  end
  --trim
  msg:gsub("^%s+", ""):gsub("%s+$", "")
  local tokens = split(msg, "%s+")
  p(tokens)
  if not tokens or not tokens[1] or not commands[tokens[1]:lower()] then
    c:privmsg(origin, "Unknown command")
    tokens[1] = 'help'
  end
  commands[tokens[1]:lower()](origin, nick, tokens)
end


--IRC Setup
c = irc:new()
c:on("connected", function (x)
  c:join(config.irc.channel.name .. " " .. config.irc.channel.password)
end)
c:on("data", function (x)
  p("::: "..x)
end)
c:on("privmsg", function (origin, nick, msg)
  if origin:sub(1,1) ~= '#' then
    irc_handler(origin, nick, msg)
  end
  msg, i =  msg:gsub("^" .. config.irc.nick .. "[%p ][ ]*", "")
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
c:connect(config.irc.host, config.irc.port, config.irc.nick, {ssl=config.irc.ssl})
server:listen(config.http.port, config.http.addr)

print(string.format("Server listening at http://%s:%d/", config.http.addr, config.http.port))
