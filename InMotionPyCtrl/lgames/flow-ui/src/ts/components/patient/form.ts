import * as m from 'mithril'
import {Patient, Gender, genders, ImpairmentSide, impairmentSides} from '../../../../server/models/patient'
import {Dict} from '../../lib/dict'
import mSelect from '../widgets/m-select'
import date3part from '../date3part'

export type FormMode = 'add' | 'edit'

export interface Attrs {
	mode: FormMode
	patient?: Patient
	onsubmit?(form: HTMLFormElement): any
}

const patientForm: m.FactoryComponent<Attrs> = function patientForm(
	{attrs: {mode, patient: patient0}}
) {
	const patient: Dict<any> = Object.assign({}, patient0)

	function view (onsubmit?: (f: HTMLFormElement) => any) {
		return m('form',
			{
				id: 'form-patient',
				onsubmit(e: Event) {
					e.preventDefault()
					onsubmit && onsubmit(e.currentTarget as HTMLFormElement)
				}
			},
			m('.patient-info-left-col',
				m('.input-container',
					m('label', {for: 'id'}, mode === 'add'
						? [m('span', "Patient ID "), m('span', {style: 'color: #FFDD99'}, "*mandatory")]
						: "Patient ID"
					),
					mode === 'add'
						? m('input', {
							type: 'text', id: 'id', name: 'id',
							maxLength: 30,
							value: patient.id,
							oninput: m.withAttr('value', id => {patient.id = id})
						})
						: [
							m('.view-field', patient.id),
							m('input', {type: 'hidden', name: 'id', value: patient.id})
						]
				),
				m('.input-container',
					m('label', {for: 'firstName'}, "First Name"),
					m('input', {
						type: 'text', id: 'firstName', name: 'firstName',
						maxLength: 60,
						value: patient.firstName,
						oninput: m.withAttr('value', s => {patient.firstName = s})
					})
				),
				m('.input-container',
					m('label', {for: 'lastName'}, "Last Name"),
					m('input', {
						type: 'text', id: 'lastName', name: 'lastName',
						maxLength: 60,
						value: patient.lastName,
						oninput: m.withAttr('value', s => {patient.lastName = s})
					})
				),
				m('.input-container',
					m(date3part, {
						name: 'birthDate', label: "Date of Birth",
						date: patient.birthDate,
						onchange: (d: Date) => {patient.birthDate = d}
					})
				),
				m('.input-container',
					m('label', {for: 'gender', id: 'gender-label'}, "Gender"),
					m(mSelect, {
						promptContent: 'Select Gender',
						options: Object.keys(genders).map(k => ({
							value: k, content: genders[k as Gender]
						})),
						defaultValue: patient.gender,
						id: 'gender',
						name: 'gender',
						labelId: 'gender-label',
						class: 'select-output-options',
						onchange: (g: string) => {
							patient.gender = g
						}
					})
				)
			),
			m('.patient-info-right-col',
				m('.halved-inputs',
					m('div.input-container',
						m(date3part, {
							name: 'dateOnset', label: "Date of Onset",
							date: patient.dateOnset,
							onchange: (d: Date) => {patient.dateOnset = d}
						})
					),
					m('.input-container',
						m('label', {for: 'diagnosis'}, "Diagnosis"),
						m('input', {
							id: 'diagnosis', name: 'diagnosis', type: "text",
							maxLength: 200,
							value: patient.diagnosis,
							oninput: m.withAttr('value', d => {patient.diagnosis = d})
						})
					),
					m('.input-container',
						m('label',
							{
								for: 'impairmentSide',
								id: 'impairmentSide-label'
							},
							"Side of Impairment"
						),
						m(mSelect, {
							promptContent: 'Select Side',
							options: Object.keys(impairmentSides).map(k => ({
								value: k, content: impairmentSides[k as ImpairmentSide]
							})),
							id: 'impairmentSide',
							name: 'impairmentSide',
							defaultValue: patient.impairmentSide,
							labelId: 'impairmentSide-label',
							class: 'select-output-options',
							onchange: (i: string) => {
								patient.impairmentSide = i
							}
						})
					),
					m('.input-container',
						m('label',
							{for: 'typeLocation', id: 'typeLocation-label'},
							"Type/Location"
						),
						m('input', {
							type: 'text', id: 'typeLocation', name: 'typeLocation',
							maxLength: 200,
							value: patient.typeLocation,
							oninput: m.withAttr('value', t => {patient.typeLocation = t})
						})
					)
				),
				m('.input-container',
					m('label', {for: 'otherImpairments'}, "Other Impairments"),
					m('input', {
						type: 'text', id: 'otherImpairments', name: 'otherImpairments',
						maxLength: 500,
						value: patient.otherImpairments,
						oninput: m.withAttr('value', o => {patient.otherImpairments = o})
					})
				),
				m('.input-container',
					m('label', {for: 'precautions'}, "Precautions for robotic therapy"),
					m('input', {
						type: 'text', id: 'precautions', name: 'precautions',
						maxLength: 500,
						value: patient.precautions,
						oninput: m.withAttr('value', o => {patient.precautions = o})
					})
				),
				m('.input-container',
					m('label', {for: 'positioningConsiderations'}, "Positioning Considerations"),
					m('input', {
						type: "text", id: 'positioningConsiderations', name: 'positioningConsiderations',
						maxLength: 500,
						value: patient.positioningConsiderations,
						oninput: m.withAttr('value', o => {patient.positioningConsiderations = o})
					})
				)
			)
		)
	}

	return {
		view({attrs: {onsubmit}}) {
			return view(onsubmit)
		}
	}
}

export default patientForm
