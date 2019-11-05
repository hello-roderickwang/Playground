// Initialize global app constants
import * as path from 'path'
import * as username from 'username'

// We can use relative or absolute environment var paths
export const APPROOT_PATH = path.join(__dirname, '..')

// Env vars
export const IMT_HOME = path.resolve(APPROOT_PATH, process.env.HOME)
export const THERAPIST_HOME = path.resolve(APPROOT_PATH, process.env.THERAPIST_HOME)
export const LGAMES_HOME = path.resolve(APPROOT_PATH, process.env.LGAMES_HOME)
export const PROTOCOLS_HOME = path.resolve(APPROOT_PATH, process.env.PROTOCOLS_HOME)
export const IMT_CONFIG = path.resolve(APPROOT_PATH, process.env.IMT_CONFIG)
export const CROB_HOME = path.resolve(APPROOT_PATH, process.env.CROB_HOME)

// Other constants
export const ROBOTS_LIST_DIR = path.join(IMT_CONFIG, 'robots')
export const CURRENT_ROBOT_FILENAME = path.join(IMT_CONFIG, 'current_robot')
export const STATUS_CMD = path.join(CROB_HOME, 'tools', 'ucplc')
export const CALIBRATE_CMD = path.join(CROB_HOME, 'tools', 'plcenter')
export const CLOCK_GAME_FILENAME = process.env.CLOCK_GAME_FILENAME || 'clock.tcl'

export const IMT_PRIVATE = process.env.IMT_HOME_PRIVATE // mocked
	? path.resolve(APPROOT_PATH, process.env.IMT_HOME_PRIVATE)
	: path.join(IMT_HOME, 'Private')
export const REPORT_CMD = path.join(LGAMES_HOME, 'pups', 'dopatient.py')
export const REPORTS_HOME = path.join(IMT_PRIVATE, 'reports')
export const REPORTS_RAW_DIR = path.join(REPORTS_HOME, 'raw_data')
export const REPORT_PDFS_DIR = path.join(REPORTS_HOME, 'pdfs')
export const REPORT_HTML_DIR = path.join(REPORTS_HOME, 'html')
export const THERAPY_HISTORY_FILENAME = 'therapy-history.txt'

// Paths to mounted external media devices
export const MEDIA_DIR = process.env.EXTERNAL_MEDIA_PATH
	? path.resolve(APPROOT_PATH, process.env.EXTERNAL_MEDIA_PATH) : '/media'
export const MEDIA_DEVS_DIR = path.join(MEDIA_DIR, username.sync())

export const LOGOUT_SYSTEM_CMD = process.env.LOGOUT_SYSTEM_CMD || 'xfce4-session-logout'

// On mocked dev systems where unix-style executables can't run
export const NO_IMT_EXECUTABLES = process.env.NO_IMT_EXECUTABLES === 'true'
