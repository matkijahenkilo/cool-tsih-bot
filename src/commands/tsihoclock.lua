local ORIGIN = "assets/images/tsihoclock/";
local IDS_PATH = "src/data/tsihclockids.json";

local fs = require("fs");
local json = require("json");
local discordia = require("discordia");

local randomTitle = {
  "Wake up honey, It's Tsih O'Clock~!",
  "Pigyamoh! It's that time of the day again~!",
  "It's Tsih O'Clock~!",
}

local randomName = {
  "ぴぎゃもーう！",
  "にゃふふふ～",
  "にゅひひ！",
  "どりゃー！",
  "そーい！",
  "うりゃー！",
  "あたっくなのら！",
  "トラップなのら",
  "いぇーい！",
  "元気になったのら",
  "覚悟はいいのら？",
  "もっともっとなのら！",
  "ツィーなのら！よろ！",
}

local randomValue = {
  "Here's a cute picture of me, nora~!",
  "I'm here, once again!",
  "Tsih is here, yo!",
  "Poor Nanako, she still doesn't have a \"Nanako O'Clock\"!",
  "Behold nanora!",
  "Bless this incredible artist nanora~!",
  "私は君よりかわいいなのら！",
  "にゅふーにゅふー♪",
  "ぴぎゃーも♪　いい気分なのらー",
  "当たりなのら",
  "満足したのら？",
  "ラッキーなのらぁ！",
  "にゅはははは！　これも使っちゃうのら！",
}

local fileTables = {
  image = fs.readdirSync(ORIGIN .. "image"),
  gif = fs.readdirSync(ORIGIN .. "gif"),
}

local function getTsihArtworkWithEmbedMessage(fileFormat)
  local list = fileTables[fileFormat];

  local fileToSend = list[math.random(#list)]; -- filename must not have weird characters, spaces nor '()' and '+'
  local file = ORIGIN .. fileFormat .. '/' .. fileToSend;

  return {
    file = file,
    embed = {
      title = randomTitle[math.random(#randomTitle)],
      color = 0xff80fd,
      timestamp = discordia.Date():toISO('T', 'Z'),
      fields = {
        {
          name = randomName[math.random(#randomName)],
          value = randomValue[math.random(#randomValue)],
        },
      },
      image = {
        url = "attachment://" .. fileToSend,
      },
    },
  };
end

local function sendCuteness(channel, fileType)
  if not channel then return end

  channel:send(getTsihArtworkWithEmbedMessage(fileType));
end

local function tsihClock(interaction, fileType)
  if fileType == "gif" or fileType == "image" then
    sendCuteness(interaction, fileType);
  else
    if math.random() <= 0.1 then
      sendCuteness(interaction, "gif");
    else
      sendCuteness(interaction, "image");
    end
  end
end

local function sign(interaction)
  if interaction.guild then
    local ids = fs.readFileSync(IDS_PATH);
    local id = interaction.channel.id;
    local guildName = interaction.guild.name;
    local t = {};
    if ids then
      t = json.decode(ids);
    end

    if t[1] then
      for _, value in ipairs(t) do
        if value.id == id then
          interaction:reply("Room is already signed for Tsih O'Clock!");
          return;
        end
      end
    end

    table.insert(t, { id = id, guildName = guildName });
    fs.writeFileSync(IDS_PATH, json.encode(t));

    interaction:reply("This room is now signed for Tsih O'Clock nanora!");
  else
    interaction:reply("This function only works withing servers nanora!", true);
  end
end

local function remove(interaction)
  if interaction.guild then
    local ids = fs.readFileSync(IDS_PATH)
    local id = interaction.channel.id;
    if ids then
      local t = json.decode(ids);
      for key, value in pairs(t) do
        if value.id == id then
          table.remove(t, key);
          fs.writeFileSync(IDS_PATH, json.encode(t));
          interaction:reply("Done! How can you meanies see my cuteness daily now nanora!?");
          return;
        end
      end
    end
    interaction:reply("B-but this room isn't even signed up nora!");
  else
    interaction:reply("This function only works withing servers nanora!", true);
  end
end

local function sendAllTOC(client)
  local ids = fs.readFileSync(IDS_PATH);
  if ids then
    local t = json.decode(ids);
    local total = 0;

    for _, value in pairs(t) do
      total = total + 1;
      coroutine.wrap(function()
        tsihClock(client:getChannel(value.id));
        print("Sending artwork to " .. value.guildName);
      end)();
    end
    print("Sending " .. total .. " Tsih's fan arts nanora!");
  end
end

local function tsihClockSlash(interaction, format)
  if format then
    interaction:reply(getTsihArtworkWithEmbedMessage(format), true)
  else
    if math.random() <= 0.1 then
      interaction:reply(getTsihArtworkWithEmbedMessage("gif"), true)
    else
      interaction:reply(getTsihArtworkWithEmbedMessage("image"), true)
    end
  end
end

local functions = {
  sign   = sign,
  unsign = remove,
  manual = tsihClockSlash
}

return {
  getSlashCommand = function(tools)
    return tools.slashCommand("tsihoclock", "For signing text channels to receive daily Tsih artworks nanora!")
        :addOption(
          tools.subCommand("sign", "When used, I'll send a random artwork of me here everyday at 9PM nanora!")
        )
        :addOption(
          tools.subCommand("unsign", "I will not send artworks here anymore if used nora!")
        )
        :addOption(
          tools.subCommand("manual", "I'll manually send a (ephemeral) random artwork nora!")
          :addOption(
            tools.string("format", "You can specify if I send a gif or an image nora!")
            :addChoice(tools.choice("gif", "gif"))
            :addChoice(tools.choice("image", "image"))
          )
        )
        :addOption(
          tools.subCommand("auto", "For the strongest, nanora.")
        )
  end,
  executeSlashCommand = function(interaction, command, args, client)
    local commandName = command.options[1].name;
    local format;
    if args.manual then
      format = args.manual.format
    end

    if commandName == "auto" then
      if client.owner.id == interaction.user.id then
        interaction:reply("Oki nanora!", true);
        sendAllTOC(client);
      else
        interaction:reply("👁️〰️👁️", true);
      end
    else
      functions[commandName](interaction, format);
    end
  end,
  executeWithTimer = function(client)
    sendAllTOC(client);
  end,
};
