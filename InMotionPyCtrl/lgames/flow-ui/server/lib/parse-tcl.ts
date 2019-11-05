/**
 * Parse a TCL config file.
 * Returns a JS object with name/value pairs.
 */
export function parseTclConfig (src: string) {
	// Get content between {...}
	let pstart = src.indexOf('{')
	if (pstart < 0) {
		throw new Error("Unexpected format. Could not find opening '{' character")
	}
	pstart += 1
	let pend = src.indexOf('}', pstart)
	if (pend < 0) {
		throw new Error("Unexpected format. Could not find closing '}' character")
	}
	// Split into lines
	const lines = src.substr(pstart, pend - pstart)
		.trim()
		.split('\n')
	// Parse each line as name/value pair
	const obj: {[id: string]: string} = {}
	lines.forEach(l => {
		const line = l.trim()
		if (line) {
			// Find first quote
			const pquote = line.indexOf('"')
			if (pquote < 0) {
				throw new Error('Unexpected format. Could not find " character in line: ' + line)
			}
			const name = line.substr(0, pquote).trim()
			const val = line.substr(pquote + 1, line.length - (pquote + 1) - 1).trim()
			obj[name] = val
		}
	})
	return obj
}
