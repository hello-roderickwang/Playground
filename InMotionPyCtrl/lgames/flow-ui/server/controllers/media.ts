import {Request, Response} from 'express-serve-static-core'
import {
	listDevices, copyPatientDir, copyPatientReport as copyReport
} from '../lib/external-media'

export function devices (req: Request, res: Response) {
	//console.log("Listing mounted devices...")
	listDevices().then(devices => {
		//console.log("Listed devices ok")
		res.send({devices})
	}).catch (e => {
		console.warn("Error listing devices:", e.message)
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}

export function copyPatientReport (req: Request, res: Response) {
	const patid: string = req.body.patid
	const drive = req.body.drive
	console.log(`Copying report for patient id ${patid}...`)
	copyReport(patid, drive).then(filename => {
		console.log("Report copied ok")
		res.send({filename})
	}).catch(e => {
		console.warn("Error copying patient report:", e.message)
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}

export function copyPatientData (req: Request, res: Response) {
	const patid: string = req.body.patid
	const drive = req.body.drive
	console.log(`Copying patient data file for id ${patid}...`)
	copyPatientDir(patid, drive).then(filename => {
		console.log("Copied ok")
		res.send({filename})
	}).catch(e => {
		console.warn("Error copying patient data folder:", e.message)
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}
