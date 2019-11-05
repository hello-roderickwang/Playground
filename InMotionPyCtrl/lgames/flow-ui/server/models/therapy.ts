export const therapyCategoryMap = {
	activeAssisted: "Active Assisted",
	resistance: "Resistance",
	stabilization: "Stabilization",
	errorAugmentation: "Error Augmentation",
	perturbation: "Curl Perturbation",
	games: "Additional Activities"
}

export type TherapyCategory = keyof typeof therapyCategoryMap

export const therapySubcategoryMap = {
	planarAdaptive: 'Active-assisted (AA) 14 Therapy', // Planar Adaptive
	planarAdaptive10: 'Active-assisted (AA) 10 Therapy', // Planar Adaptive 10
	random: "AA 14 Random Therapy", // Random
	k1012adaptive: "AA 10 Graphical Therapy A", // K1012 Adaptive
	k1012random: "AA 10 Random Graphical Therapy A", // K1012 Random
	ku10adaptive: "AA 10 Graphical Therapy B", // KU 10 Adaptive
	ku10random: "AA 10 Random Graphical Therapy B", // KU 10 Random
	fanNorth: "AA 14 Fan North Therapy", // Fan North
	fanSouth: "AA 14 Fan South Therapy", // Fan South
	fanEast: "AA 14 Fan East Therapy", // Fan East
	fanWest: "AA 14 Fan West Therapy", // Fan West
	strength50: "Resistance 50 Therapy", // Strength 50
	strength100: "Resistance 100 Therapy", // Strength 100
	strength150: "Resistance 150 Therapy", // Strength 150
	strength200: "Resistance 200 Therapy", // Strength 200
	static50: "Stabilization 50 Therapy", // Static 50
	static100: "Stabilization 100 Therapy", // Static 100
	static150: "Stabilization 150 Therapy", // Static 150
	static200: "Stabilization 200 Therapy", // Static 200
	orthogonalGain2: "Error Augmentation 2 Therapy", // Orthogonal Gain 2
	orthogonalGain3: "Error Augmentation 3 Therapy", // Orthogonal Gain 3
	orthogonalGain4: "Error Augmentation 4 Therapy", // Orthogonal Gain 4
	curlcw12: "Curl Perturbation CW 12 Therapy", // Curl CW 12
	curlcw24: "Curl Perturbation CW 24 Therapy", // Curl CW 24
	curlccw12: "Curl Perturbation CCW 12 Therapy", // Curl CCW 12
	curlccw24: "Curl Perturbation CCW 24 Therapy", // Curl CCW 24
	games: "Additional Activities"
}

export type TherapySubcategory = keyof typeof therapySubcategoryMap

/**
 * On the IMT system, activities are categorized as 'therapy' or 'eval'.
 * 'game' is a special type for games
 */
export type ImtActivityType = 'therapy' | 'eval' | 'game'

export type RangeOfMotion = 14 | 10

export const RANGES_OF_MOTION: RangeOfMotion[] = [14, 10]

export const rangeOfMotionMap = {
	14: '14cm (5.51")',
	10: '10cm (3.94")'
}

export interface Activity {
	/** Protocol (in system protocols directory) */
	protocol: string
	/** System categorization, either 'therapy' or 'eval' */
	type: ImtActivityType
	/** System name of activity (eg 'oneway_rec_1') */
	id: string
	/** Range of motion */
	range: RangeOfMotion
	/** Descriptive text to display on UI */
	label: string
	/** Therapy category (only applies to therapies) */
	cat?: TherapyCategory
	/** Therapy subcategory (only applies to therapies) */
	subcat?: TherapySubcategory
	/** Flags that this activity was not found on system in protocols */
	missing?: boolean
}

export interface ActivityGroup {
	activities: Activity[]
}

export interface ActivityMap {
	orientation: ActivityGroup
	evaluation: ActivityGroup
	therapy: ActivityGroup
}

export type ActivityGroupID = keyof ActivityMap

/**
 * Desired Robot Activities grouping and order.
 * This is validated against what actually exists
 * on the system.
 */
