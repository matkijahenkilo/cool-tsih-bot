local SAUCE_LIMITS_JSON = "src/data/sauceLimits.json";

local spawn = require("coro-spawn");
local fs = require("fs");
local json = require("json");
require('discordia').extensions();

-- Depending on your needs, you may add more websites in the following tables
-- just be sure if said website works with gallery-dl, and
-- if its links can be embeded into discord, if not then insert
-- the link into requireDownload table.
local doesNotRequireDownload = {
  "https://pawoo.net/",
  "https://nijie.info/",
  "https://kemono.party/",
  "https://e-hentai.org/",
  "https://hentai2read.com/",
}

local requireDownload = {
  "https://hitomi.la/",
  "https://exhentai.org/",
  "https://www.pixiv.net/",
}

local function hasFile(file)
  return file or file[1];
end

local function hasUrl(url)
  return url ~= '';
end

local function getSpecificLinks(t, string)
  local specificLinks = {};
  for _, value in ipairs(t:split('\n')) do
    if value:find(string) then
      table.insert(specificLinks, value .. '\n');
    end
  end
  return specificLinks;
end

local function readProcess(child)
  local linksTable = {};
  child:waitExit();
  local link = child.stdout.read();

  table.insert(linksTable, link);
  if link then
    if link:find("pbs.twimg") then
      return getSpecificLinks(link, "video.twimg");
    elseif link:find("media.baraag.net") then
      local baraagLinks = getSpecificLinks(link, "media.baraag.net");
      table.remove(baraagLinks, 1);
      return baraagLinks;
    end
  end

  return linksTable;
end

local function checkSuccess(success, err, message, value)
  if not success then
    p("Couldn't get link: " .. value, "Reason: " .. err);
    message:addReaction("🇳");
    message:addReaction("🇴");
  end
end

