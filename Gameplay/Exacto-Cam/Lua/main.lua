local MYVERSION = 113
if rawget(_G, "ExactoCam_Version")
	if ExactoCam_Version == MYVERSION then return end
	if (ExactoCam_Version > MYVERSION) then return end
end
rawset(_G,"ExactoCam_Version", MYVERSION)
local TR = TICRATE

local function P_ClosestPointOnLine3D(p, lstart, lend)
	local t,d
	local V = Vec3.Sub(lend, lstart)
	local c = Vec3.Sub(p, lstart)
	
	-- d = R_PointToDist2(0, lend.z, R_PointToDist2(lend.x, lend.y, lstart.x, lstart.y), lstart.z)
	d = R_PointTo3DDist(lstart.x,lstart.y,lstart.z, lend.x,lend.y,lend.z)
	if d == 0 then return lstart; end
	local n = Vec3.Div(Vec3.New(V.x, V.y, V.z), d)
	t = Vec3.Dot(n, c)
	
	if t <= 0
		return lstart
	elseif t >= d
		return lend
	end
	
	n = $ * t
	return Vec3.Add(lstart, n)
end

local function SafeVecPos(v, mo, absolute)
	local destx = v.x
	local desty = v.y
	local destz = v.z
	if not absolute then
		destx = $ + mo.x
		desty = $ + mo.y
		destz = $ + mo.z
	end
	destz = clamp(mo.floorz + FU, $, mo.ceilingz - 30*FU)
	
	local oldmz = mo.momz
	mo.momz = destz - mo.z
	P_ZMovement(mo)
	if (mo.z ~= destz)
		mo.momz = oldmz; return false;
	end
	mo.momz = oldmz
	
	if not P_TryMove(mo, destx, desty, true)
		return false
	end
	
	return true
end

local cammo = nil

-- ANGLETURN is the angle used when positioning the camera...
local ANGLETURN = 0
-- ...ANGLETURN2 is the angle the camera faces
local ANGLETURN2 = 0
local AIMING = 0
addHook("PlayerCmd",function(p,cmd)
	if p ~= consoleplayer then return end
	
	ANGLETURN = cmd.angleturn<<16
	ANGLETURN2 = ANGLETURN
	AIMING = cmd.aiming<<16
	
	if (p.realmo.flags2 & MF2_TWOD or twodlevel)
		if cmd.sidemove == 0
			cmd.sidemove = cmd.forwardmove
		end
	end
end)
addHook("PlayerSpawn",function(p)
	if (p ~= consoleplayer) then return end
	if not p.realmo and p.realmo.valid then return end
	ANGLETURN = p.realmo.angle
	ANGLETURN2 = ANGLETURN
end)

local cv_camdist = CV_FindVar("cam_dist")
local cv_camheight = CV_FindVar("cam_height")
local cv_camrotate = CV_FindVar("cam_rotate")
local cv_chasecam = CV_FindVar("chasecam")
local exitingzoom = FU

local sidefrac = 0
local idletime = 0
local twodanim = 0

local blockingmobjs = {}
local movewasblocked = false

local dest_zoomfrac = FU
local zoomfrac = dest_zoomfrac
local ZOOM_ADJ = FU / 5
local ZOOM_MIN = FU / 10
local ZOOM_MAX = 8*FU

local ctrldown = false
addHook("KeyDown",function(ev)
	if isdedicatedserver then return end
	if (ExactoCam_Version > MYVERSION) then return end
	
	if ev.name == "lctrl" or ev.name == "rctrl"
		ctrldown = true
	end

	if ctrldown
		local eat = false
		if ev.name == "wheel 1 up"
			dest_zoomfrac = $ - ZOOM_ADJ
			eat = true
		end
		if ev.name == "wheel 1 down"
			dest_zoomfrac = $ + ZOOM_ADJ
			eat = true
		end
		if ev.name == "mouse3"
			dest_zoomfrac = FU
			eat = true
		end
		
		if dest_zoomfrac > ZOOM_MAX
			dest_zoomfrac = ZOOM_MAX
		elseif dest_zoomfrac < ZOOM_MIN
			dest_zoomfrac = ZOOM_MIN
		end
		if eat then return true; end
	end
end)
addHook("KeyUp",function(ev)
	if isdedicatedserver then return end
	if (ExactoCam_Version > MYVERSION) then return end
	
	if ev.name == "lctrl" or ev.name == "rctrl"
		ctrldown = false
	end
end)

