import * as m from 'mithril'
import * as stream from 'mithril/stream'
import {readyDom} from '../../lib/html'

let isOpen = false
const options = stream<ModalOptions>()

export interface ModalButton {
	id: string
	text: string
}

export interface ModalOptions {
	title: string
	content?: m.Children
	buttons?: ModalButton[]
	onclick?(id: string): any
}

export function openModal (opts: ModalOptions) {
	if (isOpen) {
		console.warn("Modal already open.")
		//return
	}
	// Deep copy the supplied opts
	const copts = {...opts}
	if (opts.buttons) {
		copts.buttons = opts.buttons.map(b => ({...b}))
	}
	options(copts)
	isOpen = true
}

export function closeModal() {
	isOpen = false
}

export function modalIsOpen() {
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
		return m('.modal-bg',
			m('.modal',
				m('.title-wrapper',
					m('.title', o.title),
				),
				o.content && m('.text', o.content),
				(o.buttons && o.buttons.length > 0) && m('.buttons',
					o.buttons.map(b =>
						m('button',
							{
								type: 'button',
								disabled: !isOpen,
								onclick() {
									isOpen = false
									o.onclick && o.onclick(b.id)
								}
							},
							b.text
						)
					)
				)
			)
		)
	}
} as m.Component<{},{}>
