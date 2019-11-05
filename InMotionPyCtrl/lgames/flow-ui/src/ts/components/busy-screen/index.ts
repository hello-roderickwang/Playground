import * as m from 'mithril'
import {readyDom} from '../../lib/html'

export default {
	oncreate ({dom}) {
		readyDom(dom)
		dom.classList.add('show')
	},

	onbeforeremove ({dom}) {
		dom.classList.remove('show')
		return new Promise(resolve => {
			dom.addEventListener('transitionend', resolve)
		})
	},

	view() {
		return m('.viewer-bg')
	}
} as m.Component<{},{}>
