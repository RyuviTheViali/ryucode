AddCSLuaFile()
do
	if SERVER then
		util.AddNetworkString("sendvecdata")
		util.AddNetworkString("sendangdata")
		util.AddNetworkString("sendpardata")
		util.AddNetworkString("sendauxdata")
	end
end

paccams = paccams or {}
	
if SERVER then
	paccams.CameraData = {}
	
	local function CaptureData(sender,lane,data)
		local tab,new = data,{}
		table.Merge(paccams.CameraData,tab)
		for k,v in pairs(tab) do
			if type(v) ~= "table" then continue end
			new[k] = {}
			for kk,vv in pairs(v) do new[k][kk] = vv end
		end
		net.Start("send"..lane.."data") net.WriteTable(new) net.Broadcast()
	end
	
	net.Receive("sendvecdata",function(l,p) CaptureData(p,"vec",net.ReadTable()) end)
	net.Receive("sendangdata",function(l,p) CaptureData(p,"ang",net.ReadTable()) end)
	net.Receive("sendpardata",function(l,p) CaptureData(p,"par",net.ReadTable()) end)
	net.Receive("sendauxdata",function(l,p) CaptureData(p,"aux",net.ReadTable()) end)
	
	hook.Add("PlayerDisconnected","removedata",function(ply)
		for k,v in pairs(paccams.CameraData) do
			if k == ply:SteamID() then
				k = nil
			end
		end
	end)
end

PacCamColors = PacCamColors or {}
PacCamColors = {
	Color(255,0  ,0  ,255), -- red ---------- 1
	Color(255,128,0  ,255), -- orange ------- 2
	Color(255,255,0  ,255), -- yellow ------- 3
	Color(64 ,255,64 ,255), -- green -------- 4
	Color(64 ,128,255,255), -- blue --------- 5
	Color(128,64 ,255,255), -- purple ------- 6
	Color(128,128,128,255), -- grey --------- 7
	Color(255,180,180,255), -- light red ---- 8
	Color(255,200,150,255), -- light orange - 9
	Color(255,255,180,255), -- light yellow - 10
	Color(200,255,200,255), -- light green -- 11
	Color(180,200,255,255), -- light blue --- 12
	Color(200,180,255,255), -- light purple - 13
	Color(100,70 ,25 ,255), -- brown -------- 14
	Color(200,200,200,255), -- white-ish ---- 15
	Color(55 ,55 ,55 ,255), -- black-ish ---- 16
}

