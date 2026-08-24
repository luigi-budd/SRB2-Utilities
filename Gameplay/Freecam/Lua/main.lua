/*
	TODO:
	-holding alt allows speed changes with mwheel
*/
rawset(_G,"clamp",function(minimum,value,maximum)
	return max(minimum,min(maximum,value))
end)
rawset(_G,"sign",function(a)
	return (a ~= 0) and (a < 0 and -1 or 1) or 0
end)
rawset(_G,"R_PointTo3DAngles",function(x1,y1,z1, x2,y2,z2)
	return R_PointToAngle2(x1,y1,x2,y2), R_PointToAngle2(
		0,z1,
		R_PointToDist2(x1,y1,x2,y2), z2
	)
end)
local function P_Lerp(frac, from, to)
	local final = from + FixedMul(to - from, frac)
	if abs(final - from) < 3
	and (final < 0 and from < 0)
		final = 0
	end
	return final
end

rawset(_G,"freecam_active",false)
local freecam_mo = nil
local freecam_cmd = {angleturn = 0, aiming = 0, oldbuttons = 0}
local freecam_vars = {
	fov = 0,
	fov_fixed = 0,
	zoomanim = 0,
	
	rotation = 0,
	rotation_fixed = 0,
	rotanim = 0,
	
	speed = 12*FU,
	friction = FU * 85/100,
	panfric = FU,
	
	frozen = false,
	hidehud = false,
	drawcontrols = true,
	playerlock = nil,
	noclip = true,
	
	x = 0, y = 0, z = 0,
	momx = 0, momy = 0, momz = 0,
	angle = 0, aiming = 0,
}
local freecam_buttons = {
	rollleft = 0, -- z
	zrelease = 0,
	rollright = 0, -- x
	xrelease = 0,
	
	ctrlmod = 0,
}
local freecam_view = nil

local cv_fov

local FOV_MAX = 170
local FOV_MIN = 5
local ROTATE_CAP = 170

local function CamFlip()
	return (freecam_mo and freecam_mo.valid and freecam_mo.flags2 & MF2_OBJECTFLIP) and -1 or 1
end

local function checkbuttons(ev, keydown)
	if not freecam_active then return end
	if chatactive then return end
	local key = ev.name
	local vars = freecam_vars
	local btn = freecam_buttons
	local eat = nil
	
	if not (ev.repeated)
		if key == "z"
		and not vars.frozen
			if keydown and not btn.rollleft
				if btn.zrelease
					btn.zrelease = 0
					vars.rotation = 0
					vars.rotanim = TICRATE/2
				else
					btn.rollleft = 1
					btn.zrelease = 6
				end
			elseif not keydown
				btn.rollleft = 0
			end
			eat = true
		end
		if key == "x"
		and not vars.frozen
			if keydown and not btn.rollright
				if btn.xrelease
					btn.xrelease = 0
					vars.rotation = 0
					vars.rotanim = TICRATE/2
				else
					btn.rollright = 1
					btn.xrelease = 6
				end
			elseif not keydown
				btn.rollright = 0
			end
			eat = true
		end
		
		if key == "c" and keydown
		and not vars.frozen
			vars.fov = 0
			vars.fov_fixed = 0
			
			vars.rotation = 0
			vars.rotation_fixed = 0
			vars.rotanim = 0
			
			vars.frozen = false
			vars.hidehud = false
			
			vars.speed = 12*FU
			vars.friction = FU * 85/100
			vars.panfric = FU
			vars.playerlock = nil
			vars.noclip = true
			
			eat = true
		end
		
		if key == "v" and keydown
			vars.frozen = not $
			eat = true
		end
		if key == "-" and keydown
			vars.hidehud = not $
			eat = true
		end
		if key == "=" and keydown
			vars.drawcontrols = not $
			eat = true
		end
		if key == "b" and keydown
			vars.noclip = not $
			eat = true
		end
		if key == "l" and keydown and not vars.frozen
			if (vars.playerlock and vars.playerlock.valid)
				vars.playerlock = nil
			else
				vars.playerlock = displayplayer
			end
			eat = true
		end
		
		if (mouse.buttons & MB_BUTTON3)
		and keydown and not vars.frozen
			vars.fov = 0
			vars.zoomanim = TICRATE / 2
		end
	end
	
	if key == "u" and keydown and not vars.frozen
		vars.speed = $ + 2*FU
		eat = true
	end
	if key == "i" and keydown and not vars.frozen
		vars.speed = max($ - 2*FU, 2*FU)
		eat = true
	end

	if key == "k" and keydown and not vars.frozen
		vars.friction = min($ + FU/100, FU)
		eat = true
	end
	if key == "j" and keydown and not vars.frozen
		vars.friction = max($ - FU/100, 0)
		eat = true
	end

	if key == "n" and keydown and not vars.frozen
		vars.panfric = min($ + FU/100, FU)
		eat = true
	end
	if key == "m" and keydown and not vars.frozen
		vars.panfric = max($ - FU/100, 0)
		eat = true
	end
	
	if key == "lctrl"
		btn.ctrlmod = (keydown) and 1 or 0
		eat = true
	end
	
	return eat
