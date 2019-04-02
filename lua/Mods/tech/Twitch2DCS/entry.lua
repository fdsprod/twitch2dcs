local self_ID = "Twitch2DCS"

declare_plugin(self_ID,
{
installed = true,
dirName = current_mod_path,
developerName = _("Jabbers"),
developerLink = _("https://github.com/jeffboulanger/twitch2dcs"),
displayName = _("Twitch2DCS"),
version = "1.11",
state = "installed",
info = _("A simple way to stay connected to your audience within DCS."),

Options = {
	{
		name = _("Twitch2DCS"),
		nameId = "Twitch2DCS",
		dir = "Options",
		CLSID = "{Twitch2DCS options}"},
	},
})

plugin_done()