export const activityMap: ActivityMap = {
	orientation: {
		activities: [
			{protocol: 'adaptive', type: 'therapy', id: 'warm_up_test', range: 14, label: 'Passive movement test'}, // Test
			{protocol: 'adaptive', type: 'therapy', id: 'oneway_rec_1', range: 14, label: 'Active movement test'}, // One Way Record
			//{protocol: 'adaptive', type: 'therapy', id: 'adaptive_1', range: 14, label: 'Active-assisted movement test'}, // Planar Adaptive
			{protocol: 'adaptive10cm', type: 'therapy', id: 'warm_up_test', range: 10, label: 'Passive movement test'}, // Test
			{protocol: 'adaptive10cm', type: 'therapy', id: 'oneway_rec_1', range: 10, label: 'Active movement test'}, // One Way Record
			//{protocol: 'adaptive10cm', type: 'therapy', id: 'adaptive_1', range: 10, label: 'Active-assisted movement test'} // Planar Adaptive
		]
	},
	evaluation: {
		activities: [
			{protocol: 'adaptive', type: 'eval', id: 'circle_9_cw', range: 14, label: "Circle assessment clockwise 9 o'clock"}, // Circle 9 o’clock Clockwise
			{protocol: 'adaptive', type: 'eval', id: 'circle_9_ccw', range: 14, label: "Circle assessment counter-clockwise 9 o'clock"}, // Circle 9 o’clock Counter-clockwise
			{protocol: 'adaptive', type: 'eval', id: 'circle_3_cw', range: 14, label: "Circle assessment clockwise 3 o'clock"}, // Circle 3 o’clock Clockwise
			{protocol: 'adaptive', type: 'eval', id: 'circle_3_ccw', range: 14, label: "Circle assessment counter-clockwise 3 o'clock"}, // Circle 3 o’clock Counter-clockwise
			{protocol: 'adaptive', type: 'eval', id: 'point_to_point', range: 14, label: "Point to Point assessment"}, // Point-to-point
			{protocol: 'adaptive', type: 'eval', id: 'playback_static', range: 14, label: "Stabilization assessment"}, // Playback static
			{protocol: 'adaptive', type: 'eval', id: 'round_dyn', range: 14, label: "Resistance assessment"}, // Playback dynamic
			{protocol: 'adaptive10cm', type: 'eval', id: 'circle_9_cw', range: 10, label: "Circle assessment clockwise 9 o'clock"}, // Circle 9 o’clock Clockwise
			{protocol: 'adaptive10cm', type: 'eval', id: 'circle_9_ccw', range: 10, label: "Circle assessment counter-clockwise 9 o'clock"}, // Circle 9 o’clock Counter-clockwise
			{protocol: 'adaptive10cm', type: 'eval', id: 'circle_3_cw', range: 10, label: "Circle assessment clockwise 3 o'clock"}, // Circle 3 o’clock Clockwise
			{protocol: 'adaptive10cm', type: 'eval', id: 'circle_3_ccw', range: 10, label: "Circle assessment counter-clockwise 3 o'clock"}, // Circle 3 o’clock Counter-clockwise
			{protocol: 'adaptive10cm', type: 'eval', id: 'point_to_point', range: 10, label: "Point to Point assessment"}, // Point-to-point
			{protocol: 'adaptive10cm', type: 'eval', id: 'playback_static', range: 10, label: "Stabilization assessment"}, // Playback static
			{protocol: 'adaptive10cm', type: 'eval', id: 'round_dyn', range: 10, label: "Resistance assessment"} // Playback dynamic
		]
	},
	therapy: {
		activities: [
			{protocol: 'adaptive10cm', type: 'therapy', cat: 'activeAssisted', subcat: 'planarAdaptive10', id: 'oneway_rec_1', range: 10, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'adaptive10cm', type: 'therapy', cat: 'activeAssisted', subcat: 'planarAdaptive10', id: 'adaptive_1', range: 10, label: 'AA 10 Therapy 1'}, // Adaptive 1
			{protocol: 'adaptive10cm', type: 'therapy', cat: 'activeAssisted', subcat: 'planarAdaptive10', id: 'oneway_rec_2', range: 10, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'adaptive10cm', type: 'therapy', cat: 'activeAssisted', subcat: 'planarAdaptive10', id: 'adaptive_2', range: 10, label: 'AA 10 Therapy 2'}, // Adaptive 2
			{protocol: 'adaptive10cm', type: 'therapy', cat: 'activeAssisted', subcat: 'planarAdaptive10', id: 'oneway_rec_3', range: 10, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'adaptive10cm', type: 'therapy', cat: 'activeAssisted', subcat: 'planarAdaptive10', id: 'adaptive_3', range: 10, label: 'AA 10 Therapy 3'}, // Adaptive 3
			{protocol: 'adaptive10cm', type: 'therapy', cat: 'activeAssisted', subcat: 'planarAdaptive10', id: 'oneway_rec_4', range: 10, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'planarAdaptive', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'},  // One-way record 1
			{protocol: 'adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'planarAdaptive', id: 'adaptive_1', range: 14, label: 'AA 14 Therapy 1'}, // Adaptive 1
			{protocol: 'adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'planarAdaptive', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'planarAdaptive', id: 'adaptive_2', range: 14, label: 'AA 14 Therapy 2'}, // Adaptive 2
			{protocol: 'adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'planarAdaptive', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'planarAdaptive', id: 'adaptive_3', range: 14, label: 'AA 14 Therapy 3'}, // Adaptive 3
			{protocol: 'adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'planarAdaptive', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'random', type: 'therapy', cat: 'activeAssisted', subcat: 'random', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'random', type: 'therapy', cat: 'activeAssisted', subcat: 'random', id: 'random_1', range: 14, label: 'Random 14 Therapy 1'}, // Random 1
			{protocol: 'random', type: 'therapy', cat: 'activeAssisted', subcat: 'random', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'random', type: 'therapy', cat: 'activeAssisted', subcat: 'random', id: 'random_2', range: 14, label: 'Random 14 Therapy 2'}, // Random 2
			{protocol: 'random', type: 'therapy', cat: 'activeAssisted', subcat: 'random', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'random', type: 'therapy', cat: 'activeAssisted', subcat: 'random', id: 'random_3', range: 14, label: 'Random 14 Therapy 3'}, // Random 3
			{protocol: 'random', type: 'therapy', cat: 'activeAssisted', subcat: 'random', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'k1012adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'k1012adaptive', id: 'oneway_rec_1', range: 10, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'k1012adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'k1012adaptive', id: 'adaptive_1', range: 10, label: 'AA 10 Graphical Therapy A 1'}, // Adaptive 1
			{protocol: 'k1012adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'k1012adaptive', id: 'oneway_rec_2', range: 10, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'k1012adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'k1012adaptive', id: 'adaptive_2', range: 10, label: 'AA 10 Graphical Therapy A 2'}, // Adaptive 2
			{protocol: 'k1012adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'k1012adaptive', id: 'oneway_rec_3', range: 10, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'k1012adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'k1012adaptive', id: 'adaptive_3', range: 10, label: 'AA 10 Graphical Therapy A 3'}, // Adaptive 3
			{protocol: 'k1012adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'k1012adaptive', id: 'oneway_rec_4', range: 10, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'k1012random', type: 'therapy', cat: 'activeAssisted', subcat: 'k1012random', id: 'oneway_rec_1', range: 10, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'k1012random', type: 'therapy', cat: 'activeAssisted', subcat: 'k1012random', id: 'random_1', range: 10, label: 'AA 10 Random Graphical Therapy A 1'}, // Random 1
			{protocol: 'k1012random', type: 'therapy', cat: 'activeAssisted', subcat: 'k1012random', id: 'oneway_rec_2', range: 10, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'k1012random', type: 'therapy', cat: 'activeAssisted', subcat: 'k1012random', id: 'random_2', range: 10, label: 'AA 10 Random Graphical Therapy A 2'}, // Random 2
			{protocol: 'k1012random', type: 'therapy', cat: 'activeAssisted', subcat: 'k1012random', id: 'oneway_rec_3', range: 10, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'k1012random', type: 'therapy', cat: 'activeAssisted', subcat: 'k1012random', id: 'random_3', range: 10, label: 'AA 10 Random Graphical Therapy A 3'}, // Random 3
			{protocol: 'k1012random', type: 'therapy', cat: 'activeAssisted', subcat: 'k1012random', id: 'oneway_rec_4', range: 10, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'ku10adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'ku10adaptive', id: 'oneway_rec_1', range: 10, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'ku10adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'ku10adaptive', id: 'adaptive_1', range: 10, label: 'AA 10 Graphical Therapy B 1'}, // Adaptive 1
			{protocol: 'ku10adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'ku10adaptive', id: 'oneway_rec_2', range: 10, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'ku10adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'ku10adaptive', id: 'adaptive_2', range: 10, label: 'AA 10 Graphical Therapy B 2'}, // Adaptive 2
			{protocol: 'ku10adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'ku10adaptive', id: 'oneway_rec_3', range: 10, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'ku10adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'ku10adaptive', id: 'adaptive_3', range: 10, label: 'AA 10 Graphical Therapy B 3'}, // Adaptive 3
			{protocol: 'ku10adaptive', type: 'therapy', cat: 'activeAssisted', subcat: 'ku10adaptive', id: 'oneway_rec_4', range: 10, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'ku10random', type: 'therapy', cat: 'activeAssisted', subcat: 'ku10random', id: 'oneway_rec_1', range: 10, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'ku10random', type: 'therapy', cat: 'activeAssisted', subcat: 'ku10random', id: 'random_1', range: 10, label: 'AA 10 Random Graphical Therapy B 1'}, // Random 1
			{protocol: 'ku10random', type: 'therapy', cat: 'activeAssisted', subcat: 'ku10random', id: 'oneway_rec_2', range: 10, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'ku10random', type: 'therapy', cat: 'activeAssisted', subcat: 'ku10random', id: 'random_2', range: 10, label: 'AA 10 Random Graphical Therapy B 2'}, // Random 2
			{protocol: 'ku10random', type: 'therapy', cat: 'activeAssisted', subcat: 'ku10random', id: 'oneway_rec_3', range: 10, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'ku10random', type: 'therapy', cat: 'activeAssisted', subcat: 'ku10random', id: 'random_3', range: 10, label: 'AA 10 Random Graphical Therapy B 3'}, // Random 3
			{protocol: 'ku10random', type: 'therapy', cat: 'activeAssisted', subcat: 'ku10random', id: 'oneway_rec_4', range: 10, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanNorth', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanNorth', id: 'nfan_1', range: 14, label: 'Fan North 14 Therapy 1'}, // Fan North 1
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanNorth', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanNorth', id: 'nfan_2', range: 14, label: 'Fan North 14 Therapy 2'}, // Fan North 2
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanNorth', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanNorth', id: 'nfan_3', range: 14, label: 'Fan North 14 Therapy 3'}, // Fan North 3
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanNorth', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanSouth', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanSouth', id: 'sfan_1', range: 14, label: 'Fan South 14 Therapy 1'}, // Fan South 1
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanSouth', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanSouth', id: 'sfan_2', range: 14, label: 'Fan South 14 Therapy 2'}, // Fan South 2
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanSouth', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanSouth', id: 'sfan_3', range: 14, label: 'Fan South 14 Therapy 3'}, // Fan South 3
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanSouth', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanEast', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanEast', id: 'efan_1', range: 14, label: 'Fan East 14 Therapy 1'}, // Fan East 1
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanEast', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanEast', id: 'efan_2', range: 14, label: 'Fan East 14 Therapy 2'}, // Fan East 2
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanEast', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanEast', id: 'efan_3', range: 14, label: 'Fan East 14 Therapy 3'}, // Fan East 3
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanEast', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanWest', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanWest', id: 'wfan_1', range: 14, label: 'Fan West 14 Therapy 1'}, // Fan West 1
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanWest', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanWest', id: 'wfan_2', range: 14, label: 'Fan West 14 Therapy 2'}, // Fan West 2
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanWest', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanWest', id: 'wfan_3', range: 14, label: 'Fan West 14 Therapy 3'}, // Fan West 3
			{protocol: 'composite', type: 'therapy', cat: 'activeAssisted', subcat: 'fanWest', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength50', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength50', id: 'strength_50_1', range: 14, label: '50 Resistance 1'}, // Strength 50 1
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength50', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength50', id: 'strength_50_2', range: 14, label: '50 Resistance 2'}, // Strength 50 2
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength50', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength50', id: 'strength_50_3', range: 14, label: '50 Resistance 3'}, // Strength 50 3
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength50', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength100', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength100', id: 'strength_100_1', range: 14, label: '100 Resistance 1'}, // Strength 100 1
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength100', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength100', id: 'strength_100_2', range: 14, label: '100 Resistance 2'}, // Strength 100 2
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength100', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength100', id: 'strength_100_3', range: 14, label: '100 Resistance 3'}, // Strength 100 3
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength100', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength150', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength150', id: 'strength_150_1', range: 14, label: '150 Resistance 1'}, // Strength 150 1
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength150', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength150', id: 'strength_150_2', range: 14, label: '150 Resistance 2'}, // Strength 150 2
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength150', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength150', id: 'strength_150_3', range: 14, label: '150 Resistance 3'}, // Strength 150 3
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength150', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength200', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength200', id: 'strength_200_1', range: 14, label: '200 Resistance 1'}, // Strength 200 1
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength200', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength200', id: 'strength_200_2', range: 14, label: '200 Resistance 2'}, // Strength 200 2
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength200', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength200', id: 'strength_200_3', range: 14, label: '200 Resistance 3'}, // Strength 200 3
			{protocol: 'composite', type: 'therapy', cat: 'resistance', subcat: 'strength200', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static50', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static50', id: 'static_50_1', range: 14, label: '50 Stabilization 1'}, // Static 50 1
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static50', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static50', id: 'static_50_2', range: 14, label: '50 Stabilization 2'}, // Static 50 2
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static50', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static50', id: 'static_50_3', range: 14, label: '50 Stabilization 3'}, // Static 50 3
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static50', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static100', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static100', id: 'static_100_1', range: 14, label: '100 Stabilization 1'}, // Static 100 1
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static100', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static100', id: 'static_100_2', range: 14, label: '100 Stabilization 2'}, // Static 100 2
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static100', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static100', id: 'static_100_3', range: 14, label: '100 Stabilization 3'}, // Static 100 3
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static100', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static150', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static150', id: 'static_150_1', range: 14, label: '150 Stabilization 1'}, // Static 150 1
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static150', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static150', id: 'static_150_2', range: 14, label: '150 Stabilization 2'}, // Static 150 2
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static150', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static150', id: 'static_150_3', range: 14, label: '150 Stabilization 3'}, // Static 150 3
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static150', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static200', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static200', id: 'static_200_1', range: 14, label: '200 Stabilization 1'}, // Static 200 1
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static200', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static200', id: 'static_200_2', range: 14, label: '200 Stabilization 2'}, // Static 200 2
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static200', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static200', id: 'static_200_3', range: 14, label: '200 Stabilization 3'}, // Static 200 3
			{protocol: 'composite', type: 'therapy', cat: 'stabilization', subcat: 'static200', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain2', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain2', id: 'ogain2_1', range: 14, label: '2x Error augmentation 1'}, // Orthogonal gain x2 1
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain2', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain2', id: 'ogain2_2', range: 14, label: '2x Error augmentation 2'}, // Orthogonal gain x2 2
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain2', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain2', id: 'ogain2_3', range: 14, label: '2x Error augmentation 3'}, // Orthogonal gain x2 3
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain2', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain3', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain3', id: 'ogain3_1', range: 14, label: '3x Error augmentation 1'}, // Orthogonal gain 3x 1
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain3', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain3', id: 'ogain3_2', range: 14, label: '3x Error augmentation 2'}, // Orthogonal gain 3x 2
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain3', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain3', id: 'ogain3_3', range: 14, label: '3x Error augmentation 3'}, // Orthogonal gain 3x 3
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain3', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain4', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain4', id: 'ogain4_1', range: 14, label: '4x Error augmentation 1'}, // Orthogonal gain 4x 1
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain4', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain4', id: 'ogain4_2', range: 14, label: '4x Error augmentation 2'}, // Orthogonal gain 4x 2
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain4', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain4', id: 'ogain4_3', range: 14, label: '4x Error augmentation 3'}, // Orthogonal gain 4x 3
			{protocol: 'composite', type: 'therapy', cat: 'errorAugmentation', subcat: 'orthogonalGain4', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlcw12', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlcw12', id: 'curln12_1', range: 14, label: 'CW 12 Curl Therapy 1'}, // Curl CW 12 1
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlcw12', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlcw12', id: 'curln12_2', range: 14, label: 'CW 12 Curl Therapy 2'}, // Curl CW 12 2
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlcw12', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlcw12', id: 'curln12_3', range: 14, label: 'CW 12 Curl Therapy 3'}, // Curl CW 12 3
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlcw12', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlcw24', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlcw24', id: 'curln24_1', range: 14, label: 'CW 24 Curl Therapy 1'}, // Curl CW 24 1
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlcw24', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlcw24', id: 'curln24_2', range: 14, label: 'CW 24 Curl Therapy 2'}, // Curl CW 24 2
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlcw24', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlcw24', id: 'curln24_3', range: 14, label: 'CW 24 Curl Therapy 3'}, // Curl CW 24 3
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlcw24', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlccw12', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlccw12', id: 'curlp12_1', range: 14, label: 'CCW 12 Curl Therapy 1'}, // Curl CCW 12 1
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlccw12', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlccw12', id: 'curlp12_2', range: 14, label: 'CCW 12 Curl Therapy 2'}, // Curl CCW 12 2
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlccw12', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlccw12', id: 'curlp12_3', range: 14, label: 'CCW 12 Curl Therapy 3'}, // Curl CCW 12 3
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlccw12', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlccw24', id: 'oneway_rec_1', range: 14, label: 'Active movement test 1'}, // One-way record 1
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlccw24', id: 'curlp24_1', range: 14, label: 'CCW 24 Curl Therapy 1'}, // Curl CCW 24 1
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlccw24', id: 'oneway_rec_2', range: 14, label: 'Active movement test 2'}, // One-way record 2
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlccw24', id: 'curlp24_2', range: 14, label: 'CCW 24 Curl Therapy 2'}, // Curl CCW 24 2
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlccw24', id: 'oneway_rec_3', range: 14, label: 'Active movement test 3'}, // One-way record 3
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlccw24', id: 'curlp24_3', range: 14, label: 'CCW 24 Curl Therapy 3'}, // Curl CCW 24 3
			{protocol: 'composite', type: 'therapy', cat: 'perturbation', subcat: 'curlccw24', id: 'oneway_rec_4', range: 14, label: 'Active movement test 4'}, // One-way record 4
			// Games
			{protocol: '-', type: 'game', cat: 'games', subcat: 'games', id: 'cs', range: 14, label: 'Maze'},
			{protocol: '-', type: 'game', cat: 'games', subcat: 'games', id: 'pong', range: 14, label: '4-Way Pong'},
			{protocol: '-', type: 'game', cat: 'games', subcat: 'games', id: 'race', range: 14, label: 'Obstacle Training'},
			{protocol: '-', type: 'game', cat: 'games', subcat: 'games', id: 'squeegee', range: 14, label: 'Squeegee'},
			//{protocol: '-', type: 'game', cat: 'games', subcat: 'games', id: 'pick', range: 14, label: 'Pick'},
			{protocol: '-', type: 'game', cat: 'games', subcat: 'games', id: 'cs', range: 10, label: 'Maze'},
			{protocol: '-', type: 'game', cat: 'games', subcat: 'games', id: 'pong', range: 10, label: '4-Way Pong'},
			{protocol: '-', type: 'game', cat: 'games', subcat: 'games', id: 'race', range: 10, label: 'Obstacle Training'},
			{protocol: '-', type: 'game', cat: 'games', subcat: 'games', id: 'squeegee', range: 10, label: 'Squeegee'},
			//{protocol: '-', type: 'game', cat: 'games', subcat: 'games', id: 'pick', range: 14, label: 'Pick'},
		]
	}
}