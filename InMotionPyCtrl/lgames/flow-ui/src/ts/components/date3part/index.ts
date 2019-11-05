import * as m from 'mithril'
import mSelect from '../widgets/m-select'
import {shortMonths, days31} from '../../lib/date'

export interface Attrs {
	name?: string
	label?: string
	date?: Date
	onchange?(dt: Date): any
}

interface DateParts {
	year: number | undefined
	month: number | undefined
	day: number | undefined
}

function currentYear() {
	return (new Date()).getFullYear()
}

function partsValid (p: DateParts) {
	if (p.year == null || p.month == null || p.day == null
		|| p.year < 1900 || p.year > currentYear() || Number.isNaN(p.year)
	) {
		return false
	}
	return true
}

function partsToString (p: DateParts) {
	return partsValid(p)
		? (new Date(p.year!, p.month!, p.day!)).toString()
		: ''
}

const date3part: m.FactoryComponent<Attrs> = function({attrs: {date}}) {
	const parts: DateParts = {
		year: undefined, month: undefined, day: undefined
	}

	if (date != null) {
		parts.year = date.getFullYear()
		parts.month = date.getMonth()
		parts.day = date.getDate()
	}
	let inputYear = parts.year

	function update(p: Partial<DateParts>, onchange?: (d: Date) => any) {
		Object.assign(parts, p)
		if (partsValid(parts)) {
			const dt = new Date(parts.year!, parts.month!, parts.day!)
			if (onchange) onchange(dt)
		}
	}

	function view (
		name?: string, label?: string, date?: Date, onchange?: (d: Date) => any
	) {
		return m('.date3part',
			m('.input-container-month',
				m('label', {for: '', id: ''}, label),
				m(mSelect, {
					promptContent: "Month",
					options: shortMonths.map(
						(mo, i) => ({value: i, content: mo})
					),
					defaultValue: parts.month,
					id: 'birthMonth',
					labelId: 'birthMonth-label',
					class: 'select-output-options',
					onchange: (month: number) => {
						update({month}, onchange)
					}
				})
			),
			m('.input-container-day',
				m(mSelect, {
					promptContent: "Day",
					options: days31.map(
						d => ({value: d, content: String(d)})
					),
					defaultValue: parts.day,
					id: 'birthDay',
					labelId: 'birthDay-label',
					class: 'select-output-options',
					onchange: (day: number) => {
						update({day}, onchange)
					}
				})
			),
			m('.input-container-year',
				m('input', {
					type: 'text', id: 'birthYear', placeholder: "Year", maxlength: '4',
					value: inputYear,
					oninput: m.withAttr('value', year => {
						inputYear = year
						update({year: Number(year)}, onchange)
					})
				})
			),
			!!name && m('input', {
				type: 'hidden', name,
				value: partsToString(parts)
			})
		)
	}

	return {
		view({attrs: {name, label, date, onchange}}) {
			return view(name, label, date, onchange)
		}
	}
}

export default date3part
