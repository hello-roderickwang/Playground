import * as m from 'mithril'

export interface Attrs {
	label: string
	id: string
	name: string
	value: string
	onchange?(checked: boolean): any
}

export default {
	view({attrs: {label, id, name, value, onchange}}) {
		return m('div.checkbox-plusminus-wrapper.checkbox-minus-wrapper',
			m('input',
				{
					id: id,
					name: name,
					value: value,
					type: 'checkbox',
					onclick(e: Event) {
						onchange && onchange((e.currentTarget as HTMLInputElement).checked)
					}
				}
			),
			m('label',
				{
					for: id
				},
				m('.circle'),
				label
			)
		)
	}
} as m.Component<Attrs,{}>