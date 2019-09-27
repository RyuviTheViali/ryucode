pacprotectnotify = {}

local grey,red,green,blue,palered = Color(200,200,200),Color(255,100,100),Color(100,255,100),Color(100,100,255),Color(255,200,200)

pacprotectnotify.PlayerName = function(ply)
	return ply.Nick and ply:Nick() or gameevent.EngineNick(ply)
end

pacprotectnotify.PrintMsg = function(ply,msg)
	Msg("[PAC Protect : Message] "..pacprotectnotify.PlayerName(ply)..": "..msg.."\n")
	
	chat.AddText(red    ,"[PAC Protect] ",
				 green  ,pacprotectnotify.PlayerName(ply),
				 grey   ,": ",
				 palered,msg)
end

pacprotectnotify.PrintFunctionRan = function(ply,tab,nam,tra,dbg,ext)
	Msg("[PAC Protect : Execution Detection] Client "..pacprotectnotify.PlayerName(ply).." executed "..tab.."."..nam.." on their client:\n\n")
	Msg("\t\tTraceback:\n")
	Msg(tra.."\n\n")
	Msg("Calling function information:\n")
	for k,v in pairs(dbg) do
		Msg("\t\t"..k..": "..tostring(v).."\n")
	end
	Msg("Calling function arguments:\n")
	if #ext == 0 then
		Msg("None")
	end
	for k,v in pairs(ext) do
		Msg("\t\t"..k..": "..tostring(v).."\n")
	end

	if not ply:CheckUserGroupLevel("developers") then
		chat.AddText(red    ,"[PAC Protect]",
					 grey   ," Client ",
		             green  ,pacprotectnotify.PlayerName(ply),
		             grey   ," executed function ",
		             blue   ,tab.."."..nam)
		chat.AddText(grey   ,"Details of execution:",
		             palered," Calling Function name: ",
		             red    ,dbg.name,
		             palered,", Calling Function source: ",
		             red    ,dbg.source)
		chat.AddText(grey   ,"Check console for further detail.")
	end
end

pacprotectnotify.PrintAutoBlocked = function(ply,tab,nam,tra,dbg,ext)
	Msg("[PAC Protect : Auto-block] Client "..pacprotectnotify.PlayerName(ply).." executed "..tab.."."..nam.." on their client:\n\n")
	Msg("\t\tTraceback:\n")
	Msg(tra.."\n\n")
	Msg("Calling function information:\n")
	for k,v in pairs(dbg) do
		Msg("\t\t"..k..": "..tostring(v).."\n")
	end
	Msg("Calling function arguments:\n")
	if #ext == 0 then
		Msg("None")
	end
	for k,v in pairs(ext) do
		Msg("\t\t"..k..": "..tostring(v).."\n")
	end
	
	chat.AddText(red    ,"[PAC Protect]",
				 grey   ," Auto-blocked client ",
	             green  ,pacprotectnotify.PlayerName(ply),
	             grey   ," from executing the function ",
	             blue   ,tab.."."..nam)
	chat.AddText(grey   ,"Details of attempted execution:",
	             palered," Calling Function name: ",
	             red    ,dbg.name,
	             palered,", Calling Function source: ",
	             red    ,dbg.source)
	chat.AddText(grey   ,"Check console for further detail.")
end

pacprotectnotify.PrintOverwriteDetected = function(ply,tab,nam)
	Msg("[PAC Protect : Override Detection] Client "..pacprotectnotify.PlayerName(ply).." overwrote "..tab.."."..nam.." on their client:\n")
	
	chat.AddText(red    ,"[PAC Protect]",
				 grey   ," Protected function ",
				 red    ,"override",
				 grey   ," detected from client ",
				 green  ,pacprotectnotify.PlayerName(ply),
				 grey   ,": ",
				 blue   ,tab.."."..nam)
	chat.AddText(grey   ,"Check console for further detail.")
end

net.Receive("pacpromsg",function(l,p)
	pacprotectnotify.PrintMsg(net.ReadEntity(),net.ReadString())
end)

net.Receive("pacproret",function(l,p)
	pacprotectnotify.PrintFunctionRan(net.ReadEntity(),net.ReadString(),net.ReadString(),net.ReadString(),net.ReadTable(),net.ReadTable())
end)

net.Receive("pacproautoprev",function(l,p)
	pacprotectnotify.PrintAutoBlocked(net.ReadEntity(),net.ReadString(),net.ReadString(),net.ReadString(),net.ReadTable(),net.ReadTable())
end)

net.Receive("pacprooveralert",function(l,p)
	pacprotectnotify.PrintOverwriteDetected(net.ReadEntity(),net.ReadString(),net.ReadString())
end)