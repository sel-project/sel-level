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
 * Source: $(HTTP github.com/sel-project/sel-level/sel/level/anvil.d, sel/level/anvil.d)
 */
module sel.level.anvil;

import std.conv : to;
import std.typetuple : TypeTuple;

import sel.level.data : LevelInfo;
import sel.level.level : Level, readLevelInfoCompound, writeLevelInfoCompound;

import sel.nbt.file : JavaLevelFormat;
import sel.nbt.tags : Named, Byte, Int, Long, String, Compound;

import std.stdio : writeln; // debug

private alias LevelInfoValues = TypeTuple!(
	String, "name", "LevelName",
	Long, "seed", "RandomSeed",
	Int, "gamemode", "GameType",
	Int, "difficulty", "Difficulty",
	Byte, "hardcore", "hardcore",
	Long, "time", "Time",
	Long, "dayTime", "DayTime",
	Int, "spawn.x", "SpawnX",
	Int, "spawn.y", "SpawnY",
	Int, "spawn.z", "SpawnZ",
	Byte, "raining", "raining",
	Int, "rainTime", "rainTime",
	Byte, "thundering", "thundering",
	Int, "thunderTime", "thunderTime",
	Byte, "commandsAllowed", "allowCommands",
);

abstract class AbstractAnvil : Level {

	private JavaLevelFormat infoReader;

	public this(string path) {
		super(path);
		this.infoReader = new JavaLevelFormat(this.path ~ "level.dat");
	}

	/**
	 * Throws:
	 * 		FileExpection if level.dat doesn't exist
	 * 		ZlibException if level.dat is badly compressed
	 * 		ConvException if a conversion error occurs
	 * Returns: the informations in level.dat, if found
	 */
	protected override LevelInfo readLevelInfo() {
		auto compound = this.infoReader.load();
		if(compound is null || !compound.has!Compound("Data")) return LevelInfo.init; //TODO throw exception
		LevelInfo ret = readLevelInfoCompound!LevelInfoValues(cast(Compound)compound["Data"]);
		foreach(gamerule ; compound.getValue!Compound("GameRules", [])) {
			if(cast(String)gamerule) {
				immutable value = (cast(String)gamerule).value;
				if(value == "true") {
					ret.gamerules[gamerule.name] = LevelInfo.GameRule(true);
				} else if(value == "false") {
					ret.gamerules[gamerule.name] = LevelInfo.GameRule(false);
				} else {
					ret.gamerules[gamerule.name] = LevelInfo.GameRule(to!int(value));
				}
			}
		}
		return ret;
	}

	protected override void writeLevelInfo(LevelInfo levelInfo) {
		auto data = writeLevelInfoCompound!LevelInfoValues(levelInfo);
		if(levelInfo.gamerules.length) {
			auto compound = new Named!Compound("GameRules");
			foreach(name, gamerule; levelInfo.gamerules) {
				compound[] = new Named!String(name, gamerule.isBool ? to!string(gamerule.bool_) : to!string(gamerule.int_));
			}
			data[] = compound;
		}
		this.infoReader.tag = new Compound(data.rename("Data"));
		this.infoReader.save();
	}

}

class AnvilImpl(string order) : AbstractAnvil { //TODO validate coordinates
	
	public this(string path) {
		super(path);
	}

}

alias Anvil = AnvilImpl!"yzx";

unittest {

	import std.stdio;

	Level anvil = new Anvil("test/Anvil");

	with(anvil.levelInfo) {
		assert(name == "New World");
		assert(seed == 608293555344486561L);
		assert(gamemode == 1);
		assert(hardcore == false);
		assert(time == 15388);
		assert(dayTime == 15388);
		assert(spawn.x == 8);
		assert(spawn.y == 64);
		assert(spawn.z == 224);
		assert(commandsAllowed == true);
	}

}
