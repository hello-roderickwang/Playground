export function endsWith(str: string, pat: string) {
	return str.length >= pat.length
		&& str.indexOf(pat, str.length - pat.length) !== -1
}
