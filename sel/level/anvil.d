/*
 * Copyright (c) 2017 SEL
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
module sel.level.anvil;

import std.conv : to;
import std.typetuple : TypeTuple;

import sel.level.data;
import sel.level.level : Level;

import sel.nbt.file : JavaLevelFormat;
import sel.nbt.tags;

import std.stdio : writeln;

private alias LevelInfoValues = TypeTuple!(
	String, "name", "LevelName", "",
	Long, "seed", "RandomSeed", 0,
	Int, "gamemode", "GameType", 0,
	Int, "difficulty", "Difficulty", 1,
	Byte, "hardcore", "hardcore", 0,
	Long, "time", "Time", 0,
	Long, "dayTime", "DayTime", 0,
	Int, "spawnX", "SpawnX", 0,
	Int, "spawnY", "SpawnY", 0,
	Int, "spawnZ", "SpawnZ", 0,
	Byte, "raining", "raining", 0,
	Int, "rainTime", "rainTime", 0,
	Byte, "thundering", "thundering", 0,
	Int, "thunderTime", "thunderTime", 0,
	Byte, "commandsAllowed", "allowCommands", 0,
);

abstract class AbstractAnvil : Level {

	private JavaLevelFormat info_reader;

	public this(string path) {
		super(path);
		this.info_reader = new JavaLevelFormat(this.path ~ "level.dat");
	}

	/**
	 * Throws:
	 * 		FileExpection if level.dat doesn't exist
	 * 		ZlibException if level.dat is badly compressed
	 * 		ConvException if a conversion error occurs
	 * Returns: the informations in level.dat, if found
	 */
	public override LevelInfo readLevelInfo() {
		auto compound = this.info_reader.load();
		if(compound is null || !compound.has!Compound("Data")) return LevelInfo.init; //TODO throw exception
		compound = cast(Compound)compound["Data"];
		LevelInfo ret;
		foreach(i, T; LevelInfoValues) {
			static if(i % 4 == 0) mixin("ret." ~ LevelInfoValues[i+1]) = to!(typeof(mixin("ret." ~ LevelInfoValues[i+1])))(compound.getValue!T(LevelInfoValues[i+2], LevelInfoValues[i+3]));
		}
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

	public override void writeLevelInfo(LevelInfo levelInfo) {
		auto data = new Named!Compound("Data");
		foreach(i, T; LevelInfoValues) {
			static if(i % 4 == 0) data[] = new Named!T(LevelInfoValues[i+2], mixin("levelInfo." ~ LevelInfoValues[i+1]));
		}
		if(levelInfo.gamerules.length) {
			auto compound = new Named!Compound("GameRules");
			foreach(name, gamerule; levelInfo.gamerules) {
				compound[] = new Named!String(name, gamerule.is_boolean ? to!string(gamerule.bool_) : to!string(gamerule.int_));
			}
			data[] = compound;
		}
		this.info_reader.tag = new Compound(data);
		this.info_reader.save();
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
		assert(seed == 670593098951997977L);
		assert(gamemode == 0);
		assert(difficulty == 1);
		assert(hardcore == false);
		assert(time == 75727);
		assert(dayTime == 85211);
		assert(spawnX == -252);
		assert(spawnY == 64);
		assert(spawnZ == 252);
		assert(commandsAllowed == false);
	}

}
