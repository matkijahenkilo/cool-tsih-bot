local omori = require('src/misc/omori');

local answer = {
  "The heck you doing to me?!",
  "Stop it you weirdo!",
  "Nyuu... くさいのら!",
  "I will smash you nanora!!",
  "Don't just hug me all of sudden nora!",
}

return {
  getSlashCommand = function (tools)
    return tools.slashCommand("hug", "You hug a kiddo!")
  end,
  executeSlashCommand = function(interaction)
    interaction:reply {
      content = answer[math.random(1, #answer)],
      file = omori.getOmoriReactionGif(2, math.random(0, 2));
    }
  end
};
