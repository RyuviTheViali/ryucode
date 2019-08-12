function GetAimVec(x,y,width,height,angle,fov)
    local d,ff,rr,uu = 4*height/(6*math.tan(0.5*math.rad(fov))),angle:Forward(),angle:Right(),angle:Up()
    return (d*ff+(x-0.5*width)*rr+(0.5*height-y)*uu):GetNormalized()
end

function GetVecAim(dir,width,height,angle,fov)
	local l = 4*height/(6*math.tan(0.5*fov))
	local p = angle:Forward():Dot(dir)
	if p == 0 then return 0,0,-1 end
	local j = (l/p)*dir
	local x = 0.5*width+angle:Right():Dot(j)
	local y = 0.5*height-angle:Up():Dot(j)
	local v
	if p < 0 then v = -1 elseif x < 0 or x > width or y < 0 or y > height then v = 0 else v = 1 end
	return x,y,v
end