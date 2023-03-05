local M = {}

function M.sendRandomReaction(message, emoticonServer)
    message:addReaction(emoticonServer.emojis:random());
end

return M;