export function range (start: number, end: number, step = 1): number[] {
	const size = Math.ceil((end - start) / step)
	if (size <= 0) return []
	const a = new Array<number>(size)
	for (let i = 0; i < size; ++i) {
		a[i] = start + step * i
	}
	return a
}

export function sample<T> (arr: Array<T>, size?: number): Array<T> {
	if (size == null) size = arr.length
	if (!size || size < 1 || arr.length < 1) return []
	if (size > arr.length) size = arr.length
	const result = new Array<T>(size)
	const a = arr.slice()
	for (let i = 0; i < size; ++i) {
		const r = Math.floor(Math.random() * a.length)
		result[i] = a[r]
		a.splice(r, 1)
	}
	return result
}

export function countWhere<T> (arr: Array<T>, f: (t: T) => boolean) {
	let n = 0
	for (let i = 0; i < arr.length; ++i) {
		if (f(arr[i])) ++n
	}
	return n
}
