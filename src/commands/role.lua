local color = require("discordia").Color();
local json = require("json");
local fs = require("fs");

local function isHex(x)
  if x == '' then return false end
  return string.byte(x) <= string.byte('f') and string.byte(x) >= string.byte('0');
end

local function deleteOldRoleFromGuildMember(interaction, member, client)
  for _, value in ipairs(member) do
    if interaction.member.id == value.userID then
      local oldRole = client:getRole(value.roleID);
      if not oldRole then return end
      oldRole:delete();
      return;
    end
  end
end

local function insertMemberInfoToTable(interaction, role, member)
  table.insert(member, {
    ["userID"] = interaction.member.id,
    ["roleID"] = role.id,
  });
  return member;
end

local function replaceOldMemberInfoWithNewInfo(interaction, role, member)
  for key, value in pairs(member) do
    if not member then break end
    if value.userID == interaction.member.id then
      table.remove(member, key);
    end
  end
  return insertMemberInfoToTable(interaction, role, member);
end

local function updateJsonFile(interaction, client, role)
  local customGuildRolesTable;
  local jsonInfo = fs.readFileSync("src/data/" .. interaction.guild.id .. ".json");
  if jsonInfo then
    customGuildRolesTable = json.decode(jsonInfo);

    if customGuildRolesTable then
      deleteOldRoleFromGuildMember(interaction, customGuildRolesTable, client);
    end
  end

  if not customGuildRolesTable then
    customGuildRolesTable = insertMemberInfoToTable(interaction, role, {});
  else
    customGuildRolesTable = replaceOldMemberInfoWithNewInfo(interaction, role, customGuildRolesTable);
  end

  fs.writeFileSync("src/data/" .. interaction.guild.id .. ".json", json.encode(customGuildRolesTable));
end

local function deleteMemberRoleAndInfoFromJson(interaction, _, client)
  local customGuildRolesTable;
  local jsonInfo = fs.readFileSync("src/data/" .. interaction.guild.id .. ".json");
  if jsonInfo then
    customGuildRolesTable = json.decode(jsonInfo);

    for index, value in ipairs(customGuildRolesTable) do
      if interaction.member.id == value.userID then
        local oldRole = client:getRole(value.roleID);
        if not oldRole then return end
        oldRole:delete();
        table.remove(customGuildRolesTable, index);
        fs.writeFileSync("src/data/" .. interaction.guild.id .. ".json", json.encode(customGuildRolesTable));
        interaction:reply("You are now free nanora!");
        return;
      end
    end
  end
end

local function giveRoleToMember(interaction, command, client)
  local name = command.give.name;
  local hex  = command.give.hex;
  if hex:find('#') then
    hex = hex:gsub('#', '');
  end

  if not isHex(hex) then
    interaction:reply("The hex value is wrong nora!", true);
    return;
  end

  local role, err = interaction.guild:createRole(name);
  if not role then
    print(err);
    interaction:reply("I couldn't create your role, I might not have permissions to do this nanora!");
    return;
  end

  updateJsonFile(interaction, client, role);

  role:setColor(color.fromHex(hex));
  interaction.member:addRole(role.id);

  interaction:reply("Done nanora! Enjoy your new role~!");
end

local functions = {
  give = giveRoleToMember,
  delete = deleteMemberRoleAndInfoFromJson
}

return {
  getSlashCommand = function(tools)
    return tools.slashCommand("role", "I can give or delete a personalized role nora!")
        :addOption(
          tools.subCommand("give", "I'll give you a personalized role nanora!")
          :addOption(
            tools.string("name", "Your role's color nora!")
            :setRequired(true)
          )
          :addOption(
            tools.string("hex", "The role's color must be in hexadecimal value, sorry nora!")
            :setRequired(true)
          )
        )
        :addOption(
          tools.subCommand("delete", "I'll delete your personalized role nanora!")
        )
  end,
  executeSlashCommand = function(interaction, command, args, client)
    if not interaction.guild then
      interaction:reply("This isn't a server nanola,,,,,", true);
      return;
    end

    functions[command.options[1].name](interaction, args, client);
  end
};
