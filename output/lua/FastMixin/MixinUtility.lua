Script.Load("lua/Table.lua")

function CreateMixin(mixin)
    if mixin then
        for k in pairs(mixin) do
            mixin[k] = nil
        end
    else
        mixin = {};
    end
	return mixin;
end

function AddMixinNetworkVars(mixin, networkVars)
    if mixin.networkVars then
        for k, v in pairs(mixin.networkVars) do
            if networkVars[k] ~= nil then
                error("Variable " .. k .. " already exists in network vars while adding mixin " .. mixin.type)
            else
            	networkVars[k] = v;
			end
        end
    end
end

local void = function() end

function InitMixin(self, mixin, optionalMixinData)

	local log = (self:isa("JetpackMarine") and mixin == WeaponOwnerMixin and Log) or void;

	-- The most likely
	if self.__constructing then

		if not self.__class_mixintypes[mixin.type] then
			local cls = self.__class;

			log("\n\n\nMixin WeaponOwnerMixin in permanently inside %s\n\n\n", self);

			for k, v in pairs(mixin) do

				if type(v) == "function" and k ~= "__initmixin" then

					log("Mixing %s in", k);

					if not cls[k] then
						log("Original was not defined!");
						self[k] = v;
						cls[k] = v;
						goto continue;
					end

					if mixin.overrideFunctions then
						for i = 1, #mixin.overrideFunctions do
							if mixin.overrideFunctions[i] == k then
								log("Original was defined, but we don't give a fuck.");
								self[k] = v;
								cls[k] = v;
								goto continue;
							end
						end
					end

					local original = cls[k];
					log("Original was defined, and it's needy... Merging with %s", debug.getinfo(original));
					local func = function(...)
						local ret = original(...); -- NB: You can only return **1** from your functions! This was UWE's decision and not mine.
						v(...);
						return ret;
					end

					self[k] = func;
					cls[k] = func;

				end

				::continue::

			end

			if mixin.defaultConstants then
				for k, v in pairs(mixin.defaultConstants) do
					self.__class_mixindata[k] = v
				end
			end

			self.__class_mixintypes[mixin.type] = true;

		end
	else
		if not self.__mixintypes then
			--Log("InitMixin(%s (%s), %sMixin, %s): Improperly initialized instance!", self, self.classname, mixin.type, optionalMixinData);
			self.__mixintypes = {};
			self.__mixindata = {};
			self.__constructing = false;
		elseif self.__mixintypes[mixin.type] then
			goto init;
		end

		log("\n\n\nMixin WeaponOwnerMixin in for %s\n\n\n", self);

		for k, v in pairs(mixin) do

			if type(v) == "function" and k ~= "__initmixin" then

				log("Mixing %s in!", k);

				if not self[k] then
					log("Original was not defined!");
					self[k] = v;
					goto continue;
				end

				if mixin.overrideFunctions then
					for i = 1, #mixin.overrideFunctions do
						if mixin.overrideFunctions[i] == k then
							log("Original was defined, but we don't give a fuck.");
							self[k] = v;
							goto continue;
						end
					end
				end

				local original = self[k];
				log("Original was defined, and it's needy... Merging with %s", debug.getinfo(original));
				local func = function(...)
					local ret = original(...); -- NB: You can only return **1** from your functions! This was UWE's decision and not mine.
					v(...);
					return ret;
				end

				self[k] = func;

			end

			::continue::

		end

		if mixin.defaultConstants then
			for k, v in pairs(mixin.defaultConstants) do
				self.__mixindata[k] = v
			end
		end
	end

	if self.__is_ent then
		Shared.AddTagToEntity(self:GetId(), mixin.type);
	end

	self.__mixintypes[mixin.type] = true;

	::init::

	if optionalMixinData then

		for k, v in pairs(optionalMixinData) do
			self.__mixindata[k] = v
		end

	end

    if mixin.__initmixin then
        mixin.__initmixin(self)
    end

end

function StaticInitMixin(cls, mixin, mixindata)
	error("Don't.");
	assert(not cls.__class_mixintypes[mixin.type]);

	for k, v in pairs(mixin) do

		if type(v) == "function" and k ~= "__initmixin" then

			if not cls[k] then
				cls[k] = v;
				goto continue;
			end

			if mixin.overrideFunctions then
				for i = 1, #mixin.overrideFunctions do
					if mixin.overrideFunctions[i] == k then
						cls[k] = v;
						goto continue;
					end
				end
			end

			local original = cls[k];
			local func = function(...)
				v(...);
				return original(...);
			end

			cls[k] = func;

		end

		::continue::

	end

	if mixin.defaultConstants then
		for k, v in pairs(mixin.defaultConstants) do
			cls.__class_mixindata[k] = v
		end
	end

	if mixindata then
		for k, v in pairs(mixindata) do
			cls.__class_mixindata[k] = v;
		end
	end

	cls.__class_mixintypes[mixin.type] = true;
end

function HasMixin(inst, mixin_type)
	return inst and inst.__mixintypes and inst.__mixintypes[mixin_type] or false;
end

function ClassHasMixin(cls, mixin_type) -- Also works with instances of the classes actually
	return cls.__class_mixintypes[mixin_type] or false;
end
