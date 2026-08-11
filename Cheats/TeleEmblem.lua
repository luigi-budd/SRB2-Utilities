local emblems = {}

addHook("MapChange",do
	emblems = {}
end)

addHook("MobjSpawn",function(em)
	if not (em and em.valid) then return end
	table.insert(emblems,em)
end,MT_EMBLEM)

COM_AddCommand("tpemblem",function(p,num)
	if gamestate ~= GS_LEVEL
		return
	end
	
	if #emblems == 0
		return
	end
	
	num = tonumber($)
	if num == nil
		return
	end
	
	if num < 0 then num = 0 end
	if num > #emblems then num = #emblems end
	
	if emblems[num] == nil
	or not (emblems[num] and emblems[num].valid)
		table.remove(emblems,num)
		return
	end
	
	P_SetOrigin(p.mo,emblems[num].x,emblems[num].y,emblems[num].z)
end)