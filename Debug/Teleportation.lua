COM_AddCommand("warp",function(p, x,y,z, a)
	P_SetOrigin(p.mo,
		tonumber(x)*FU,
		tonumber(y)*FU,
		tonumber(z)*FU
	)
	local angle = FixedAngle(tonumber(a or "0")*FU)
	p.mo.angle = angle
end)
