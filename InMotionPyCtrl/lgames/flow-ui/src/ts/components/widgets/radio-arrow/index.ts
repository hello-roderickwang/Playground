import * as m from 'mithril'

export interface Attrs {
	id?: string
	name?: string
	value?: string
	checked?: boolean
	onclick?(e: MouseEvent): any
	[id: string]: any
}

export default {
	view({attrs, children}) {
		const a = {...attrs, type: 'radio'}
		const lstyle = attrs.disabled ? 'cursor: default' : ''
		return m('div.radio-wrapper.radio-wrapper-arrow',
			{style: !!attrs.disabled ? 'opacity: 0.5' : ''},
			m('input', a),
			m('label',
				a.id != null ? {for: a.id, style: lstyle} : {style: lstyle},
				m('.circle'),
				children
			)
		)
	}
} as m.Component<Attrs,{}>