local camerawasswitched = false
local VIEW_MAXANIM = 8
local viewpointswitch = {
	animation = 0,
	startpoint = {x=0,y=0,z=0, ang=0,aim=0}
}

addHook("ViewpointSwitch",function(p, next, forced)
	if (ExactoCam_Version > MYVERSION) then return end
	
	local nmo = next.realmo
	if not (nmo and nmo.valid) then return end
	
	viewpointswitch.animation = VIEW_MAXANIM
	viewpointswitch.startpoint.x = cammo.x
	viewpointswitch.startpoint.y = cammo.y
	viewpointswitch.startpoint.z = cammo.z
	viewpointswitch.startpoint.ang = cammo.angle
	viewpointswitch.startpoint.aim = cammo.aiming
end)

rawset(_G, "ExactoCam_Thinker", function(p, camera)
	if ExactoCam_Version > MYVERSION then return end
	
	if not (p and p.valid) then return end
	local me = p.realmo
	if not (me and me.valid) then return end
	if (p.spectator) then return end
	
	if not (cv_chasecam.value)
		if p.awayviewmobj == cammo
			p.awayviewmobj = nil
		end
		return
	end
	
	if ((p.awayviewtics > 0) and (p.awayviewmobj ~= cammo))
	or (camerawasswitched)
	-- or (p.awayviewtics == 0 and not cv_chasecam.value)
		if (p.awayviewaiming == AIMING) and not (freecam_active)
			p.awayviewaiming = 0
		end
		return
	end
	
	if (p.powers[pw_carry] == CR_NIGHTSFALL or p.powers[pw_carry] == CR_NIGHTSMODE) then return end
	
	if not (cammo and cammo.valid)
		cammo = P_SpawnMobjFromMobj(me, 0,0,0, MT_RAY)
		cammo.fuse = -1
		cammo.tics = -1
		cammo.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOSECTOR|MF_NOBLOCKMAP|MF_NOTHINK
		cammo.exactocam = true
	end
	cammo.height = 16 * me.scale
	cammo.radius = 4 * me.scale
	
	if p ~= consoleplayer
		ANGLETURN = p.cmd.angleturn << 16
		ANGLETURN2 = ANGLETURN
		AIMING = p.cmd.aiming << 16
	end
	ANGLETURN = $ + FixedAngle(cv_camrotate.value * FU)
	
	zoomfrac = P_Lerp(FU / 4, $, dest_zoomfrac)
	
	local camflip = P_MobjFlip(me)
	local camdist = FixedMul(cv_camdist.value, me.scale)
	camdist = FixedMul($, p.camerascale)
	camdist = FixedMul($, zoomfrac)
	camdist = FixedMul($, exitingzoom)
	camdist = $ + (20*FU - 20*me.scale)
	
	local camheight = FixedMul(cv_camheight.value, me.scale)
	camheight = FixedMul($, zoomfrac)
	camheight = $ - (16*FU - 16*me.scale)
	
	local shiftVec = Vec3.New(0,0,0)
	local focusPos = Vec3.MobjPosToVec(me)
	if camflip == 1
		focusPos.z = $ + ((41*P_GetPlayerHeight(p)/48) + camheight)
	else
		-- 20fu because srb2 offsets awayview z by that much for some reason
		-- times 2 because..?????!?!?!?!?!!!!!?!?!?
		focusPos.z = ($ + me.height) - 40*FU
		focusPos.z = $ - ((41*P_GetPlayerHeight(p)/48)) - camheight
	end
	
	local twod = (me.flags2 & MF2_TWOD or twodlevel)
	if twod
		twodanim = P_Lerp(FU/3, $, FU)
		
		camdist = $ * 2
		local runspeed = FixedMul(skins[p.skin].normalspeed * 6/10, me.scale)
		local speedfrac = min(abs(FixedDiv(me.momx, runspeed)), FU)
		local movefrac = abs(FixedDiv(p.cmd.sidemove*FU, 50*FU))
		movefrac = FixedMul($, speedfrac)
		
		local pushfactor = p.cmd.sidemove
		local dopush = abs(pushfactor) > 10
		if p.cmd.sidemove == 0 and abs(me.momx) > runspeed
			pushfactor = me.momx
			dopush = true
			movefrac = speedfrac
		end
		
		if dopush
		-- and P_CheckSight(cammo, me)
		and not movewasblocked
			sidefrac = P_Lerp(FixedMul(FU/10, movefrac), $, FU * sign(pushfactor))
			idletime = 0
		else
			if not P_CheckSight(cammo, me)
				sidefrac = P_Lerp(FU/15, $, 0)
			end
			idletime = $ + 1
			
			if idletime >= 3*TR
			or p.exiting
				sidefrac = P_Lerp(FU/15, $, 0)
			end
		end
		
		shiftVec = Vec3.Mul(Vec3.New(camdist * 2/5, 0,0), sidefrac)
		if me.momz * P_MobjFlip(me) < 0
			shiftVec.z = $ + me.momz
		end
		
		shiftVec.z = $ + FixedMul(camdist / 2, sin(AIMING))
		AIMING = 0
	else
		twodanim = P_Lerp(FU/3, $, 0)
		sidefrac = P_Lerp(FU/2, $, 0)
	end
	if twodanim
		ANGLETURN = P_Lerp(twodanim, $, ANGLE_90)
		ANGLETURN2 = ANGLETURN
	end
	
	movewasblocked = false
	
	local adjustVec = Vec3.Mul(Vec3.SphereToCartesian(ANGLETURN, AIMING), (-camdist))
	adjustVec = Vec3.Add(focusPos, adjustVec)
	
	-- clipping / poppercam
	cammo.flags = ($ &~(MF_NOCLIP|MF_NOCLIPHEIGHT))|(me.flags & (MF_NOCLIP|MF_NOCLIPHEIGHT))
	if not (me.flags & (MF_NOCLIP|MF_NOCLIPHEIGHT) or p.powers[pw_carry] == CR_NIGHTSMODE or twod)
	and (p.playerstate == PST_LIVE)
		focusPos:ToMobjPos(cammo, true, false)
		local steps = 270
		local offsetVec
		offsetVec = Vec3.Sub(Vec3.Add(adjustVec, shiftVec), focusPos)
		offsetVec = Vec3.Div(offsetVec, steps*FU)
		
		for i = 0, steps
			local destPos = Vec3.Add(focusPos, Vec3.Mul(offsetVec, (i*FU)))
			if not SafeVecPos(destPos, cammo, true)
				cammo.momx = (destPos.x) - cammo.x
				cammo.momy = (destPos.y) - cammo.y
				P_SlideMove(cammo)
				cammo.momx,cammo.momy,cammo.momz = 0,0,0
				movewasblocked = true
				break
			end
		end
	elseif (p.playerstate == PST_LIVE)
		local destPos = Vec3.Add(adjustVec, shiftVec)
		destPos:ToMobjPos(cammo, true, false)
	end
	
	if (viewpointswitch.animation)
		local frac = FU - FixedDiv(viewpointswitch.animation*FU, VIEW_MAXANIM*FU)
		frac = ease.inoutquad(frac, 0, FU)
		
		ANGLETURN2 = P_Lerp(frac, viewpointswitch.startpoint.ang, ANGLETURN2)
		AIMING = P_Lerp(frac, viewpointswitch.startpoint.aim, AIMING)
		
		local newpos = Vec3.New(
			P_Lerp(frac, viewpointswitch.startpoint.x, cammo.x),
			P_Lerp(frac, viewpointswitch.startpoint.y, cammo.y),
			P_Lerp(frac, viewpointswitch.startpoint.z, cammo.z)
		)
		newpos:ToMobjPos(cammo, true, false)
		cammo.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT
		
		viewpointswitch.animation = $ - 1
	end
	
	local updateangles = true
	
	-- invisicam
	if (p.playerstate == PST_LIVE)
		local checkplayers = (gametyperules & GTR_FRIENDLY) == 0
		local ray = P_SpawnMobjFromMobj(cammo,
			0,0,0, MT_RAY)
		ray.height = 8*FU
		ray.radius = 4*FU
		ray.flags = $|MF_NOCLIPTHING|MF_NOCLIPHEIGHT|MF_NOCLIP
		Vec3.ToMobjMom(Vec3.Mul(Vec3.SphereToCartesian(ANGLETURN,AIMING), (8*FU)), ray, true)
		
		local blockrad = ray.radius + me.radius
		for i = 0,255
			if not (ray and ray.valid) then break; end
			
			if abs(ray.x - me.x) <= blockrad
			and abs(ray.y - me.y) <= blockrad
			--and ((ray.z+ray.height >= me.z) and (ray.z <= me.z+me.height))
				P_RemoveMobj(ray)
				break
			end
			
			P_RailThinker(ray)
			searchBlockmap("objects", function(m, found)
				if not (found and found.valid and found.health) then return end
				if (found == me) then return end
				if (blockingmobjs[found]) then return end
				if (found.type == MT_PLAYER and not checkplayers) then return end
				if (found.flags & (MF_SOLID|MF_SCENERY|MF_NOTHINK) == 0) then return end
				if (found.hitlag) then return end
				
				if abs(ray.x - found.x) <= ray.radius + found.radius
				and abs(ray.y - found.y) <= ray.radius + found.radius
				and ((ray.z+ray.height >= found.z) and (ray.z <= found.z+found.height))
					return
				end
				
				blockingmobjs[found] = found
			end, ray)
		end
		if ray and ray.valid then P_RemoveMobj(ray); end
		
		local radius = me.radius * 3/2
		local height = me.height * 3/2
		for _,found in pairs(blockingmobjs)
			if not (found and found.valid) then continue end
			
			local obscuring = false
			local intersect = P_ClosestPointOnLine3D(Vec3.MobjPosToVec(found), adjustVec, focusPos)
			
			local angletome = R_PointToAngle2(found.x,found.y, me.x,me.y)
			local angdiff = AngleFixed(angletome - ANGLETURN)
			
			/*
			local linesintersect = false
			if (found.frame & FF_PAPERSPRITE or found.renderflags & RF_PAPERSPRITE)
				local a = found.angle
				local mstart = Vec3.New(
					found.x - FixedMul(found.radius, cos(a)),
					found.y - FixedMul(found.radius, sin(a)),
					found.z
				)
				local mend = Vec3.New(
					found.x + FixedMul(found.radius, cos(a)),
					found.y + FixedMul(found.radius, sin(a)),
					found.z
				)
				local mint = P_ClosestPointOnLine3D(intersect, mstart, mend)
				linesintersect = (mint.x == intersect.x) and (mint.y == intersect.y)
			end
			*/
			
			if (abs(intersect.x - found.x) <= found.radius + radius
			and abs(intersect.y - found.y) <= found.radius + radius
			and (
				found.z <= intersect.z + height -- check overhead
				and found.z+found.height*3/2 >= intersect.z -- check underhead
			))
			and (
				(angdiff <= 28*FU or angdiff >= (360 - 28)*FU)
				or R_PointToDist2(adjustVec.x,adjustVec.y, found.x,found.y) <= 64*me.scale
			)
			--or linesintersect
			or (abs(focusPos.x - found.x) <= found.radius + radius
			and abs(focusPos.y - found.y) <= found.radius + radius
			and (
				found.z <= focusPos.z + height -- check overhead
				and found.z+found.height*3/2 >= focusPos.z -- check underhead
			))
				obscuring = true
			end
			
			if obscuring
				found.alpha = P_Lerp(FU/3, $, FU/3)
			else
				found.alpha = FixedCeil(P_Lerp(FU/2, $, FU)*100)/100
				if found.alpha >= FU
					blockingmobjs[_] = nil
				end
			end
		end
	else
		local ha,va = R_PointTo3DAngles(cammo.x,cammo.y,cammo.z, focusPos.x,focusPos.y,focusPos.z)
		ANGLETURN2 = ha
		
		local aim = AngleFixed(va)
		if aim > 180*FU then aim = -(360*FU - $); end
		if aim > 50*FU and aim < 180*FU
			aim = 50*FU
		elseif aim < -50*FU
			aim = -50*FU
		end
		AIMING = FixedAngle(aim)
		
		camdist = $ * 3/2
		if (focusPos.z > me.floorz)
			local dist = R_PointTo3DDist(cammo.x,cammo.y,cammo.z, focusPos.x,focusPos.y,focusPos.z)
			if dist > camdist
				local adjust = dist - camdist
				local moveVec = Vec3.Mul(Vec3.SphereToCartesian(ha,va), adjust)
				moveVec:ToMobjPos(cammo, false, false)
			else
				local adjust = (dist - camdist) / 5
				local moveVec = Vec3.Mul(Vec3.SphereToCartesian(ha,va), adjust)
				moveVec:ToMobjPos(cammo, false, false)
			end
		end
	end
	
	if (p.exiting)
		exitingzoom = P_Lerp(FU/3, $, 2*FU)
		if not (multiplayer or netgame)
			updateangles = false
		end
	else
		exitingzoom = FU
	end
	
	-- done very last incase ANGLETURN2 was changed
	ANGLETURN2 = $ + FixedAngle(cv_camrotate.value * FU)
	
	if updateangles
		cammo.angle = ANGLETURN2
		cammo.aiming = AIMING
	end
	if cv_chasecam.value and not freecam_active
		if updateangles
			p.awayviewaiming = AIMING
		end
		p.awayviewmobj = cammo
		p.awayviewtics = 2
	elseif p.awayviewmobj == cammo
		p.awayviewmobj = nil
	end
end)

