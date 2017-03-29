local Shine = Shine

local Plugin = {}
Plugin.Version = "1.0"

local p = require "jit.p";

local profiling = false;

local function startProfiler(client, mode)
	if profiling then
		Shine:NotifyColour(client, 255, 20, 20, "Already profiling!");
		return;
	end

	local time = os.date("!*t");
	local file = string.format("config://lj_profiler_logs/%s-%s-%s-%s-%s-%s.txt", time.year, time.month, time.day, time.hour, time.min, time.sec);
	Log(file);

	p.start(mode, file);
	profiling = true;
end

local function stopProfiler()
	profiling = false;
	p.stop();
end

function Plugin:Initialise()
	local command = self:BindCommand("sh_lj_start_profile", "StartProfiler", startProfiler);
	command:AddParam {
		Type = "string";
		Help = "Luajit profiling mode";
		Default = "-50fm1s";
		Optional = true;
	};
	command:Help("Starts profiling");

	local command = self:BindCommand("sh_lj_stop_profile", "StopProfiler", stopProfiler);
	command:Help("Stops profiling");

	self.Enabled = true
	return true
end

Shine:RegisterExtension("luajit_profiling", Plugin)
