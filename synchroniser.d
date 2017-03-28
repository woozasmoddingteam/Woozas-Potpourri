#!/usr/bin/env rdmd

import std.stdio;
import std.file;
import std.path;
import std.array;
import std.process;
import core.stdc.stdlib : exit;

void main() {
	// Update submodules
	if(auto err = spawnProcess(["git", "submodule", "update"]).wait) {
		writefln("git returned error code %s!", err);
		exit(1);
	}
		
	// Files that need to be removed when re-running
	if(exists("registered_files.txt")) foreach(string file; readText("registered_files.txt").split('\n')) if(exists(file)) {
		writefln("Removing file %s...", file);
		file.remove;
	}

	// Mods that need to be merged
	foreach(string modfolder; dirEntries("submodules", SpanMode.shallow)) {
		// Look for output folder
		string output = modfolder;
		foreach(string subdir; modfolder.dirEntries(SpanMode.shallow)) {
			if(subdir.isDir && subdir.baseName == "output") {
				output = subdir;
				break;
			}
		}
		writefln("Output folder for %s: %s", modfolder, output);
	}
}
