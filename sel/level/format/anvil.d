/*
 * Copyright (c) 2017-2018 sel-project
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
 * Copyright: Copyright (c) 2017-2018 sel-project
 * License: MIT
 * Authors: Kripth
 * Source: $(HTTP github.com/sel-project/sel-level/sel/level/format/anvil.d, sel/level/format/anvil.d)
 */
module sel.level.format.anvil;

import std.algorithm : sort;
import std.bitmanip : peek;
import std.conv : to, ConvException;
import std.file : exists, isFile, read, write, dirEntries, SpanMode, FileException;
import std.path : dirSeparator;
import std.string : endsWith, split;
import std.system : Endian;
import std.typetuple : TypeTuple;
import std.zlib : Compress, UnCompress, HeaderFormat, ZlibException;

import sel.level.data;
import sel.level.exception;
import sel.level.level;

import sel.math : Vector2;

import sel.nbt.file : JavaLevelFormat;
import sel.nbt.stream : Stream, ClassicStream;
import sel.nbt.tags;

import xbuffer : Buffer;

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

	private ubyte[][Vector2!int] regions;

	public this(string path) {
		super(path);
		this.infoReader = new JavaLevelFormat(this.path ~ "level.dat");
	}

	protected override LevelInfo readLevelInfo() {
		Compound compound;
		try {
			compound = this.infoReader.load();
		} catch(FileException) {
			throw new LevelInfoException(LevelInfoException.NOT_FOUND, "Level info was not found");
		} catch(ZlibException) {
			throw new LevelInfoException(LevelInfoException.BADLY_COMPRESSED, "Level info was badly compressed");
		}
		enforceLevelInfoException(compound !is null, LevelInfoException.WRONG_FORMAT, "Root tag is not a compound");
		enforceLevelInfoException(compound.has!Compound("Data"), LevelInfoException.WRONG_FORMAT, "Compound has no data tag");
		LevelInfo ret = readLevelInfoCompound!LevelInfoValues(cast(Compound)compound["Data"]);
		foreach(gamerule ; compound.getValue!Compound("GameRules", [])) {
			if(cast(String)gamerule) {
				immutable value = (cast(String)gamerule).value;
				if(value == "true") {
					ret.gamerules[gamerule.name] = LevelInfo.GameRule(true);
				} else if(value == "false") {
					ret.gamerules[gamerule.name] = LevelInfo.GameRule(false);
				} else {
					try {
						ret.gamerules[gamerule.name] = LevelInfo.GameRule(to!int(value));
					} catch(ConvException) {
						throw new LevelInfoException(LevelInfoException.WRONG_VALUE, "Gamerule " ~ gamerule.name ~ " cannot be converted to integer");
					}
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

	protected override Chunk readChunkImpl(Dimension dimension, Vector2!int position) {
		auto savedChunk = position in chunks;
		if(savedChunk) return *savedChunk;
		Vector2!int regionPosition = position >> 5;
		immutable file = this.path ~ dimensionPath(dimension) ~ dirSeparator ~ "r." ~ regionPosition.x.to!string ~ "." ~ regionPosition.z.to!string ~ ".mca";
		if(exists(file)) {
			// region exists
			void enforce(bool condition, uint code, lazy string msg, string file=__FILE__, size_t line=__LINE__) {
				enforceChunkException(condition, position, code, msg, file, line);
			}
			auto cached = regionPosition in this.regions;
			ubyte[] data = cached ? *cached : cast(ubyte[])read(file);
			enforce(data.length > 8192, ChunkException.WRONG_FORMAT, "Data is too short");
			// region may be valid
			immutable infoOffset = ((position.x & 31) + (position.z & 31) * 32) * 4;
			immutable info = peek!uint(data, infoOffset);
			immutable timestamp = peek!uint(data, infoOffset + 4096);
			if(info == 0) return null;
			// chunk exists
			immutable offset = (info >> 8) * 4096;
			Buffer buffer = new Buffer(data[offset..offset+(info & 255)*4096]); //TODO validate and avoid range errors
			immutable length = buffer.read!(Endian.bigEndian, uint)();
			enforce(buffer.read!ubyte() == 2, ChunkException.UNKNOWN_COMPRESSION_METHOD, "Chunk has an unknown compression method");
			UnCompress uncompress = new UnCompress();
			const(void)[] ucd = uncompress.uncompress(buffer.readData(length-1));
			ucd ~= uncompress.flush();
			buffer.data = ucd;
			Compound compound = cast(Compound)new ClassicStream!(Endian.bigEndian)(buffer).readTag();
			enforce(compound !is null, ChunkException.WRONG_FORMAT, "Root tag is not a compound");
			Chunk chunk = new Chunk(position, timestamp);
			Compound level = compound.get!Compound("Level", null);
			enforce(level !is null, ChunkException.WRONG_FORMAT, "Level tag does not exist or is not a compound");
			if(level.has!IntArray("Biomes")) {
				// read biomes
				int[] biomes = cast(IntArray)level["Biomes"];
				if(biomes.length == 256) chunk.biomes = biomes;
			}
			if(level.has!List("Sections")) {
				// read sections
				List sections = cast(List)level["Sections"];
				enforce(sections.childType == NBT_TYPE.COMPOUND, ChunkException.WRONG_FORMAT, "Sections are not of type compound");
				foreach(sectionList ; sections) {
					Compound sectionCompound = cast(Compound)sectionList;
					enforce(sectionCompound.has!Byte("Y"), ChunkException.WRONG_FORMAT, "The Y coordinate tag is missing or has a wrong format");
					immutable byte y = cast(Byte)sectionCompound["Y"];
					enforce(y >= 0 && y <= 15, ChunkException.WRONG_FORMAT, "The Y coordinate is not is a valid range (" ~ y.to!string ~ ")");
					enforce(y !in chunk.sections, ChunkException.WRONG_FORMAT, "Duplicate section");
					Chunk.Block[] palette;
					if(sectionCompound.has!List("Palette")) {
						List paletteList = cast(List)sectionCompound["Palette"];
						enforce(paletteList.childType == NBT_TYPE.COMPOUND, ChunkException.WRONG_FORMAT, "Palette's children are not of type compound");
						foreach(paletteValue ; cast(List)sectionCompound["Palette"]) {
							Compound paletteCompound = cast(Compound)paletteValue;
							enforce(paletteCompound.has!String("Name"), ChunkException.WRONG_FORMAT, "Palette value has no name");
							Chunk.Block block = Chunk.Block(cast(String)paletteCompound["Name"]);
							if(paletteCompound.has!Compound("Properties")) {
								foreach(v ; (cast(Compound)paletteCompound["Properties"])[]) {
									String value = cast(String)v;
									if(value !is null) block.properties[value.name] = value;
								}
							}
							palette ~= block;
						}
						if(sectionCompound.has!LongArray("BlockStates")) {
							buffer.data = [];
							foreach(value ; cast(LongArray)sectionCompound["BlockStates"]) {
								buffer.write!(Endian.bigEndian)(value);
							}
						}
					}
				}
			}
			this.chunks[position] = chunk;
			return chunk;
		} else {
			return null;
		}
	}

	protected override ReadChunksResult readChunksImpl(Dimension dimension) {
		ReadChunksResult ret;
		immutable path = this.path ~ dimensionPath(dimension) ~ dirSeparator;
		foreach(string file ; dirEntries(path, SpanMode.shallow)) {
			if(file.isFile && file.endsWith(".mca")) {
				string[] splitted = file[path.length..$-4].split(".");
				if(splitted.length == 3 && splitted[0] == "r") {
					try {
						Vector2!int region = Vector2!int(to!int(splitted[1]) << 5, to!int(splitted[2]) << 5);
						foreach(x ; region.x..region.x+32) {
							foreach(z ; region.z..region.z+32) {
								Vector2!int position = Vector2!int(x, z);
								try {
									ret.chunks[position] = this.readChunk(dimension, position);
								} catch(ChunkException e) {
									ret.exceptions ~= e;
								}
							}
						}
						this.regions.remove(region);
					} catch(ConvException) {}
				}
			}
		}
		return ret;
	}

	private static string dimensionPath(Dimension dimension) {
		if(dimension.java == 0) return "region";
		else return "DIM" ~ dimension.java.to!string ~ dirSeparator ~ "data";
	}

}

class AnvilImpl(string order) : AbstractAnvil if(order.split("").sort.release == ["x", "y", "z"]) {

	public this(string path) {
		super(path);
	}

}

alias Anvil = AnvilImpl!"yzx";

unittest {

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

	Chunk chunk = anvil.readChunk(0, 0);

	assert(chunk !is null);

	assert(chunk.biomes[0] == 0);
	assert(chunk.biomes[$-1] == 7);

}
