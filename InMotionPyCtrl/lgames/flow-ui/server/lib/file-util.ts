import * as fs from 'fs-extra'
import * as path from 'path'
import {SpawnOptions, spawn} from 'child_process'

/** Filter a directory listing */
export function filterDirectory (
	directory: string,
	filter: (filename: string, stats: fs.Stats) => boolean
) {
	let filenames: string[]
	return fs.readdir(
		directory
	).then(_fnames => {
		filenames = _fnames
		return Promise.all(filenames.map(
			filename => fs.lstat(path.join(directory, filename))
		))
	}).then(stats => {
		const dirs: string[] = []
		for (let i = 0; i < filenames.length; ++i) {
			if (filter(filenames[i], stats[i])) {
				dirs.push(filenames[i])
			}
		}
		return dirs
	})
}

/** Returns a list of directories in the specified directory */
export function getSubDirectories (directory: string) {
	return filterDirectory(
		directory, (fname, stats) => stats.isDirectory()
	)
}

export interface ExtraSpawnOptions {
	logOutput?: boolean | 'stdout' | 'stderr'
	onStdout?(data: string | Buffer): any
	onStderr?(data: string | Buffer): any
	onError?(code: number): any
	onExit?(code: number): any
}

/** Child Process spawn wrapper */
export function spawnProcess (
	cmd: string, params?: string[], opts?: SpawnOptions, exOpts?: ExtraSpawnOptions
): Promise<number> {
	// Spawn the process
	return new Promise<number>((resolve, reject) => {
		const proc = spawn(cmd, params, opts)
		const logStdout = (!exOpts || exOpts.logOutput === undefined)
			|| (exOpts && (exOpts.logOutput === true || exOpts.logOutput === 'stdout'))
		const logStderr = (!exOpts || exOpts.logOutput === undefined)
			|| (exOpts && (exOpts.logOutput === true || exOpts.logOutput === 'stderr'))
		const onStdout = exOpts ? exOpts.onStdout : undefined
		const onStderr = exOpts ? exOpts.onStderr : undefined
		proc.stdout.on('data', data => {
			if (logStdout) {
				console.log(data.toString())
			}
			if (onStdout) {
				onStdout(data)
			}
		})
		proc.stderr.on('data', data => {
			if (logStderr) {
				console.log(data.toString())
			}
			if (onStderr) {
				onStderr(data)
			}
		})
		proc.on('error', err => {
			reject(err)
		})
		proc.on('exit', code => {
			resolve(code)
		})
	})
}


/* const Y = <T>(x: T) => [x]
const N = () => []

const concat = <T>(a: T[], b: T[]) => a.concat(b)
const flatten = <T>(xs: T[]) => xs.reduce(concat, [])
const map = f => xs => xs.map(f)

const $lstatAsyncFilter = fn => filepath => {
	return fs.lstat(
		fn(filepath)
	).then(x => (x ? Y : N)(filepath))
}

function getSubDirectoriesFancy(directory: string) {
    return fs.readdir(directory)
    .then(map($lstatAsyncFilter(stat => stat.isDirectory()))
    .then(Promise.all)
    .then(flatten)
} */
