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
 * Source: $(HTTP github.com/sel-project/sel-level/sel/level/level.d, sel/level/level.d)
 */
module sel.level.level;

import std.conv : to;
import std.path : buildNormalizedPath, dirSeparator;

import sel.level.data : LevelInfo;

import sel.nbt.tags : Named, Compound;

abstract class Level {

	public immutable string path;

	private bool levelInfoLoaded = false;
	private LevelInfo _levelInfo;

	public this(string path) {
		this.path = buildNormalizedPath(path) ~ dirSeparator;
	}

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

}

LevelInfo readLevelInfoCompound(Info...)(Compound compound) if(Info.length % 3 == 0) {
	LevelInfo ret;
	foreach(i, T; Info) {
		static if(i % 3 == 0) {
			auto tag = Info[i+2] in compound;
			if(tag && cast(T)*tag) mixin("ret." ~ Info[i+1]) = to!(typeof(mixin("ret." ~ Info[i+1])))((cast(T)*tag).value);
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
