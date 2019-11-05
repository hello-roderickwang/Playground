import * as m from 'mithril'
import {Patient, createPatient} from '../../../../server/models/patient'
import {Dict} from '../../lib/dict'
import {deletePatient} from '../../actions/patient'
import {openModal, closeModal} from '../modal'
import radio from '../widgets/radio'

const SCAN_FREQUENCY = 3000

function formatPatientStr (p: Patient) {
	return p.lastName || p.firstName
		? `${p.lastName}, ${p.firstName} (${p.id})`
		: p.id
}

function trimStr (s: string, max: number) {
	if (!max || max < 1) return s
	if (s.length <= max) return s
	return s.substr(0, max) + '...'
}

const foldersComponent: m.FactoryComponent<{}> = function foldersComponent() {
	let patients: Patient[] = []
	let selectedPatient: Patient | undefined
	let usbDrives: string[] = []
	let usbBusy = false
	let timer: number | undefined

	function copyPatientFolder (id: string) {
		if (usbBusy) {
			console.warn("Can't copy - USB busy")
			return
		}
		if (usbDrives.length < 1) {
			console.warn("Can't copy - no USB drives found")
			return
		}

		usbBusy = true
		openModal({title: "Copying patient folder to USB...."})
		window.setTimeout(() => {
			// delay request a moment to ensure UI shows up
			m.request<{filename: string}>({
				url: '/api/media/copy-patient',
				method: 'post',
				data: {patid: id}
			}).then(({filename}) => {
				closeModal()
				window.setTimeout(() => {
					openModal({
						title: "Patient data copied",
						content: `Copied folder '${filename}' on USB drive.`,
						buttons: [{id: 'ok', text: "Ok"}],
						onclick() {usbBusy = false}
					})
					m.redraw()
				}, 500)
			}).catch(err => {
				closeModal()
				m.redraw()
				window.setTimeout(() => {
					openModal({
						title: "Error copying patient data",
						content: err.message,
						buttons: [{id: 'ok', text: "Ok"}],
						onclick() {usbBusy = false}
					})
					m.redraw()
				}, 500)
			})
		}, 200)
	}

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

	function deletePatientFolder (patid: string) {
		setTimeout(() => {
			openModal({title: "Deleting patient folder..."})
			deletePatient(patid).then(() => {
				patients.splice(patients.findIndex(p => p.id === patid), 1)
				selectedPatient = undefined
				setTimeout(() => {
					openModal({
						title: `Patient ID ${patid} deleted.`,
						buttons: [
							{id: 'ok', text: 'Ok'}
						]
					})
					m.redraw()
				}, 500)
			}).catch(err => {
				console.warn('Delete patient failed:', err)
				setTimeout(() => {
					openModal({
						title: `Error deleting patient.`,
						content: err.message,
						buttons: [
							{id: 'ok', text: 'Ok'}
						]
					})
					m.redraw()
				}, 500)
			})
			m.redraw()
		}, 200)
	}

	scanDrives()

	m.request<{patients: Dict<any>[]}>({url: '/api/patients'}).then((result) => {
		patients = result.patients.map(createPatient)
	})

	function onremove() {
		if (timer != null) {
			window.clearTimeout(timer)
			timer = undefined
		}
	}

	function view() {
		return m('.manage-patient-files',
			m('.name-time-div', "Manage Patient Files"),
			m('.hr'),
			m('.tab-content',
				m('.tab-pane',
					m('div',
						m('.left-col',
							m('.h2-wrapper',
								m('h2', "Select Patient")
							),
							m('.list-wrapper',
								patients.map(p =>
									m('.list-item',
										m(radio,
											{
												id: 'radio-' + p.id,
												name: 'radio-patient',
												value: p.id,
												onclick() {
													selectedPatient = patients.find(_p => _p.id === p.id)
												}
											},
											formatPatientStr(p)
										)
									)
								)
							)
						),
						m('.right-col',
							m('.h2-wrapper',
								m('h2', "Selected Patient")
							),
							m('div',
								{
									class: 'usb-status-wrapper' + (usbDrives.length > 0 ? ' ready' : '')
								},
								m('span', "USB Drive: "),
								m('span', usbDrives.length > 0 ? trimStr(usbDrives[0], 24) : "None found")
							),
							m('.list-wrapper',
								selectedPatient && m('ul',
									m('li', formatPatientStr(selectedPatient))
								)
							),
							m('.btns-wrapper',
								m('button.btn-pill-blue',
									{
										disabled: !selectedPatient || usbBusy || usbDrives.length < 1,
										onclick() {
											copyPatientFolder(selectedPatient!.id)
										}
									},
									"Copy to USB"
								),
								m('button.btn-pill-blue',
									{
										disabled: !selectedPatient || selectedPatient.id.toLowerCase() === 'test',
										onclick() {
											openModal({
												title: `Are you sure you want to delete ALL files for patient ID: ${selectedPatient!.id}?`,
												buttons: [
													{id: 'delete', text: "Delete"},
													{id: 'cancel', text: "Cancel"}
												],
												onclick(id) {
													if (!!selectedPatient && id === 'delete') {
														deletePatientFolder(selectedPatient.id)
													}
												}
											})
										}
									},
									"Delete Files"
								)
							)
						)
					)
				)
			)
		)
	}

	return {onremove, view}
}

export default foldersComponent
