pacprotect = pacprotect or {}

if SERVER then
	
	util.AddNetworkString("pacpromsg")
	util.AddNetworkString("pacproret")
	util.AddNetworkString("pacproautoprev")
	util.AddNetworkString("pacprooveralert")
	
	pacprotect.getloggers = function()
		local p = {}
		for k,v in pairs(player.GetAll()) do
			if v.CheckUserGroupLevel and v:CheckUserGroupLevel("guardians") then
				p[#p+1] = v
			end
		end
		return p
	end
	
	net.Receive("pacpromsg",function(l,p)
		local msg = net.ReadString()
		Msg("[PAC Protect] "..p:Nick()..": "..msg.."\n")
		net.Start("pacpromsg")
			net.WriteEntity(p)
			net.WriteString(msg)
		net.Send(pacprotect.getloggers())
	end)
	
	net.Receive("pacproret",function(l,p)
		local functable,funcname,functrace,dbg,extra = net.ReadString(),net.ReadString(),net.ReadString(),net.ReadTable(),net.ReadTable()
		net.Start("pacproret")
			net.WriteEntity(p)
			net.WriteString(functable)
			net.WriteString(funcname)
			net.WriteString(functrace)
			net.WriteTable(dbg)
			net.WriteTable(extra)
		net.Send(pacprotect.getloggers())
	end)
	
	net.Receive("pacproautoprev",function(l,p)
		local functable,funcname,functrace,dbg,extra = net.ReadString(),net.ReadString(),net.ReadString(),net.ReadTable(),net.ReadTable()
		Msg("[PAC Protect] Auto-blocked "..functable.."."..funcname.." from executing on "..p:Nick().."'s client:\n")
		Msg("\tTrace:\n")
		Msg("\t\t"..functrace.."\n")
		Msg("\n\tArguments:\n")
		for k,v in pairs(extra) do
			Msg("\t\t\""..k.."\": \""..tostring(v).."\"\n")
		end
		net.Start("pacproautoprev")
			net.WriteEntity(p)
			net.WriteString(functable)
			net.WriteString(funcname)
			net.WriteString(functrace)
			net.WriteTable(dbg)
			net.WriteTable(extra)
		net.Broadcast()
	end)

	net.Receive("pacprooveralert",function(l,p)
		local functable,funcname = net.ReadString(),net.ReadString()
		Msg("[PAC Protect] Warning, function overwrite detected: "..functable.."."..funcname.." was overwritten on "..p:Nick().."'s client\n")
		net.Start("pacprooveralert")
			net.WriteEntity(p)
			net.WriteString(functable)
			net.WriteString(funcname)
		net.Broadcast()
	end)
else
	hook.Add("InitPostEntity","PACProtect_Init",function()

	pacprotect._old = pacprotect._old or {
		file  = {
			Open = file.Open,
			Read = file.Read,
			Write = file.Write
		},
		debug = {
			getupvalue = debug.getupvalue,
			getlocal = debug.getlocal
		}
	}
	
	pacprotect._new = {}
	
	pacprotect.sendmsg = function(msg)
		net.Start("pacpromsg")
			net.WriteString(msg)
		net.SendToServer()
	end
	
	pacprotect.checkisuserfunc = function(trace)
		if trace.source:find(_G.LocalPlayer():SteamID()) or
		   trace.source:find(_G.LocalPlayer():Nick()) or
		   trace.source:find(_G.LocalPlayer():RealName()) or not
	   	   trace.source:find(".lua") then
			return true
		end
		return false
	end
	
	pacprotect.sendlog = function(functable,funcname,functrace,dbg,extra)
		if not pacprotect.checkisuserfunc(dbg) then return end
		if _G.LocalPlayer().CheckUserGroupLevel and _G.LocalPlayer():CheckUserGroupLevel("owners") then return end
		timer.Simple(0.25,function()
			net.Start("pacproret")
				net.WriteString(functable)
				net.WriteString(funcname)
				net.WriteString(functrace)
				net.WriteTable({
					currentline = dbg.currentline,
					isvararg = dbg.isvararg,
					lastlinedefined = dbg.lastlinedefined,
					linedefined = dbg.linedefined,
					name = dbg.name,
					namewhat = dbg.namewhat,
					nparams = dbg.nparams,
					nups = dbg.nups,
					short_src = dbg.short_src,
					source = dbg.source,
					what = dbg.what
				})	
				net.WriteTable(extra ~= nil and istable(extra) and {extra} or {})
			net.SendToServer()
		end)
	end
	
	pacprotect.autopreventlog = function(functable,funcname,functrace,dbg,extra)
		timer.Simple(0.25,function()
			net.Start("pacproautoprev")
				net.WriteString(functable)
				net.WriteString(funcname)
				net.WriteString(functrace)
				net.WriteTable({
					currentline = dbg.currentline,
					isvararg = dbg.isvararg,
					lastlinedefined = dbg.lastlinedefined,
					linedefined = dbg.linedefined,
					name = dbg.name,
					namewhat = dbg.namewhat,
					nparams = dbg.nparams,
					nups = dbg.nups,
					short_src = dbg.short_src,
					source = dbg.source,
					what = dbg.what
				})	
				net.WriteTable(extra ~= nil and istable(extra) and {extra} or {})
			net.SendToServer()
		end)
	end
	
	pacprotect.overwritealert = function(functable,funcname)
		timer.Simple(0.25,function()
			net.Start("pacprooveralert")
				net.WriteString(functable)
				net.WriteString(funcname)
			net.SendToServer()
		end)
	end
	
	pacprotect.checklevel = function(gro)
		local lvl = _G.LocalPlayer().CheckUserGroupLevel and _G.LocalPlayer():CheckUserGroupLevel(gro)
		local crl = _G.LocalPlayer().CanRunLua and _G.LocalPlayer():CanRunLua() or false
		return lvl and crl
	end
	
	pacprotect.detour = function()
		for kk,vv in pairs(pacprotect._old.file) do
			pacprotect._new["file"] = pacprotect._new["file"] or {}
			_G["file"][kk] = function(...)
				local dbg = debug.getinfo(2)
				pacprotect.sendlog("file",kk,debug.traceback(),dbg,...)
				return vv(...)
			end
			pacprotect._new["file"][kk] = _G["file"][kk]
		end
		
		for kk,vv in pairs(pacprotect._old.debug) do
			pacprotect._new["debug"] = pacprotect._new["debug"] or {}
			_G["debug"][kk] = function(...)
				local dbg = debug.getinfo(2)
				pacprotect.sendlog("debug",kk,debug.traceback(),dbg,...)
				if not pacprotect.checklevel("guardians") and pacprotect.checkisuserfunc(dbg) then
					pacprotect.autopreventlog("debug",kk,debug.traceback(),dbg,...)
					return nil
				end
				return vv(...)
			end
			pacprotect._new["debug"][kk] = _G["debug"][kk]
		end
		pacprotect.sendmsg("Successfully applied pac protection")
	end
	
	local knownoverwrites = {}
	timer.Create("pacpro-overwritepro",15,0,function()
		for k,v in pairs(pacprotect._new) do
			for kk,vv in pairs(v) do
				local info = debug.getinfo(_G[k][kk])
				if info.func ~= vv and not (knownoverwrites[k] and knownoverwrites[k][kk] or false) then
					knownoverwrites[k] = knownoverwrites[k] or {}
					knownoverwrites[k][kk] = true
					pacprotect.overwritealert(k,kk)
				end
			end
		end
	end)
	
	pacprotect.detour()

	end)
end