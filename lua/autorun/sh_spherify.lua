spi = spi or {}
spi.persist = spi.persist or {}
spi.spheres = spi.spheres or {}
spi.netstring = "spi-network"
spi.dampening = true
spi.debug = false

spi.defaults = {
	eyes            = {"•","•"},
	mouth           = "v",
	nametag         = "",
	physicsmaterial = "glassbottle",
	jumped          = false,
	speed           = false,
	slow            = false,
	color           = Color(255,255,255,255),
	eyecolor        = Color(255,255,255,255),
	mouthcolor      = Color(255,255,255,255),
	nametagcolor    = Color(255,255,255,255),
	scale           = 1,
	speedmultiplier = 1,
	jumpmultiplier  = 1,
	physicsmass     = 8
}

spi.nosend = {
	physicsmaterial = true,
	jumped          = true,
	speed           = true,
	slow            = true,
	color           = true,
	speedmultiplier = true,
	jumpmultiplier  = true,
	physicsmass     = true
}

spi.hardreset        = true
spi.persistancereset = false

if SERVER then
	do util.AddNetworkString(spi.netstring) end
end

function spi:HardReset()
	local recreation = {}
	
	for k,v in pairs(self.spheres) do
		if v:IsValid() and v:GetClass() == "prop_physics" then
			recreation[k] = v
			v:Remove()
		else
			v = nil
		end
	end
	
	if self.Refresh then
		self:Refresh()
	else
		net.Start(self.netstring)
			net.WriteString("refresh")
			net.WriteTable({self.spheres})
		net.Broadcast()
	end
	
	if self.persistancereset then
		self.persist = {}
		
		if self.RefreshPersistant then
			self:RefreshPersistant()
		else
			net.Start(self.netstring)
				net.WriteString("refresh")
				net.WriteTable({self.persist})
			net.Broadcast()
		end
	end
	
	if SERVER then
		for k,p in pairs(player.GetAll()) do
			pac.TogglePartDrawing(p,true)
			
			p:SetNoDraw(false)
			
			if p:GetCollisionGroup() == COLLISION_GROUP_IN_VEHICLE then
				p:SetCollisionGroup(p.spi_collision_original or COLLISION_GROUP_PLAYER)
			end
			
			if p.spherify_weapon then
				p:SelectWeapon(p.spi_weapon or "none")
			end
			
			for k,v in pairs(recreation) do
				self:Create(k)
			end
		end
	end
end

if SERVER and spi.hardreset then
	spi:HardReset()
end

function spi:Refresh()
	if SERVER then
		local s = self.spheres
		
		for k,v in pairs(s) do
			spi:Profiler(k,v)
			if not k:IsValid() or not v:IsValid() or v == NULL then
				s[k] = nil
			end
		end
		
		for k,v in pairs(player.GetAll()) do
			if v.sphere and v.sphere:IsValid() then
				s[v] = v.sphere
			end
		end
		
		net.Start(self.netstring)
			net.WriteString("refresh")
			net.WriteTable({s})
		net.Broadcast()
	else
		net.Start(self.netstring)
			net.WriteString("requestrefresh")
			net.WriteTable({})
		net.SendToServer()
	end
end

function spi:RefreshPersistant(specific)
	if SERVER then
		local s = {}
		
		for k,v in pairs(self.persist) do
			if specific and specific ~= k then continue end
			
			s[k] = s[k] or {}
			
			for kk,vv in pairs(v) do
				if not self.nosend[kk] then
					s[k][kk] = vv
				end
			end
		end
		
		if specific then
			s["spec"] = specific
		end
		
		net.Start(self.netstring)
			net.WriteString("refreshpersistant")
			net.WriteTable({s})
			net.WriteBool(true)
		net.Broadcast()
		
		spi:Profiler("Refreshed Persistant Data")
	else
		net.Start(self.netstring)
			net.WriteString("requestrefreshpersistant")
			net.WriteTable({})
		net.SendToServer()
	end
end

function spi:Profiler(...)
	if self.debug then
		print("[SPI] >>",unpack{...})
	end
end

