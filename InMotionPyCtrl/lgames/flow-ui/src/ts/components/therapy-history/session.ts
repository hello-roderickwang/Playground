import * as m from 'mithril'
import {readyDom} from '../../lib/html'

interface Attrs {
	content?: m.Children
	onclose?(): any
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

	view({attrs: {content, onclose}}) {
		return m('.modal-bg',
			m('.modal',
				{style: 'width: auto'},
				m('.title-wrapper',
					m('.title', "Session Activities")
				),
				m('.content', content),
				m('.buttons',
					m('button',
						{
							type: 'button',
							onclick() {
								onclose && onclose()
							},
						},
						"Close"
					)
				)
			)
		)
	}
} as m.Component<Attrs,{}>
