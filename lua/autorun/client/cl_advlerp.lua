function AdvLerp(inputvalue,startvalue,endvalue,direction,speed,intclamp)
	assert(inputvalue ~= nil,"[INTERP-FUNC] Missing input value")
	assert(startvalue ~= nil,"[INTERP-FUNC] Missing start value")
	assert(endvalue   ~= nil,"[INTERP-FUNC] Missing end value")
	assert(direction  ~= nil,"[INTERP-FUNC] Missing interpolation direction")
	
	local _value      = inputvalue
	local value       = _value or inputvalue
	local _startclamp = 1 - intclamp
	local _endclamp   = 0 + intclamp
	local speed       = speed or 4
	
	if direction > 0 then
		if _value < _startclamp then
			_value = Lerp(speed*FrameTime(),_value,endvalue)	
			value = math.Clamp(_value,startvalue,endvalue)
		else
			_value = 1
			value = _value
		end
		return value
	elseif direction < 0 then
		if _value > _endclamp then
			_value = Lerp(speed*FrameTime(),_value,startvalue)
			value = math.Clamp(_value,startvalue,endvalue)
		else
			_value = 0
			value = _value
		end
		return value
	end
end