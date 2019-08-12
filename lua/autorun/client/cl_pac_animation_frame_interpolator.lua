local function InterpolateFrames(f1,f2)
	f1,f2 = pace.timeline.data.FrameData[f1],pace.timeline.data.FrameData[f2]
	local idata = {}
	idata.FrameRate = Lerp(0.5,f1.FrameRate,f2.FrameRate)
	idata.BoneInfo = {}
	for k,v in pairs(f1.BoneInfo) do
		idata.BoneInfo[k] = {}
		for kk,vv in pairs(v) do
			idata.BoneInfo[k][kk] = f2.BoneInfo[k] and f2.BoneInfo[k][kk] and Lerp(0.5,vv,f2.BoneInfo[k][kk]) or Lerp(0.5,vv,0)
		end
	end
	for k,v in pairs(f2.BoneInfo) do
		idata.BoneInfo[k] = idata.BoneInfo[k] or {}
		for kk,vv in pairs(v) do
			idata.BoneInfo[k][kk] = f1.BoneInfo[k] and f1.BoneInfo[k][kk] and Lerp(0.5,f1.BoneInfo[k][kk],vv) or Lerp(0.5,0,vv)
		end
	end
	local keyframe = pace.timeline.frame:AddKeyFrame()
	local tbl = idata.BoneInfo
	for i,v in pairs(tbl) do
		local data = keyframe:GetData()
		data.BoneInfo[i] = table.Copy(idata.BoneInfo[i] or {})
		data.BoneInfo[i] = {MU=v.MU,MR=v.MR,MF=v.MF,RU=v.RU,RR=v.RR,RF=v.RF}
	end
	keyframe:SetLength(1/(idata.FrameRate))
	pace.timeline.SelectKeyframe(keyframe)
end

--PrintTable(InterpolateFrames(pace.timeline.data.FrameData[1],pace.timeline.data.FrameData[2]))
--InterpolateFrames(pace.timeline.data.FrameData[3],pace.timeline.data.FrameData[4])

hook.Add("ChatCommand","iframe",function(c,a,m)
	if c:lower() == "iframe" or c:lower() == "if" then
		local f1,f2 = unpack(string.Explode(" ",a))
		InterpolateFrames(tonumber(f1),tonumber(f2))
	end
end)

concommand.Add("iframe",function(p,c,a)
	local f1,f2 = a[1],a[2]
	InterpolateFrames(tonumber(f1),tonumber(f2))
end)