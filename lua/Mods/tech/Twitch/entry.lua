local self_ID = "Twitch2DCS by Jabbers_"

declare_plugin(self_ID,
{
	image		 = "Tacview.png",
	installed	 = true, -- if false that will be place holder , or advertising
	dirName		 = current_mod_path,

	displayName	 = _("Twitch2DCS"),
	shortName	 =	 "Twitch2DCS" ,
	fileMenuName = _("Twitch2DCS"),

	version		 = "1.1.1 Beta",
	state		 = "installed",
	developerName= _("Jabbers_"),
	developerLink = _("https://github.com/jeffboulanger/twitch2dcs"),
	info = _("A simple way to stay connected to your audience within DCS."),
	
	Skins	=
	{
		{
			name	= "Twitch2DCS",
			dir		= "Theme"
		},
	},

	Options =
	{
		{
			name		= _("Twitch2DCS"),
			nameId		= "Twitch2DCS",
			dir			= "Options",
			CLSID		= "{Twitch2DCS options}"
		},
	},
})