function spi:Create(p)
	if CLIENT then
		spi:SetNetData("create",true)
		return
	end
	
	if spi.spheres[p] and spi.spheres[p]:IsValid() then
		spi.spheres[p]:Remove()
	end
	
	local vel = p:GetVelocity()
	
	local s = ents.Create("prop_physics")
	s:SetPos(p:GetPos()+Vector(0,0,9.5))
	s:SetAngles(Angle())
	s:SetModel("models/pac/default.mdl")
	s:Spawn()
	s:CallOnRemove("FreePlayerFromParent",function(e,p)
		for k,v in pairs(e:GetChildren()) do
			if v:IsValid() then
				v:SetParent(nil)
			end
		end
		
		spi:Remove(p)
	end,p)
	s:PhysicsInitSphere(8,spi.defaults.physicsmaterial)
	
	local phys = s:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
		phys:SetVelocity(vel)
	end
	
	s:SetRenderMode(RENDERMODE_TRANSALPHA)
	s:CPPISetOwner(p)
	
	p:SetPos(s:GetPos()+Vector(0,0,-s:OBBMaxs().z))
	p:DeleteOnRemove(s)
	p:SetNoDraw(true)
	pac.TogglePartDrawing(p,false)
	p.spi_collision_original = p:GetCollisionGroup() == COLLISION_GROUP_PLAYER and p:GetCollisionGroup() or COLLISION_GROUP_PLAYER
	p:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	p.spi_weapon = p:GetActiveWeapon():IsValid() and p:GetActiveWeapon():GetClass()
	p:SetSuppressPickupNotices(true)
	p:Give("none")
	p:SetSuppressPickupNotices(false)
	p:SelectWeapon("none")
	
	p.sphere = s
	self.spheres[p] = s
	
	if not self.persist[p] then
		self.persist[p] = {}
		
		for k,v in pairs(self.defaults) do
			self.persist[p][k] = v
		end
	end
	
	for k,v in pairs(self.defaults) do
		local ip = self.persist[p]
		
		if k == "color" then
			if s:IsValid() then
				s:SetColor(ip[k] or v)
			end
		else
			s[k] = ip[k] or v
		end
	end
	
	timer.Simple(0.1,function()
		if s:IsValid() then
			s:SetColor(self.persist[p] and self.persist[p].color or spi.defaults.color)
			local phys = s:GetPhysicsObject()
			if phys and phys:IsValid() then
				phys:SetMaterial(self.persist[p] and self.persist[p].physicsmaterial or self.defaults.physicsmaterial)
				phys:SetMass    (self.persist[p] and self.persist[p].physicsmass     or self.defaults.physicsmass    )
			end
		end
		
		self:Refresh()
		
		timer.Simple(0.2,function()
			spi.netpaths.scale(p,{self.persist[p] and self.persist[p].scale or self.defaults.scale})
		end)
	end)
	self:Profiler("Created Sphere",s)
	return s
end

function spi:Remove(p)
	if CLIENT then
		spi:SetNetData("remove",true)
		return
	end
	
	if self.spheres[p]:IsValid() then
		self.spheres[p]:Remove()
		self.spheres[p] = nil
	else
		self.spheres[p] = nil
	end
	
	self:Refresh()
	
	pac.TogglePartDrawing(p,true)
	p:SetNoDraw(false)
	
	if p:GetCollisionGroup() == COLLISION_GROUP_IN_VEHICLE then
		p:SetCollisionGroup(p.spi_collision_original)
	end
	
	if p.spherify_weapon then
		p:SelectWeapon(p.spi_weapon)
	end
	
	self:Profiler("Removed Sphere",p)
end

function spi:SetAttribute(p,a,data)
	if CLIENT then
		spi:SetNetData("setattr",{a=a,data=data})
		return
	end
	
	self.persist[p][a] = data
	self:RefreshPersistant(p)
	
	self:Profiler("Set Attribute",a,"with data [",unpack(type(data) == "table" and data or {data}),"] for",p)
end

function spi:Hook(hid,where,qq)
	if where then
		hook.Add(hid,"Spherify"..hid,qq)
		
		self:Profiler("Added Hook",hid)
	end
end

function spi:UnHook(hid,where)
	if where then
		hook.Remove(hid,"Spherify"..hid)
		
		self:Profiler("Removed Hook",hid)
	end
end

