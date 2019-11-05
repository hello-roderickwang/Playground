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
		const a = {...attrs, type: 'checkbox'}
		//if (attrs.disabled) a.checked = false
		const lstyle = attrs.disabled ? 'cursor: default' : ''
		return m('div.checkbox-wrapper',
			{style: !!attrs.disabled ? 'opacity: 0.5' : ''},
			m('input', a),
			m('label',
				a.id != null ? {for: a.id, style: lstyle} : {style: lstyle},
				m('.square'),
				children
			)
		)
	}
} as m.Component<Attrs,{}>
