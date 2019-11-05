import * as fs from 'fs-extra'
import * as path from 'path'
import {THERAPIST_HOME, MEDIA_DEVS_DIR, REPORT_PDFS_DIR} from '../config'
import {dateStr} from './date'
import ImtError from './imt-error'
import {getSubDirectories} from './file-util'
import {patientExists} from './patient'

export function listDevices(): Promise<string[]> {
	return getSubDirectories(MEDIA_DEVS_DIR)
}

export function copyPatientReport (patid: string, devName?: string): Promise<string> {
	if (!patientExists(patid)) {
		return Promise.reject(new ImtError("Invalid patient ID", 406))
	}
	return listDevices().then(drives => {
		if (drives.length < 1) {
			throw new ImtError("No external drives found", 403)
		}
		let drive: string
		if (devName) {
			if (drives.indexOf(devName) < 0) {
				throw new ImtError(
					"Could not find specified destination device: " + devName, 406
				)
			}
			drive = devName
		} else {
			drive = drives[0]
		}
		const pdfName = `reports_${patid}.pdf`
		const srcName = path.join(REPORT_PDFS_DIR, pdfName)
		const devDir = path.join(MEDIA_DEVS_DIR, drive)
		const dstName = path.join(devDir, pdfName)
		return fs.copy(srcName, dstName).then(
			() => pdfName
		)
	})
}

export function copyPatientDir (patid: string, devName?: string): Promise<string> {
	if (!patientExists(patid)) {
		return Promise.reject(new ImtError("Invalid patient ID", 406))
	}
	let dstDir = ''
	const dirName = `patient-${patid}-${dateStr()}`
	return listDevices().then(drives => {
		if (drives.length < 1) {
			throw new ImtError("No external drives found", 403)
		}
		let drive: string
		if (devName) {
			if (drives.indexOf(devName) < 0) {
				throw new ImtError("Could not find specified destination device: " + devName, 406)
			}
			drive = devName
		} else {
			// Default to first device.
			// TODO: Always require a specified device?
			drive = drives[0]
		}
		const devDir = path.join(MEDIA_DEVS_DIR, drive)
		dstDir = path.join(devDir, dirName)
		return fs.pathExists(dstDir)
	}).then(
		exists => exists ? fs.remove(dstDir) : Promise.resolve()
	).then(
		() => fs.copy(path.join(THERAPIST_HOME, patid), dstDir)
	).then(
		() => dirName
	)
}