local function downloadImage(url, id, limit)
  local child = spawn("gallery-dl", {
    args = {
      "--cookies", "cookies.txt",
      "--range", "1-" .. limit, "--ugoira-conv",
      "-D", "./temp/" .. id .. "/",
      url
    }
  });

  local file = table.concat(readProcess(child));
  file = file:gsub("# ", '');
  file = file:split("\n");
  table.remove(file, #file);

  return file;
end

local function sendDownloadedImage(message, images)
  return message.channel:send {
    files = images,
    reference = {
      message = message,
      mention = false,
    }
  };
end

local function deleteDownloadedImage(file, id)
  for _, value in ipairs(file) do
    fs.unlinkSync(value);
  end
  fs.rmdir("./temp/" .. id);
end

local function getUrl(url, limit)
  if limit > 5 then limit = 5 end

  local child = spawn("gallery-dl", {
    args = {
      "--cookies", "cookies.txt",
      "--range", "1-" .. limit,
      "-g",
      url
    }
  });

  return table.concat(readProcess(child));
end

local function sendUrl(message, url)
  return message.channel:send {
    content = url,
    reference = {
      message = message,
      mention = false,
    }
  };
end

local function shouldSendBaraagLinks(url)
  local quantity = 0;
  for _, value in ipairs(url:split('\n')) do
    if value:find("baraag.net") and value:find(".mp4") then
      return true;
    elseif value:find("baraag.net") then
      quantity = quantity + 1;
    end
  end

  return quantity > 1;
end

local function verify(string, list)
  for _, value in pairs(list) do
    if string:find(value) then
      return true;
    end
  end

  return false;
end

local function sendTwitterDirectVideoUrl(value, message, limit)
  local url = getUrl(value, limit);
  if url:find("video.twimg") then
    local success, err = sendUrl(message, url);
    checkSuccess(success, err, message, value);
  end
end

local function sendDirectImageUrl(value, message, limit)
  if value:find("https://baraag.net/") then
    value = value:gsub("web/", '');
  end

  local url = getUrl(value, limit);
  if hasUrl(url) then
    if shouldSendBaraagLinks(url) or not url:find("https://baraag.net/") then
      local success, err = sendUrl(message, url);
      checkSuccess(success, err, message, value);
    end
  end
end

local function downloadSendAndDeleteImages(value, message, limit)
  local id = message.channel.id;
  local file = downloadImage(value, id, limit);

  if hasFile(file) then
    local success, err = sendDownloadedImage(message, file);
    checkSuccess(success, err, message, value);
  end

  deleteDownloadedImage(file, id);
end

local function createJsonFileWithChannelRule(newLimit, guildId, channelId)
  local newJsonFileWithRule = {
    [guildId] = {
      [channelId] = newLimit
    }
  };
  fs.writeFileSync(SAUCE_LIMITS_JSON, json.encode(newJsonFileWithRule));
end

local function verifyIfRuleExists(t, guildId, channelId)
  if t[guildId] then
    return t[guildId][channelId] ~= nil;
  end
  return false;
end

local function replaceChannelRule(t, newLimit, guildId, channelId)
  t[guildId][channelId] = newLimit;

  fs.writeFileSync(SAUCE_LIMITS_JSON, json.encode(t));
end

local function addGuildAndChannelRule(t, newLimit, guildId, channelId)
  if not t[guildId] then t[guildId] = {} end
  t[guildId][channelId] = newLimit;

  fs.writeFileSync(SAUCE_LIMITS_JSON, json.encode(t));
end

local function getRoomImageLimit(message)
  if not message.guild then return end
  local guildId = message.guild.id;
  local channelId = message.channel.id;

  local rawJson = fs.readFileSync(SAUCE_LIMITS_JSON);
  if rawJson then
    local t = json.decode(rawJson);
    if t then
      if t[guildId] then
        return t[guildId][channelId];
      end
    end
  end
end

local function setSauceLimitOnChannel(interaction, args)
  if not interaction.guild then
    interaction:reply("This function does not work with DMs nanora!", true);
    return;
  end

  local newLimit = args.limit
  local guildId = interaction.guild.id;
  local channelId = interaction.channel.id;

  local rawJson = fs.readFileSync(SAUCE_LIMITS_JSON);

  if rawJson then
    local jsonContent = json.decode(rawJson);
    if verifyIfRuleExists(jsonContent, guildId, channelId) then
      replaceChannelRule(jsonContent, newLimit, guildId, channelId);
    else
      addGuildAndChannelRule(jsonContent, newLimit, guildId, channelId);
    end
  else
    createJsonFileWithChannelRule(newLimit, guildId, channelId);
  end

  if newLimit ~= 0 then
    interaction:reply("I will send up to " .. newLimit .. " images per link in this room nanora!");
  else
    interaction:reply("I won't be sending the link's sauces in this room anymore nanora!");
  end
end

local function sendSauce(message)
  local content = message.content;
  if content then
    if content:find("https://") then
      content = content:gsub('\n', ' '):gsub('||', ' ');
      local t = content:split(' ');
      local limit = getRoomImageLimit(message) or 5;

      if limit == 0 then return end

      for _, value in ipairs(t) do
        if value ~= '' then
          coroutine.wrap(function()
            if verify(value, doesNotRequireDownload) then
              sendDirectImageUrl(value, message, limit);
            elseif verify(value, requireDownload) then
              downloadSendAndDeleteImages(value, message, limit);
            elseif value:find("https://twitter.com/") then
              sendTwitterDirectVideoUrl(value, message, limit);
            end
          end)();
        end
      end
    end
  end
end

local function sendAnySauce(message)
  local content = message.content;
  if content then
    if content:find("https://") then
      content = content:gsub('\n', ' '):gsub('||', ' ');
      local t = content:split(' ');
      local limit = getRoomImageLimit(message) or 5;

      if limit == 0 then return end

      for _, value in ipairs(t) do
        if value ~= '' and value:find("https://") then
          coroutine.wrap(function()
            downloadSendAndDeleteImages(value, message, limit);
          end)();
        end
      end
    end
  end
end

return {
  getSlashCommand = function(tools)
    return tools.slashCommand("sauce", "Sets a limit for images I send nanora!")
        :addOption(
          tools.integer("limit", "Default is 5 nanora! Input 0 if you don't want me to send images again nora!")
          :setMinValue(0)
          :setMaxValue(10)
          :setRequired(true)
        );
  end,
  getMessageCommand = function(tools)
    return tools.messageCommand("Send sauce");
  end,
  executeSlashCommand = function(interaction, _, args)
    setSauceLimitOnChannel(interaction, args);
  end,
  executeMessageCommand = function (interaction, _, message)
    interaction:reply("Alrighty nanora! One second...", true);
    sendAnySauce(message);
  end,
  sendSauce = function(message)
    sendSauce(message);
  end
}
