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
 * Source: $(HTTP github.com/sel-project/sel-level/sel/level/data.d, sel/level/data.d)
 */
module sel.level.data;

struct LevelInfo {

	string name;

	long seed;

	ubyte gamemode;
	ubyte difficulty;
	bool hardcore;

	ulong time;
	ulong dayTime;

	Position!int spawn;

	bool raining;
	uint rainTime;
	bool thundering;
	uint thunderTime;

	bool commandsAllowed;

	GameRule[string] gamerules;

	static struct Position(T) {

		T x, y, z;

	}

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
