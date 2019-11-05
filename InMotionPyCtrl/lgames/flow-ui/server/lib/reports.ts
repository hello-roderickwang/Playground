import * as fs from 'fs-extra'
import * as path from 'path'
import {REPORT_CMD, REPORTS_RAW_DIR, REPORT_HTML_DIR} from '../config'
import {endsWith} from './string'
import ImtError from './imt-error'
import {spawnProcess, filterDirectory} from './file-util'
import {patientExists} from './patient'
import * as templates from './report-templates'

export function generateReport (patid: string) {
	return patientExists(patid).then(exists => {
		if (!exists) {
			throw new ImtError('Invalid patient ID', 403)
		}
		return spawnProcess(REPORT_CMD, ['--nocache', patid])
	})
}

export function buildEvaluationReport (patid: string) {
	return patientExists(patid).then(exists => {
		if (!exists) {
			throw new ImtError('Invalid patient ID', 403)
		}
		const rawDir = path.join(REPORTS_RAW_DIR, patid)
		return findEvaluationImages(rawDir)
	}).then(imgs => {
		const evalHtml = templates.evaluation
		const evalsHtml = templates.evaluations.replace('{{evaluations}}', evalHtml)
		const html = templates.master.replace(
			'{{content}}', evalsHtml
		)
		return fs.writeFile(path.join(REPORT_HTML_DIR, patid), html)
	})
}

function findEvaluationImages (dir: string) {
	return filterDirectory(dir, (f, s) => {
		return s.isFile() && endsWith(f, '.gif')
	})
}
