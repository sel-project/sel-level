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
 * Source: $(HTTP github.com/sel-project/sel-level/sel/level/level.d, sel/level/level.d)
 */
module sel.level.level;

import std.conv : to, ConvException;
import std.path : buildNormalizedPath, dirSeparator;

import sel.level.data;
import sel.level.exception : LevelInfoException, ChunkException;
import sel.level.util;

import sel.math : Vector2;

import sel.nbt.tags : Named, Compound;

abstract class Level {

	public immutable string path;

	private bool levelInfoLoaded = false;
	private LevelInfo _levelInfo;

	public Chunk[Vector2!int] chunks;

	public this(string path) {
		this.path = buildNormalizedPath(path) ~ dirSeparator;
	}

	/**
	 * Throws: LevelInfoExeption if level.dat has an invalid format.
	 */
	public final @property ref LevelInfo levelInfo() {
		if(!this.levelInfoLoaded) this.reloadLevelInfo();
		return this._levelInfo;
	}

	public final @property ref LevelInfo levelInfo(LevelInfo levelInfo) {
		this.levelInfoLoaded = true;
		return this._levelInfo = _levelInfo;
	}

	public final void reloadLevelInfo() {
		this.levelInfoLoaded = true;
		this._levelInfo = this.readLevelInfo();
	}

	protected abstract LevelInfo readLevelInfo();

	protected abstract void writeLevelInfo(LevelInfo);

	/**
	 * Reads the chunk at the given coordinates.
	 * Throws: ChunkException
	 */
	public final Chunk readChunk(Dimension dimension, Vector2!int position) {
		return this.readChunkImpl(dimension, position);
	}

	/// ditto
	public final Chunk readChunk(Dimension dimension, int x, int z) {
		return this.readChunk(dimension, Vector2!int(x, z));
	}

	/// ditto
	public final Chunk readChunk(Vector2!int position) {
		return this.readChunk(Dimension.overworld, position);
	}

	/// ditto
	public final Chunk readChunk(int x, int z) {
		return this.readChunk(Vector2!int(x, z));
	}

	protected abstract Chunk readChunkImpl(Dimension, Vector2!int);

	/**
	 * Reads all chunks in the level.
	 * Throws: ChunkException
	 */
	public final ReadChunksResult readChunks(Dimension dimension=Dimension.overworld) {
		return this.readChunksImpl(dimension);
	}

	protected abstract ReadChunksResult readChunksImpl(Dimension);

}

struct ReadChunksResult {

	Chunk[Vector2!int] chunks;
	ChunkException[] exceptions;

}

LevelInfo readLevelInfoCompound(Info...)(Compound compound) if(Info.length % 3 == 0) {
	LevelInfo ret;
	foreach(i, T; Info) {
		static if(i % 3 == 0) {
			auto tag = Info[i+2] in compound;
			if(tag && cast(T)*tag) {
				try {
					mixin("ret." ~ Info[i+1]) = to!(typeof(mixin("ret." ~ Info[i+1])))((cast(T)*tag).value);
				} catch(ConvException) {
					throw new LevelInfoException(LevelInfoException.WRONG_VALUE, "Tag " ~ Info[i+2] ~ " cannot be converted to " ~ typeof(mixin("ret." ~ Info[i+1])).stringof);
				}
			}
		}
	}
	return ret;
}

Compound writeLevelInfoCompound(Info...)(LevelInfo levelInfo) if(Info.length % 3 == 0) {
	Compound ret = new Compound();
	foreach(i, T; Info) {
		static if(i % 3 == 0) ret[] = new Named!T(Info[i+2], mixin("levelInfo." ~ Info[i+1]));
	}
	return ret;
}
