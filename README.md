#### Goals
Twitch2DCS was primarily created so that DCS World streamers who play in VR can interact with their viewers without the need to take off the HMD, or have Twitch chat hooked up to a text-to-speech engine. By allowing the chat to be visible within DCS, the immersion of the simulator does not have to be broken, and VR streamers can still interact with their audience. Twitch2DCS is not restricted to VR users and will work on a single 2D monitor and surround setups.

#### Features
* Separate in-game chat window (similar to multiplayer chat)
* Easily installed to Saved Games/DCS directory
* In-game twitch chat communicate both read and write
* Join/Part messages
* Customizable hotkey
* Not dependent on mission start. The UI exists in every aspect of DCS (Main Menu, Config, Mission Editor, In-Mission) allowing you to always be connected to your audience.
* Random colors assigned to each user in chat.
* Colors are customizable in Mods/tech/Twitch/Options/optionsDb.lua
* Ability to use Multiplayer chat instead of Twitch chat. *Using Multiplayer chat will only allow you to see twitch chat during multiplayer games*.

#### Installation
1. Find your Saved Games/DCS folder.
    * Typically: (C:/Users/_username_/Saved Games/DCS)
2. Extract the downloaded ZIP and place both "Mods" and "Scripts" folders inside Saved Games/DCS folder.
3. Launch DCS World
4. Go to Options and find the 'Special' tab for Twitch2DCS.
5. Enter your Twitch channel name and oAuthentication token from [TwitchApps.com](https://twitchapps.com/tmi/). Make include the "oauth:" at the beginning.
    * If DCS posts an error, just close the dialog.
6. Restart DCS World.

#### Upgrading
1. Extract the downloaded file and place both "Mods" and "Scripts" folders inside Saved Games/DCS folder.
    * Typically: (C:/Users/_username_/Saved Games/DCS)
2. Launch DCS World

#### Troubleshooting
If something isn't working right or is posting errors, a quick fix is find and delete 'options.lua' file inside Saved Games/DCS/Config. DCS World will then be restored to default settings allowing you to start over fresh with Installation steps.

#### Support
ED Thread - https://forums.eagle.ru/showthread.php?t=178302

#### Credits
* Created by Jeff ["Jabbers"](https://forums.eagle.ru/member.php?u=122130) Boulanger
* Maintained by Jeff ["Jabbers"](https://forums.eagle.ru/member.php?u=122130) Boulanger & Randy ["Tailhook"](https://forums.eagle.ru/member.php?u=90028) Thom
* Contributed code by [MOOSE Development Team](https://github.com/FlightControl-Master)