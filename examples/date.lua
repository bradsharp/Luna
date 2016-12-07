local class = require'lib/luna'

local date = class {

	__construct = function (this, time)
		local s=type(time)=='number' and time or os.time()
		this.ticks = s
		local fy,dim=math.floor(s/126230400),{31,0,31,30,31,30,31,31,30,31,30,31}
		local y,s,m,d,h,mm=fy*4,s-(126230400*fy)
		for i=1,4 do local sy=i==2 and 31622400 or 31536000
			if s<(sy) then break
			else y=y+1 s=s-(sy)
		end end
		for i=1,12 do local sm=(i==2 and ((y%4)==0 and 29 or 28) or dim[i])*86400
			if s<(sm) then m=i break
			else s=s-(sm)
		end end
		local d=math.floor(s/86400) s=s-(d*86400)
		local h=math.floor(s/3600) s=s-(h*3600)
		local mm=math.floor(s/60) s=s-(mm*60)
		this.year = 1970+y
		this.month = m
		this.day = d+1
		this.hour = h
		this.minute = mm
		this.second = s
	end;
  
	Ticks = {get = function (this) return this.ticks end};
  
	Year = {get = function (this) return this.year end};
	Month = {get = function (this) return this.month end};
	Day = {get = function (this) return this.day end};
  
	Hour = {get = function (this) return this.hour end};
	Minute = {get = function (this) return this.minute end};
	Second = {get = function (this) return this.second end};
  
	__tostring = function (this)
		return string.format("%02i:%02i:%02i %02i/%02i/%04i", 
			this.Hour, this.Minute, this.Second,
			this.Day, this.Month, this.Year)
	end
  
}
