export const genders = {
	M: 'Male',
	F: 'Female',
	O: 'Other'
}

export type Gender = keyof typeof genders

export const impairmentSides = {
	L: 'Left',
	R: 'Right',
	B: 'Bilateral'
}

export type ImpairmentSide = keyof typeof impairmentSides

export const rxPatient = /^[0-9a-z]+$/

export interface Patient {
	id: string
	firstName: string | null
	lastName: string | null
	birthDate: Date | null
	gender: Gender | null
	impairmentSide: ImpairmentSide | null
	dateOnset: Date | null
	typeLocation: string | null
	diagnosis: string | null
	otherImpairments: string | null
	precautions: string | null
	positioningConsiderations: string | null
}

/** Create a valid Patient object. Throws on validation error. */
export function createPatient (data: {[id: string]: any}): Patient {
	if (!rxPatient.test(data.id)) {
		throw new Error("Invalid Patient ID")
	}
	if (data.gender != null && data.gender !== '' && !(data.gender in genders)) {
		throw new Error("Invalid gender")
	}
	if (data.impairmentSide != null && data.impairmentSide !== '' && !(data.impairmentSide in impairmentSides)) {
		throw new Error("Invalid impairment side")
	}
	return {
		id: data.id,
		firstName: data.firstName || null,
		lastName: data.lastName || null,
		birthDate: data.birthDate ? new Date(data.birthDate) : null,
		gender: data.gender as Gender || null,
		impairmentSide: data.impairmentSide as ImpairmentSide || null,
		dateOnset: data.dateOnset ? new Date(data.dateOnset) : null,
		typeLocation: data.typeLocation || null,
		diagnosis: data.diagnosis || null,
		otherImpairments: data.otherImpairments || null,
		precautions: data.precautions || null,
		positioningConsiderations: data.positioningConsiderations || null
	}
}
