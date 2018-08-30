/*
 * Copyright (c) 2017-2018 SEL
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU Lesser General Public License for more details.
 * 
 */
/**
 * Copyright: Copyright © 2017-2018 SEL
 * License: LGPL-3.0
 * Authors: Kripth
 * Source: $(HTTP github.com/sel-project/sel-level/sel/level/leveldb.d, sel/level/leveldb.d)
 */
module sel.level.leveldb;

import std.typetuple : TypeTuple;

import sel.level.data : LevelInfo;
import sel.level.level : Level, readLevelInfoCompound, writeLevelInfoCompound;

import sel.nbt.file : PocketLevelFormat;
import sel.nbt.tags;

import std.stdio : writeln; // debug

private alias LevelInfoValues = TypeTuple!(
	String, "name", "LevelName",
	Long, "seed", "RandomSeed",
	Int, "gamemode", "GameType",
	Int, "difficulty", "Difficulty",
	Long, "time", "Time",
	Int, "spawn.x", "SpawnX",
	Int, "spawn.y", "SpawnY",
	Int, "spawn.z", "SpawnZ",
	Byte, "raining", "rainLevel",
	Int, "rainTime", "rainTime",
	Byte, "thundering", "thunderLevel",
	Int, "thunderTime", "thunderTime",
	Byte, "commandsAllowed", "commandsEnabled",
);

class LevelDB : Level {

	private PocketLevelFormat infoReader;

	public this(string path) {
		super(path);
		this.infoReader = new PocketLevelFormat(this.path ~ "level.dat");
	}

	protected override LevelInfo readLevelInfo() {
		auto compound = this.infoReader.load();
		if(compound !is null) return readLevelInfoCompound!LevelInfoValues(compound);
		else return LevelInfo.init;
	}

	protected override void writeLevelInfo(LevelInfo levelInfo) {

	}

}

unittest {

	auto level = new LevelDB("test/LevelDB");

	with(level.levelInfo) {
		assert(name == "My World");
		assert(seed == 2245251969L);
		assert(gamemode == 0);
		assert(spawn.x == 8);
		assert(spawn.y == 32767);
		assert(spawn.z == 32);
	}

}
