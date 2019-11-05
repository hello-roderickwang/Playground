import * as m from 'mithril'
import {dateTimeStr} from '../../lib/date'
import {openModal} from '../modal'
//import {openViewer} from '../viewer'
import {ROBOT_STATUS, ROBOT_BUSY, PATIENT, CLINID, pollRobotStatus} from '../../state'

let dateTimer: number | undefined
let statusTimer: number | undefined

function renderDateTime() {
	const el = document.getElementById('current-date-time')
	if (el) {
		el.textContent = dateTimeStr()
	}
	dateTimer = window.setTimeout(renderDateTime, 60000)
}

/**
 * Check if the current route is ok to be on if the robot status is not ready
 */
function checkRouteSafe() {
	const r = m.route.get()
	return r === '/' || r === '/home' || r === '/admin' || r === '/patient/folders'
}

/**
 * Poll the robot status via the server.
 * This loop will keep itself running.
 */
function pollStatus() {
	if (!ROBOT_BUSY()) {
		pollRobotStatus().then(() => {
			const s = ROBOT_STATUS()
			if (s == null || s.calibrationStatus !== 'calibrated' || s.readyStatus !== 'ready') {
				if (checkRouteSafe()) {
					// Route is ok for not-ready robot. Test robot status again in 3 sec
					statusTimer = window.setTimeout(pollStatus, 3000)
				} else {
					openModal({
						title: "Robot status not ready",
						content: "You will be returned to the home screen.",
						buttons: [{id: 'ok', text: "Ok"}],
						onclick() {
							// Start polling again when modal dismissed
							m.route.set('/home')
							statusTimer = window.setTimeout(pollStatus, 3000)
						}
					})
				}
			} else {
				/* const delay = (s != null && s.calibrationStatus === 'calibrated' && s.readyStatus === 'ready')
					? 10000 : 3000 */
				// All ok, don't test for another 10 sec
				statusTimer = window.setTimeout(pollStatus, 10000)
			}
		})
	} else {
		const s = ROBOT_STATUS()
		const delay = (s != null && s.calibrationStatus === 'calibrated' && s.readyStatus === 'ready')
			? 10000 : 3000
		statusTimer = window.setTimeout(pollStatus, delay)
	}
}

function viewHelp () {
	m.request({
		url: '/api/open-pdf-window',
		method: 'post',
		data: {url: 'pdf/user-manual.pdf'}
	})
}

function confirmEndTherapy (onconfirm: () => any) {
	openModal({
		title: "End therapy session",
		content: "Are you sure you want to end the therapy session?",
		buttons: [
			{id: 'yes', text: "Yes"},
			{id: 'no', text: "No"}
		],
		onclick(id) {
			if (id === 'yes') {
				onconfirm()
			}
		}
	})
}

export default {
	oncreate() {
		dateTimer = window.setTimeout(renderDateTime, 60000)
		statusTimer = window.setTimeout(pollStatus, 3000)
	},

	onremove() {
		if (dateTimer != null) {
			window.clearTimeout(dateTimer)
			dateTimer = undefined
		}
		if (statusTimer != null) {
			window.clearTimeout(statusTimer)
			statusTimer = undefined
		}
	},

	view() {
		const status = ROBOT_STATUS()
		const statusOk = status != null
			&& status.calibrationStatus === 'calibrated' && status.readyStatus === 'ready'
		let patientIdStr = PATIENT() ? PATIENT()!.id : 'N/A'
		let clinIdStr = CLINID() || 'N/A'
		let statusClass = ''
		let statusText = "Ready"
		if (!status || status.calibrationStatus === undefined || status.readyStatus === undefined) {
			statusClass = ' red'
			statusText = "Error"
		} else {
			if (status.readyStatus === 'busy') {
				statusClass = ' yellow'
				statusText = 'Not Ready'
			} else if (status.calibrationStatus === 'uncalibrated') {
				statusClass = ' yellow'
				statusText = 'Cal'
			}
		}

		const route = m.route.get()

		return m('header',
			m('.home-btn-wrapper',
				m('button',
					{
						type: 'button',
						disabled: route === '/home' || route === '/patient/dashboard'
							|| route === '/patient/edit' || route === '/therapy-history',
						onclick() {
							if (route.startsWith('/robot')) {
								confirmEndTherapy(() => {m.route.set('/home')})
							} else {
								m.route.set('/home')
							}
						}
					},
					"Home"
				)
			),
			m('.patient-dashboard-btn-wrapper',
				m('button',
					{
						disabled: !PATIENT() || !statusOk
							|| (!route.startsWith('/robot') && route !== '/therapy-history' && route !== '/patient/edit'),
						onclick() {
							m.route.set('/patient/dashboard')
						}
						/* onclick() {
							if (PATIENT()) {
								if (route.indexOf('/robot') === 0) {
									confirmEndTherapy(() => {m.route.set('/patient/dashboard')})
								} else {
									m.route.set('/patient/dashboard')
								}
							} else {
								openModal({
									title: "You have not selected a Patient",
									buttons: [{id: 'ok', text: "Ok"}]
								})
							}
						} */
					},
					"Patient Dashboard"
				)
			),
			m('.time-status-div',
				m('div',
					m('div', {id: 'current-date-time'}, dateTimeStr()),
					m('div', {class: 'robot-status-wrapper' + statusClass},
						m('span', "Robot Status: "),
						m('span', statusText)
					)
				),
			),
			m('.time-status-div',
				m('div',
					m('div', "Clinician ID: " + clinIdStr),
					m('div.patient-id', "Patient ID: " + patientIdStr)
				)
			),
			m('.help-btn-wrapper',
				m('button',
					{
						type: 'button',
						onclick() {
							viewHelp()
						}
					},
					"Help"
				)
			),
			m('.logo-wrapper',
				m('img', {src: 'img/bionik-logo-white.svg'})
			),
		)
	}
} as m.Component<{},{}>
