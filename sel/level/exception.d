/*
 * Copyright (c) 2017-2019 sel-project
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
 * Copyright: Copyright (c) 2017-2019 sel-project
 * License: MIT
 * Authors: Kripth
 * Source: $(HTTP github.com/sel-project/sel-level/sel/level/exception.d, sel/level/exception.d)
 */
module sel.level.exception;

import sel.math : Vector2;

class LevelException : Exception {
	
	public immutable uint code;
	
	this(uint code, string msg, string file=__FILE__, size_t line=__LINE__) {
		super(msg, file, line);
		this.code = code;
	}
	
}

class LevelInfoException : LevelException {
	
	enum : uint {

		NOT_FOUND = 1,
		BADLY_COMPRESSED,
		WRONG_FORMAT,
		WRONG_VALUE,
		
	}
	
	this(uint code, string msg, string file=__FILE__, size_t line=__LINE__) {
		super(code, msg, file, line);
	}
	
}

class ChunkException : LevelException {
	
	enum : uint {
		
		INSUFFICIENT_DATA = 1,
		UNKNOWN_COMPRESSION_METHOD,
		WRONG_FORMAT,
		
	}

	Vector2!int position;
	
	this(Vector2!int position, uint code, string msg, string file=__FILE__, size_t line=__LINE__) {
		super(code, msg, file, line);
		this.position = position;
	}
	
}

void enforceLevelInfoException(bool condition, uint code, lazy string msg, string file=__FILE__, size_t line=__LINE__) {
	if(!condition) throw new LevelInfoException(code, msg, file, line);
}

void enforceChunkException(bool condition, Vector2!int position, uint code, lazy string msg, string file=__FILE__, size_t line=__LINE__) {
	if(!condition) throw new ChunkException(position, code, msg, file, line);
}
