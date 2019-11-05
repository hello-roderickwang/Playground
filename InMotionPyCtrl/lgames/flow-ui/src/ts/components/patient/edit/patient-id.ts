import * as m from 'mithril'
import {Patient} from '../../../../../server/models/patient'

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
				)
			)
		)
	}
} as m.Component<Attrs,{}>
