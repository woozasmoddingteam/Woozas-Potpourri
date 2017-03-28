#!/usr/bin/env rdmd

import std.stdio;
import std.file;
import std.path;
import std.string;
import std.process;
import core.stdc.stdlib : exit;

void main() {
	// Update submodules
	if(auto err = spawnProcess(["git", "submodule", "update"]).wait) {
		writefln("git returned error code %s!", err);
		exit(1);
	}
	
	if(exists("output"))
		rmdir("output");
	mkdir("output");

	// Mods that need to be merged
	foreach(string modfolder; dirEntries("submodules", SpanMode.shallow)) if(modfolder.baseName != "self") {
		// Look for output folder
		string output = modfolder;
		foreach(string subdir; modfolder.dirEntries(SpanMode.shallow)) {
			if(subdir.isDir && subdir.baseName == "output") {
				output = subdir;
				break;
			}
		}
		output ~= '/';
		writefln("Output folder for %s: %s", modfolder, output);
		foreach(file; output.dirEntries(SpanMode.breadth)) {
			writefln("%s         : %s", file.isDir ? "Dir " : "File", file);
			auto path = chainPath("output", file.chompPrefix(output));
			writefln("Relative path: %s", path);
			if(file.isDir) {
				path.mkdir;
			} else {
			}
		}
	}
}
