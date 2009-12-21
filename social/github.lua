local social = require"social"
--------------------------------
local mime = require"mime" -- luarocks install luasocket
local url = require"socket.url" --             luasocket
local json = require"json" --                  json4lua

--- SocialLua - GitHub module.
-- This module is alpha quality, and behaviour may change without prior notice.
-- @author Linus Sjögren (thelinx@unreliablepollution.net)
module("social.github", package.seeall) -- seeall for now

function full(page, ...)
    return "https://github.com/api/v2/json/"..string.format(page, ...)
end

local function check(s,d,h,c)
    if not s then return false,d end
    local t = json.decode(d)
    if c ~= 200 then
        return false,t.error[1].error
    else
        return true,t
    end
end

client = {}
local cl_mt = { __index = client }

--- Creates a new GitHub client
function client:new()
    return setmetatable({authed = false}, cl_mt)
end

function cl_mt:__tostring()
    if self.authed then
        return "GitHub client, authed as "..self.username.." ("..self.token..")"
    else
        return "GitHub client, not authed"
    end
end

--- Flushes account data from client.
function client:logout()
    self.authed = false
    self.auth = nil
    self.username = nil
    self.token = nil
    self.user = t
end

--- Attempts authetication with GitHub.
-- @param username Username
-- @param token API token
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the user.
function client:login(username, token)
    local auth = {login = username, token = token}
    local s,d,h,c = social.get(full("user/show/%s", username), auth)
    if not s then return false,d end
    local t = json.decode(d)
    if c ~= 200 then
        self:logout()
        return false,t.error[1].error
    elseif t.user.plan then -- only returned if correctly authed
        self.authed = true
        self.auth = auth
        self.username = username
        self.token = token
        self.user = t.user
        return true,t.user
    else
        self:logout()
        return false,"failed to authorize"
    end
end

--- Searches for a GitHub user.
-- @param query Search query.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the results.
function client:userSearch(query)
    local s,d,h,c = social.get(full("user/search/%s", query))
    return check(s,d,h,c)
end

--- Shows information about a user.
-- @param username Target user.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the user.
function client:userShow(username)
    local s,d,h,c = social.get(full("user/show/%s", username), self.auth)
    return check(s,d,h,c)
end

--- Edits a user's information.
-- Username is set to the currently authed user, no matter what.
-- @param values See http://develop.github.com/p/users.html#authenticated_user_management
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the new user info.
function client:userEdit(values)
    local arg = assert(self.auth, "You must be logged in to do this!")
    for k,v in pairs(values) do
        arg["values["..k.."]"] = v
    end
    local s,d,h,c = social.post(full("user/show/%s", self.username), arg)
    if s then
        self.user = d.user
    end
    return check(s,d,h,c)
end

--- Returns a list of users the specified user is following.
-- @param username Target user. Defaults to currently authed user.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the users.
function client:userFollowing(username)
    local s,d,h,c = social.get(full("user/show/%s/following", username or self.username))
    return check(s,d,h,c)
end
