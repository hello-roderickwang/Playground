import * as m from 'mithril'
import {Patient, genders, impairmentSides} from '../../../../../server/models/patient'
import {age, dateStr} from '../../../lib/date'

export interface Attrs {
	patient: Patient
}

export default {
	view ({attrs: {patient}}) {
		return m('div',
			m('.h2-wrapper',
				m('h2', "Patient Info")
			),
			m('.patient-info-left-col',
				m('.input-container',
					m('.view-label', "Patient ID"),
					m('.view-field', patient.id)
				),
				m('.input-container',
					m('.view-label', "First Name"),
					m('.view-field', patient.firstName)
				),
				m('.input-container',
					m('.view-label', "Last Name"),
					m('.view-field', patient.lastName)
				),
				m('.input-container.input-container-dob',
					m('.view-label', "Date of Birth"),
					m('.view-field', patient.birthDate ? dateStr(patient.birthDate) : '')
				),
				m('.input-container.input-container-age',
					m('.view-label', "Age"),
					m('.view-field', patient.birthDate
						? age(patient.birthDate)
						: ''
					)
				),
				m('.input-container',
					m('.view-label', "Gender"),
					m('.view-field', patient.gender ? genders[patient.gender] : '')
				),
			),
			m('.patient-info-right-col',
				m('.halved-inputs',
					m('.input-container',
						m('.view-label', "Date of Onset"),
						m('.view-field', patient.dateOnset ? dateStr(patient.dateOnset) : '')
					),
					m('.input-container',
						m('.view-label', "Diagnosis"),
						m('.view-field', patient.diagnosis || '')
					),
					m('.input-container',
						m('.view-label', "Type/Location"),
						m('.view-field', patient.typeLocation || '')
					),
					m('.input-container',
						m('.view-label', "Side of Impairment"),
						m('.view-field',
							patient.impairmentSide ? impairmentSides[patient.impairmentSide] : ''
						)
					)
				),
				m('.input-container',
					m('.view-label', "Other Impairments"),
					m('.view-field', patient.otherImpairments || '')
				),
				m('.input-container',
					m('.view-label', "Precautions for robotic therapy"),
					m('.view-field', patient.precautions || '')
				),
				m('.input-container',
					m('.view-label', "Positioning Considerations"),
					m('.view-field', patient.positioningConsiderations || '')
				)
			)
		)
	}
} as m.Component<Attrs,{}>
