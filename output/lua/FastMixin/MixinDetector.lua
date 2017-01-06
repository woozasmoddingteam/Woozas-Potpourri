Script.Load("lua/MixinUtility.lua");
local classes = debug.getregistry().__CLASSES;

local metatable = {
	__index = function(self, key)
		if rawget(self, key) ~= nil then
			return rawget(self, key);
		else
			return self.__class[key];
		end
	end
}

local detected_classes = {};

function DetectMixins(cls)
	assert(not detected_classes[cls]);
	detected_classes[cls] = true;
	local meta = getmetatable(cls);

	cls.__class = cls;

	if not cls.OnCreate then
		return;
	else
		local args = "";
		for i = 1, debug.getinfo(cls.OnCreate).nparams do
			args = args .. ", arg" .. i;
		end

		local str = [[
			local cls = ...;
			local meta = getmetatable(cls);
			local old = cls.OnCreate;

			return function(self%s)
				if not self.__class then
					self.__mixintypes = {};
					self.__mixindata = setmetatable({}, {__index = meta.mixindata});
					self.__constructing = true;
					old(self%s);
					self.__constructing = false;
				else
					old(self%s);
				end
			end
		]];

		str = str:format(args, args, args);
		cls.OnCreate = assert(loadstring(str))(cls);
	end

	if not cls.OnInitialized then
	else
		local args = "";
		for i = 1, debug.getinfo(cls.OnInitialized).nparams-1 do
			args = args .. ", arg" .. i;
		end

		local str = [[
			local cls = ...;
			local meta = getmetatable(cls);
			local old = cls.OnInitialized;

			return function(self%s)
				if not self.__constructing then
					self.__constructing = true;
					old(self%s);
					self.__constructing = false;
				else
					old(self%s);
				end
			end
		]];

		str = str:format(args, args, args);
		cls.OnInitialized = assert(loadstring(str))(cls);
	end
end

function BeginMixinDetection()
	for i = 1, #classes do
		DetectMixins(classes[i]);
	end
end
