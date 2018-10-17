<?php


// try to find all mentions of time in the literary quotes

// we'll first try to find simple formats with digits (like '04.23 P.M.' and '1am') using a regular expreission.
// instead of trying to catch everything else with more complicated regular expressions (and have a lot of false positives),
// make a function to try several different time formats one after another, 
// longest ('twenty-three minutes past four') first and then shorter ones (like 'At five').
// Save the first found result in a csv-file.

$file = fopen("litclock_annotated_1.csv","w");

$row = 1;
if (($handle = fopen("litclock.csv", "r")) !== FALSE) {
	while (($data = fgetcsv($handle, 1000, ";")) !== FALSE) {
		$num = count($data);
		$row++;
		$time = $data[0];
		$time = new DateTime($time);
		$quote = $data[1];
		$quote = trim(preg_replace('/\s+/', ' ', $quote));
		$title = $data[2];
		$author = $data[3];

		// first try simple digital mentions of time in the quote
		$result = findDigitalMentionsOfTime($quote, $time);
		if ( $result !== FALSE ) {

			list($foundstring, $foundposition) = $result;
			// echo $time->format('H:i') . "\t" . $foundposition . "\t" . $foundstring . "\t\t" . $quote . "\n";
			fputcsv($file, array($time->format('H:i'), $foundposition, (string)$foundstring, $quote, $title, $author),'|');

		} else {

			$result = findTimeStrings($quote, $time);

			if ( $result !== FALSE ) {
			// if that didn't get us anywhere, try strings with numerals

				list($foundstring, $foundposition) = $result;
				// echo $time->format('H:i') . "\t" . $foundposition . "\t" . $foundstring . "\t\t" . $quote . "\n";
				fputcsv($file, array($time->format('H:i'), $foundposition, (string)$foundstring, $quote, $title, $author),'|');

			} else {

				// echo $time->format('H:i') . "\tNO RESULT:\t\t" . $quote . "\n";
				fputcsv($file, array($time->format('H:i'), "", "", $quote, $title, $author),'|');

			}

		}

	}
	fclose($handle);
}

fclose($file);



function findDigitalMentionsOfTime($quote, $time) {

	// [0-9]{1,4}[:\.]?\d*(\s?[ap\.M]{2,})?h? -> this worked well, but also gave too many false negatives and false positives.
	// To prevent that, we'll use the same regex but with the time we know should be in the quote.

	$preg_string = '/0?';

	if ( $time->format('A') == 'PM' ) {
		$preg_string .= '(' . $time->format('g') . '|' . $time->format('G') . ')';
	} else {
		$preg_string .= $time->format('g');
	}

	$preg_string .= '[:\.]?';

	// we need to specify the minutes too, otherwise "From 1am to 1.16am" will get us '1am' even if the quote is there for '1:16'
	$preg_string .= $time->format('i');
	$preg_string .= '(\s?[ap\.M]{2,})?h?/i';

	preg_match($preg_string, $quote, $found, PREG_OFFSET_CAPTURE);
	
	if ( count($found) > 0 ) {
		$foundstring = $found[0][0];
		$foundposition = $found[0][1];
		return array($foundstring, $foundposition); 
	} else {
		return FALSE;
	}

}


function findTimeStrings($quote, $time) {


	$preg_string = '/0?';

	if ( $time->format('A') == 'PM' ) {
		$preg_string .= '(' . $time->format('g') . '|' . $time->format('G') . ')';
	} else {
		$preg_string .= $time->format('g');
	}

	$minutes = $time->format('i');

	$timestrings = formulateTimeStrings($time);


    foreach ($timestrings as $timestring)
	{
		$foundposition=stripos($quote, $timestring);
		if ( $foundposition !== FALSE ) {
			// when a time is found
			return array($timestring, $foundposition);
			break;
		}
	}

	return FALSE;
}


