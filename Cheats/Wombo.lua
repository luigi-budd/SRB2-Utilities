local cv_wombo = CV_RegisterVar({
	name = "wombo",
	defaultvalue = "On",
	flags = CV_SHOWMODIF|CV_NETVAR,
	PossibleValue = {Off = 0, On = 1, PostThink = 2},
})

addHook("PlayerThink",function(p) if cv_wombo.value ~= 1 then return; end p.powers[pw_flashing] = 0; end)
addHook("PostThinkFrame", do
	if cv_wombo ~= 2 then return end
	for p in players.iterate
		p.powers[pw_flashing] = 0
	end
end)