addHook("PlayerThink",function(p)
	if p.deadtimer >= 3*TICRATE
	and p.playerstate == PST_DEAD
		G_DoReborn(#p)
		p.deadtimer = 0
	end
end)