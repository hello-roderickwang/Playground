import * as m from 'mithril'
import * as stream from 'mithril/stream'
import {readyDom} from '../../lib/html'

let isOpen = false
const options = stream<ViewerOptions>()

export interface ViewerOptions {
	title?: string
	url: string
	onclose?(): any
}

export function openViewer (opts: ViewerOptions) {
	if (isOpen) {
		console.warn("Viewer already open.")
		return
	}
	// Deep copy the supplied opts
	const copts = {...opts}
	options(copts)
	isOpen = true
}

export function closeViewer() {
	isOpen = false
}

export function viewerIsOpen() {
	return isOpen
}

export default {
	oncreate ({dom}) {
		readyDom(dom)
		dom.classList.add('show')
	},

	onbeforeremove ({dom}) {
		// Fade out menu on close
		dom.classList.remove('show')
		return new Promise(resolve => {
			dom.addEventListener('transitionend', resolve)
		})
	},

	view() {
		const o = options()
		return m('.viewer-bg',
			m('.viewer',
				m('.header',
					m('.title', o.title),
					m('button.close',
						{
							onclick() {
								isOpen = false
								o.onclose && o.onclose()
							}
						},
						m.trust('&times;')
					)
				),
				m('iframe', {src: o.url})
			)
		)
	}
} as m.Component<{},{}>
