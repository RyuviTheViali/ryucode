materials = materials or {}

materials.Replaced = {}

function materials.ReplaceTexture(path, to)
	if check then check(path, "string") end
	if check then check(to, "string", "ITexture", "Material") end

	path = path:lower()

	local mat = Material(path)

	if not mat:IsError() then

		local typ = type(to)
		local tex

		if typ == "string" then
			tex = Material(to):GetTexture("$basetexture")
		elseif typ == "ITexture" then
			tex = to
		elseif typ == "Material" then
			tex = to:GetTexture("$basetexture")
		else return false end

		materials.Replaced[path] = materials.Replaced[path] or {}	

		materials.Replaced[path].OldTexture = materials.Replaced[path].OldTexture or mat:GetTexture("$basetexture")
		materials.Replaced[path].NewTexture = tex

		mat:SetTexture("$basetexture",tex) 

		return true
	end

	return false
end


function materials.SetColor(path, color)
	if check then check(path, "string") end
	if check then check(color, "Vector") end

	path = path:lower()

	local mat = Material(path)

	if not mat:IsError() then
		materials.Replaced[path] = materials.Replaced[path] or {}
		materials.Replaced[path].OldColor = materials.Replaced[path].OldColor or mat:GetVector("$color")
		materials.Replaced[path].NewColor = color

		mat:SetVector("$color", color)

		return true
	end

	return false
end

function materials.SetAlpha(path,alpha)
	if check then check(path,"string") end
	if check then check(alpha,"number") end

	path = path:lower()

	local mat = Material(path)

	if not mat:IsError() then
		materials.Replaced[path] = materials.Replaced[path] or {}
		materials.Replaced[path].OldAlpha = materials.Replaced[path].OldAlpha or mat:GetFloat("$alpha")
		materials.Replaced[path].NewAlpha = alpha

		mat:SetFloat("$alpha",alpha)

		return true
	end

	return false
end

function materials.SetBump(path,bump)
	if check then check(path,"string") end
	if check then check(bump,"string") end

	path = path:lower()

	local mat = Material(path)

	if not mat:IsError() then
		materials.Replaced[path] = materials.Replaced[path] or {}
		materials.Replaced[path].OldBump = materials.Replaced[path].OldBump or mat:GetTexture("$bumpmap")
		materials.Replaced[path].NewBump = bump

		mat:SetTexture("$bumpmap",bump)	

		return true
	end

	return false
end

function materials.SetSpecular(path,specular)
	if check then check(path,"string") end
	if check then check(specular,"string") end

	path = path:lower()

	local mat = Material(path)
	
	if not mat:IsError() then
		materials.Replaced[path] = materials.Replaced[path] or {}
		materials.Replaced[path].OldSpecular = materials.Replaced[path].OldSpecular or mat:GetTexture("$envmap")
		materials.Replaced[path].NewSpecular = specular

		mat:SetTexture("$envmap",specular)	

		return true
	end

	return false
end

function materials.SetDetail(path,detail,scale)
	if check then check(path,"string") end
	if check then check(detail,"string") end
	if check then check(scale,"number") end

	path = path:lower()
	scale = tonumber(scale) or 4

	local mat = Material(path)
	
	if not mat:IsError() then
		materials.Replaced[path] = materials.Replaced[path] or {}
		materials.Replaced[path].OldDetail = materials.Replaced[path].OldDetail or mat:SetTexture("$detail")
		materials.Replaced[path].OldDetailScale = materials.Replaced[path].OldDetailScail or mat:SetFloat("$detailscale")
		materials.Replaced[path].NewDetail = detail
		materials.Replaced[path].NewDetailScale = scale

		mat:SetTexture("$detail",detail)
		mat:SetFloat("$detailscale",scale)

		return true
	end

	return false
end

function materials.RestoreAll()
	for name, tbl in pairs(materials.Replaced) do
		if 
			not pcall(function()
				if tbl.OldTexture then
					materials.ReplaceTexture(name,tbl.OldTexture)
				end

				if tbl.OldColor then
					materials.SetColor(name,tbl.OldColor)
				end
				
				if tbl.OldAlpha then
					materials.SetAlpha(name,tbl.OldAlpha)
				end
				
				if tbl.OldBump then
					materials.SetBump(name,tbl.OldBump)
				end
				
				if tbl.OldSpecular then
					materials.SetSpecular(name,tbl.OldSpecular)
				end
				
				if tbl.OldDetail then
					materials.SetDetail(name,tbl.OldDetail)
				end
			end) 
		then 
			print("Failed to restore: " .. tostring(name)) 
		end
	end
end
hook.Add("ShutDown", "material_restore", materials.RestoreAll)
