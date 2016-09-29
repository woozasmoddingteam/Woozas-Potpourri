local Plugin = Plugin;

local unwanted = {"Hints"};

Client.HookNetworkMessage("ADVERTS_LAS_ADVERT", function(msg)
	local group = string.Explode(msg.group, "|");
	for _, v in ipairs(group) do
		if table.contains(unwanted, msg) then Shared.Message("Skipped an advert."); return nil; end;
	end
	Shine.AddChatText(msg.pr, msg.pg, msg.pb, msg.prefix, msg.r/255, msg.g/255, msg.b/255, msg.message);
end);
