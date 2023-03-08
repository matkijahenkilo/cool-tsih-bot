# cool-tsih-bot

Tsih's **primary function** is to fill the gap of badly embeded links on discord for websites links like Pixiv, Pawoo and any other website compatible with [gallery-dl](https://github.com/mikf/gallery-dl). Pretty much what [SaucyBot](https://github.com/Sn0wCrack/saucybot-discord) does, but with more websites that you can insert into a table as you see fit. You can also choose if the bot needs to download the image to send it or simply link the direct image's url into chat.

cool-tsih-bot is a discord bot chosen to be written in Lua because the language's icon shares the same color as her hair. cool-tsih-bot was made using [Discordia](https://github.com/SinisterRectus/discordia) API.

It's just a fun project I always wanted to create~

Inicially she was made for fun/entertainment porpuses, but after a long time studying and managing to program my primary objective into her, I decided to leave the cosmetics functions in her code~

I wanted to make her act canonically as she would act in one of the games she's in, but I'm kinda bad at this. w

## Commands

cool-tsih-bot supports slash and message commands, to load them pass a third argument "true" when loading main.lua, you would prefer to do this only once however.

## Installation

Be aware that simply installing cool-tsih-bot may cause crashes during runtime because of the absence of the /assets folder files.

### pre-requisites programs

`ffmpeg yt-dlp gallery-dl`

### bot installation:

Follow [Discordia](https://github.com/SinisterRectus/discordia)'s installation guide.

Git clone [discordia-interactions](https://github.com/Bilal2453/discordia-interactions) and [discordia-slash](https://github.com/GitSparTV/discordia-slash) inside `deps` folder.

to run the bot: `luvit src/core/main.lua [token] [true or false or nil for loading slash commands]`

### gallery-dl configuration

Depending of which website cool-tsih-bot is going to get the images and send, you will need to configurate your gallery-dl to work in those websites eg. login credentials.
For that, you will usually need to create an account for example, nijie.info in order to get the link for the bot to send.
Some websites like Pixiv will need you to run an [oauth](https://github.com/mikf/gallery-dl#oauth) command in gallery-dl in order to download the images from the website and send it to Discord.
It's recommended to export your browser's cookies for gallery-dl to use.

Please check [here](https://github.com/mikf/gallery-dl#configuration) to understand how to configurate your gallery-dl.

When using `gallery-dl.conf`, be sure to drag it inside cool-tsih-bot folder in case you're on Windows. If you're on Linux just put it to `/etc/`