end
local function buttonthink()
	if not freecam_active then return end
	local vars = freecam_vars
	local btn = freecam_buttons
	
	if btn.rollleft
		vars.rotation = $ - 2
		vars.rotanim = TICRATE/2
		
		btn.rollleft = $ + 1
	end
	if btn.rollright
		vars.rotation = $ + 2
		vars.rotanim = TICRATE/2
		
		btn.rollright = $ + 1
	end
	
	if btn.zrelease
		btn.zrelease = $ - 1
	end
	if btn.xrelease
		btn.xrelease = $ - 1
	end
end
addHook("KeyDown", function(ev)
	return checkbuttons(ev, true)
end)
addHook("KeyUp", function(ev)
	return checkbuttons(ev, false)
end)

local function locktoplayer(p,cmd)
	if (freecam_vars.playerlock and freecam_vars.playerlock.valid)
		local cmo = freecam_mo
		local pmo = freecam_vars.playerlock.realmo
		local ha,va = R_PointTo3DAngles(
			cmo.x, cmo.y, cmo.z,
			pmo.x, pmo.y, pmo.z + pmo.height / 2
		)
		freecam_cmd.angleturn = ha >> 16
		freecam_cmd.aiming = va >> 16
	else
		freecam_vars.playerlock = nil
	end
end