function spi:SetNetData(pl,id,data)
	data = type(data) == "table" and data or {data}
	data.p = data.p or pl
	
	net.Start(self.netstring)
		net.WriteString(id)
		net.WriteTable(data)
	net[CLIENT and "SendToServer" or "Send"](pl or player.GetAll())
	
	self:Profiler("Set Net Data",id,"with data [",unpack(data),"] for",pl)
end

spi.SetupMove = function(p,d,c)
	local s = p.sphere
	
	if not s or not s:IsValid() then return end
	
	local b = d:GetButtons()
	d:SetVelocity(s:GetVelocity())
	d:SetOrigin(s:GetPos())
	
	if SERVER then
		if not p:Alive() then spi:Remove(p) end
		if not s or not s:IsValid() then return end
		
		local wep = p:GetActiveWeapon() or nil
		if wep and wep:GetClass() ~= "none" then p:SelectWeapon("none") end
		
		d:SetVelocity(s:GetVelocity())
		d:SetOrigin(s:GetPos())
		
		local spdmlt,jmpmlt,scale = spi.persist[p].speedmultiplier,spi.persist[p].jumpmultiplier,spi.persist[p].scale
		local ea    = Angle(0,p:EyeAngles().y,0)
		local speed = bit.band(b,IN_SPEED) > 0
		local slow  = bit.band(b,IN_WALK) > 0
		local mult  = speed and 24*scale or (slow and 4*scale or 8*scale)
		local fore,back,left,right = bit.band(b,IN_FORWARD) > 0,bit.band(b,IN_BACK) > 0,bit.band(b,IN_MOVELEFT) > 0,bit.band(b,IN_MOVERIGHT) > 0
		local phys  = s:GetPhysicsObject()
		local vel   = phys:GetVelocity()
		
		if speed ~= s.speed then s.speed = speed end
		if slow  ~= s.slow  then s.dlow = slow   end
		
		if not phys or not phys:IsValid() then spi:Remove(p) end
		
		if left  then vel = vel-ea:Right()*mult*spdmlt   end
		if right then vel = vel+ea:Right()*mult*spdmlt   end
		if fore  then vel = vel+ea:Forward()*mult*spdmlt end
		if back  then vel = vel-ea:Forward()*mult*spdmlt end
		
		if not fore and not back and not left and not right and spi.dampening then vel = Vector(vel.x*0.97,vel.y*0.97,vel.z) end
		
		local onground = util.TraceLine({start=s:GetPos(),endpos=s:GetPos()+Vector(0,0,-1)*(10*scale),filter=s,mask=MASK_ALL}).Hit
		
		if onground and bit.band(b,IN_JUMP) > 0 and not s.jumped then
			s.jumped = true
			vel      = vel+Vector(0,0,s.speed and 1024*scale or (s.slow and 128*scale or 256*scale))*jmpmlt
			
			s:EmitSound("physics/glass/glass_bottle_impact_hard"..math.random(1,2)..".wav",75,not s.speed and math.random(95,105) or math.random(65,75),1,CHAN_AUTO)
			
			timer.Simple(0.5,function() s.jumped = false end)
		end
		
		phys:SetVelocity(vel)
		
		b = bit.band(b,IN_SPEED)
		b = bit.bor(b,IN_DUCK)
		
		d:SetButtons(b)
		d:SetForwardSpeed(0)
		d:SetUpSpeed(0)
		d:SetSideSpeed(0)
	end
end
spi:Hook("SetupMove",CLIENT or SERVER,spi.SetupMove)

spi.AllowPlayerPickup = function(p,e)
	local s = spi.spheres[p] or NULL
	
	if not s or not s:IsValid() then return end
	if s == e then return false end
end
spi:Hook("AllowPlayerPickup",SERVER,spi.AllowPlayerPickup)

