import * as m from 'mithril'
import * as stream from 'mithril/stream'
import {PATIENT, SHOW_PATIENT_DETAILS} from '../../../state'
import {startTherapySession} from '../../../actions/patient'
import {Dict} from '../../../lib/dict'
import {Patient, createPatient} from '../../../../../server/models/patient'
//import mSelect from '../../widgets/m-select'
import detailsView from './details'

const patients = stream<Patient[] | undefined>()
let loading = false

function loadPatients() {
	patients(undefined)
	loading = true
	m.request<{patients: Dict<any>[]}>(
		'/api/patients'
	).then(result => {
		loading = false
		patients(result.patients.map(createPatient))
	}).catch(err => {
		console.warn(err)
		loading = false
	})
}

function filterPatients (pid: string, str: string) {
	return pid.toLowerCase().indexOf(str.trim().toLowerCase()) >= 0
}

const searchPatients: m.FactoryComponent<{}> = function() {
	let filterStr = ''
	loadPatients()

	function view() {
		let pats = patients()
		if (pats) {
			pats = pats.filter(p => filterPatients(p.id, filterStr))
		}
		const patient = PATIENT()
		return m('.patient-management.find-patient',
			m('.name-time-div', "Find a Patient"),
			m('.hr'),
			m('.tab-content',
				m('.tab-pane',
					m('div',
						m('.single-col.flexdiv',
							m('.subcol-left',
								m('.h2-wrapper',
									m('h2', "Search Patient")
								),
								m('div',
									/* m('.input-container',
										pats && m(mSelect, {
											promptContent: "- Select -",
											options: pats.map(p => ({value: p.id, content: p.id})),
											defaultValue: patient ? patient.id : undefined,
											class: 'select-output-options',
											onchange: (val: string) => {
												PATIENT(pats.find(p => p.id === val))
											}
										}),
									), */
									m('.input-container',
										m('input',
											{
												type: 'text',
												'aria-label': "Filter",
												value: filterStr,
												oninput: m.withAttr('value', (str: string) => {
													filterStr = str
												})
											}
										)
									),
									m('.input-container',
										pats && m('select.listbox',
											{
												size: Math.max(pats.length, 2),
												oninput: m.withAttr('value', (id: string) => {
													if (!!id && !!pats) {
														PATIENT(pats.find(p => p.id === id))
													} else {
														PATIENT(undefined)
													}
												})
											},
											pats.map(p =>
												m('option',
													{
														value: p.id,
													},
													p.id
												)
											)
										)
									)
								),
							),
							m('.subcol-right', patient && (
								SHOW_PATIENT_DETAILS() // show all selected patient details
									? m(detailsView, {
										patient: patient
									})
									: m('.h2-wrapper', // show only selected patient ID
										m('h2', "Patient ID: " + patient.id)
									)
								)
							)
						)
					),
					m('.cta-wrapper-flex',
						m('button.btn-pill-blue',
							{
								disabled: !PATIENT(),
								onclick() {
									startTherapySession(PATIENT()!.id)
									m.route.set('/robot/orientation')
								}
							},
							"Start Therapy Session"
						)
					)
				)
			)
		)
	}

	return {view}
}

export default searchPatients
