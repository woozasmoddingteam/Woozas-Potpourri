local Plugin = Plugin;

function Plugin:Initialise()
	Shared.Message("I AM HERE");
	Shared.RegisterNetworkMessage("ADVERTS_LAS_ADVERT", {
		pr = "integer (0 to 255)";
		pg = "integer (0 to 255)";
		pb = "integer (0 to 255)";
		r = "integer (0 to 255)";
		r = "integer (0 to 255)";
		b = "integer (0 to 255)";
		prefix = StringMessage;
		message = StringMessage;
	});

	Client.HookNetworkMessage("ADVERTS_LAS_ADVERT", function(msg)
		Shine.AddChatText(msg.pr, msg.pg, msg.pb, msg.prefix, msg.r/255, msg.g/255, msg.b/255, msg.message);
	end);

	return true;
end