spi.netpaths = {
	["refresh"] = function(p,d) if SERVER then return end spi.spheres = d end,
	["requestrefresh"] = function(p,d) if CLIENT then return end spi:Refresh() end,
	["refreshpersistant"] = function(p,d)
		if SERVER then return end
		
		local s,specific = d,d["spec"]
		
		if specific then
			spi.persist = spi.persist or {}
			spi.persist[specific] = {}
			spi.persist[specific] = s[specific]
		else
			spi.persist = s
		end
	end,
	["requestrefreshpersistant"] = function(p,d) if CLIENT then return end spi:RefreshPersistant() end,
	["enable"]  = function(p,d) if CLIENT then return end if not spi.spheres[p] or not spi.spheres[p]:IsValid() then spi:Create(p) else spi:Remove(p) end end,
	["create"]  = function(p,d) if CLIENT then return end spi:Create(p) end,
	["remove"]  = function(p,d) if CLIENT then return end spi:Remove(p) end,
	["setattr"] = function(p,d) if CLIENT then return end spi:SetAttribute(p,d.a,d.data) end,
	["eyes"] = function(p,d)
		if CLIENT then return end
		
		spi:SetAttribute(p,"eyes",{d[1] or spi.defaults.eyes[1],d[2] or (d[1] or spi.defaults.eyes[1])})
	end,
	["mouth"] = function(p,d)
		if CLIENT then return end
		
		spi:SetAttribute(p,"mouth",d[1] or spi.defaults.mouth)
	end,
	["nametag"] = function(p,d)
		if CLIENT then return end
		
		spi:SetAttribute(p,"nametag",(d[2] and table.concat(d," ") or d[1]) or spi.defaults.nametag)
	end,
	["color"] = function(p,d)
		if CLIENT then return end
		
		local def = d[1] or spi.defaults.eyecolor.r
		
		spi:SetAttribute(p,"color",Color(d[1] or def,d[2] or def,d[3] or def,d[4] or 255))
		spi.spheres[p]:SetRenderMode(RENDERMODE_TRANSALPHA)
		spi.spheres[p]:SetColor(Color(d[1] or def,d[2] or def,d[3] or def,d[4] or 255))
	end,
	["facecolor"] = function(p,d)
		if CLIENT then return end
		
		local def = d[1] or spi.defaults.eyecolor.r
		
		spi:SetAttribute(p,"eyecolor"  ,Color(d[1] or def,d[2] or def,d[3] or def,d[4] or 255))
		spi:SetAttribute(p,"mouthcolor",Color(d[1] or def,d[2] or def,d[3] or def,d[4] or 255))
	end,
	["eyecolor"] = function(p,d)
		if CLIENT then return end
		
		local def = d[1] or spi.defaults.eyecolor.r
		
		spi:SetAttribute(p,"eyecolor",Color(d[1] or def,d[2] or def,d[3] or def,d[4] or 255))
	end,
	["mouthcolor"] = function(p,d)
		if CLIENT then return end 
		
		local def = d[1] or spi.defaults.eyecolor.r
		
		spi:SetAttribute(p,"mouthcolor",Color(d[1] or def,d[2] or def,d[3] or def,d[4] or 255))
	end,
	["nametagcolor"] = function(p,d)
		if CLIENT then return end 
		
		local def = d[1] or spi.defaults.eyecolor.r
		
		spi:SetAttribute(p,"nametagcolor",Color(d[1] or def,d[2] or def,d[3] or def,d[4] or 255))
	end,
	["allcolor"] = function(p,d)
		if CLIENT then return end 
		
		local def = d[1] or spi.defaults.eyecolor.r
		
		spi:SetAttribute(p,"eyecolor"    ,Color(d[1] or def,d[2] or def,d[3] or def,d[4] or 255))
		spi:SetAttribute(p,"mouthcolor"  ,Color(d[1] or def,d[2] or def,d[3] or def,d[4] or 255))
		spi:SetAttribute(p,"nametagcolor",Color(d[1] or def,d[2] or def,d[3] or def,d[4] or 255))
		spi:SetAttribute(p,"color"       ,Color(d[1] or def,d[2] or def,d[3] or def,d[4] or 255))
		
		spi.spheres[p]:SetRenderMode(RENDERMODE_TRANSALPHA)
		spi.spheres[p]:SetColor(Color(d[1] or def,d[2] or def,d[3] or def,d[4] or 255))
	end,
	["scale"] = function(p,d) --broken
		--[[if CLIENT then return end
		
		local s,c = spi.spheres[p] or NULL,d[1] or spi.defaults.scale
		
		if not s:IsValid() then return end
		
		if c == s:GetModelScale() then
			local phys = s:GetPhysicsObject()
			
			if phys and phys:IsValid() then
				phys:Wake()
			end
			return
		end
		s:SetPos(s:GetPos()+Vector(0,0,c*9.5))
		s:SetModelScale(c)
		s:PhysicsDestroy()
		s:PhysicsInitSphere(c,spi.persist[p] and spi.persist[p].physicsmaterial or spi.defaults.physicsmaterial)
		s:EnableCustomCollisions(true)
		s:SetFriction(c == 1 and 1 or c)
		local phys = s:GetPhysicsObject()
		if phys and phys:IsValid() then
			phys:SetMass(spi.persist[p] and spi.persist[p].physicsmass^c or spi.defaults.physicsmass^c)
			phys:SetMaterial(spi.persist[p] and spi.persist[p].physicsmaterial or spi.defaults.physicsmaterial)
			phys:Wake()
			phys:SetVelocity(phys:GetVelocity())
		end
		spi:SetAttribute(p,"scale",d[1] and tonumber(d[1]) or spi.defaults.scale)]]
	end,
	["mass"] = function(p,d)
		if CLIENT then return end
		
		local s = spi.spheres[p] or NULL
		local phys = s:GetPhysicsObject()
		if phys and phys:IsValid() then
			phys:SetMass(d[1] and tonumber(d[1]) or spi.defaults.physicsmass)
		end
		spi:SetAttribute(p,"physicsmass",d[1] and tonumber(d[1]) or spi.defaults.physicsmass)
	end,
	["speedmult"] = function(p,d)
		if CLIENT then return end 
		
		spi:SetAttribute(p,"speedmultiplier",d[1] and tonumber(d[1]) or spi.defaults.speedmultiplier)
	end,
	["jumpmult"] = function(p,d)
		if CLIENT then return end 
		
		spi:SetAttribute(p,"jumpmultiplier",d[1] and tonumber(d[1]) or spi.defaults.jumpmultiplier)
	end,
	["physmat"] = function(p,d)
		if CLIENT then return end
		
		local s = spi.spheres[p] or NULL
		local phys = s:GetPhysicsObject()
		
		if phys and phys:IsValid() then
			phys:SetMaterial(d[1] or spi.defaults.physicsmaterial)
		end
		
		spi:SetAttribute(p,"physicsmaterial",d[1] or spi.defaults.physicsmaterial)
	end
}

