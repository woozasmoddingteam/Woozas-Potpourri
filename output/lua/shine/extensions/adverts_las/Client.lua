local Plugin = Plugin;

local unwanted = {};

function Plugin:Initialise()
	Shared.Message("shine adverts client init")
	return true
end

Client.HookNetworkMessage("ADVERTS_LAS_ADVERT", function(msg)
	local group = string.Explode(msg.group, "|");
	for _, v in ipairs(group) do
		if table.contains(unwanted, v) then Shared.Message("AdvertsLasClient: Skipped an advert."); return nil; end;
	end
	Shine.AddChatText(msg.pr, msg.pg, msg.pb, msg.prefix, msg.r/255, msg.g/255, msg.b/255, msg.message);
end);

Event.Hook("Console_sh_disable_advert_group", function(group)
	table.insert(unwanted, group);
end)
--Plugin.BindCommand("sh_disable_advert", "DisableAdvert", Plugin.DisableAdvert, true, true);
