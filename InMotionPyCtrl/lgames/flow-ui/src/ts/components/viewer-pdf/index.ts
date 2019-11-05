import * as m from 'mithril'
import * as stream from 'mithril/stream'
import {readyDom} from '../../lib/html'
declare const PDFJS: any

let isOpen = false
const options = stream<PdfViewerOptions>()

export interface PdfViewerOptions {
	title?: string
	url: string
	onclose?(): any
}

export function openPdfViewer (opts: PdfViewerOptions) {
	if (isOpen) {
		console.warn("Viewer already open.")
		return
	}
	// Deep copy the supplied opts
	const copts = {...opts}
	options(copts)
	isOpen = true
}

export function closePdfViewer() {
	isOpen = false
}

export function pdfViewerIsOpen() {
	return isOpen
}

function loadPDF (canvas: HTMLCanvasElement, url: string) {
	PDFJS.workerSrc = 'js/vendor/pdf.worker.min.js'
	return PDFJS.getDocument(url).then((pdf: any) => {
		// Fetch the first page
		pdf.getPage(1).then((page: any) => {
			const scale = 1.0
			const viewport = page.getViewport(scale)
			// Prepare canvas using PDF page dimensions
			const context = canvas.getContext('2d');
			canvas.height = viewport.height
			canvas.width = viewport.width
			// Render PDF page into canvas context
			const renderContext = {
				canvasContext: context,
				viewport: viewport
			}
			page.render(renderContext)
		})
	})
}

export default {
	oncreate ({dom}) {
		loadPDF(
			dom.querySelector('canvas')!,
			options().url
		)
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
				m('canvas', {
					id: 'pdf-canvas',
					style: 'width: 100%; height: 100%; background-color: #888'
				})
			)
		)
	}
} as m.Component<{},{}>
