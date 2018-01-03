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
	Int, "spawnX", "SpawnX",
	Int, "spawnY", "SpawnY",
	Int, "spawnZ", "SpawnZ",
	Byte, "raining", "rainLevel",
	Int, "rainTime", "rainTime",
	Byte, "thundering", "thunderLevel",
	Int, "thunderTime", "thunderTime",
	Byte, "commandsAllowed", "commandsEnabled",
);

class LevelDB : Level {

	private PocketLevelFormat info_reader;

	public this(string path) {
		super(path);
		this.info_reader = new PocketLevelFormat(this.path ~ "level.dat");
	}

	protected override LevelInfo readLevelInfo() {
		auto compound = this.info_reader.load();
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
		assert(spawnX == 8);
		assert(spawnY == 32767);
		assert(spawnZ == 32);
	}

}