function formulateTimeStrings($time) {

	$timestrings = array();

	$numeral = array('', 'one','two','three','four','five','six','seven','eight','nine','ten','eleven','twelve','thirteen','fourteen','fifteen','sixteen','seventeen','eighteen','nineteen','twenty','twenty-one','twenty-two','twenty-three','twenty-four','twenty-five','twenty-six','twenty-seven','twenty-eight','twenty-nine','thirty','thirty-one','thirty-two','thirty-three','thirty-four','thirty-five','thirty-six','thirty-seven','thirty-eight','thirty-nine','forty','forty-one','forty-two','forty-three','forty-four','forty-five','forty-six','forty-seven','forty-eight','forty-nine','fifty','fifty-one','fifty-two','fifty-three','fifty-four','fifty-five','fifty-six','fifty-seven','fifty-eight','fifty-nine');

	$minutes = (int)$time->format('i'); // minutes without leading zeroes
	$minutesNumerals = $numeral[$minutes];


	/*
	g	12-hour format of an hour without leading zeros	1 through 12
	G	24-hour format of an hour without leading zeros	0 through 23
	i	Minutes with leading zeros	00 to 59
	*/

	$timestrings[] = $numeral[$time->format('g')] . "-" . $numeral[(int)$time->format('i')]; // 'Five-thirty'
	$timestrings[] = $numeral[$time->format('g')] . " " . $numeral[(int)$time->format('i')]; // 'Five thirty'

	if ( $time->format('G') == 0 ) {
		if ( $time->format('i') == '00' ) {
			$timestrings[] = "midnight";
		} else {
			$timestrings[] = $numeral[(int)$time->format('i')] . " past midnight";
			$timestrings[] = (int)$time->format('i') . " past midnight";
			$timestrings[] = $numeral[(int)$time->format('i')] . " minutes past midnight";
			$timestrings[] = (int)$time->format('i') . " minutes past midnight";
		}
	}

	if ( $time->format('G') == 12 ) {
		if ( $time->format('i') == '00' ) {
			$timestrings[] = "noon";
		} else {
			$timestrings[] = $numeral[(int)$time->format('i')] . " past noon";
			$timestrings[] = (int)$time->format('i') . " past noon";
		}
	}

	if ( $time->format('i') == '00' ) {
		$timestrings[] = $numeral[$time->format('g')] . " o'clock";
		$timestrings[] = $time->format('g') . " o'clock";
		$timestrings[] = "At " . $numeral[$time->format('g')];
		$timestrings[] = $numeral[$time->format('g')];
		$timestrings[] = $numeral[$time->format('G')];
	} else {	
		$timestrings[] = $numeral[(int)$time->format('i')] . " past " . $numeral[$time->format('g')];
		$timestrings[] = (int)$time->format('i') . " past " . $numeral[$time->format('g')];
		$timestrings[] = $numeral[(int)$time->format('i')] . " minutes past " . $numeral[$time->format('g')];
		$timestrings[] = (int)$time->format('i') . " minutes past " . $numeral[$time->format('g')];
	}

	if ($time->format('i') == 15) {
		$timestrings[] = "quarter past " . $numeral[$time->format('g')];
	}

	if ( $time->format('i') == 30 ) {
		$timestrings[] = "half past " . $numeral[$time->format('g')];
		$timestrings[] = "half-past " . $numeral[$time->format('g')];
		$timestrings[] = "half past " . $time->format('g');		
	}

	// add one hour for counting towards the next hour
	date_add($time, date_interval_create_from_date_string('1 hours'));

	if ( $time->format('i') > 30 ) {
		$timestrings[] = $numeral[60-(int)$time->format('i')] . " to " . $numeral[$time->format('g')];
		$timestrings[] = (60-(int)$time->format('i')) . " to " . $numeral[$time->format('g')];
		$timestrings[] = $numeral[60-(int)$time->format('i')] . " minutes to " . $numeral[$time->format('g')];
		$timestrings[] = (60-(int)$time->format('i')) . " minutes to " . $numeral[$time->format('g')];
		$timestrings[] = $numeral[60-(int)$time->format('i')] . " before " . $numeral[$time->format('g')];
		$timestrings[] = (60-(int)$time->format('i')) . " before " . $numeral[$time->format('g')];
		$timestrings[] = $numeral[60-(int)$time->format('i')] . " minutes before " . $numeral[$time->format('g')];
		$timestrings[] = (60-(int)$time->format('i')) . " minutes before " . $numeral[$time->format('g')];
	}

	if ($time->format('i') == '45') {
		$timestrings[] = "quarter to " . $numeral[$time->format('g')];
	}

	// reset the time to prevent confusion
	date_sub($time, date_interval_create_from_date_string('1 hours'));

	usort($timestrings,'sortByLength');

	return $timestrings;

}

function sortByLength($a,$b){
    return strlen($b)-strlen($a);
}






?>