local cv_invertmouse = CV_FindVar("invertmouse")
local panmom = {
	angle = 0,
	aiming = 0
}
local TICCMD_RECIEVED = 1 -- ouuuu
addHook("PlayerCmd",function(p, cmd)
	if not freecam_active then return end
	
	if freecam_vars.frozen then locktoplayer(p,cmd); return end
	if not cv_fov
		cv_fov = CV_FindVar("fov")
	end
	
	local zoommul = FixedDiv(cv_fov.value + freecam_vars.fov_fixed, cv_fov.value)
	zoommul = min($, FU)
	
	local anglechange = (mouse.dx * 8) << 16
	local aimingchange = (-mouse.dy << 19) * ((cv_invertmouse.value) and -1 or 1) * CamFlip()
	-- arrowkey looking
	if not freecam_buttons.ctrlmod
		if input.gameControlDown(GC_TURNLEFT)
			anglechange = $ - (640 << 16)
		end
		if input.gameControlDown(GC_TURNRIGHT)
			anglechange = $ + (640 << 16)
		end
		
		if input.gameControlDown(GC_LOOKUP)
			aimingchange = $ + ((1<<25) * CamFlip())
		end
		if input.gameControlDown(GC_LOOKDOWN)
			aimingchange = $ - ((1<<25) * CamFlip())
		end
	end
	/*
	printf(
		"angle: %f\n"..
		"aim:   %f\n"..
		"zoom:  %f\n"..
		"fang:  %f\n"..
		"faim:  %f",
		anglechange, aimingchange,
		zoommul,
		FixedMul(anglechange, zoommul), FixedMul(aimingchange, zoommul)
	)
	*/
	local final_angle = FixedMul(anglechange, zoommul)
	local final_aiming = FixedMul(aimingchange, zoommul)
	panmom.angle = $ + final_angle
	panmom.aiming = $ + final_aiming
	-- theres still a little more work to be done
	-- until the angles can be added to the ticcmd
		local panVec = Vec2.New(panmom.angle, panmom.aiming)
		/*
		if (
			AngleFixed(freecam_cmd.aiming<<16) >= 90*FU and
			AngleFixed(freecam_cmd.aiming<<16) <= 270*FU
		)
			panVec.x = -$
		end
		*/
		local rot = -FixedAngle(freecam_vars.rotation*FU)
		local sinrot = sin(rot)
		local cosrot = cos(rot)
		panVec = Vec2.New(
			FixedMul(panVec.x, cosrot) - FixedMul(panVec.y, sinrot),
			FixedMul(panVec.x, sinrot) + FixedMul(panVec.y, cosrot)
		)
		-- works well enough
		final_angle = (panVec.x >> 16)
		final_aiming = (panVec.y >> 16)
		
		-- deadzones
		if abs(final_angle) <= 8 then final_angle = 0; end
		if abs(final_aiming) <= 8 then final_aiming = 0; end
		
		freecam_cmd.angleturn = $ - final_angle
		freecam_cmd.aiming = $ + final_aiming
		if (input.gameControlDown(GC_CENTERVIEW))
			freecam_cmd.aiming = 0
			panmom.aiming = 0
		end
	--
	panmom.angle = P_Lerp(freecam_vars.panfric, $, 0)
	panmom.aiming = P_Lerp(freecam_vars.panfric, $, 0)
	
	locktoplayer(p,cmd)
	
	freecam_cmd.oldbuttons = (freecam_cmd.buttons or 0)
	freecam_cmd.forwardmove = cmd.forwardmove
	freecam_cmd.sidemove = cmd.sidemove
	freecam_cmd.buttons = cmd.buttons
	-- ..?
	if (input.gameControlDown(GC_JUMP))
		freecam_cmd.buttons = $|BT_JUMP
	end
	if (input.gameControlDown(GC_SPIN))
		freecam_cmd.buttons = $|BT_SPIN
	end
	
	if (freecam_cmd.forwardmove == 0 and freecam_cmd.sidemove == 0)
		local ford = 0
		local side = 0
		local shiftmod = freecam_buttons.ctrlmod
		if (
			input.gameControlDown(GC_FORWARD) or
			(input.gameControlDown(GC_LOOKUP) and shiftmod)
		) then
			ford = 50
		elseif (
			input.gameControlDown(GC_BACKWARD) or
			(input.gameControlDown(GC_LOOKDOWN) and shiftmod)
		) then
			ford = -50
		end
		if (
			input.gameControlDown(GC_STRAFELEFT) or
			(input.gameControlDown(GC_TURNLEFT) and shiftmod)
		) then
			side = -50
		elseif (
			input.gameControlDown(GC_STRAFERIGHT) or
			(input.gameControlDown(GC_TURNRIGHT) and shiftmod)
		) then
			side = 50
		end
		if (ford and side)
			local ang = R_PointToAngle2(0,0,side,ford)
			local maxford = abs(P_ReturnThrustY(ang,50))
			local maxside = abs(P_ReturnThrustX(ang,50))
			ford = clamp(-maxford, $, maxford)
			side = clamp(-maxside, $, maxside)
		end
		freecam_cmd.forwardmove = ford
		freecam_cmd.sidemove = side
	end
	
	cmd.forwardmove = 0
	cmd.sidemove = 0
	cmd.angleturn = p.cmd.angleturn &~TICCMD_RECIEVED
	cmd.aiming = p.cmd.aiming
	cmd.buttons = 0	
end)

addHook("ViewpointSwitch",function(p, next, forced)
	if not freecam_active then return end
	if not (freecam_mo and freecam_mo.valid) then return end
	local nmo = next.realmo
	if not (nmo and nmo.valid) then return end
	
	local ang = next.cmd.angleturn << 16
	local off = -256*FU
	freecam_view = {
		nmo.x + P_ReturnThrustX(nil, ang, off),
		nmo.y + P_ReturnThrustY(nil, ang, off),
		nmo.z + nmo.height * 2
	}
	freecam_cmd.angleturn = next.cmd.angleturn
	freecam_cmd.aiming = 0
	
	if freecam_vars.playerlock and freecam_vars.playerlock.valid
		freecam_vars.playerlock = next
	end
end)

