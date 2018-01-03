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
module sel.level.level;

import std.conv : to;
import std.path : buildNormalizedPath, dirSeparator;

import sel.level.data : LevelInfo;

import sel.nbt.tags : Named, Compound;

abstract class Level {

	public immutable string path;

	private bool _level_info_init = false;
	private LevelInfo _level_info;

	public this(string path) {
		this.path = buildNormalizedPath(path) ~ dirSeparator;
	}

	public final @property ref LevelInfo levelInfo() {
		if(!this._level_info_init) this.reloadLevelInfo();
		return this._level_info;
	}

	public final @property ref LevelInfo levelInfo(LevelInfo levelInfo) {
		this._level_info_init = true;
		return this._level_info = _level_info;
	}

	public final void reloadLevelInfo() {
		this._level_info_init = true;
		this._level_info = this.readLevelInfo();
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