if CLIENT then
	hook.Add("InitPostEntity","PAC_CAMS_CLIENT_INIT",function()
		timer.Remove("pcamtimerclientVEC")
		timer.Remove("pcamtimerclientANG")
		timer.Remove("pcamtimerclientPAR")
		timer.Remove("pcamtimerclientAUX")
		hook.Remove("HUDPaint","pcams")
		
		local m = LocalPlayer()
		local ptd = ptd or {}
		local datalast = {}
		local function pcamaggrigate() local t = net.ReadTable() table.Merge(ptd,t) end
		net.Receive("sendvecdata",pcamaggrigate)
		net.Receive("sendangdata",pcamaggrigate)
		net.Receive("sendpardata",pcamaggrigate)
		net.Receive("sendauxdata",pcamaggrigate)
		
		paccams.Initialize = function()
			local tab = {[m:SteamID()]={
				["pos"]=pace.ViewPos,["ang"]=pace.ViewAngles*1,
				["active"]=pace.IsActive(),["fov"]=pace.ViewFOV,
				["w"]=ScrW(),["h"]=ScrH(),["parts"]=m.pac_parts and table.Count(pac.GetParts(true)) or -1,
				["slow"]=input.IsKeyDown(KEY_LCONTROL),["fast"]=input.IsKeyDown(KEY_LSHIFT)
			}}
			local t = tab[m:SteamID()]
			net.Start("sendvecdata") net.WriteTable({[m:SteamID()]={["pos"]=t["pos"]}})                                                              net.SendToServer()
			net.Start("sendangdata") net.WriteTable({[m:SteamID()]={["ang"]=t["ang"]}})                                                              net.SendToServer()
			net.Start("sendpardata") net.WriteTable({[m:SteamID()]={["active"]=t["active"],["fov"]=t["fov"],["slow"]=t["slow"],["fast"]=t["fast"]}}) net.SendToServer()
			net.Start("sendauxdata") net.WriteTable({[m:SteamID()]={["w"]=t["w"],["h"]=t["h"],["parts"]=t["parts"]}})                                net.SendToServer()
		end
		
		local function DataCheck(old,new)
			if old ~= nil and new ~= nil and old ~= new then
				return true
			end
			return false
		end
		
		local function pcamsdatanet()
			local datatable = {
				[m:SteamID()] = {
					["pos"] = pace.ViewPos,
					["ang"] = pace.ViewAngles*1,
					["active"] = pace.IsActive(),
					["fov"] = pace.ViewFOV,
					["slow"] = input.IsKeyDown(KEY_LCONTROL),
					["fast"] = input.IsKeyDown(KEY_LSHIFT),
					["w"] = ScrW(),
					["h"] = ScrH(),
					["parts"] = m.pac_parts and table.Count(pac.GetParts(true)) or -1,
				}
			}
			local t,l = datatable[m:SteamID()],datalast[m:SteamID()] or {}
			local po,an,ac,fo,sl,fa,ww,hh,pa = t["pos"],t["ang"],t["active"],t["fov"],t["slow"],t["fast"],t["w"],t["h"],t["parts"]
			if po ~= l["pos"] then
				local send = {}
				if DataCheck(l["pos"],po) then send["pos"] = po end
				net.Start("sendvecdata") net.WriteTable({[m:SteamID()]=send}) net.SendToServer()
			end
			if an ~= l["ang"] then
				local send = {}
				if DataCheck(l["ang"],an) then send["ang"] = an end
				net.Start("sendangdata") net.WriteTable({[m:SteamID()]=send}) net.SendToServer()
			end
			if ac ~= l["active"] or fo ~= l["fov"] or sl ~= l["slow"] or fa ~= l["fast"] then
				local send = {}
				if DataCheck(l["active"],ac) then send["active"] = ac end
				if DataCheck(l["fov"]   ,fo) then send["fov"]    = fo end
				if DataCheck(l["slow"]  ,sl) then send["slow"]   = sl end
				if DataCheck(l["fast"]  ,fa) then send["fast"]   = fa end
				net.Start("sendpardata") net.WriteTable({[m:SteamID()]=send}) net.SendToServer()
			end
			if pa ~= l["parts"] then
				local send = {}
				if DataCheck(l["w"]    ,ww) then send["w"]     = ww end
				if DataCheck(l["h"]    ,hh) then send["h"]     = hh end
				if DataCheck(l["parts"],pa) then send["parts"] = pa end
				net.Start("sendauxdata") net.WriteTable({[m:SteamID()]=send}) net.SendToServer()
			end
			
			if DataCheck(l["active"],ac) then paccams.Initialize() end
			
			datalast = datatable
		end
		hook.Add("Think","pcamsdatanet",pcamsdatanet)
		
		local psca = {}
		local pcamvp = {}
		local pcamva = {}
		local lines = {}
		local maxlines = 20
		
		local function AimVec(x,y,w,h,a,f) return (4*h/(6*math.tan(0.5*math.rad(f)))*a:Forward()+(x-0.5*w)*a:Right()+(0.5*h-y)*a:Up()):GetNormalized() end
		
		local function pcams2d()
			for k,v in pairs(ptd) do
				local p = player.GetBySteamID(k) or nil
				if not IsValid(p) then continue end
				if freecam then
					if not freecam.enab and p == m then continue end
				else
					if p == m then continue end
				end
				local na = p:Name()
				local active,vp = v["active"] or false,v["pos"] or Vector()
				local vpp = pcamvp[p] or Vector()
				if not active then continue end
				local col = PacCamColors[p:EntIndex()] or Color(255,64,255,255)
				local textcol = Color(math.Clamp(col.r+64,0,255),math.Clamp(col.g+64,0,255),math.Clamp(col.b+64,0,255),col.a)
				vpp = vpp:ToScreen()	
				if vpp.visible then
					draw.SimpleTextOutlined(na:gsub("%^%d+", ""):gsub("<(.-)=(.-)>", ""),"Default",vpp.x,vpp.y-5,textcol,1,4,1,Color(0,0,0,255))
					if pace.IsActive() and pace.GetViewPos():Distance(v["pos"] or Vector()) <= 256 then
						draw.SimpleTextOutlined((v["parts"] or "N/A").." parts","Default",vpp.x,vpp.y+5,textcol,1,3,1,Color(0,0,0,255))
					end
				end
			end
		end
		hook.Add("HUDPaint","pcams2d",pcams2d)
		
		local function pcams3d()
			for k,v in pairs(ptd) do
				local p = player.GetBySteamID(k) or nil
				if not IsValid(p) then continue end
				if freecam then
					if not freecam.enab and p == m then continue end
				else
					if p == m then continue end
				end
				local na = p:Name()
				psca[p],pcamvp[p],pcamva[p] = psca[p] or 1,pcamvp[p] or Vector(),pcamva[p] or Angle()
				local active,vp,va,vf,w,h,parts,slo = v["active"] or false,v["pos"] or Vector(),v["ang"] or Angle(),v["fov"] or 75,v["w"] or 1920,v["h"] or 1080,v["parts"] or -1,v["slow"] or false
				local fas = v["fast"] or false
				pcamvp[p] = pcamvp[p] and (pcamvp[p] ~= vp and LerpVector(0.2,pcamvp[p],vp) or pcamvp[p]) or Vector()
				pcamva[p] = pcamva[p] and (pcamva[p] ~= va and Angle(Lerp(0.2,pcamva[p].p,va.p),Lerp(0.2,pcamva[p].y,va.y),Lerp(0.2,pcamva[p].r,va.r))  or pcamva[p]) or Angle()
				local vpp,vaa = pcamvp[p],pcamva[p]
				psca[p] = fas and Lerp(0.25,psca[p],2) or not fast and (slo and Lerp(0.25,psca[p],0.25) or Lerp(0.25,psca[p],1)) or Lerp(0.25,psca[p],1)
				local sca = psca[p]*12
				if not active then continue end
				local ratio = w/h
				local p1,p2,p3,p4 = AimVec(0,0,w,h,vaa,vf),AimVec(w,0,w,h,vaa,vf),AimVec(w,h,w,h,vaa,vf),AimVec(0,h,w,h,vaa,vf)
				p1,p2,p3,p4 = vpp+(p1*sca),vpp+(p2*sca),vpp+(p3*sca),vpp+(p4*sca)
				local hn,nn,col = vaa:Forward()*sca,((p1+p2+p3+p4)/4),PacCamColors[p:EntIndex()] or Color(255,64,255,255)
				local ww,hh = p1:Distance(p2),p1:Distance(p3)
				if not lines[p] then lines[p] = {} end 
				if #lines[p] > maxlines then table.remove(lines[p],1) end
				lines[p][#lines[p]+1] = vpp*1
				for i=1,#lines[p] do
					local aa,bb = lines[p][i],lines[p][i-1] and lines[p][i-1] or lines[p][i]
					local lcol = Color(col.r,col.g,col.b,(i/#lines[p])*255)
					if aa == bb then continue end
					render.DrawLine(aa,bb,lcol,false)
				end
				render.DrawLine(vpp,p1,col,false)
				render.DrawLine(vpp,p2,col,false)
				render.DrawLine(vpp,p3,col,false)
				render.DrawLine(vpp,p4,col,false)
				render.DrawLine(p1 ,p2,col,false)
				render.DrawLine(p2 ,p3,col,false)
				render.DrawLine(p3 ,p4,col,false)
				render.DrawLine(p4 ,p1,col,false)
				local tl,tc,tr = LerpVector(0.25,p1,p2)+vaa:Up()*1,LerpVector(0.5,p1,p2)+vaa:Up()*4.5,LerpVector(0.75,p1,p2)+vaa:Up()*1
				render.DrawLine(tl ,tc,col,false)
				render.DrawLine(tc ,tr,col,false)
				render.DrawLine(tr ,tl,col,false)
			end
		end
		hook.Add("PostDrawTranslucentRenderables","pcams3d",pcams3d)
		hook.Remove("InitPostEntity","PAC_CAMS_CLIENT_INIT")
	end)
end
	