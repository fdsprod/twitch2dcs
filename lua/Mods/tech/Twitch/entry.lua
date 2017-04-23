local self_ID = "Twitch2DCS by Jabbers_"

declare_plugin(self_ID,
{
	image		 = "Tacview.png",
	installed	 = true, -- if false that will be place holder , or advertising
	dirName		 = current_mod_path,
	binaries	 =
	{
--		'Tacview',
	},

	displayName	 = _("Twitch2DCS"),
	shortName	 =	 "Twitch2DCS" ,
	fileMenuName = _("Twitch2DCS"),

	version		 = "1.0.1 Beta",
	state		 = "installed",
	developerName= _("Jabbers_"),
	info		 = _("Twitch2DCS oh baby!"),

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

plugin_done()