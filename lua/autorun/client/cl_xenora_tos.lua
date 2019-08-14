local function XTOS(check)

surface.CreateFont("tosheader"   ,{font="Helvetica",size=36,weight=0,antialias=true})
surface.CreateFont("tossubheader",{font="Helvetica",size=24,weight=0,antialias=true})

local tos = {
	"Welcome to Xenora, a sandbox-based building, PAC-editing, and developer-friendly server.",
	"Here is what you shouldn't do while you're here:",
	"",
	"• Harass others or be rude.",
	"    - If you don't have anything nice to say, don't say anything at all.",
	"• Destroy someone else's things.",
	"    - You wouldn't want your hard work to be ruined by someone else, why ruin their things?",
	"• Be malicious.",
	"    - If you're coming here with ill-intent, or you want to snatch up some pac outfits or lua files, this is not the server",
	"      for you, and you should head elsewhere.",
	"",
	"Here are things you're free to do while you're here (and no one can judge you on these things either):",
	"",
	"• Have NSFW or nude PAC outfits",
	"    - A PAC outfit is technically a form of art, so what people make with it is not to be judged.",
	"      Wear whatever outfit you like. However, if you are under the legal age in your area, this may not be the server for you.",
	"• Build freely",
	"    - Want a quiet place to work on a project of yours? Xenora is a good place for that. If you need a quiet,",
	"      safe spot to build, reach out to a mod or admin and we can help.",
	"• Ask for help",
	"    - If you need help with anything, ask around. Mods and admins available can help point you in the",
	"      right direction.",
	"",
	"Xenora is a server all about freedom, and creativity. However, with great power comes great",
	"responsibility, and here online, not everyone is responsible. Due to that, some things are in place",
	"here in Xenora to help keep everyone here secure and happy. Here is what you agree to by being with",
	"us in Xenora:",
	"",
	"• Higher admins are capable of surveying any code you run while you are connected.",
	"    - We do this to help prevent any malicious code from being ran, and report those who are running",
	"      code with ill-intent.",
	"",
	"• Higher admins are capable of surveying into a worn PAC outfit.",
	"    - We do this to prevent against any potential exploits from command or script parts.",
	"",
	"• Higher admins are capable of viewing your game's data folder.",
	"    - We do this to check and make sure someone isn't hiding any malicious code - this is only",
	"      performed if the person in question is suspicious.",
	"",
	"",
	"",
	"For further questions, please contact Xenora's owner, Ryuvi.",
	"If they are unavailable, any Guardian or Overwatch member can help you as well."
}

local function CheckTOSAgreement()
	if not file.IsDir("xenora","DATA") then
		file.CreateDir("xenora")
	end
	local tosaccept = file.Read("xenora/tos_accept.txt","DATA")
	if tosaccept == "true" then return true end
	return false
end

if check and CheckTOSAgreement() then return end

local jointos = vgui.Create("DFrame")
jointos:SetSize(640,824)
jointos:Center()
jointos:SetTitle("")
jointos:ShowCloseButton(false)
function jointos:Paint(w,h)
	BlurBoxPanel(self,4,255,Color(0,0,0,200))
	draw.SimpleTextOutlined("• Xenora •","tosheader",w/2,22,Color(0,0,0,255),1,1,1,Color(150,100,255,255))
	draw.SimpleTextOutlined("Terms of Service & Surveillance Notice","tossubheader",w/2,52,Color(255,255,255,255),1,1,1,Color(64,64,64,255))
	
	for k,v in pairs(tos) do
		draw.SimpleTextOutlined(v,"Default",16,64+k*16,Color(255,255,255,255),0,0,1,Color(64,64,64,255))
	end
	
	draw.SimpleTextOutlined("Don't show again","Default",w/2,h-32,Color(255,255,255,255),1,1,1,Color(64,64,64,255))
end
jointos:MakePopup()

if jointos and jointos:IsValid() then
	RunConsoleCommand("vechud","visible","0")
end

local remember = vgui.Create("DCheckBox",jointos)
remember:SetPos(jointos:GetWide()/2-8,jointos:GetTall()-20)
remember:SetValue(0)

local accept = vgui.Create("DButton",jointos)
accept:SetText("Accept and Continue")
accept:SetPos(8,jointos:GetTall()-40)
accept:SetSize(128,32)
accept:SetTextColor(Color(255,255,255,255))
function accept:Paint(w,h)
	surface.SetDrawColor(Color(150,100,255,64))
	surface.DrawRect(0,0,w,h)
end
function accept:DoClick()
	jointos:Close()
	if remember:GetChecked() then
		if not file.IsDir("xenora","DATA") then
			file.CreateDir("xenora")
		end
		local tosaccept = file.Open("xenora/tos_accept.txt","w","DATA")
		tosaccept:Write("true")
		tosaccept:Close()
	end
	RunConsoleCommand("vechud","visible","1")
end

local decline = vgui.Create("DButton",jointos)
decline:SetText("Decline and Disconnect")
decline:SetPos(jointos:GetWide()-136,jointos:GetTall()-40)
decline:SetSize(128,32)
decline:SetTextColor(Color(255,255,255,255))
function decline:Paint(w,h)
	surface.SetDrawColor(Color(0,0,0,128))
	surface.DrawRect(0,0,w,h)
end
function decline:DoClick()
	jointos:Close()
	RunConsoleCommand("vechud","visible","1")
	RunConsoleCommand("disconnect")
end

hook.Add("HUDPaint","TOSBlur",function()
	if jointos and jointos:IsValid() then
		BlurBox(4,0,0,ScrW(),ScrH(),255,Color(0,0,0,200))
	end
end)

end
hook.Add("InitPostEntity","XenoraTermsOfService",XTOS)

concommand.Add("show_tos",function(p,c,a,s)
	XTOS(true)
end)