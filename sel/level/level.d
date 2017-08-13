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
module sel.level.level;

import std.path;

import sel.level.data : LevelInfo;

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
