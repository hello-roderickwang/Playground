import * as fs from 'fs-extra'
import * as path from 'path'
import {REPORT_PDFS_DIR} from '../config'
import {Request, Response} from 'express-serve-static-core'
import ImtError from '../lib/imt-error'
import {generateReport, buildEvaluationReport} from '../lib/reports'
import {
	loadTherapyHistory, appendStartSession, appendActivity
} from '../lib/therapy-history'
import {patientExists} from '../lib/patient'
import {spawnFirefox} from '../lib/window'

export function generate (req: Request, res: Response) {
	const patid = req.body.patid
	console.log("Generating report...")
	generateReport(patid).then(() => {
		console.log("Report generated")
		//buildEvaluationReport(patid).then(() => {
		res.send({status: 'ok'})
	}).catch((e: ImtError) => {
		console.warn("Error generating report:", e.message)
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}

export function serve (req: Request, res: Response) {
	const patid = req.params.patid
	if (!patientExists(patid)) {
		res.status(404).send('<html>Patient report not found</html>')
		return
	}
	const pdfFilename = path.join(REPORT_PDFS_DIR, `reports_${patid}.pdf`)
	if (!fs.existsSync(pdfFilename)) {
		res.status(404).send('<html>Patient report not found</html>')
		return
	}
	res.sendFile(pdfFilename)
}

export function getTherapyHistory (req: Request, res: Response) {
	loadTherapyHistory(req.params.patid).then(sessions => {
		res.send({sessions})
	}).catch(e => {
		console.warn("Error loading therapy history:", e.message)
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}

export function startTherapySession (req: Request, res: Response) {
	return appendStartSession(req.params.patid).then(() => {
		res.send({status: 'ok'})
	}).catch(e => {
		console.warn("Error starting therapy session:", e.message)
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}

export function addActivity (req: Request, res: Response) {
	return appendActivity(
		req.params.patid, req.body
	).then(() => {
		res.send({status: 'ok'})
	}).catch(e => {
		console.warn("Error adding activity:", e.message)
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}

export function openPdfWindow (req: Request, res: Response) {
	const url = req.body.url
	if (!url) {
		res.status(406).send({message: "url required"})
	}
	spawnFirefox(url)
	res.send({status: 'ok'})
}
