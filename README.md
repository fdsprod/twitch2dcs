### Goals
Twitch2DCS was primarily created so that DCS World streamers who played in VR could interact with Twitch chat without the need to take the HMD off, or have Twitch chat hooked up to a text-to-speech engine.   By allowing the chat to be visible within DCS the immersion of the game does not have to be broken, and VR streamers can still interact with the audience.  Twitch2DCS is not restricted to VR users, it will work for single monitor and surround setups.

### Current Features
* Separate in-game chat window (similar to multiplayer chat)
* Easily installed to Saved Games directory
* In-game twitch chat communicate both read and write
* Join/Part messages
* Customizable hotkey
* Not dependent on mission start.  The UI exists in every aspect of DCS (Main Menu, Config, Mission Editor, In-Mission) allowing you to always be connected to your twitch audience.

### Installation
1. Get the latest version of Twitch2DCS from [here](https://github.com/jeffboulanger/twitch2dcs/releases)
1. Extract the zip to your Saved Games DCS folder
 (C:\Users\ _username_ \Saved Games\DCS)
2. Open the file Twitch2DCSConfig.lua in the Config folder with your favorite text editor.
3. Add your Twitch username
4. Add your Twitch oauth key from [TwitchApps.com](http://twitchapps.com/tmi/) make sure you include the **"oauth:"** text
5. Launch DCS and enjoy communicating with Twitch from ingame.
