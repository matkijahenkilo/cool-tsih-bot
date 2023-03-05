local function sendMessage(interaction, args, client)
  local avatarLink;
  if not args then
    avatarLink = interaction.member.user:getAvatarURL(1024);
  else
    avatarLink = client:getUser(args.user.id):getAvatarURL(1024);
  end

  interaction:reply {
    embed = {
      title = "Your avatar nanora!",
      fields = {
        { name = "What a lazy adult!", value = "They look like holding a lot of shiny stars..." },
      },
      image = { url = avatarLink },
      color = 0xff80fd,
    },
  };
end

return {
  getSlashCommand = function(tools)
    return tools.slashCommand("avatar", "I send your or somebody else's avatar nanora!")
        :addOption(
          tools.user("user", "Somebody else's avatar")
        )
  end,
  executeSlashCommand = function(interaction, _, args, client)
    sendMessage(interaction, args, client);
  end
};
