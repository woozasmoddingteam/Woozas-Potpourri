#!/usr/bin/env rdmd

import std.stdio;
import std.file;

void main() {
	auto dirs = dirEntries("submodules", SpanMode.shallow);
	// Files that need to be removed when re-running
	//auto registered_files = File("registered_submodule_files.txt", "r+");

	// Mods that need to be merged
	foreach(dir; dirs) {
		// Look for output folder
		foreach(subdir; dir.dirEntries) {

		}
	}
}
