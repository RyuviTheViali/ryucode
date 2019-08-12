do return end -- No longer necessary

reviver = reviver or {}
reviver.PlayerData = reviver.PlayerData or {}
reviver.PlayerDeathTracker = function(p,a,d)
	reviver.PlayerData[p] = {
		["ActiveWeapon"] = p:GetActiveWeapon():GetClass(),
	}
end
hook.Add("DoPlayerDeath","reviver.PlayerDeathTracker",reviver.PlayerDeathTracker)

concommand.Add("revive",function(p,c,a,s)
	if p:Alive() then return end
	local ang,pos,wep = p:EyeAngles(),p:GetPos(),"none"
	if reviver and reviver.PlayerData and reviver.PlayerData[p] then
		wep = reviver.PlayerData[p].ActiveWeapon
	end
	p:Spawn()
	p:SetPos(pos)
	p:SetEyeAngles(ang)
	p:Give(wep)
	p:SelectWeapon(wep)
end)