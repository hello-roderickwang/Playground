export const master =
`<!DOCTYPE html>
<html>
<head>
	<meta http-equiv="content-type" content="text/html; charset=utf-8"/>
	<meta name="viewport" content="initial-scale=1, width=device-width"/>
	<title>Bionik InMotion - Report</title>
	<link rel="stylesheet" type="text/css" href="/css/report.css"/>
</head>
<body>
{{content}}
</body>
</html>
`

export const evaluations =
`<h1>Evaluation Results</h1>
<div class="reports">
{{evaluations}}
</div>
`

export const therapies =
`<div class="reports">
</div>
`

export const evaluation =
`<div class="report">
	<table>
		<tr>
			<th colspan="7">{{title}}</th>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td colspan="2">Initial Eval: {{date1}}</td>
			<td colspan="2">Previous Eval: {{date2}}</td>
			<td colspan="2">Current Eval: {{date3}}</td>
		</tr>
		<tr>
			<td>Movement Record</td>
			<td colspan="2">{{image1}}</td>
			<td colspan="2">{{image2}}</td>
			<td colspan="2">{{image3}}</td>
		</tr>
		<tr>
			<td>Metrics</td>
			<td>Result</td>
			<td>Goal</td>
			<td>Result</td>
			<td>Goal</td>
			<td>Result</td>
			<td>Goal</td>
		</tr>
		<tr>
			<td>Smoothness</td>
			<td></td>
			<td></td>
			<td></td>
			<td></td>
			<td></td>
			<td></td>
		</tr>
		<tr>
			<td>Summary</td>
			<td colspan="6">
				Patient’s movement smoothness or ability to control acceleration improves with a higher number. Reach accuracy reflects the average error with hitting the center of the target. A lower number indicates more accurate reaching accuracy.
			</td>
		</tr>
	</table>
</div>
`