local function SaveState()
	freecam_vars.x = freecam_mo.x
	freecam_vars.y = freecam_mo.y
	freecam_vars.z = freecam_mo.z
	freecam_vars.momx = freecam_mo.momx
	freecam_vars.momy = freecam_mo.momy
	freecam_vars.momz = freecam_mo.momz
	freecam_vars.angle = freecam_cmd.angleturn
	freecam_vars.aiming = freecam_cmd.aiming
end
local function LoadState(cam)
	P_SetOrigin(cam,
		freecam_vars.x, freecam_vars.y, freecam_vars.z
	)
	freecam_view = {freecam_vars.x, freecam_vars.y, freecam_vars.z}
	cam.momx = freecam_vars.momx
	cam.momy = freecam_vars.momy
	cam.momz = freecam_vars.momz
	
	freecam_cmd.angleturn = freecam_vars.angle
	freecam_cmd.aiming = freecam_vars.aiming
	cam.angle = freecam_cmd.angleturn << 16
	cam.aiming = freecam_cmd.aiming << 16
end

addHook("PostThinkFrame",do
	if not freecam_active then return end
	if not (freecam_mo and freecam_mo.valid)
	and (consoleplayer and consoleplayer.valid and consoleplayer.realmo.valid)
		freecam_mo = P_SpawnMobjFromMobj(consoleplayer.realmo, 0,0,0, MT_RAY)
		freecam_mo.height = camera.height
		freecam_mo.radius = camera.radius
		
		freecam_mo.tics = -1
		freecam_mo.fuse = -1
		freecam_mo.flags2 = $|MF2_DONTDRAW|(consoleplayer.realmo.flags2 & MF2_OBJECTFLIP)
		freecam_mo.flags = MF_NOCLIPTHING|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOTHINK|MF_SLIDEME
		
		freecam_mo.tracer = consoleplayer.realmo
		
		LoadState(freecam_mo)
		camera.chase = true
	end
	
	local cmd = freecam_cmd
	local cam = freecam_mo
	local vars = freecam_vars
	
	if freecam_view ~= nil
		P_SetOrigin(cam, freecam_view[1],freecam_view[2],freecam_view[3])
		freecam_view = nil
	end
	
	buttonthink()
	
	cam.angle = cmd.angleturn << 16
	cam.aiming = cmd.aiming << 16
	
	if vars.noclip
		cam.flags = $|(MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOCLIPTHING)
	else
		cam.flags = $ &~(MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOCLIPTHING)
	end
	
	local zoommul = FixedDiv(cv_fov.value + freecam_vars.fov_fixed, cv_fov.value)
	local speed = vars.speed
	local friction = vars.friction
	if vars.slowtoggle
		speed = $ / 12
		if zoommul > FU
			speed = FixedDiv($, zoommul)
		elseif zoommul < FU
			speed = FixedMul($, zoommul)
		end
	end
	
	local sine = {
		angle   = sin(cam.angle),
		angle_p = sin(cam.angle - ANGLE_90),
		aim     = sin(cam.aiming),
		aim_p   = sin(cam.aiming + ANGLE_90),
		roll    = sin(FixedAngle(vars.rotation*FU)),
	}
	local cosine = {
		angle   = cos(cam.angle),
		angle_p = cos(cam.angle - ANGLE_90),
		aim     = cos(cam.aiming),
		aim_p   = cos(cam.aiming + ANGLE_90),
		roll    = cos(FixedAngle(vars.rotation*FU)),
	}
	
	local forwardVec = Vec3.New(
		FixedMul(cosine.aim, cosine.angle),
		FixedMul(cosine.aim, sine.angle),
		sine.aim
	)
	local rightVec = Vec3.New(
		 FixedMul(sine.angle, cosine.roll) + FixedMul(cosine.angle, FixedMul(sine.aim, sine.roll)),
		-FixedMul(cosine.angle, cosine.roll) + FixedMul(sine.angle, FixedMul(sine.aim, sine.roll)),
		-FixedMul(cosine.aim, sine.roll)
	)
	local upVec = Vec3.New(
		-FixedMul(cosine.angle, FixedMul(sine.aim, cosine.roll)) + FixedMul(sine.angle, sine.roll),
		-FixedMul(sine.angle, FixedMul(sine.aim, cosine.roll)) - FixedMul(cosine.angle, sine.roll),
		 FixedMul(cosine.roll, cosine.aim)
	)
	local push = Vec3.New(0,0,0)
	push.x = $ + FixedMul(FixedMul(speed, FixedDiv(cmd.forwardmove*FU, 50*FU)), forwardVec.x)
	push.y = $ + FixedMul(FixedMul(speed, FixedDiv(cmd.forwardmove*FU, 50*FU)), forwardVec.y)
	push.z = $ + FixedMul(FixedMul(speed, FixedDiv(cmd.forwardmove*FU, 50*FU)), forwardVec.z)
	
	push.x = $ + FixedMul(FixedMul(speed, FixedDiv(cmd.sidemove*FU, 50*FU)), rightVec.x)
	push.y = $ + FixedMul(FixedMul(speed, FixedDiv(cmd.sidemove*FU, 50*FU)), rightVec.y)
	push.z = $ + FixedMul(FixedMul(speed, FixedDiv(cmd.sidemove*FU, 50*FU)), rightVec.z)
	
	local pushsign = 0
	if (cmd.buttons & BT_JUMP)
		pushsign = 1
	elseif (cmd.buttons & BT_SPIN)
		pushsign = -1
	end
	if pushsign ~= 0
		local spd = (speed / 2) * pushsign * CamFlip()
		push.x = $ + FixedMul(spd, upVec.x)
		push.y = $ + FixedMul(spd, upVec.y)
		push.z = $ + FixedMul(spd, upVec.z)
	end
	
	cam.momx = P_Lerp(FU - friction, $, 0)
	cam.momy = P_Lerp(FU - friction, $, 0)
	cam.momz = P_Lerp(FU - friction, $, 0)
	
	cam.momx = $ + push.x
	cam.momy = $ + push.y
	cam.momz = $ + push.z
	
	if vars.frozen
		cam.momx,cam.momy,cam.momz = 0,0,0
	end
	
	local f_in = (mouse.buttons & MB_SCROLLUP)
	local f_out = (mouse.buttons & MB_SCROLLDOWN)
	if not vars.frozen
	and not chatactive
		if f_in
			vars.fov = $ - 5
			vars.zoomanim = TICRATE / 2
		elseif f_out
			vars.fov = $ + 5
			vars.zoomanim = TICRATE / 2
		end
	end
	local cur_fov = cv_fov.value/FU
	if (cur_fov + vars.fov > FOV_MAX)
		vars.fov = $ - 5
	elseif (cur_fov + vars.fov < FOV_MIN)
		vars.fov = $ + 5
	end
	vars.fov_fixed = $ + FixedMul((vars.fov*FU) - $, FU / 3)
	displayplayer.fovadd = vars.fov_fixed
	vars.zoomanim = max($ - 1, 0)

	vars.rotanim = max($ - 1, 0)
	vars.rotation = max(-ROTATE_CAP, min(ROTATE_CAP, $))
	vars.rotation_fixed = $ + FixedMul((vars.rotation*FU) - $, FU / 3)
	displayplayer.viewrollangle = FixedAngle(vars.rotation_fixed)

	displayplayer.awayviewmobj = cam
	displayplayer.awayviewaiming = cam.aiming
	displayplayer.awayviewtics = 2
	cam.flags2 = ($ &~MF2_OBJECTFLIP)|(displayplayer.realmo.flags2 & MF2_OBJECTFLIP)
	
	if (cam.flags & MF_NOTHINK)
		P_XYMovement(cam)
		P_ZMovement(cam)
	end
	SaveState()
end)

