import * as m from 'mithril'
import {Patient} from '../../../../../server/models/patient'
import {API_URL} from '../../../config'
import {PATIENT, REPORT_GENERATED} from '../../../state'
import checkbox from '../../widgets/checkbox'
import radio from '../../widgets/radio'
import {openModal, closeModal} from '../../modal'

const SCAN_FREQUENCY = 3000

const reports = [
	{label: "Evaluation Report (Also Contains Patient Report)", name: "evaluation-report"},
	{label: "Daily Therapy Report", name: "daily-therapy-report"},
	{label: "Session Log", name: "session-log"},
	{label: "Performance Metrics", name: "performance-metrics"}
]

let reportBusy = false
let usbDrives: string[] = []
let usbBusy = false

function generateReport(patid: string) {
	if (reportBusy) {
		console.warn("Busy generating report")
		return
	}
	reportBusy = true
	openModal({title: "Generating report..."})
	setTimeout(() => {
		return m.request({
			url: API_URL + '/report/generate',
			method: 'POST',
			data: {patid}
		}).then(() => {
			closeModal()
			window.setTimeout(() => {
				openModal({
					title: "Report successfuly generated.",
					buttons: [{id: 'ok', text: "Ok"}],
					onclick() {reportBusy = false}
				})
				REPORT_GENERATED(true)
				m.redraw()
			}, 500)
		}).catch(err => {
			console.warn("Error generating report: ", err)
			closeModal()
			setTimeout(() => {
				openModal({
					title: "Error generating report",
					content: err.message,
					buttons: [{id: 'ok', text: "Ok"}],
					onclick() {reportBusy = false}
				})
				m.redraw()
			}, 500)
		})
	}, 200)
}

function viewReport (patid: string) {
	//openPdfViewer({url: '/api/report/' + patient.id})
	m.request({
		url: '/api/open-pdf-window',
		method: 'post',
		data: {url: '/api/report/' + patid}
	})
}

function copyReportToUSB (patid: string) {
	if (reportBusy) {
		console.warn("Can't copy report - busy.")
		return
	}
	reportBusy = true
	openModal({title: "Copying report to USB..."})
	window.setTimeout(() => {
		m.request({
			url: '/api/media/copy-report',
			method: 'post',
			data: {patid}
		}).then(() => {
			closeModal()
			window.setTimeout(() => {
				openModal({
					title: "Report copied to USB drive.",
					buttons: [{id: 'ok', text: "Ok"}],
					onclick() {reportBusy = false}
				})
				m.redraw()
			}, 500)
		}).catch(err => {
			console.warn("Error copying report: ", err)
			closeModal()
			window.setTimeout(() => {
				openModal({
					title: "Error copying report",
					content: err.message,
					buttons: [{id: 'ok', text: "Ok"}],
					onclick() {reportBusy = false}
				})
				m.redraw()
			}, 500)
		})
	}, 200)
}

const reportsComp: m.FactoryComponent<{}> = function() {
	let timer: number | undefined

	function scanDrives() {
		if (!usbBusy) {
			console.log('Scanning USB drives')
			m.request<{devices: string[]}>({url: '/api/media/devices'}).then(
				({devices}) => {
					usbDrives = devices
					timer = window.setTimeout(scanDrives, SCAN_FREQUENCY)
				}
			).catch(err => {
				usbBusy = true
				usbDrives = []
				openModal({
					title: "Error scanning for USB drives:",
					content: err.message,
					buttons: [{id: 'ok', text: "Ok"}],
					onclick() {usbBusy = false}
				})
			})
		} else {
			timer = window.setTimeout(scanDrives, SCAN_FREQUENCY)
		}
	}

	scanDrives()

	function onremove() {
		if (timer != null) {
			window.clearTimeout(timer)
			timer = undefined
		}
	}

	function view() {
		const patient = PATIENT()
		return m('.reports',
			m('.tab-content',
				m('.tab-pane',
					m('div',
						m(leftPanel, {patient}),
						m(rightPanel, {patient})
					)
				)
			)
		)
	}

	return {onremove, view}
}

export default reportsComp

const leftPanel: m.Component<{patient?: Patient},{}> = {
	view ({attrs: {patient}}) {
		return m('.left-col',
			m('.h2-wrapper',
				m('h2', "Choose Reports")
			),
			m('.list-wrapper',
				/* reports.map(r =>
					m('.list-item',
						m(checkbox,
							{
								disabled: true,
								id: 'check-' + r.name, name: r.name, value: '1',
								checked: true
							},
							r.label
						)
					)
				), */
				m('.list-item',
					m(checkbox,
						{
							checked: true,
							disabled: true,
							id: 'check-report-type',
							value: '1'
						},
					"Full Report")
				),
				m('button.btn-pill-blue.btn-arrow',
					{
						disabled: reportBusy,
						onclick() {
							if (patient) {
								generateReport(patient.id)
							} else {
								openModal({
									title: "No patient selected",
									buttons: [{id: 'ok', text: "Ok"}]
								})
							}
						}
					},
					m('span', "Generate Report"),
				)
			)
		)
	}
}

let reportAction: 'view' | 'copy' = 'view'

const rightPanel: m.Component<{patient?: Patient},{}> = {
	view ({attrs: {patient}}) {
		return m('.right-col',
			m('.h2-wrapper',
				m('h2', "Choose Output"),
			),
			m('div',
				{
					class: 'usb-status-wrapper' + (usbDrives.length > 0 ? ' ready' : '')
				},
				m('span', "USB Drive: "),
				m('span', usbDrives.length > 0 ? usbDrives[0] : "None found")
			),
			m('.list-wrapper',
				m('.list-item',
					m(radio,
						{
							name: 'report', id: 'radio-report-view',
							checked: reportAction === 'view',
							onclick() {reportAction = 'view'}
						},
						"View/Print"
					),
				),
				m('.list-item',
					m(radio,
						{
							name: 'report', id: 'radio-report-copy',
							checked: reportAction === 'copy',
							onclick() {reportAction = 'copy'}
						},
						"Copy to USB"
					)
				),
				m('button.btn-pill-blue.btn-arrow',
					{
						disabled: reportBusy || !REPORT_GENERATED()
							|| (reportAction === 'copy' && usbDrives.length < 1),
						onclick() {
							if (!patient) {
								openModal({
									title: "No patient selected",
									buttons: [{id: 'ok', text: "Ok"}]
								})
							} else {
								if (reportAction === 'view') {
									viewReport(patient.id)
								} else {
									copyReportToUSB(patient.id)
								}
							}
						}
					},
					m('span', "Go"),
				)
			)
		)
	}
}
