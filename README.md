### Goals
Twitch2DCS was primarily created so that DCS World streamers who play in VR can interact with their viewers without the need to take off the HMD, or have Twitch chat hooked up to a text-to-speech engine. By allowing the chat to be visible within DCS, the immersion of the simulator does not have to be broken, and VR streamers can still interact with their audience. Twitch2DCS is not restricted to VR users and will work on a single 2D monitor and surround setups.

### Features
* Separate in-game chat window (similar to multiplayer chat)
* Easily installed to Saved Games/DCS directory
* In-game twitch chat communicate both read and write
* Join/Part messages
* Customizable hotkey
* Not dependent on mission start. The UI exists in every aspect of DCS (Main Menu, Config, Mission Editor, In-Mission) allowing you to always be connected to your audience.
* Random colors assigned to each user in chat.
* Colors are customizable in Mods/tech/Twitch2DCS/Options/optionsDb.lua
* Ability to use Multiplayer chat instead of Twitch chat. *Using Multiplayer chat will only allow you to see twitch chat during multiplayer games*.

### Installation
1. Extract the downloaded file and place both "Mods" and "Scripts" folders of version 1.11 inside Saved Games/DCS folder.
    -- Typically: (C:/Users/ _username_ /Saved Games/DCS) or open Windows Run with LWin+R and enter "%HOMEPATH%/Saved Games", without quotes.
2. Launch DCS World
3. Go to Options and find the Special tab for Twitch2DCS.
4. Enter your Twitch channel name and oAuthentication token from [TwitchApps.com](https://twitchapps.com/tmi/). Make sure to include the "oauth:" at the beginning.
    -- If DCS posts an error, don't worry, just close the dialog.
5. Restart DCS World.

_Upgrading from 1.0.3_
1. Find and remove all files of version 1.0.3 from Saved Games/DCS folder.
2. Extract the downloaded file and place both "Mods" and "Scripts" folders of version 1.11 inside Saved Games/DCS folder.
    -- Typically: (C:/Users/ _username_ /Saved Games/DCS) or open Windows Run with LWin+R and enter "%HOMEPATH%/Saved Games", without quotes.
3. Launch DCS World
4. Go to Options and find the Special tab for Twitch2DCS.
5. Confirm the previously inserted data is successfully ported.

_Troubleshooting_
If for any reason something doesn't want to work right or is posting errors, find and delete 'options.lua' inside Saved Games/DCS/Config then restart DCS World and start over with Installation steps.

### Support
ED Thread - https://forums.eagle.ru/showthread.php?t=178302