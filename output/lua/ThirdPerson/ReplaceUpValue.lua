
local function upvalues( func )
	local i = 0;
	if not func then
		return function() end
	else
		return function()
			i = i + 1
			local name, val = debug.getupvalue (func, i)
			if name then
				return i,name,val
			end -- if
		end
	end
end

local function GetUpValues( func )

	local data = {}

	for _,name,val in upvalues( func ) do
		data[name] = val;
	end

	return data

end

local function LocateUpValue( func, upname, options )
	for i,name,val in upvalues( func ) do
		if name == upname then
			return func,val,i
		end
	end

	if options and options.LocateRecurse then
		for i,name,innerfunc in upvalues( func ) do
			if type( innerfunc ) == "function" then
				local r = { LocateUpValue( innerfunc, upname, options ) }
				if #r > 0 then
					return unpack( r )
				end
			end
		end
	end
end

local function SetUpValues( func, source )

	for i,name,val in upvalues( func ) do
		if source[name] then
			if val == nil then
				assert( val == nil )
				debug.setupvalue( func, i, source[name] )
			else
			end
			source[name] = nil
		end
	end

end

local function CopyUpValues( dst, src )
	SetUpValues( dst, GetUpValues( src ) )
end

function ReplaceUpValue( func, localname, newval, options )
	local val,i;

	func, val, i = LocateUpValue( func, localname, options );

	if options and options.CopyUpValues then
		CopyUpValues( newval, val )
	end

	debug.setupvalue( func, i, newval )
end;

