local M = {}
local ORIGIN = "assets/images/omori/";

---Returns a gif file of Tsih's drawn on omori's panels style
---
---For "type" parameter:
--- 0 - Neutral
--- 1 - Happy
--- 2 - Angry
--- 3 - Sad
--- 4 - Cringe
---
---For "intensity" parameter:
--- it ranges from 0 to 2, meaning the weakest to the strongest feeling.
---@param type integer
---@param intensity integer
---@return string
function M.getOmoriReactionGif(type, intensity)
  return ORIGIN .. type .. "_" .. intensity .. ".gif";
end

return M;
