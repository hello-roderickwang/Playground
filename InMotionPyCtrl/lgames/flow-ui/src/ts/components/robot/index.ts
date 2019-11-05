import * as m from 'mithril'
import {loadProtocols, RobotMode} from './../../protocols'
import reports from './reports'
import orientation from './orientation'
import evaluation from './evaluation'
import therapy from './therapy'

const therapyComponents = {orientation, evaluation, therapy}

const robotTabs: {id: RobotMode, label: string}[] = [
	{id: 'orientation', label: "Orientation"},
	{id: 'evaluation', label: "Evaluation"},
	{id: 'therapy', label: "Therapy"},
	{id: 'reports', label: "Reports"}
]

export interface Attrs {
	mode: RobotMode
}

export default {
	oninit() {
		loadProtocols().then(() => {m.redraw()})
	},

	view ({attrs: {mode}}) {
		return m('.therapy',
			m('.name-time-div', "Therapy Session"),
			m('.hr'),
			m('ol.nav-tabs', robotTabs.map(tab =>
				m('li',
					m('button',
						{
							class: mode === tab.id ? 'active' : '',
							onclick() {m.route.set('/robot/' + tab.id)}
						},
						tab.label
					)
				)
			)),
			mode === 'reports'
				? m(reports)
				: m(therapyComponents[mode])
		)
	}
} as m.Component<Attrs,{}>
