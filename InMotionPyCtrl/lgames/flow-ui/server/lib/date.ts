export function dateStr (dt = new Date()) {
	const yr = String(dt.getFullYear())
	let mo = String(dt.getMonth() + 1)
	if (mo.length < 2) mo = '0' + mo
	let dy = String(dt.getDate())
	if (dy.length < 2) dy = '0' + dy
	return `${yr}${mo}${dy}`
}