local blockingflags = (ML_IMPASSIBLE|ML_BLOCKMONSTERS)
addHook("MobjLineCollide",function(ray, line)
	if not ray.exactocam then return end
	if not line then return end
	
	if (line.flags & ML_TWOSIDED) and (line.flags & blockingflags)
		return false
	end
end,MT_RAY)

addHook("ThinkFrame",do
	if (gamestate ~= GS_LEVEL) then return end
	if (ExactoCam_Version > MYVERSION) then return end
	
	local p = displayplayer
	if not (p and p.valid) then return end
	local me = p.realmo
	if not (me and me.valid) then return end
	if (p.spectator) then return end
	
	-- check right before we set our exacto just incase it changes
	if ((cammo and cammo.valid) and (p.awayviewmobj ~= cammo) and p.awayviewtics)
		camerawasswitched = true
	end
end)
addHook("PostThinkFrame",do
	if (gamestate ~= GS_LEVEL) then return end
	if (ExactoCam_Version > MYVERSION) then return end
	ExactoCam_Thinker(displayplayer, camera)
	camerawasswitched = false
	
	local p = displayplayer
	if not (p and p.valid) then return end
	
	-- ummm why doesnt srb2 do this
	if (p.awayviewtics == 0) and (p.awayviewmobj ~= nil)
		p.awayviewmobj = nil
	end
end)