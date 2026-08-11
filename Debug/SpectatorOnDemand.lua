COM_AddCommand("spectator_od", function(p)
	if (p.spectator)
		p.spectator = false
		P_KillMobj(p.realmo)
		return
	end
	p.spectator = true
end)