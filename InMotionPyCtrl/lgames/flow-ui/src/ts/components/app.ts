import * as m from 'mithril'
import {ROBOT_BUSY} from '../state'
import header from './header'
import modal, {modalIsOpen} from './modal'
import viewer, {viewerIsOpen} from './viewer'
import pdfViewer, {pdfViewerIsOpen} from './viewer-pdf'
import busyScreen from './busy-screen'

export default {
	view ({children}) {
		return [
			m('.app',
				m(header),
				children
			),
			viewerIsOpen() && m(viewer),
			pdfViewerIsOpen() && m(pdfViewer),
			modalIsOpen() && m(modal),
			ROBOT_BUSY() && m(busyScreen)
		]
	}
} as m.Component<{},{}>