spi.GetNetData = function(l,p)
	local h,d = net.ReadString(),net.ReadTable()
	
	spi.netpaths[h](d.p,d[1])
	spi:Profiler("Got Net Data,",h,"with data [",unpack(d),"] for",d.p)
end
net.Receive(spi.netstring,spi.GetNetData)

if CLIENT then
	local m = LocalPlayer()
	
	surface.CreateFont("fff",{font="Helvetica",size=150,weight=0,antialias=true})
	
	spi.RenderView = function(p,pos,angles,fov,nearz,farz,...)
		local ss = spi.spheres[p] or NULL
		
		if ss:IsValid() and not pace.Active and not ctp.Enabled then
			local view = {}
			view.origin = ss:GetPos()
		 	view.angles = angles
		 	view.fov = fov
		 	view.nearz = nearz
		 	view.farz = farz
		 	return view
		end
	end
	spi:Hook("CalcView",CLIENT,spi.RenderView)
	
	local function RenderEyes(blink,e,mo,ec,mc)
		surface.SetFont("fff")
		
		local mw,mh         = surface.GetTextSize(mo)
		local bb            = blink >= 0.9 and (e[1] ~= " " and e[2] ~= " ")
		local noleye,noreye = e[1] == "" or e[1] == " ",e[2] == "" or e[2] == " "
		local leye          = bb and not noleye and ("-"):rep(utf8.len(e[1],1,nil)) or e[1]
		local reye          = bb and not noreye and ("-"):rep(utf8.len(e[2],1,nil)) or e[2]
		
		draw.SimpleTextOutlined(leye,"fff",-mw/2,0,ec,2,1,1,Color(0,0,0,255))
		draw.SimpleTextOutlined(mo  ,"fff",0    ,0,mc,1,1,1,Color(0,0,0,255))
		draw.SimpleTextOutlined(reye,"fff", mw/2,0,ec,0,1,1,Color(0,0,0,255))
	end
	
	spi.Render = function()
		--[[if LocalPlayer():GetNWEntity("box"):IsValid() and spi.spheres[LocalPlayer()] then --Switched to Boxify
			spi:SetNetData(LocalPlayer(),"enable",true)
		end]]
		
		local sor = {}
		
		for k,v in pairs(spi.spheres or {}) do
			if not v or not v:IsValid() then continue end
			
			sor[#sor+1] = {k,v}
		end
		
		table.sort(sor,function(a,b) return EyePos():Distance(a[2]:GetPos()) > EyePos():Distance(b[2]:GetPos()) end)
		
		for i=1,#sor do
			local k,v = sor[i][1],sor[i][2]
			
			if not v or not v:IsValid() then continue end
			
			local p     = v:GetPos()
			local q     = (spi.persist and spi.persist[k]) and spi.persist[k] or spi.defaults
			local blink = math.abs(math.sin((v:EntIndex()/8)+CurTime()*0.4)^450)
			local pos   = v:LocalToWorld(v:OBBCenter())+k:EyeAngles():Forward()*9.5*q.scale
			local ang   = (v:LocalToWorld(v:OBBCenter())-pos):Angle()
			
			ang:RotateAroundAxis(k:EyeAngles():Right(),90)
			ang:RotateAroundAxis(k:EyeAngles():Forward(),-90)
			ang:RotateAroundAxis(k:EyeAngles():Up(),180)
			
			cam.Start3D2D(pos,ang,0.1*q.scale)
				RenderEyes(blink,q.eyes,q.mouth,q.eyecolor,q.mouthcolor)
			cam.End3D2D()
			
			if k == m and not pace.Active and not ctp.Enabled then
				ang:RotateAroundAxis(k:EyeAngles():Up(),180)
				
				cam.Start3D2D(pos,ang,0.035*q.scale)
					RenderEyes(blink,q.eyes,q.mouth,q.eyecolor,q.mouthcolor)
				cam.End3D2D()
			else
				render.CullMode(MATERIAL_CULLMODE_CW)
					cam.Start3D2D(pos,ang,0.1*q.scale)
						RenderEyes(blink,q.eyes,q.mouth,q.eyecolor,q.mouthcolor)
					cam.End3D2D()
				render.CullMode(MATERIAL_CULLMODE_CCW)
			end
			if k ~= m or pace.Active or ctp.Enabled then
				local sa = ((v:LocalToWorld(v:OBBCenter())+Vector(0,0,12*q.scale))-EyePos()):Angle():Forward():Angle()
				
				sa:RotateAroundAxis(sa:Right(),90)
				sa:RotateAroundAxis(sa:Up(),-90)
				
				cam.Start3D2D(v:GetPos()+Vector(0,0,12*q.scale),sa,0.05*q.scale)
					draw.SimpleTextOutlined(q.nametag ~= "" and q.nametag or k:Nick():gsub("%^%d+",""):gsub("<(.-)=(.-)>",""),"fff",0,0,q.nametagcolor,1,1,1,Color(0,0,0,255))
				cam.End3D2D()
			end
		end
	end

	hook.Add("InitPostEntity","SPI Render init",fucntion()
		spi:Hook("PostDrawTranslucentRenderables",CLIENT,spi.Render)
	end)

	if LocalPlayer and LocalPlayer():IsValid() then
		spi:Hook("PostDrawTranslucentRenderables",CLIENT,spi.Render)
	end
	
	concommand.Add("spi",function(p,c,aa)
		local a,b = aa[1],aa
		
		table.remove(b,1)
		
		spi:SetNetData(p,a or "enable",a and {b} or true)
	end)
	
	hook.Add("ChatCommand","Spherify_Chat",function(com,paramstr,msg)
		if not (com == "spi" or com == "spherify") then return end
		
		local split = string.Explode(",",paramstr)
		local path  = split[1] ~= "" and split[1] or nil
		local data  = table.Copy(split)
		
		table.remove(data,1)
		
		spi:SetNetData(LocalPlayer(),path or "enable",path and {data} or true)
	end)
end
