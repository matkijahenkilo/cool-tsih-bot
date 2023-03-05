local MUSIC_FOLDER = "assets/sounds/yt-dlp/";

local discordia = require("discordia");
local spawn = require('coro-spawn');
local fs = require("fs");
local cache = {};
discordia.extensions();



local function connectAndCacheNewConnection(message)
  cache[message.guild.id] = {
    connection   = message.member.voiceChannel:join();
    playlist     = discordia.Deque();
    whoRequested = {};
    nowPlaying   = '';
    isPlaying    = false;
  }
  return cache[message.guild.id];
end

local function isMemberOnVoiceChannel(voiceChannel, message)
  return voiceChannel.connection.channel.id == message.member.voiceChannel.id;
end

local function deleteExistingFiles(message, id)
  message:reply("**Song was opted to be re-downloaded**.\nDeleting existing files and re-downloading possible corrupted song nanora! Please wait~");
  fs.unlinkSync(MUSIC_FOLDER .. id .. ".mp3");
  fs.unlinkSync(MUSIC_FOLDER .. id .. ".webm");
end

local function findAndDeleteExistingFile(message, url)
  local child = spawn("yt-dlp", {args = {"--print", "id", url}});
  if child then
    child.waitExit();
    local id = child.stdout.read():gsub("%c", '');
    deleteExistingFiles(message, id);
  end
end

local function downloadSong(currentSongInfo, message)
  local url = currentSongInfo["url"];

  if currentSongInfo["shouldRedownload"] and url then
    findAndDeleteExistingFile(message, url);
  end

  local child = spawn("yt-dlp", {
    args = {
      "--no-simulate",
      "--paths", MUSIC_FOLDER,
      "--print", "title",
      "--print", "id",
      "--extract-audio", "--audio-format", "mp3",
      "--output", "%(id)s.mp3",
      url,
    }
  });

  local t = {};

  if child then
    child.waitExit();
    local info = child.stdout.read();
    if not info then return end
    t = info:split('\n');
  end

  return {
    title = t[1],
    id    = t[2],
  };
end

local function setInformationToCache(voiceChannel, song, whoRequested)
  voiceChannel.nowPlaying = song.title;
  voiceChannel.whoRequested = whoRequested;
end

local function getListOfVideosFromPlaylist(url)
  local child = spawn("yt-dlp", { args = { "--flat-playlist", "-g", url } });
  if child then
    child.waitExit();
    return child.stdout.read():split('\n');
  end
end

local function addIndividualUrlsFromPlaylistIntoDeque(url, playlist, user, shouldRedownload)
  local list = getListOfVideosFromPlaylist(url);
  for _, link in ipairs(list) do
    if link ~= '' then
      playlist:pushRight({["url"]=link, ["whoRequested"]=user, ["shouldRedownload"]=shouldRedownload});
    end
  end
end

local function isPlaylist(url)
  local playlistIndicators = {
    "?list=",
    "&list=",
    "/sets/",
    "/album/",
  }
  for _, value in ipairs(playlistIndicators) do
    if url:find(value) then return true end
  end
  return false;
end

local function showCurrentMusic(message, song, user, count)
  message:reply {
    title = "Enjoy this banger nora!",
    color = 0x6f5ffc,
    fields = {
      {
        name = song.title,
        value = "There's " .. count .. " tracks left to play... nanora!"
      },
    },
    footer = {
      text = "Requested by " .. user.name .. " nora.",
      icon_url = user.avatarURL;
    }
  };
  message:reply("");
end

local function notifySongAdded(message, playlistSize)
  local playlistAddResponse = "Song added into the playlist";
  if playlistSize > 5 then
    playlistAddResponse = playlistAddResponse .. "~\nThere's now " .. playlistSize .. " tracks to play nora!"
  else
    playlistAddResponse = playlistAddResponse .. " nora!";
  end

  message.channel:send {
    content = playlistAddResponse,
    reference = {
      message = message,
      mention = false,
    };
  };
end

local function getQueuedSongInfo(currentSongInfo, message)
  if not currentSongInfo then return end
  local song = downloadSong(currentSongInfo, message);
  local whoRequested = currentSongInfo["whoRequested"];
  return song, whoRequested;
end

local function addSongIntoUrlsForDownloadDeque(url, playlist, user, shouldRedownload)

  if isPlaylist(url) then
    addIndividualUrlsFromPlaylistIntoDeque(url, playlist, user, shouldRedownload);
  else
    playlist:pushRight({["url"]=url, ["whoRequested"]=user, ["shouldRedownload"]=shouldRedownload});
  end

end

local function addSongsIntoDeque(playlist, user, args, shouldRedownload)
  for _, link in ipairs(args) do
    if link and link ~= '' then
      addSongIntoUrlsForDownloadDeque(link, playlist, user, shouldRedownload);
    end
  end
end

local function startStreaming(message, voiceChannel)
  coroutine.wrap(function ()
    while true do

      local room = voiceChannel.connection;

      voiceChannel.isPlaying = true;
      message:reply("Fetching song, please wait nanora!");

      local currentSongInfo = voiceChannel.playlist:popLeft();
      local song, whoRequested = getQueuedSongInfo(currentSongInfo, message);
      if song then

        showCurrentMusic(message, song, whoRequested, voiceChannel.playlist:getCount());
        setInformationToCache(voiceChannel, song, whoRequested);
        room:playFFmpeg(MUSIC_FOLDER .. song.id .. ".mp3");

      else

        if voiceChannel.playlist:peekLeft() then
          message:reply("I couldn't fetch the song! Attempting to fetch the next song from the list~");
        else
          message:reply("Queue is empty nora! Stopping~");
          room:close();
          cache[message.guild.id] = nil;
          return;
        end

      end

    end
  end)();
