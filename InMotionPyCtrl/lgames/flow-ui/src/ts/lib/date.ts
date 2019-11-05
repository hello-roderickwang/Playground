import {range} from './array'

export function dateTimeStr() {
	const d = new Date()
	let yr = String(d.getFullYear())
	let mo = String(d.getMonth() + 1)
	if (mo.length < 2) mo = '0' + mo
	let dy = String(d.getDate())
	if (dy.length < 2) dy = '0' + dy
	const h = d.getHours()
	let h12 = h % 12
	if (h12 === 0) h12 = 12
	let hr = String(h12)
	let min = String(d.getMinutes())
	if (min.length < 2) min = '0' + min
	const ap = h >= 12 ? 'PM' : 'AM'
	return `${hr}:${min}${ap} ${mo}/${dy}/${yr}`
}

export function dateStr (dt = new Date()) {
	const yr = String(dt.getFullYear())
	let mo = String(dt.getMonth() + 1)
	if (mo.length < 2) mo = '0' + mo
	let dy = String(dt.getDate())
	if (dy.length < 2) dy = '0' + dy
	//return `${yr}${mo}${dy}`
	return `${mo}/${dy}/${yr}`
}

export function timeStr (dt = new Date()) {
	const h = dt.getHours()
	let h12 = h % 12
	if (h12 === 0) h12 = 12
	let hr = String(h12)
	let min = String(dt.getMinutes())
	if (min.length < 2) min = '0' + min
	const ap = h >= 12 ? 'PM' : 'AM'
	return `${hr}:${min} ${ap}`
}

export function age (dt: Date) {
	const now = new Date()
	const ya = dt.getFullYear()
	const ma = dt.getMonth()
	const da = dt.getDate()
	const yn = now.getFullYear()
	const mn = now.getMonth()
	const dn = now.getDate()
	let a = yn - ya
	if (ma > mn) {
		a -= 1
	} else if (ma === mn && da > dn) {
		a -= 1
	}
	return a
}

export const shortMonths = [
	'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
]

export const days31 = range(1, 32)
