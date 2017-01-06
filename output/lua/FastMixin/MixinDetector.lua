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
		local info = debug.getinfo(cls.OnCreate);
		local args = "";
		if info.isvararg then
			args = "...";
		else
			for i = 1, info.nparams-1 do
				args = args .. ", arg" .. i;
			end
		end

		local str = [[
			local cls = ...;
			local meta = getmetatable(cls);
			local old = cls.OnCreate;

			return function(self%s)
				if not self.__constructing then
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

	if cls.OnInitialized then
		local info = debug.getinfo(cls.OnInitialized);
		local args = "";
		if info.isvararg then
			args = "...";
		else
			for i = 1, info.nparams-1 do
				args = args .. ", arg" .. i;
			end
		end

		local str = [[
			local cls = ...;
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
