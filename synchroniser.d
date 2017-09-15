#!/usr/bin/env rdmd

import std.stdio;
import std.file;
import std.path;
import std.string;
import std.array;
import std.process;

int main(string[] args) {

	bool partial = false;

	switch (args.length) {
	case 2:
		// Update submodules
		writeln("Making sure submodules are initialised...");
		if(auto err = spawnProcess(["git", "submodule", "init"]).wait) {
			stderr.writefln("Could not initialise submodules! Error code: %s", err);
			return 1;
		}

		writeln("Checking for submodule updates...");
		if(auto err = spawnProcess(["git", "submodule", "update", "--remote"]).wait) {
			stderr.writefln("Could not update submodules! Error code: %s", err);
			return 2;
		}


		if(exists("output"))
			rmdirRecurse("output");
		mkdir("output");

		auto mod = args[1];
		copy("mod.settings." ~ mod, "mod.settings");

		break;
	case 3:
		if (args[2] != "partial") {
			stderr.writeln("The second argument can only be \"partial\"!");
			return 3;
		}

		partial = true;

		if(!exists("output"))
			mkdir("output");

		copy("mod.settings." ~ args[1], "mod.settings");

		break;
	default:
		stderr.writeln("synchroniser.d <mod> [partial]");
		return 4;
	}

	// Mods that need to be merged
	foreach(string modfolder; dirEntries("submodules", SpanMode.shallow)) {
		// Look for output folder
		string output = modfolder;
		foreach(string entry; modfolder.dirEntries(SpanMode.shallow)) if(entry.isDir && entry.baseName == "source")
			output = entry;
		foreach(string entry; modfolder.dirEntries(SpanMode.shallow)) if(entry.isDir && entry.baseName == "output")
			output = entry;
		output ~= dirSeparator;
		writefln("Output folder for %s: %s", modfolder, output);
		outer: foreach(string entry; output.dirEntries(SpanMode.breadth)) {
			string rpath = entry[output.length .. $];
			auto normalised_name = rpath.toLower.stripExtension;
			auto parts = rpath.split(dirSeparator);
			auto path = chainPath("output", rpath).array;
			foreach(part; parts[0 .. $-1]) if(part[0] == '.')
				continue outer;
			if(
				rpath.extension == ".deuser" ||
				rpath.extension == ".deproj" ||
				rpath == "mod.settings" ||
				rpath == "preview.jpg" ||
				parts[$-1][0] == '.' ||
				normalised_name == "license" ||
				normalised_name == "readme"
			) {
				writefln("Ignored %s!", rpath);
			} else if(entry.isDir) {
				if(!path.exists) path.mkdir;
			} else {
				copy(entry, path);
			}
		}
	}

	return 0;
}
