local self_ID = "Twitch2DCS by Jabbers"

declare_plugin(self_ID,
{
	image = "Tacview.png",
	installed = true,
	dirName = current_mod_path,
	developerName = _("Jabbers"),
	developerLink = _("https://github.com/jeffboulanger/twitch2dcs"),
	displayName = _("Twitch2DCS"),
	version = "1.1.3",
	state = "installed",
	info = _("A simple way to stay connected to your audience within DCS."),
	Skins = {
		{name = "Twitch2DCS", dir = "Theme"},
	},
	Options = {
		{name = _("Twitch2DCS"), nameId = "Twitch2DCS", dir = "Options", CLSID = "{Twitch2DCS options}"},
	},
})

plugin_done()