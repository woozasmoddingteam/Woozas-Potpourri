#!/usr/bin/env rdmd

import std.stdio;
import std.file;
import std.path;
import std.string;
import std.array;
import std.process;
import core.stdc.stdlib : exit;

void main() {
	// Update submodules
	foreach(cmd; ["init", "update"]) if(auto err = spawnProcess(["git", "submodule", cmd]).wait) {
		stderr.writefln("git returned error code %s!", err);
		exit(1);
	}
	
	if(exists("output"))
		rmdirRecurse("output");
	mkdir("output");

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
			if(entry.baseName[0] == '.') {
				writefln("Ignored %s!", path);
			} else if(entry.isDir) {
				if(!path.exists) path.mkdir;
			} else if(path.exists) {
				stderr.writefln("Already exists: %s!", path);
			} else {
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
