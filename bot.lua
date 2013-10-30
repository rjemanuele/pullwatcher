local http = require("http")
local JSON = require('json')
local parse = require('querystring').parse
local string = require('string')
local irc = require("irc")

local server
local c
local channel

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
	 c:privmsg (channel, give)
	end
    end)
  end)
end

--IRC Setup
local host = "chat.freenode.net"
channel = '#rjetest'
c = irc.new ()
c:on ("connected", function (x)
  p("connected bot")
  c:join(channel)
end)
c:on ("data", function (x)
  p("::: "..x)
end)


--Go
server = http.createServer(handler)

c:connect (host, 6667, "ghpw", {ssl=false})
server:listen(8080)

print("Server listening at http://localhost:8080/")
