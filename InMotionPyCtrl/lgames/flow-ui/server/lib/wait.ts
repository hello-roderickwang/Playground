export function waitMS (milliseconds: number): Promise<number> {
	return new Promise(resolve => {
		setTimeout(() => {resolve(milliseconds)}, milliseconds)
	})
}
