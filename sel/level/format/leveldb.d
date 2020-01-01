/*
 * Copyright (c) 2017-2020 sel-project
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */
/**
 * Copyright: Copyright (c) 2017-2020 sel-project
 * License: MIT
 * Authors: Kripth
 * Source: $(HTTP github.com/sel-project/sel-level/sel/level/format/leveldb.d, sel/level/format/leveldb.d)
 */
module sel.level.format.leveldb;

import std.file : exists, isFile, read, write, dirEntries, SpanMode, FileException;
import std.string : endsWith;
import std.typetuple : TypeTuple;
import std.zlib : Compress, UnCompress;

import sel.level.data;
import sel.level.exception;
import sel.level.level;

import sel.math : Vector2;

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
		Compound compound;
		try {
			compound = this.infoReader.load();
		} catch(FileException) {
			throw new LevelInfoException(LevelInfoException.NOT_FOUND, "Level info was not found");
		}
		enforceLevelInfoException(compound !is null, LevelInfoException.WRONG_FORMAT, "Root tag is not a compound");
		return readLevelInfoCompound!LevelInfoValues(compound);
	}

	protected override void writeLevelInfo(LevelInfo levelInfo) {

	}

	protected override Chunk readChunkImpl(Dimension dimension, Vector2!int position) {
		return null;
	}

	protected override ReadChunksResult readChunksImpl(Dimension dimension) {
		// uncompress and copy to uc
		/*foreach(string file ; dirEntries(this.path ~ "db", SpanMode.shallow)) {
			if(file.isFile && file.endsWith(".ldb")) {
				UnCompress uncompress = new UnCompress();
				const(void)[] data = uncompress.uncompress(read(file));
				data ~= uncompress.flush();
				write(this.path ~ "uncompressed_db" ~ file[this.path.length+2..$], data);
			}
		}*/
		return ReadChunksResult.init;
	}

}

unittest {

	auto level = new LevelDB("test/LevelDB");

	with(level.levelInfo) {
		assert(name == "My World");
		assert(seed == 2354673524L);
		assert(gamemode == 1);
		assert(difficulty == 2);
		assert(spawn.x == 152);
		assert(spawn.y == 32767);
		assert(spawn.z == 4);
	}

	level.readChunks();

}
