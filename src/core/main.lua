if not args[2] then
  print("please especify a token!");
  return;
end

local discordia   = require("discordia");
local tools       = require("discordia-slash").util.tools();
local client      = discordia.Client():useApplicationCommands();
local clock       = discordia.Clock();
local settings    = require("../data/settings");
local statusTable = require("../misc/statusTable");
local randomReact = require("../misc/randomReact");

local fs      = require("fs");
local wrap    = coroutine.wrap;
local handler
local emoticonsServer;
discordia.extensions.string();

local function readCommands(handl)
  local commands = {};
  for _, value in ipairs(handl) do
    local commandName = value:sub(1, value:find(".lua") - 1);
    local commandTable = require(".." .. "/commands/" .. value);
    commands[commandName] = commandTable;
  end
  local commandsMetaTable = {
    __index = function()
      local M = {};
      function M.execute(message)
        client:warning("Something went wrong.")
      end

      return M;
    end
  };
  return setmetatable(commands, commandsMetaTable);
end

local function hasTsihMention(message)
  local content = message.content:lower();
  return content:find("tsih") or content:find("nora");
end

local function rollRandomReactionDice(message)
  if hasTsihMention(message) or math.random() <= 0.01 then
    randomReact.sendRandomReaction(message, emoticonsServer);
  end
end

local function initializeCommands(commandsHandler, shouldResetCommands)
  if shouldResetCommands then
    client:info("Bot was opted to reset all global commands~");
    for commandId in pairs(client:getGlobalApplicationCommands()) do
      client:deleteGlobalApplicationCommand(commandId);
    end

    client:info("Starting commands...");

    for _, command in pairs(commandsHandler) do
      if command.getSlashCommand then
        client:createGlobalApplicationCommand(command.getSlashCommand(tools));
      end
      if command.getMessageCommand then
        client:createGlobalApplicationCommand(command.getMessageCommand(tools));
      end
    end

    client:info("Done!");
  end
end



client:on("ready", function()
  handler = readCommands(fs.readdirSync("src/commands"));

  client:info("I'm currently serving in " .. #client.guilds .. " servers nanora!");
  for _, guild in pairs(client.guilds) do print(guild.id, guild.name) end

  clock:start();
  client:setActivity(statusTable[math.random(#statusTable)]);
  emoticonsServer = client:getGuild(settings.emoticonsServerId);

  initializeCommands(handler, args[3]);
  require("./timedFunctions")(clock, client, statusTable, handler);

  client:info("💙Ready nanora!💜");
end)

client:on("messageCreate", function(message)
  if message.author.bot then return end
  wrap(function() rollRandomReactionDice(message) end)();
  handler["sauce"].sendSauce(message);
end)

client:on("slashCommand", function(interaction, command, args)
  handler[command.name].executeSlashCommand(interaction, command, args, client);
end)

client:on("messageCommand", function(interaction, command, message)
  handler[command.name:gsub("Send ", '')].executeMessageCommand(interaction, command, message);
end)

client:run('Bot ' .. args[2])
