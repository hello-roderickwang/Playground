export type Dict<T> = {
	[id: string]: T
}

export interface Static {
	/** Creates an empty dictionary with no prototype. */
	<T>(dict?: Dict<T>): Dict<T>
	/** Returns true if object has no (own) entries. */
	isEmpty (dict: Dict<any>): boolean
	/** Returns number of (own) keys. */
	size (dict: Dict<any>): number
	/** Returns true if object has (own) key. */
	has (dict: Dict<any>, key: string): boolean
	/** Returns key for first matched value otherwise undefined. */
	keyOf<T>(dict: Dict<T>, v: T): string | undefined
	/** Returns nth iterated key or undefined. Object key order caveats apply. */
	keyAt (dict: Dict<any>, index: number): string | undefined
	/** Returns first iterated key or undefined. Object key order caveats apply. */
	firstKey (dict: Dict<any>): string | undefined
	/** Returns last iterated key or undefined. Object key order caveats apply. */
	lastKey (dict: Dict<any>): string | undefined
}

function create<T>(o?: Dict<T>): Dict<T> {
	const d = Object.create(null)
	if (o) {
		for (const k in o) {
			if (has(o, k)) d[k] = o[k]
		}
	}
	return d
}

function isEmpty (d: Dict<any>) {
	for (const k in d) {
		if (has(d, k)) return false
	}
	return true
}

function size (d: Dict<any>) {
	let s = 0
	for (const k in d) {
		if (has(d, k)) ++s
	}
	return s
}

function has (d: Dict<any>, k: string) {
	return Object.prototype.hasOwnProperty.call(d, k)
}

function keyOf<T>(d: Dict<T>, v: T) {
	for (const k in d) {
		if (has(d, k)) {
			if (d[k] === v) return k
		}
	}
	return undefined
}

function keyAt (d: Dict<any>, i: number) {
	let j = 0
	for (const k in d) {
		if (has(d, k)) {
			if (j === i) return k
			j += 1
		}
	}
	return undefined
}

function firstKey (d: Dict<any>) {
	for (const k in d) {
		if (has(d, k)) return k
	}
	return undefined
}

function lastKey (d: Dict<any>) {
	let kLast: string | undefined
	for (const k in d) {
		if (has(d, k)) kLast = k
	}
	return kLast
}

const D: Static = create as any
D.isEmpty = isEmpty
D.size = size
D.has = has
D.keyOf = keyOf
D.keyAt = keyAt
D.firstKey = firstKey
D.lastKey = lastKey

export default D
