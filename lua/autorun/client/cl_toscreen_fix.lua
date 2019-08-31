local vecmeta = debug.getregistry().Vector
vecmeta.ToScreenOld = vecmeta.ToScreen

local function GetFOV()
	if pace and pace:IsActive() then
		return pace.ViewFOV
	elseif ctp and ctp:IsEnabled() then
		return ctp:GetFOV()
	else
		return LocalPlayer():GetFOV()
	end
end

function vecmeta:ToScreen()
	local forward = (self-EyePos()):Angle():Forward()
	local dist    = 4*ScrH()/(6*math.tan(0.5*math.rad(GetFOV())))
	local dot     = EyeAngles():Forward():Dot(forward)
	
	if dot == 0 then
		return {
			x = 0,
			y = 0,
			visible = false,
			behind = false
		}
	end
	
	local v = (dist/dot)*forward
	local x = 0.5*ScrW()+EyeAngles():Right():Dot(v)
	local y = 0.5*ScrH()-EyeAngles():Up   ():Dot(v)
	
	local visible = not (dot < 0 or x < -2048 or x > ScrW()+2048 or y < -2048 or y > ScrH()+2048) and true or false
	
	if not visible then
		x,y = 999999,999999
	end
	
	return {
		x = x,
		y = y,
		visible = visible
	}
end