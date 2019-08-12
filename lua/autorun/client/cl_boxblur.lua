MAT_BLUR = Material("pp/blurscreen")

function BlurBox(amount,x,y,width,height,b_alpha,color)
	amount = math.Clamp(amount,0,1)
	surface.SetMaterial(MAT_BLUR)
	if amount > 0 then
		for i=(1/amount),1,(1/amount) do
			MAT_BLUR:SetInt("$blur",10*i)
			render.UpdateScreenEffectTexture()
			surface.SetDrawColor(0,0,0,b_alpha)
			surface.DrawPoly({
				{x=x    ,y=y     ,u=x    /ScrW(),v=y     /ScrH()},
				{x=width,y=y     ,u=width/ScrW(),v=y     /ScrH()},
				{x=width,y=height,u=width/ScrW(),v=height/ScrH()},
				{x=x    ,y=height,u=x    /ScrW(),v=height/ScrH()}
			}) 
		end
	end
	surface.SetTexture(surface.GetTextureID("vgui/white"))
	surface.SetDrawColor(color)
	surface.DrawRect(x,y,width,height)
end

function BlurBoxPanel(panel,amount,b_alpha,color)
	local x,y = panel:LocalToScreen(0,0)
	local w,h = panel:LocalToScreen(panel:GetWide(),panel:GetTall())
	local a,b = panel:GetWide(),panel:GetTall()
	surface.SetMaterial(MAT_BLUR)
	if amount > 0 then
		for i=(1/amount),1,(1/amount) do
			MAT_BLUR:SetInt("$blur",10*i)
			render.UpdateScreenEffectTexture()
			surface.SetDrawColor(0,0,0,b_alpha)
			surface.DrawPoly({
				{x=0,y=0,u=x/ScrW(),v=y/ScrH()},
				{x=a,y=0,u=w/ScrW(),v=y/ScrH()},
				{x=a,y=b,u=w/ScrW(),v=h/ScrH()},
				{x=0,y=b,u=x/ScrW(),v=h/ScrH()}
			}) 
		end
	end
	surface.SetTexture(surface.GetTextureID("vgui/white"))
	surface.SetDrawColor(color)
	surface.DrawRect(0,0,a,b)
end