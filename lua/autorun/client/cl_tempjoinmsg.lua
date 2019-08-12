do return end --not public anymore

hook.Add("InitPostEntity","tempjoinrun",function()
local m = LocalPlayer()

tempjoin = tempjoin or {}
local tj = tempjoin

tj.BGAnim = 0
tj.MainVGUI = tj.MainVGUI or NULL
tj.ButtonCalled = false
tj.GlowMat = Material("particle/Particle_Glow_04_Additive")
tj.Labels = {
	["Main"]       = "",
	["Continue"]   = "Continue to Development",
	["Disconnect"] = "Disconnect from server"
}
tj.Lines = {
	"Hello "..LocalPlayer():GetName()..",",
	"",
	"Welcome to the public development server for Xenora, or rather, soon-to-be Xenora 2.0.",
	"If you're here to have casual fun, this is not the place for you, as we're doing focused work here,",
	"and distractions only subtract from our focus. If you feel, however, you will add to the experience",
	"and suggest helpful ideas to us, that would be appreciated, and you're more than welcome to provide",
	"suggestions for the re-development of this server and its' community.",
	"",
	"Since the server was newly recreated and since it is a dev server after all, don't expect a polished",
	"server just yet; it is in a very raw state right now and many things are either broken or missing.",
	"Things will be added in due time, and as seen necessary to the development of the server.",
	"",
	"Do note that all developers currently working have the right to kick anyone at any time, if they feel",
	"they are disturbing the peace in some way. Either work with us in some way, or find some other server.",
	"",
	"Thanks for helping,",
	"    - Sauermon"
}

tj.Show = function()
	if tj.MainVGUI:IsValid() then
		tj.MainVGUI:Close()
		tj.MainVGUI = NULL
	end
	tj.CreateVGUI()
	tj.MainVGUI:SetVisible(true)
	
end

tj.CreateVGUI = function()
	local mu = vgui.Create("DFrame")
	mu:SetSize(ScrW(),ScrH())
	mu:SetPos(0,0)
	mu:SetTitle("")
	function mu:Paint(w,h)
		return true
	end
	mu:MakePopup()
	tj.MainVGUI = mu
end

tj.WithinBox = function(x,y,w,h)
	local mx,my = gui.MouseX(),gui.MouseY()
	if mx >= x and mx <= x+w and my >= y and my <= y+h then
		return true
	end
	return false
end

tj.Button = function(text,font,x,y,w,h,color,bordercolor,callback)
	local hover,click = tj.WithinBox(x,y,w,h),input.IsMouseDown(MOUSE_LEFT)
	draw.RoundedBox(0,x,y,w,h,color)
	surface.SetDrawColor(bordercolor)
	surface.DrawOutlinedRect(x,y,w,h)
	draw.SimpleText(text,font,x+w/2,y+h/2,Color(255,255,255,color.a),1,1)
	if hover then
		draw.RoundedBox(0,x,y,w,h,Color(255,255,255,color.a))
		surface.SetDrawColor(Color(64,128,255,bordercolor.a))
		surface.DrawOutlinedRect(x,y,w,h)
		if click and not tj.ButtonCalled then
			draw.RoundedBox(0,x,y,w,h,Color(64,0,0,color.a))
			surface.SetDrawColor(Color(255,0,0,bordercolor.a))
			surface.DrawOutlinedRect(x,y,w,h)
			tj.ButtonCalled = true
			timer.Simple(0.5,function()
				tj.ButtonCalled = false
			end)
			callback()
		end
		draw.SimpleText(text,font,x+w/2,y+h/2,click and not tj.ButtonCalled and Color(255,0,0,bordercolor.a) or Color(64,128,255,bordercolor.a),1,1)
	end
end

local a = 0
tj.RenderBackground = function()
	tj.BGAnim = tj.MainVGUI:IsValid() and tj.MainVGUI:IsVisible()
	local mat = Lerp(8*FrameTime(),a,tj.BGAnim and 1 or 0)
	a = mat <= 0.01 and 0 or mat >= 0.99 and 1 or mat
	if not tj.BGAnim and a <= 0 then return end
	
	draw.RoundedBox(0,0,0,ScrW(),ScrH(),Color(0,0,0,a*255))
	
	local glowwiggle = 0.5+math.sin(CurTime())*0.5
	
	surface.SetDrawColor(64,128,255,a*128)
	surface.SetMaterial(tj.GlowMat)
	surface.DrawTexturedRect(ScrW()/2-(a*ScrW()*0.5)-glowwiggle*ScrH()/4,ScrH()/2-(a*ScrW()*0.5)-glowwiggle*ScrH()/4,(a*ScrW()*0.5*2)+glowwiggle*ScrH()/2,(a*ScrW()*0.5*2)+glowwiggle*ScrH()/2)
	
	for k,v in pairs(tj.Lines) do
		draw.SimpleText(v,"TargetID",ScrW()/2,ScrH()/4-ScrH()/7+k*32,Color(255,255,255,a*255),1,1)
	end
	
	tj.Button("Disconnect","TargetID",ScrW()/2-ScrW()/8*2,ScrH()-ScrH()/4,ScrW()/10,48,Color(0,0,0,a*255),Color(64,64,64,a*255),function()
		RunConsoleCommand("disconnect")
	end)
	tj.Button("Continue","TargetID",ScrW()/2+ScrW()/8,ScrH()-ScrH()/4,ScrW()/10,48,Color(0,0,0,a*255),Color(64,64,64,a*255),function()
		tj.MainVGUI:Close()
	end)
end
hook.Add("PostRenderVGUI","tempjoin.HUDPaint",tj.RenderBackground)
timer.Simple(3,function()
	tj.Show()
end)
end)