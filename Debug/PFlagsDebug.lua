local cv_pflags = CV_RegisterVar({
	name = "pflagsdebug",
	defaultvalue = "true",
	flags = CV_SHOWMODIF,
	PossibleValue = CV_TrueFalse
})

local getpstate = {
	[0] = "PST_LIVE",
	[1] = "PST_DEAD",
	[2] = "PST_REBORN",
}
local getdmg = {
	[0] = "None",
	[1] = "DMG_WATER",
	[2] = "DMG_FIRE",
	[3] = "DMG_ELECTRIC",
	[4] = "DMG_SPIKE",
	[5] = "DMG_NUKE",
	[128] = "DMG_INSTAKILL",
	[129] = "DMG_DROWNED",
	[130] = "DMG_SPACEDROWN",
	[131] = "DMG_DEATHPIT",
	[132] = "DMG_CRUSHED",
	[133] = "DMG_SPECTATOR",
}

local getcarry = {
	[0] = "none",
	[1] = "generic",
	[2] = "player",
	[3] = "nightsmode",
	[4] = "nightsfall",
	[5] = "brakgoop",
	[6] = "zoomtube",
	[7] = "ropehang",
	[8] = "macespin",
	[9] = "minecart",
	[10] = "rollout",
	[11] = "pterabyte",
	[12] = "dustdevil",
	[13] = "fan",
	[20] = "kart",
}
local charabilites = {
	[0] = "CA_NONE",
	[1] = "CA_THOK",
	[2] = "CA_FLY",
	[3] = "CA_GLIDEANDCLIMB",
	[4] = "CA_HOMINGTHOK",
	[5] = "CA_SWIM",
	[6] = "CA_DOUBLEJUMP",
	[7] = "CA_FLOAT",
	[8] = "CA_SLOWFALL",
	[9] = "CA_TELEKINESIS",
	[10] = "CA_FALLSWITCH",
	[11] = "CA_JUMPBOOST",
	[12] = "CA_AIRDRILL",
	[13] = "CA_JUMPTHOK",
	[14] = "CA_BOUNCE",
	[15] = "CA_TWINSPIN",
}
local charabilites2 = {
	[0] = "CA2_NONE",
	[1] = "CA2_SPINDASH",
	[2] = "CA2_GUNSLINGER",
	[3] = "CA2_MELEE",
}

local function drawflag(v,x,y,string,flags,onmap,offmap,align,flag)
	local map = offmap
	if flag
		map = onmap
	end
	
	v.drawString(x,y,string,flags|map,align)
end

addHook("HUD",function(v,p)
	if not (p and p.valid) then return end
	if not cv_pflags.value then return end

	v.drawString(100,50,"Charability1: "..(charabilites[p.charability] or p.charability),
		V_ALLOWLOWERCASE|V_PERPLAYER,"small-thin"
	)
	v.drawString(100,54,"Charability2: "..(charabilites2[p.charability2] or p.charability2),
		V_ALLOWLOWERCASE|V_PERPLAYER,"small-thin"
	)
	v.drawString(100,86,"Skin flags",V_ALLOWLOWERCASE|V_PERPLAYER,"small")
	drawflag(v,100,90,"SUP",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_SUPER)
	)		
	drawflag(v,115,90,"NSS",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_NOSUPERSPIN)
	)		
	drawflag(v,130,90,"NSD",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_NOSPINDASHDUST)
	)
	drawflag(v,145,86,string.format("%.2f",skins[p.skin].highresscale*100).."%",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_HIRES)
	)		
	drawflag(v,145,90,"HIR",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_HIRES)
	)		
	drawflag(v,160,90,"NSK",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_NOSKID)
	)		
	drawflag(v,175,90,"NSA",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_NOSPEEDADJUST)
	)		
	drawflag(v,190,90,"ROW",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_RUNONWATER)
	)		
	drawflag(v,205,90,"NJD",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_NOJUMPDAMAGE)
	)		
	drawflag(v,220,90,"STP",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_STOMPDAMAGE)
	)		
	drawflag(v,235,90,"MAR",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_MARIODAMAGE)
	)		
	drawflag(v,250,90,"MCH",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_MACHINE)
	)		
	drawflag(v,265,90,"DSH",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_DASHMODE)
	)		
	drawflag(v,100,94,"FSE",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_FASTEDGE)
	)		
	drawflag(v,115,94,"MAB",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_MULTIABILITY)
	)		
	drawflag(v,130,94,"NNR",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_NONIGHTSROTATION)
	)		
	drawflag(v,145,94,"NNS",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_NONIGHTSSUPER)
	)		
	drawflag(v,160,94,"SSP",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_NOSUPERSPRITES)
	)		
	drawflag(v,175,94,"SJB",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_NOSUPERJUMPBOOST)
	)		
	drawflag(v,190,94,"CBW",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_CANBUSTWALLS)
	)		
	drawflag(v,205,94,"NSA",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.charflags & SF_NOSHIELDABILITY)
	)		
	
	drawflag(v,100,60,"FC",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_FLIPCAM)
	)
	drawflag(v,110,60,"AM",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_ANALOGMODE)
	)
	drawflag(v,120,60,"DC",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_DIRECTIONCHAR)
	)
	drawflag(v,130,60,"AB",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_AUTOBRAKE)
	)
	drawflag(v,140,60,"GM",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_GODMODE)
	)
	drawflag(v,150,60,"NC",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_NOCLIP)
	)
	drawflag(v,160,60,"IV",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_INVIS)
	)
	drawflag(v,170,60,"ad",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_ATTACKDOWN)
	)
	drawflag(v,180,60,"sd",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_SPINDOWN)
	)
	drawflag(v,190,60,"jd",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_JUMPDOWN)
	)
	drawflag(v,200,60,"wd",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_WPNDOWN)
	)
	drawflag(v,210,60,"FS",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_FULLSTASIS)
	)
	drawflag(v,220,60,"SS",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_STASIS)
	)
	drawflag(v,230,60,"JS",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_JUMPSTASIS)
	)
	
	drawflag(v,100,70,"AA",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_APPLYAUTOBRAKE)
	)
	drawflag(v,110,70,"sj",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_STARTJUMP)
	)
	drawflag(v,120,70,"ju",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_JUMPED)
	)
	drawflag(v,130,70,"nj",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_NOJUMPDAMAGE)
	)
	drawflag(v,140,70,"sp",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_SPINNING)
	)
	drawflag(v,150,70,"ss",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_STARTDASH)
	)
	drawflag(v,160,70,"th",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_THOKKED)
	)
	drawflag(v,170,70,"sa",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_SHIELDABILITY)
	)
	drawflag(v,180,70,"gl",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_GLIDING)
	)
	drawflag(v,190,70,"bc",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_BOUNCING)
	)
	drawflag(v,200,70,"sl",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_SLIDING)
	)
	drawflag(v,210,70,"tc",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_TRANSFERTOCLOSEST)
	)
	drawflag(v,220,70,"nd",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_DRILLING)
	)
	drawflag(v,230,70,"go",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_GAMETYPEOVER)
	)
	drawflag(v,240,70,"it",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_TAGIT)
	)
	drawflag(v,250,70,"fs",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_FORCESTRAFE)
	)
	drawflag(v,260,70,"cc",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_CANCARRY)
	)
	drawflag(v,270,70,"fin",
		V_PERPLAYER,
		V_GREENMAP,V_REDMAP,
		"small",
		(p.pflags & PF_FINISHED)
	)
	v.drawString(270,74,
		"exiting "..p.exiting,
		V_PERPLAYER|(p.exiting and V_GREENMAP or V_REDMAP),
		"small"
	)
end,"game")