// Client UI Application entry point

import * as m from 'mithril'
import router from './router'
import {pollRobotStatus} from './state'

// Initialize application routes, default to '/'
m.route(document.body, '/', router)

const DEFAULT_WIDTH = 1320
const DEFAULT_FONT_SIZE = 16

// Scale layout on smaller screens
function resize() {
	const w = window.innerWidth
	const scale = Math.min(w / DEFAULT_WIDTH, 1.0)
	document.body.style.fontSize = (DEFAULT_FONT_SIZE * scale) + 'px'
}

window.addEventListener('resize', resize)
resize()

// Perform an initial robot status poll so we have a status
// before clinician logs in.
// Thereafter, the header component will be polling.
setTimeout(() => {
	pollRobotStatus()
}, 1000)
