/**
 * Ensures this DOM element is rendered and ready so that CSS animations can be applied.
 */
export function readyDom (dom: Element) {
	// Assign value to a variable for side-effects.
	// Reading from the DOM element ensures it is rendered.
	let temp = (dom as HTMLElement).offsetHeight /* tslint:disable-line no-unused-variable */
}