addHook("HUD",function(v)
	if not freecam_active then return end
	if not (freecam_mo and freecam_mo.valid) then return end
	local cam = freecam_mo
	local vars = freecam_vars
	if (vars.hidehud) then return end
	
	local fovtotal = cv_fov.value
	fovtotal = FixedDiv($ + vars.fov*FU, $)
	
	local spacing = 50
	v.drawString(160 - spacing, 195,
		("x%.2f (%d)"):format(fovtotal, (cv_fov.value/FU + vars.fov)),
		V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "small-thin-center"
	)
	if vars.frozen
		v.drawString(160, 185,
			"frozen",
			V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "small-thin-center"
		)
	end
	if vars.playerlock and vars.playerlock.valid
		v.drawString(160 - spacing, 190,
			"lock-on: "..(vars.playerlock.name),
			V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "small-thin-center"
		)
	end
	
	v.drawString(160, 195,
		("%.2f fu/t"):format(vars.speed),
		V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "small-thin-center"
	)
	v.drawString(160, 190,
		("stiffness: %.2f%% move"):format((FU - vars.friction) * 100),
		V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "small-thin-center"
	)
	v.drawString(160 + spacing, 190,
		("%.2f%% pan"):format((vars.panfric) * 100),
		V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "small-thin-center"
	)
	v.drawString(160 + spacing, 195,
		("%dd"):format(vars.rotation),
		V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "small-thin-center"
	)
	
	if vars.rotanim
		local x = 160*FU
		local y = 100*FU
		local scale = FU/4
		local space = 24*scale
		local aligned = vars.rotation == 0
		local ang = FixedAngle(vars.rotation_fixed)
		
		v.drawScaled(x,y,scale, v.cachePatch(aligned and "FRCAM_BALLY" or "FRCAM_BALL"), 0)
		
		if aligned
			v.drawScaled(x + space,y,scale, v.cachePatch("FRCAM_ALIGNED"), 0)
			v.drawScaled(x - space,y,scale, v.cachePatch("FRCAM_ALIGNED"), V_FLIP)
		else
			v.drawScaled(x + space,y,scale, v.cachePatch("FRCAM_UNALIGNED"), V_50TRANS)
			v.drawScaled(x - space,y,scale, v.cachePatch("FRCAM_UNALIGNED"), V_50TRANS|V_FLIP)
			
			local step = 16*scale
			local space = space - 16*scale
			local ox = P_ReturnThrustX(nil, ang, space)
			local oy = -P_ReturnThrustY(nil, ang, space)
			for i = -7,7
				if not i then continue end
				local sign = (i < 0) and -1 or 1
				v.interpolate(i)
				v.drawScaled(
					x + P_ReturnThrustX(nil, ang, step*i) + ox*sign,
 					y - P_ReturnThrustY(nil, ang, step*i) + oy*sign,
					scale, v.cachePatch("FRCAM_BALL"), 0
				)
				v.interpolate(false)
			end
		end
	end
	if (vars.zoomanim)
		local res = 50
		local fov = (cv_fov.value/FU + vars.fov) - FOV_MIN
		local fovfrac = FixedDiv(fov*FU, (FOV_MAX - FOV_MIN)*FU)
		local x,y = 160*FU,100*FU
		local scale = FU/8
		local rad = (24 - 16)*FU
		local angle = 360 * fovfrac
		v.drawScaled(x,y,scale, v.cachePatch("FRCAM_BALL"), 0
		)
		for i = 0,res
			local frac = FixedDiv(i, res)
			local ang = FixedAngle(-FixedMul(angle, frac) + 90*FU)
			v.interpolate(i)
			v.drawScaled(
				x + FixedMul(rad, cos(ang)),
				y - FixedMul(rad, sin(ang)),
				scale, v.cachePatch("FRCAM_BALL"), 0
			)
			v.interpolate(false)
		end
	end
	
	if (vars.drawcontrols)
		local controls = {
			"[Z] - rotate left",
			"[X] - rotate right",
			"double tap either to reset",
			"",
			"[U/I] - change speed",
			"[J/K] - change speed stiffness",
			"[N/M] - change pan stiffness",
			"",
			"[C] - reset settings",
			"[V] - freeze camera",
			"[-] - hide hud",
			"[=] - hide side info",
			"[L] - player lock",
			"[B] - toggle noclipping",
			"",
			"[scroll wheel] - adjust zoom",
			"[mwheel down] - reset zoom",
		}
		local x = 2
		local y = 160 - (5 * #controls)
		for i = 1,#controls
			v.drawString(x,y, controls[i],
				V_ALLOWLOWERCASE|V_SNAPTOLEFT,
				"small-thin"
			)
			y = $ + 5
		end
		
		local todo = {
			{"x", freecam_mo.x, false},
			{"y", freecam_mo.y, false},
			{"z", freecam_mo.z, false},
			{"momx", freecam_mo.momx, false},
			{"momy", freecam_mo.momy, false},
			{"momz", freecam_mo.momz, false},
			"",
			{"yaw/ang", freecam_mo.angle, true},
			{"pitch/aim", freecam_mo.aiming, true},
			{"roll", freecam_vars.rotation_fixed, false},
		}
		local pos = {}
		for i = 1, #todo
			if todo[i] == ""
				pos[i] = ""; continue
			end
			
			local tag,num,isang = unpack(todo[i])
			if isang then num = AngleFixed($); end
			
			local sign = (num < 0 and "-" or "")
			local int = tostring(FixedInt(abs(num)))
			local frac = ("%.5f"):format(num & (FU - 1))
			frac = $:sub(3)
			if int:len() < 5
				int = ("\x86".."0"):rep(5 - int:len()) .."\x80".. $
			end
			int = ("\x80"..sign) .. $
			
			pos[i] = tag.." = "..int.."."..frac..((isang or tag == "roll") and "d" or "")
		end
		
		x = (320 - 2)
		y = 160 - (5 * #pos)
		for i = 1,#pos
			v.drawString(x,y, pos[i],
				V_ALLOWLOWERCASE|V_SNAPTORIGHT,
				"small-thin-right"
			)
			y = $ + 5
		end
		v.drawString(x,y, "noclip = "..(vars.noclip and "on" or "off"),
			V_ALLOWLOWERCASE|V_SNAPTORIGHT,
			"small-thin-right"
		)
	end
end,"game")

COM_AddCommand("freecam",function(p)
	if freecam_active
		if (freecam_mo and freecam_mo.valid)
			P_RemoveMobj(freecam_mo)
		end
		
		p.viewrollangle = 0
		p.awayviewmobj = nil
		p.awayviewaiming = 0
		p.awayviewtics = 0
		p.fovadd = 0
		
		freecam_active = false
		--input.ignoregameinputs = false
	else
		--input.ignoregameinputs = true
		
		if not (freecam_mo and freecam_mo.valid)
			freecam_mo = P_SpawnMobjFromMobj(p.realmo, 0,0,0, MT_RAY)
			freecam_mo.height = camera.height
			freecam_mo.radius = camera.radius
			P_SetOrigin(freecam_mo, camera.x,camera.y,camera.z - 41*freecam_mo.height/48)
			
			freecam_mo.tics = -1
			freecam_mo.fuse = -1
			freecam_mo.flags2 = $|MF2_DONTDRAW|(p.realmo.flags2 & MF2_OBJECTFLIP)
			freecam_mo.flags = MF_NOCLIPTHING|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOTHINK|MF_SLIDEME
			
			freecam_mo.angle = camera.angle
			freecam_mo.aiming = camera.aiming
			freecam_mo.tracer = p.realmo
			
			freecam_mo.momx = camera.momx
			freecam_mo.momy = camera.momy
			freecam_mo.momz = camera.momz
			
			freecam_cmd.angleturn = camera.angle >> 16
			freecam_cmd.aiming = camera.aiming >> 16
			camera.chase = true
		end
		freecam_active = true
		
		freecam_vars.fov = 0
		freecam_vars.fov_fixed = 0
		
		freecam_vars.rotation = 0
		freecam_vars.rotation_fixed = 0
		freecam_vars.rotanim = 0
		
		freecam_vars.frozen = false
		freecam_vars.hidehud = false
		freecam_vars.noclip = true
		
		freecam_vars.speed = 12*FU
		freecam_vars.friction = FU * 85/100
		freecam_vars.panfric = FU
		freecam_vars.playerlock = nil
	end
end,COM_LOCAL)