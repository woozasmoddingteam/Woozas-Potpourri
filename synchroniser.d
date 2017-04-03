#!/usr/bin/env rdmd

import std.stdio;
import std.file;
import std.path;
import std.string;
import std.array;
import std.process;
import core.stdc.stdlib : exit;

void main(string[] args) {

	bool partial = false;

	if(args.length < 2) {
		// Update submodules
		writeln("Making sure submodules are initialised...");
		if(auto err = spawnProcess(["git", "submodule", "init"]).wait) {
			stderr.writefln("Could not initialise submodules! Error code: %s", err);
		}

		writeln("Checking for submodule updates...");
		if(auto err = spawnProcess(["git", "submodule", "update", "--remote"]).wait) {
			stderr.writefln("Could not update submodules! Error code: %s", err);
		}

		if(exists("output"))
			rmdirRecurse("output");
		mkdir("output");
	} else if(args.length > 2) {
		stderr.writefln("Too many arguments passed!");
		return;
	} else if(args[1] == "partial") {
		if(!exists("output"))
			mkdir("output");
		partial = true;
	} else {
		stderr.writefln("Incorrect argument passed!");
		return;
	}

	// Mods that need to be merged
	foreach(string modfolder; dirEntries("submodules", SpanMode.shallow)) {
		// Look for output folder
		string output = modfolder;
		foreach(string entry; modfolder.dirEntries(SpanMode.shallow)) if(entry.isDir && entry.baseName == "output") {
			output = entry;
		}
		output ~= '/';
		writefln("Output folder for %s: %s", modfolder, output);
		foreach(string entry; output.dirEntries(SpanMode.breadth)) {
			string path = chainPath("output", entry.chompPrefix(output)).array;
			auto normalised_name = entry.baseName.toLower.stripExtension;
			if(normalised_name[0] == '.' || normalised_name == "license" || normalised_name == "readme") {
				writefln("Ignored %s!", entry);
			} else if(entry.isDir) {
				if(!path.exists) path.mkdir;
			} else if(path.exists && !partial) {
			} else if(!partial || !path.exists || path.timeLastModified != entry.timeLastModified) {
				version(Posix) {
					char[] relative_path;
					foreach(i; 0 .. path.count('/'))
						relative_path ~= "../";
					relative_path ~= entry;
					symlink(relative_path, path);
				} else {
					copy(entry, path);
				}
			}
		}
	}
}
