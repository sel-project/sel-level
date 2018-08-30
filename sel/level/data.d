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
 * Source: $(HTTP github.com/sel-project/sel-level/sel/level/data.d, sel/level/data.d)
 */
module sel.level.data;

import sel.level.util;

import sel.nbt : Compound;

/**
 * Informations about a level (world) usually found in level.dat
 * in NBT format.
 */
struct LevelInfo {

	/**
	 * Name of the world.
	 */
	string name;

	/**
	 * Seed of the world.
	 */
	long seed;

	/**
	 * Gamemode currently used in the world.
	 * 0 for survival, 1 for creative, 2 for adventure and
	 * 3 for spectator.
	 */
	ubyte gamemode;

	/**
	 * Current difficulty of the world.
	 * 0 for peacefully, 1 for easy, 2 for normal and
	 * 3 for hard.
	 */
	ubyte difficulty;

	/**
	 * Indicates whether the world is deleted when the
	 * player dies.
	 */
	bool hardcore;

	ulong time;
	ulong dayTime;

	Vector3!int spawn;

	bool raining;
	uint rainTime;
	bool thundering;
	uint thunderTime;

	bool commandsAllowed;

	GameRule[string] gamerules;

	static struct GameRule {

		bool isBool;

		union {
			bool bool_;
			int int_;
		}

		this(bool bool_) {
			this.isBool = true;
			this.bool_ = bool_;
		}

		this(int int_) {
			this.isBool = false;
			this.int_ = int_;
		}

	}

}

enum Dimension : Data!byte {

	overworld = Data!byte(0, 0),
	nether = Data!byte(1, -1),
	end = Data!byte(2, 1),

}

class Chunk {

	Vector2!int position;
	immutable uint timestamp;

	int[256] biomes;

	Section[uint] sections;

	this(Vector2!int position, uint timestamp) {
		this.position = position;
		this.timestamp = timestamp;
	}

	static struct Section {

		byte[4096] blockLight, skyLight;
		string[4096] blocks;

	}

}
