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

function InitMixin(self, mixin, optionalMixinData)
    PROFILE("InitMixin");

	-- The most likely
	if self.__constructing then

		if not self.__class_mixintypes[mixin.type] then
			local cls = self.__class;

			for k, v in pairs(mixin) do

				if type(v) == "function" and k ~= "__initmixin" then

					if not cls[k] then
						self[k] = v;
						cls[k] = v;
						goto continue;
					end

					if mixin.overrideFunctions then
						for i = 1, #mixin.overrideFunctions do
							if mixin.overrideFunctions[i] == k then
								self[k] = v;
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
			Log("InitMixin(%s (%s), %sMixin, %s): Improperly initialized instance!", self, self.classname, mixin.type, optionalMixinData);
			self.__mixintypes = {};
			self.__mixindata = {};
			self.__constructing = false;
		elseif self.__mixintypes[mixin.type] then
			goto init;
		end

		for k, v in pairs(mixin) do

			if type(v) == "function" and k ~= "__initmixin" then

				if not self[k] then
					self[k] = v;
					goto continue;
				end

				if mixin.overrideFunctions then
					for i = 1, #mixin.overrideFunctions do
						if mixin.overrideFunctions[i] == k then
							self[k] = v;
							goto continue;
						end
					end
				end

				local original = self[k];
				local func = function(...)
					v(...);
					return original(...);
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

	do
		local add_tag = self.__isent;

		if add_tag == nil then
			add_tag = self:isa("Entity");
			self.__isent = add_tag;
		end

		if add_tag then
			Shared.AddTagToEntity(self:GetId(), mixin.type);
		end

		self.__mixintypes[mixin.type] = true;
	end -- Otherwise lua complains about jumping into the scope of a local

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

function HasMixin(inst, mixin_type)
	return inst and inst.__mixintypes and inst.__mixintypes[mixin_type] or false;
end

function ClassHasMixin(cls, mixin_type) -- Also works with instances of the classes actually
	return cls.__class_mixintypes[mixin_type] or false;
end