end

local function play(message, args, shouldRedownload)
  local voiceChannel = cache[message.guild.id];
  if voiceChannel == nil then
    voiceChannel = connectAndCacheNewConnection(message);
  end

  addSongsIntoDeque(voiceChannel.playlist, message.member.user, args, shouldRedownload);

  notifySongAdded(message, voiceChannel.playlist:getCount());

  if not voiceChannel.isPlaying then
    startStreaming(message, voiceChannel)
  end

end

local function showWhatIsPlayingCurrently(message)
  local voiceChannel = cache[message.guild.id];
  if voiceChannel == nil then return end
  local nowPlaying = voiceChannel.nowPlaying;
  local user = voiceChannel.whoRequested;

  if not user or not user[1] or not nowPlaying then return end
  message.channel:send {
    embed = {
      title = "Now playing: **" .. nowPlaying .. "** ...nanora!",
      description = voiceChannel.playlist:getCount() .. " tracks remaining nanora.",
      color = 0xff80fd,
      footer = {
        text = "Requested by " .. user.name .. " nora.",
        icon_url = user.avatarURL
      }
    }
  }
end

local function pause(message)
  local voiceChannel = cache[message.guild.id];
  if voiceChannel == nil then return end
  message.channel:send("Pausing... nanora!");
  voiceChannel.connection:pauseStream();
end

local function resume(message)
  local voiceChannel = cache[message.guild.id];
  if voiceChannel == nil then return end
  message.channel:send("Resuming... nanora!");
  voiceChannel.connection:resumeStream();
end

local function skip(message)
  local voiceChannel = cache[message.guild.id];
  if voiceChannel == nil then return end
  message.channel:send("Skipping... nanora!");
  voiceChannel.connection:stopStream();
end

local function stop(message)
  local voiceChannel = cache[message.guild.id];
  if voiceChannel == nil then return end
  message.channel:send("Stopping... nanora!");
  while voiceChannel.playlist:peekLeft() do
    voiceChannel.playlist:popLeft();
  end
  voiceChannel.connection:close();
  cache[message.guild.id] = nil;
end

local function populateTableWithDequePlaylist(t, voiceChannel)
  local dequeCount = voiceChannel.playlist:getCount();
  for i = 1, dequeCount do
    t[i] = voiceChannel.playlist:popLeft();
  end
  return t;
end

local function shuffleTable(t)
  for i = #t, 2, -1 do
    local j = math.random(i);
    t[i], t[j] = t[j], t[i];
  end
  return t;
end

local function populateDequeWithShuffledPlaylist(t, voiceChannel)
  for i = 1, #t do
    voiceChannel.playlist:pushRight(t[i]);
  end
end

local function shuffle(message)
  message:reply{
    content = "Shuffling playlist nora...",
    reference = {
      message = message,
      mention = false,
    }
  };

  local voiceChannel = cache[message.guild.id];

  local t = {};
  t = populateTableWithDequePlaylist(t, voiceChannel);
  t = shuffleTable(t);
  populateDequeWithShuffledPlaylist(t, voiceChannel);

  message:reply("Playlist has now " .. voiceChannel.playlist:getCount() .. " shuffled tracks nanora!");
end

local functions = {
  play       = play,
  skip       = skip,
  nowplaying = showWhatIsPlayingCurrently,
  stop       = stop,
  pause      = pause,
  resume     = resume,
  shuffle    = shuffle
}

return {
  getSlashCommand = function(tools)
    --[[ currently commented because interaction.member.voiceChannel:join() gives an error
    return tools.slashCommand("song", "I'll play any song for you nanora!")
        :addOption(
          tools.subCommand("play", "I'll play or add any song for you nanora!")
          :addOption(
            tools.string("urls", "One or more URL that works with yt-dlp nora!")
            :setRequired(true)
          )
          :addOption(
            tools.boolean("redownload", "Re-downloads the song if you feel the need nora!")
          )
        )
        :addOption(
          tools.subCommand("skip", "I'll skip the current song nanora!")
        )
        :addOption(
          tools.subCommand("stop", "I'll stop and clear the current playlist nanora!")
        )
        :addOption(
          tools.subCommand("shuffle", "Shuffles the current playlist nanora!")
        )
        :addOption(
          tools.subCommand("pause", "I'll just pause the song nanora.")
        )
        :addOption(
          tools.subCommand("resume", "I'll just resume the song nanora.")
        )
        :addOption(
          tools.subCommand("nowplaying", "Shows you the current song playing nora!")
        )
    ]]
  end,
  executeSlashCommand = function(message, command, args)
    if not message.guild then
      message:reply("You're not even in a server nora!", true);
      return;
    end

    if not message.member.voiceChannel then
      message:reply("You're not even in a voice chat nora!", true);
      return;
    end

    local voiceChannel = cache[message.guild.id];
    if voiceChannel then
      if not isMemberOnVoiceChannel(voiceChannel, message) then
        message:reply("Get into the voice channel with the boys first nanora!");
        return;
      end
    end

    local url, redownload;
    local commandName = command.options[1].name;
    if commandName == "play" then
      url         = args.play.urls:split(' ');
      redownload  = args.play.redownload;
    end

    functions[commandName](message, url, redownload or false);
  end
};

