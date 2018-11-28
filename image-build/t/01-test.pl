use Modern::Perl '2017';

use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::Modern;

use lib '.';
use TimeMatch;

# prove t/01-test.pl |& egrep -E '^|<<[^>]+(>>|$)|^[^<>]+>>'

compare_strings(get_book_tests(), "book tests");
compare_strings(get_csv_tests(),  "csv tests");

if (0) {
check_substring(get_csv_tests());

check_extract(get_book_tests(), "book tests");
check_extract(get_csv_tests(),  "csv tests");

check_extract_times(get_book_tests(), "book tests");
check_extract_times(get_csv_tests(),  "csv tests");
}
done_testing;

exit;


sub compare_strings {
    my ($tests, $type) = @_;

    subtest "Compare $type" => sub {
        foreach my $t (@$tests) {
            my ($match, $name, $expected) = @$t;

            my $string = $expected;
            while ($string =~ s{<< ([^|>]+) [|] \d+ \w? (:\d)? >>}{$1}gx) { }

            $string =~ s{<<(.*?)>>}{$1}g;

            my $result = do_match($string);
            if ($match == 1) {
                is($result, $expected, $name);
            }
            elsif ($match == 0) {
                isnt($result, $expected, $name);
            }
            elsif ($match == -1) {
                local $TODO = "should work";
                is($result, $expected, $name);
            }
            elsif ($match == -2) {
                local $TODO = "shouldn't work";
                isnt($result, $expected, $name);
            }
            else {
                die;
            }
        }
    };
}

sub check_substring {
    my ($tests) = @_;

    subtest "Extraction test" => sub {
        foreach my $t (@$tests) {
            my ($match, $name, $expected) = @$t;

            my $string = $expected;
            while ($string =~ s{<< ([^|>]+) [|] \d+ \w? (:\d)? >>}{$1}gx) { }

            $string =~ s{<<(.*?)>>}{$1}g;

            my $result = do_match($string);

            my ($time, $timestr) = $name =~ m{^ Timestr \s \[ ( \d\d:\d\d ) \] : \s (.+)}xi
                or die "Bad name '$name'";

            if ($match == 1) {
                like($result, qr{<< (?^i:\Q$timestr\E) [|] \d+ \w? (:\d)? >>}x, $name);
            }
            elsif ($match == 0) {
                like($result, qr{<< (?^i:\Q$timestr\E) [|] \d+ \w? (:\d)? >>}x, $name);
            }
            elsif ($match == -1) {
                local $TODO = "should work";
                like($result, qr{<< (?^i:\Q$timestr\E) [|] \d+ \w? (:\d)? >>}x, $name);
            }
            elsif ($match == -2) {
                local $TODO = "shouldn't work";
                like($result, qr{<< (?^i:\Q$timestr\E) [|] \d+ \w? (:\d)? >>}x, $name);
            }
            else {
                die;
            }
        }
    };
}

sub check_extract {
    my ($tests, $type) = @_;

    subtest "Extract $type" => sub {
        foreach my $t (@$tests) {
            my ($match, $name, $string) = @$t;

            my @times = extract_times($string);
            my @matches = $string =~ m{<< ([^|>]+) [|] \d+ \w? (?: :\d)? >>}xg;

            if ($match == 1) {
                is(int(@times), int(@matches), "Extract '$string': ". join(", ", map {"'$_'"} @matches));
            }
            elsif ($match == -1) {
                local $TODO = "should work";
                is(int(@times), int(@matches), "Extract: '$string'". join(", ", map {"'$_'"} @matches));
            }
        }
    };
}


sub check_extract_times {
    my ($tests, $type) = @_;

    subtest "Extract time $type" => sub {
        foreach my $t (@$tests) {
            my ($match, $name, $string) = @$t;

            if ($type eq 'csv tests') {
                # CSV tests
                my ($time, $timestr) = $name =~ m{^ Timestr \s \[ ( \d\d:\d\d ) \] : \s (.+)}xi
                    or die "Bad name '$name'";

                my @times = extract_times($string, 1);
                my @matches = $string =~ m{<< ([^|>]+) [|] \d+ \w? (?: :\d)? >>}xg;

                if ($match == 1 or $match == -1) {
                    local $TODO = "should work"
                        if $match == -1;

                    ok(grep({ m{^\Q$time\E:} } @times),
                       "Match time $time: "
                       . join(", ", map {"'$_'"} @matches)
                       . "; got: ". join(", ", map {"'$_'"} @times)
                        );
                }
            }
            else {
                # Book tests
                my ($time) = $name =~
                    m{^ \[ (?<time> ( ap \s )? ( ( ~ | < | > | << | >> )  \s )? \d\d:\d\d ) \] \s }xin;
                $time ||= '';

                my @times = extract_times($string, 0);
                my @matches = $string =~ m{<< ([^|>]+) [|] \d+ \w? (?: :\d)? >>}xg;

                if ($match == 1 or $match == -1) {
                    local $TODO = "should work"
                        if $match == -1;

                    ok(grep({ m{^\Q$time\E:} } @times) || ($time eq '' and @times == 0),
                       "Match time $time: "
                       . join(", ", map {"'$_'"} @matches)
                       . "; got: ". join(", ", map {"'$_'"} @times)
                        );
                }
            }
        }
    };
}


sub get_book_tests {
    return [[1, "[ap 01:00] Trainspotting", "— Well, ah’m at <<one|9c:0>>. Ah’ll see ye back here at <<two|9b>>. Ah’ll gie ye ma tie tae pit oan, n some speed. Buck ye up a bit, let ye sell yirsel, ken? So let’s get tae work oan they appos."],

            ## Terry Pratchett/Making Money
          [
            1,
            '[ap 08:00] Making Money - Terry Pratchett.epub (Making_Money_split_004.html) - eight',
            "\x{201c}No, not at all. You have become an exemplary citizen, Mr. Lipwig,\x{201d} said Vetinari, carefully stamping a V into the cooling wax. \x{201c}You rise each morning at <<eight|9c:0>>, you are at your desk at thirty minutes past. You have turned the Post Office from a calamity into a smoothly running machine. You pay your taxes and a little bird tells me that you are tipped to be next year\x{2019}s chairman of the Merchants\x{2019} Guild. Well done, Mr. Lipwig!\x{201d}"
          ],
          [
            1,
            '[ap 11:29] Making Money - Terry Pratchett.epub (Making_Money_split_004.html) - twenty-nine minutes past eleven',
            "At <<twenty-nine minutes past eleven|10>> the alarm on his desk clock went bing. Moist got up, put his chair under the desk, walked to the door, counted to three, opened it, said \x{201c}Hello, Tiddles\x{201d} as the Post Office\x{2019}s antique cat padded in, counted to nineteen as the cat did its circuit of the room, said \x{201c}Good-bye, Tiddles\x{201d} as it plodded back into the corridor, shut the door, and went back to his desk."
          ],
          [
            1,
            '[ap 01:27] Making Money - Terry Pratchett.epub (Making_Money_split_005.html) - twenty-seven minutes and thirty-six seconds past one',
            "\x{201c}You jest, Mr. Lipwig, but there may be a grain of truth there.\x{201d} Bent sighed. \x{201c}I can see you have a lot to learn, and at least you\x{2019}ll have me to teach you. And now, I think, you would like to see the Mint. People always like to see the Mint. It\x{2019}s <<twenty-seven minutes and thirty-six seconds past one|10>>, so they should have finished their lunch hour.\x{201d}"
          ],
          [
            1,
            '[ap 02:00] Making Money - Terry Pratchett.epub (Making_Money_split_006.html) - two',
            "\x{201c}So if I save ninety-three-point-forty-seven dollars a year for seven years at <<two|9c:0>> and a quarter percent, compound, how\x{2014}\x{201d}"
          ],
          [
            1,
            '[12:00] Making Money - Terry Pratchett.epub (Making_Money_split_006.html) - midday',
            "Lunchtime arrived, and with it a plate of one-foot-wide cheese sandwiches delivered by Gladys, along with the <<midday|13>> copy of the Times\x{2014}"
          ],
          [
            1,
            '[12:00] Making Money - Terry Pratchett.epub (Making_Money_split_007.html) - noon',
            "\x{201c}She died sitting at her desk, Master,\x{201d} said Bent soothingly, as he untied the string on the big round box. \x{201c}We have replaced the chair. By the way, she is to be buried tomorrow. Small Gods, at <<noon|9e>>, family members only, by request.\x{201d}"
          ],
          [
            1,
            '[~ 00:00] Making Money - Terry Pratchett.epub (Making_Money_split_007.html) - around midnight',
            "Next evening, it turned out that the pecunious youth spent the evening in a bar and died outside in a drunken brawl <<around midnight|13>>, short of money and even shorter of breath. Heretofore\x{2019}s room was next to Cranberry\x{2019}s. On reflection, he\x{2019}d heard the man come in late that night."
          ],
          [
            1,
            '[< 20:00] Making Money - Terry Pratchett.epub (Making_Money_split_008.html) - Nearly twenty',
            "\x{201c}<<Nearly twenty|9:0>>!\x{201d}"
          ],
          [
            1,
            '[ap ~ 02:00] Making Money - Terry Pratchett.epub (Making_Money_split_008.html) - About two',
            "\x{201c}<<About two|9:0>> or three hundred, but\x{2014}\x{201d}"
          ],
          [
            1,
            '[ap 02:00] Making Money - Terry Pratchett.epub (Making_Money_split_008.html) - two',
            "\x{201c}Do you mean \x{2018}borrow at one-half, lend at <<two|9c:0>>, go home at <<three|9c:0>>\x{2019}?\x{201d} said Bent."
          ],
          [
            1,
            '[ap ~ 00:00] Making Money - Terry Pratchett.epub (Making_Money_split_008.html) - About twelve',
            "\x{201c}<<About twelve|9:0>>,\x{201d} said Moist."
          ],
          [
            1,
            '[ap 05:00] Making Money - Terry Pratchett.epub (Making_Money_split_008.html) - Five',
            "\x{201c}<<Five|9k:0>>? It says it\x{2019}s worth one!\x{201d} said Pucci, aghast."
          ],
          [
            1,
            '[17:00] Making Money - Terry Pratchett.epub (Making_Money_split_008.html) - Seventeen',
            "\x{201c}<<Seventeen|9k:0>>,\x{201d} said Moist."
          ],
          [
            1,
            '[00:00] Making Money - Terry Pratchett.epub (Making_Money_split_009.html) - midnight',
            "The guard who finally turned up to see who was struggling to unlock the front door gave him a bit of trouble until a second guard, who was capable of modest intelligence, pointed out that if the chairman wanted to get into the bank at <<midnight|13>> then that was fine. He was the damn boss, wasn\x{2019}t he? Don\x{2019}t you read the papers? See gold suit? And he had a key! So what if he had a big fat bag? He was coming in with it, right? If he was leaving with it, might be a different matter, ho ho, just my little joke, sir, sorry about that sir\x{2026}"
          ],
          [
            1,
            '[02:00] Making Money - Terry Pratchett.epub (Making_Money_split_009.html) - two a.m.',
            "The man would be miles away by now, and not even a vampire or a werewolf could smell him on a wet and windy night like this. They couldn\x{2019}t pin anything on Moist, but in the cold, wet light of <<two a.m.|5>>, he could imagine bloody Commander Vimes worrying at this, picking away at it in that thick-headed way of his."
          ],
          [
            1,
            "[ap ~ 04:00] Making Money - Terry Pratchett.epub (Making_Money_split_009.html) - about four o\x{2019}clock",
            "It must be <<about four o\x{2019}clock|6>>, thought Moist. <<Four o\x{2019}clock|6>>! I hate it when there are two <<four o\x{2019}clocks|6>> in the same day\x{2026}"
          ],
          [
            1,
            '[00:13] Making Money - Terry Pratchett.epub (Making_Money_split_009.html) - 0.13',
            "\x{201c}Ah, yes, in the third iteration,\x{201d} said Ponder. \x{201c}They couldn\x{2019}t get much further than that in those days. Now, of course, we\x{2019}ve got controlled recursion and aim-driven folding that effectively reduces collateral boxing to <<0.13|5a:0>> percent, a twelvefold improvement in the last year alone!\x{201d}"
          ],
          [
            1,
            "[ap 03:00] Making Money - Terry Pratchett.epub (Making_Money_split_009.html) - three o\x{2019}clock",
            "\x{201c}I said the Department of Postmortem Communications,\x{201d} said Ponder very firmly. \x{201c}I suggest you come back at <<three o\x{2019}clock|6>>.\x{201d}"
          ],
          [
            1,
            '[ap 04:00] Making Money - Terry Pratchett.epub (Making_Money_split_010.html) - Four',
            "\x{201c}I told you. <<Four|9k:0>>.\x{201d}"
          ],
          [
            1,
            '[ap 07:30] Making Money - Terry Pratchett.epub (Making_Money_split_010.html) - half past seven',
            "\x{201c}I\x{2019}m not sure. In fact I\x{2019}d better go and check. Look, we\x{2019}ve both had a busy day. I\x{2019}ll send a cab at <<half past seven|10>>, all right?\x{201d}"
          ],
          [
            1,
            '[ap 09:06] Making Money - Terry Pratchett.epub (Making_Money_split_011.html) - nine six',
            "The Patrician shut his eyes, drummed his fingers on the desktop for a moment. \x{201c}Hmm\x{2026}<<nine six|5a:0>> <<three one|5a:0>> seven four\x{2014}\x{201d} Drumknott scribbled hastily as the numbers streamed, and Vetinari eventually concluded: \x{201c}\x{2014}<<eight four|5a:0>> <<seven three|5a:0>>. And I\x{2019}m sure they used that one last month. On a Monday, I believe.\x{201d}"
          ],
          [
            1,
            "[ap 09:00] Making Money - Terry Pratchett.epub (Making_Money_split_012.html) - nine o\x{2019}clock",
            "
\x{201c}I\x{2019}M AFRAID I have to close the office now, Reverend,\x{201d} the voice of Ms. Houser broke into Cribbins\x{2019}s dreams. \x{201c}We open up again at <<nine o\x{2019}clock|6>> tomorrow,\x{201d} it added hopefully."
          ],
          [
            1,
            '[ap 03:00] Making Money - Terry Pratchett.epub (Making_Money_split_012.html) - three',
            "\x{201c}\x{2014}and so you have two, and soon it\x{2019}s <<three|9f>>, and eventually there\x{2019}s more horseradish than beef, and then one day you realize the beef fell out and you didn\x{2019}t notice.\x{201d}"
          ],
          [
            1,
            '[ap 04:15] Making Money - Terry Pratchett.epub (Making_Money_split_012.html) - Four fifteen',
            "He looked at his watch. <<Four fifteen|9j>>, and no one about but the guards. There were watchmen on the main doors. He was indeed not under arrest, but this was one of those civilized little arrangements: he was not under arrest, provided that he didn\x{2019}t try to act like a man who was not under arrest."
          ],
          [
            1,
            '[13:00] Making Money - Terry Pratchett.epub (Making_Money_split_012.html) - Thirteen',
            "\x{201c}<<Thirteen|9k:0>>?\x{201d} he quavered."
          ],
          [
            1,
            "[ap 09:00] Making Money - Terry Pratchett.epub (Making_Money_split_014.html) - Nine o\x{2019}clock",
            "\x{201c}<<Nine o\x{2019}clock|6>> tomorrow, in the Great Hall,\x{201d} said Vetinari. \x{201c}I invite all interested parties to attend. We shall get to the bottom of this.\x{201d} He raised his voice. \x{201c}Are there any directors of the Royal Bank here? Ah, Mr. Lavish. Are you well?\x{201d}"
          ],
          [
            1,
            '[ap 05:00] Making Money - Terry Pratchett.epub (Making_Money_split_015.html) - five',
            "In fact, it stomped after the coach all the way to the palace. There were a lot of watchmen lining the route and there seemed to be a black-clad figure on every rooftop. It looked as though Vetinari was not taking any chances on him escaping. There were more guards waiting in the back courtyard\x{2014}more than was efficient, Moist could tell, since it can be easier for a swift-thinking man to get away from twenty men than from <<five|9c:0>>. But somebody was Making A Statement. It didn\x{2019}t matter what it was, so long as it looked impressive."
          ],
          [
            1,
            '[06:00] Making Money - Terry Pratchett.epub (Making_Money_split_016.html) - six a.m.',
            '
It was <<six a.m.|5>>, and the fog seemed glued to the windows, so thick that it should have contained croutons. But he liked these moments, before the fragments of yesterday reassembled themselves.'
          ],
          [
            1,
            '[ap 02:00] Making Money - Terry Pratchett.epub (Making_Money_split_016.html) - Two',
            "\x{201c}Oh, yes. <<Two|9i:0>>, <<five|9i:0>>, and ten dollars to start with. And the fives and tens will talk.\x{201d}"
          ],


            ## Paul Theroux - The Old Patagonian Express
          [
            1,
            '[ap 07:30] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter019.html) - seven-thirty',
            "


    The Old Patagonian Express







Necessity kissed me with luck. There was no better way to leave the high plains \x{2013} that world of kitty litter \x{2013} than to slip across Argentina\x{2019}s simple frontier at night, make the acquaintance of its empty quarter the next day and, the following morning, arrive at a large provincial capital and to walk its streets while the city slept. It was only <<seven-thirty|9c:1>>; not even the coffee shops were open. The royal palms and the dark green araucarias dripped in the mist. The day was mine; if nothing in the city of Tucuman persuaded me to stay, I could board the North Star that evening on a sleeper and wake up in Buenos Aires. There was a risk on this route. In my notebook, I had a clipping which I had cut out of a Bogot\x{e1} newspaper. Railway Catastrophe in Argentina: 50 Dead, ran the Spanish headline. \x{2018}The train \x{201c}The North Star\x{201d}, said the police, was leaving the province of Tucuman when it charged a heavy truck at a level crossing.\x{2019} The incident, which was reported with all the enthusiasm Latin Americans have for disasters, had happened only a month before. \x{2018}You will have no difficulty getting a berth on that train,\x{2019} a station porter told me in Tucuman. \x{2018}Ever since it crashed, people have been frightened to take it.\x{2019}"
          ],
          [
            1,
            '[16:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter019.html) - four in the afternoon',
            "After the barrel-chested Indians living among wind-haunted rocks in the high plains, and the farmers in the tumbledown villages near the border, and the yawning cracked-open river valleys of the north, I was prepared for anything but Tucuman. It was gloomy, but gloom was part of the Argentine temper; it was not a dramatic blackness, but rather a dampness of soul, the hang-dog melancholy immigrants feel on rainy afternoons far from home. There was no desolation, and if there were barbarities they remained dark secrets and were enacted in the torture chambers of the police stations or in the cramped workers\x{2019} quarters of the sugar planations. It was <<four in the afternoon|9a>> before I found a bar \x{2013} Tucuman was that proper."
          ],
          [
            1,
            "[ap 10:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter019.html) - ten o\x{2019}clock",
            "Dinner was served at <<ten o\x{2019}clock|6>> \x{2013} four courses, including a fat steak, for two dollars. It was the sort of dining car where the waiters and stewards were dressed more formally than the people eating. All the tables were full, a well-fed noisy crowd of mock-Europeans. Two men had joined Oswaldo and me, and after a decent pause and some wine, one of them began talking about his reason for going to Buenos Aires: his father had just had a heart attack."
          ],
          [
            1,
            "[03:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter019.html) - three o\x{2019}clock in the morning",
            "There was a hint of this cultural overlay in the composition of the city. The pink-flowered \x{2018}drunken branch\x{2019} trees of the pampas grew in the parks, but the parks were English and Italian, and this told in their names, Britannia Park, Palermo Park. The downtown section was architecturally French, the industrial parts German, the harbour Italian. Only the scale of the city was American; its dimensions, its sense of space, gave it a familiarity. It was a clean city. No one slept in its doorways or parks \x{2013} this, in a South American context, is almost shocking to behold. I found the city safe to walk in at all hours and at <<three o\x{2019}clock in the morning|6>> there were still crowds in the streets. Because of the day-time humidity, groups of boys played football in the floodlit parks until <<well after midnight|13>>. It was a city without significant Indian population \x{2013} few, it seemed, strayed south of Tucuman, and what Indians existed came from Paraguay, or just across the Rio de la Plata in Uruguay. They worked as domestics, they lived in outlying slums, they were given little encouragement to stay."
          ],
          [
            1,
            '[ap 05:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter021.html) - five',
            'It took an hour for the Lakes of the South Express to disentangle itself from the city. We had left at <<five|9c:1>>, on a sunny afternoon, but when we began speeding across the pampas, a cool immense pasture, it was growing dark. Then the afterglow of sunset was gone, and in the half-dark the grass was grey, the trees black; some cattle were as reposeful as boulders and in one field five white cows were as luminous as laundry.'
          ],
          [
            1,
            '[> 11:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter021.html) - Just after eleven',
            "<<Just after eleven that morning|10>> we came to the town of Carmen de Patagones, on the north bank of the Rio Negro. At the other end of the bridge was Viedma. This river I took to be the true dividing line between the fertile part of Argentina and the dusty Patagonian plateau. Hudson begins his book on Patagonia with a description of this river valley, and the inaccuracy of its name was consistent with all the misnamed landscape features I had seen since Mexico. \x{2018}The river was certainly miscalled Cusar-leof\x{fa}, or Black River, by the aborigines,\x{2019} says Hudson, \x{2018}unless the epithet referred only to its swiftness and dangerous character; for it is not black at all in appearance \x{2026} The water, which flows from the Andes across a continent of stone and gravel, is wonderfully pure, in colour a clear sea-green.\x{2019} We remained on the north bank, at a station on the bluff. A lady in a shed was selling stacks of bright red apples, five at a time. She looked like the sort of brisk enterprising woman you see on a fall day in a country town in Vermont \x{2013} her hair in a bun, rosy cheeks, a brown sweater and heavy skirt. I bought some apples and asked if they were Patagonian. Yes, she said, they were grown right here. And then, \x{2018}Isn\x{2019}t it a beautiful day!\x{2019}"
          ],
          [
            1,
            '[01:30] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter021.html) - one-thirty in the morning',
            "It was sunny, with a stiff breeze riffling the Lombardy poplars. We were delayed for about an hour, but I didn\x{2019}t mind. In fact, the longer we were delayed the better, since I was scheduled to get off the train at Jacobacci at the inconvenient hour of <<one-thirty in the morning|5>>. The connecting train to Esquel was not leaving until <<six AM|5>>, so it hardly mattered what time I got to Jacobacci."
          ],
          [
            1,
            '[ap ~ 02:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter021.html) - About two',
            "\x{2018}<<About two|9e>>, tomorrow morning.\x{2019}"
          ],
          [
            1,
            '[ap 05:30] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter021.html) - five-thirty',
            "\x{2018}Wait,\x{2019} he said. \x{2018}The train to Esquel does not leave until <<five-thirty|9c:1>>.\x{2019}"
          ],
          [
            1,
            '[07:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter004.html) - seven in the morning',
            "I had arrived in Veracruz at <<seven in the morning|9a>>, found a hotel in the pretty Plaza Constitucion and gone for a walk. I had absolutely nothing to do: I did not know a soul in Veracruz, and the train to the Guatemalan border was not leaving for two days. Still, this did not seem a bad place. There are few tourist attractions in Veracruz; there is an old fort and, about two miles south, a beach. The guidebooks are circumspect about des-scribing this fairly ugly city: one calls it \x{2018}exuberant\x{2019}, another \x{2018}picturesque\x{2019}. It is a faded seaport, with slums and tacky modernity crowding the quaintly ruined buildings at its heart. Unlike any other Mexican city, it has pavement caf\x{e9}s, where forlorn children beg and marimba players complete the damage to your eardrums that was started on the descent from the heights of Orizaba. Mexicans treat stray children the way other people treat stray cats (Mexicans treat stray cats like vermin), taking them on their laps and buying them ice cream, all the while shouting to be heard over the noise of the marimbas."
          ],
          [
            1,
            "[23:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter004.html) - eleven o\x{2019}clock at night",
            "
\x{2018}Pomp and Circumstance\x{2019}? In Veracruz? At <<eleven o\x{2019}clock at night|6>>?"
          ],
          [
            1,
            '[< 00:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter004.html) - near midnight',
            "But he had boarded the plane and vanished. In nine days of searching, Nicky had not been able to find a trace of him. Perhaps it was the effect of the Dashiell Hammett novel I had just read, but I found myself examining her situation with a detective\x{2019}s scepticism. Nothing could have been more melodramatic, or more like a Bogart film: <<near midnight|13>> in Veracruz, the band playing ironical love songs, the plaza crowded with friendly whores, the woman in the white suit describing the disappearance of her Mexican husband. It is possible that this sort of movie-fantasy, which is available to the solitary traveller, is one of the chief reasons for travel. She had cast herself in the role of leading lady in her search drama, and I gladly played my part. We were far from home: we could be anyone we wished. Travel offers a great occasion to the amateur actor."
          ],
          [
            1,
            '[07:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter016.html) - seven in the morning',
            "The Rimac river flowed past the railway station. At <<seven in the morning|9a>> it was black; it became grey as the sun moved above the foothills of the Andes. The sandy mountains at the city\x{2019}s edge give Lima the feel of a desert city hemmed-in on one side by hot plateaux. It is only a few miles from the Pacific Ocean, but the land is too flat to permit a view of the sea, and there are no sea breezes in the day-time. It seldom rains in Lima. If it did, the huts \x{2013} several thousand of them \x{2013} in the shanty town on the bank of the Rimac would need roofs. The slum is odd in another way; besides being entirely roofless, the huts in this (to use the Peruvian euphemism) \x{2018}young village\x{2019} are woven from straw and split bamboo and cane. They are small frail baskets, open to the stars and sun, and planted beside the river which, some miles from the station, is cocoa-coloured. The people wash in this river water; they drink it and cook with it; and when their dogs die, or there are chickens\x{2019} entrails to be disposed of, the river receives this refuse."
          ],
          [
            1,
            "[ap 04:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter016.html) - four o\x{2019}clock",
            "We entered the valley and zig-zagged on the walls. It was hardly a valley. It was a cut in the rock, a slash so narrow that the diesel\x{2019}s hooter hardly echoed: the walls were too close to sustain an answering sound. We were due at Huancayo at <<four o\x{2019}clock|6>>; by mid-morning I thought we might arrive early, but at <<noon|13>> our progress had been so slow I wondered whether we would get to Huancayo that day. And long before Ticlio I had intimations of altitude sickness. I was not alone; a number of other passengers, some of them Indians, looked distinctly ghastly."
          ],
          [
            1,
            '[06:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter007.html) - six in the morning',
            "


    The Old Patagonian Express







It was a brutal city, but at <<six in the morning|9a>> a froth of fog endowed it with a secrecy and gave it the simplicity of a mountain-top. Before the sun rose to burn it away, the fog dissolved the dull straight lines of its streets, and whitened its low houses and made its sombre people ghostly as they appeared for moments before being lifted away, like revengers glimpsed in their hauntings. Then Guatemala City, such a grim thing, became a tracing, a sketch without substance, and the poor Indians and peasants \x{2013} who had no power \x{2013} looked blue and bold and watchful. They possessed it at this hour. There was no wind; the fog hung in fine grey clouds, a foot from the ground. Even the railway station, no more than a brick shed, took on the character of a great terminus: there was no way of verifying that it did not rise up for five stories in a clock tower crowned by pigeons and iron-work, so well hidden was its small tin roof by the fog the volcanoes had trapped. There were about twenty people standing near the ticket window of the station \x{2013} in rags; but their rags seemed just another deception of the fog."
          ],
          [
            1,
            '[10:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter007.html) - ten in the morning',
            "I did have one fear: that the train would stop, just like that, no warning, no station; that the engine would seize up in the heat and that we would be stuck here. It had happened on what was regarded as a fine railway a hundred miles out of Veracruz, and the Mexicans had no explanation. This railway was clearly much older, the engine more of a gasper. And suppose it does, I thought, suppose it just stops here and can\x{2019}t start? It was <<ten in the morning|9a>>, the open cars were full of people, the train carried no water, there was no road for miles, nor was there any shade. How long did it take to die? I guessed it would not take long in this boundless desert."
          ],
          [
            1,
            '[06:30] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter007.html) - six-thirty in the morning',
            "\x{2018}Yes, there is a train to Metapan in two days \x{2013} on Wednesday. At <<six-thirty in the morning|5>>. Do you want a ticket?\x{2019}"
          ],
          [
            1,
            "[ap > 01:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter012.html) - past one o\x{2019}clock",
            "\x{2018}Golly,\x{2019} he said, looking at his own. \x{2018}It\x{2019}s <<past one o\x{2019}clock|6>>. I don\x{2019}t know about you, but I\x{2019}m real hungry.\x{2019}"
          ],
          [
            1,
            "[ap 10:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter012.html) - ten o\x{2019}clock",
            "I had not been inside an American high school for twenty years; how strange it was that the monkey house from which I had graduated had been reassembled, down to its last brick and home-room bell and swatch of ivy, here in Central America. And I knew in my bones what my reaction would have been at Medford High if it had been announced that, instead of Latin at <<ten o\x{2019}clock|6>>, there would be an assembly: a chance to fart around!"
          ],
          [
            1,
            '[ap 05:15] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter012.html) - 5:15',
            "If I was to stay in Col\x{f3}n I would have to choose between the chaos and violence of the native quarter or the colonial antisepsis of the Zone. I took the easy way out, bought a ticket back to Panama City and boarded the <<5:15|2>>. As soon as we pulled out of the station, the skies darkened and it began to rain. This was the Caribbean: it might rain anytime here. Fifty miles away, on the Pacific, it was the Dry Season; it was not due to rain for six weeks. The Isthmus may be narrow, but the coasts are as distinct as if a great continent lay between them. The rain came down hard and swept across the fields; it blackened the canal and wrinkled it with wind; and it splashed the sides of the coach and ran down the windows. With the first drops the passengers had shut the windows and now we sat perspiring, as if soaked by the downpour."
          ],
          [
            1,
            "[ap 07:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter012.html) - seven o\x{2019}clock",
            "All over the Zone it was Club-going Hour. At the officer\x{2019}s mess and the VFW, the American Legion and the Elks, at the Church of God Servicemen\x{2019}s Center, the Shriners Club, the Masons, the golf clubs, the Star of Eden Lodge No. 9, of the Ancient and Illustrious Star of Bethlehem, the Buffaloes, and the Moose, and at the Lord Kitchener Lodge No. 25, and the Company cafeteria in Balboa the day\x{2019}s work was done and clubby colonials of the Zone were talking. There was only one subject, the treaty. It was <<seven o\x{2019}clock|6>> in the Zone, but the year \x{2013} who could tell? It was not the present. It was the past that mattered to the Zonian; the present was what most Zonians objected to, and they had succeeded so far in stopping the clock, even as they kept the canal running."
          ],
          [
            1,
            '[00:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter012.html) - midnight',
            "At Balboa High some students were waiting for it to grow dark enough so that in stealth they could drive nails again into the locks, and jam them, and prevent school from opening. At <<midnight|9m>> the arts teacher suddenly remembered that she had left a kiln on and was afraid the school would burn down. She phoned the principal and he changed out of his pyjamas and checked. But there was no danger: the kiln had been left unplugged. Nor were the locks successfully jammed. The next day, school opened as usual, and all was well in the Zone. I was asked to stay longer, to go to a party, to discuss the treaty, to see the Indians. But my time was getting short; already it was March, and I had not yet set foot in South America. In a few days, there was a national election in Colombia, \x{2018}and they\x{2019}re expecting trouble,\x{2019} said Miss McKinven at the Embassy. These considerations, as Gulliver wrote, moved me to hasten my departure sooner than I intended."
          ],
          [
            1,
            "[ap > 09:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter005.html) - just after nine o\x{2019}clock",
            "


    The Old Patagonian Express







I had been on the train for twelve hours. There was something wrong with this train; a whole day of travelling and we had gone only a hundred miles or so, mostly through swamps. The heat had made me nauseous, and the noise of the banging doors, the anvil clang of the coupling, had given me a headache. Now it was night, still noisy, but very cold. The coach was open \x{2013} most of the eighty seats were occupied, nearly all the windows were broken, or jammed open. The bulbs on the ceiling were too dim to read by, too bright to allow me to sleep. The rest of the passengers slept, and one across the aisle was snoring loudly. The man behind me who, all day, had sighed and cursed and kicked the back of my seat in exasperation, had made a pillow of his fist and gone to sleep. The spiders and ants I had noticed during the day crawling in and out of the horsehair of the burst cushions had begun biting me. Or was it mosquitoes? My ankles itched and stung. It was <<just after nine o\x{2019}clock|10>>. I held a copy of Pudd\x{2019}nhead Wilson. I had given up trying to read it."
          ],
          [
            1,
            '[ap 01:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter005.html) - one',
            "At <<one|9m>> stop \x{2013} a station, not a breakdown \x{2013} a boy got on and stood at the front of the coach. He sang in a very sweet voice. At first the passengers were embarrassed, but with the second and third songs, they applauded. The boy was encouraged. He sang a fourth. The whistle blew. He walked to the back of the coach, collecting money from the people. What impressed me as much as his voice was his age \x{2013} he was about twenty, old enough to be a cane-cutter or a farm labourer (but farm labourers in Mexico work on average only 135 days a year). This singing seemed an unlikely occupation, but perhaps he only performed when the train passed through his village."
          ],
          [
            1,
            '[ap 01:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter005.html) - one',
            "There were few stops \x{2013} some villages, some settlements that were less than villages. I saw doorways flickering in candlelight and hut interiors whitened by lanterns. At <<one|9m>> doorway the highly erotic sight of a girl or woman, leaning against the jamb, canted forward, her legs apart, her arms upraised, and the light behind her showing the slimness of the body beneath her gauzy dress \x{2013} this lovely shape in a lighted rectangle surrounded by the featureless Mexican night. It left me flustered and a bit anxious."
          ],
          [
            1,
            '[ap 01:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter005.html) - one',
            "At <<one|9m>> town, a boy leaned out of the train and called to a girl selling corn. He said, \x{2018}Where are we?\x{2019}"
          ],
          [
            1,
            '[06:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter005.html) - six',
            'At <<six that morning|9a>>, I blinked at my watch. The lights in the car had fused: it was pitch dark. Moments later, it was dawn. No bulb of sun, but a seepage of light that dissolved the darkness and rose on all sides bringing a bluer ozone-scented softness to a sky which became gigantic. With it was a warm buoyancy of air, and scale was restored to the landscape, and the car was sweetened with the odour of desert dew. I had never seen dawn break so swiftly, but I had never slept that way. The windows were open, there were no shades: it was like sleeping on a park bench.'
          ],
          [
            1,
            "[ap 11:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter005.html) - eleven o\x{2019}clock",
            "The mountain range \x{2013} now like a fortress, now like a cathedral (it was yet another protectively maternal strip of the Sierra Madre) \x{2013} stayed with us the whole day. But we never climbed it. We moved south along the hot lowland, and the more southerly we penetrated the more primitive and tiny became the Indian villages, the more emblematic the people: naked child, woman with basket, man on horseback, posed in the shattering sunlight before a poor mud hut. As the morning wore on the people withdrew and by <<eleven o\x{2019}clock|6>> we were watched from the windows of huts which had grown much smaller. Shade was scarce: skinny village dogs slept under the bellies of cows which were themselves transfixed by hanks of course grass."
          ],
          [
            1,
            '[> 00:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter022.html) - just after midnight',
            '


    The Old Patagonian Express







It was not necessary for Otto to wake me up; the dust did that. It filled my compartment, and as the Lakes of the South Express hurried across the plateau where it seldom rains (what good were leakproof shoes here?), the dust was raised, and our speed forced it through the rattling windows and the jiggling door. I woke feeling suffocated and made a face mask of my bed sheet in order to breathe. When I opened the door a cloud of dust blew against me. It was no ordinary dust storm, more like a disaster in a mine shaft: the noise of the train, the darkness, the dust, the cold. There was no danger of my sleeping through Ingeniero Jacobacci. I was fully awake <<just after midnight|10>>. I gritted my teeth and sand grains crunched in my molars.'
          ],
          [
            1,
            '[02:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter022.html) - two in the morning',
            "That express train \x{2013} and how I yearned to be back on it \x{2013} had blurred distance and altitude. The statistics were given at Jacobacci. We were over a thousand miles from Buenos Aires, and since Carmen de Patagones, which was at sea-level, we had climbed to over 3,000 feet, on a plateau that did not descend again until the Straits of Magellan. In this wind, at this altitude, at this time of night \x{2013} <<two in the morning|5>> \x{2013} it was very cold in Jacobacci. No one stops at Jacobacci, people had said. I could disprove that. Passengers had got off the train. I assumed that, like me, they would be waiting for the train to Esquel. I looked around for them. They were gone."
          ],
          [
            1,
            '[< 03:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter022.html) - nearly three in the morning',
            'If only he had said, Want to hear something strange? He was old enough to know a good story. But he was half asleep, and it was cold, and <<nearly three in the morning|9h>>. So I left him alone and went outside. I walked up the tracks, away from the lights of the station. The wind in the thorn bushes rasped like sand in a chute. The air smelled of dust. The moon on the bushes shone blue across the bumpy monotony of Patagonia.'
          ],
          [
            1,
            '[ap 05:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter022.html) - five',
            'I had arrived at Ingeniero Jacobacci in darkness. It was still dark when I boarded the train. The station master gave me more tea and said I could get into the coach. It was as small as I had been warned it would be, and it was filled with dust that had blown through the windows. But at least I had a seat. At <<five|9e>>, people started to gather. Incredibly, at this hour, they were seeing friends and family off. I had noticed this custom all over Bolivia and Argentina, this send-off, lots of kisses, hugs, and waves, and at the larger stations weeping men parting from their wives and children. I found it touching, and at odds with their ridiculously masculine self-appraisal.'
          ],
          [
            1,
            '[ap < 06:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter022.html) - just before six',
            "There was a whistle, a steam-whistle \x{2013} a shrill fluting pipe. The station bell was rung. Well-wishers scrambled from the train, passengers boarded; and, <<just before six|10>>, we were off."
          ],
          [
            1,
            '[ap 08:30] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter022.html) - 8.30',
            "We were. The hills and dales of Patagonia which I had welcomed for their variation and their undeniable beauty were the cause of our slow progress. On a straight track this trip would not have taken more than three hours, but we were not due to arrive in Esquel until <<8.30|5a:1>> \x{2013} nearly a fourteen-hour ride. The hills were not so much hills as they were failed souffl\x{e9}s."
          ],
          [
            1,
            "[ap > 08:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter022.html) - after eight o\x{2019}clock",
            "It was <<after eight o\x{2019}clock|6>> when I saw the lights. I looked for more. There were no more. There was nothing to these places, I thought, until you were on top of them. I did not know at that moment that we were on top of Esquel. I had expected more \x{2013} an oasis, perhaps taller poplars, the sight of a few friendly bars, a crowded restaurant, a flood-lit church, anything to signify my arrival. Or less: like one of the tiny stations along the line; like Jacobacci, a few sheds, a few dogs, a bell. The train emptied quickly."
          ],
          [
            1,
            "[ap 09:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter013.html) - nine o\x{2019}clock",
            "At <<nine o\x{2019}clock|6>>, or just after, we passed Aracataca. The novelist Gabriel Garcia Marquez was born here; this was the Macondo of Leaf-Storm and One Hundred Years of Solitude. In the light of fires and lanterns I could see mud huts, the silhouettes of palms and banana trees, and glow-worms in the tall grass. It was not late, but there were few people awake; glassy-eyed youths who had stayed up watched the train go by. \x{2018}It\x{2019}s coming,\x{2019} says a woman in Marquez\x{2019}s Macondo, when she sees the first train approach the little town. \x{2018}Something frightful, like a kitchen dragging a village behind it.\x{2019}"
          ],
          [
            1,
            '[00:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter013.html) - midnight',
            "I made myself a baloney sandwich, drank two of the beers I had bought in Santa Marta and went to sleep. The noise, the rhythm of the clicking on the rails, was a soporific; it was silence and a stillness in the car that woke me. At <<midnight|9e>>, I came awake: the train had stopped. I did not know where we were, but it must have been a fairly large place because most of the people in the car \x{2013} including the man next to me \x{2013} got off. But an equal number boarded here, so we were no less crowded. Children woke and cried, and people pushed and fought for the empty seats. An Indian girl sat next to me; her plump profile, outlined by the station lights, was unmistakable. She wore a baseball cap and a jersey and slacks, and her luggage was three cardboard boxes and an empty oil-drum. When the train started, she snuggled up to me and went to sleep. My shirt was damp with sweat, but the humid breeze was no help; and I knew we would not be out of this swamp until late the next day. I fell asleep, but when I woke again at another lonely station \x{2013} a low building, a man, a lantern \x{2013} I saw that the girl had moved across the aisle and was snuggling against a murmuring man."
          ],
          [
            1,
            '[ap 05:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter013.html) - Five',
            "\x{2018}Five months I have been travelling! <<Five|9k:0>>. I left Paris in October. I spent one month in New York City.\x{2019}"
          ],
          [
            1,
            '[ap 01:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter013.html) - one',
            "At <<one|9m>> town there was a bar; it was called \x{2018}The Blue Danube\x{2019} in Spanish, this bar near the much-mightier Magdalena. Outside it was a hitching post, with three saddled horses tied to it; the riders were at the window, drinking beer. It was an appropriate wild-west scene in this poor empty land, the settlers\x{2019} shacks and the pig-pens and the rumours of emeralds. It was no better in the train. The passengers were either asleep or sitting silently, traumatized by the heat. Half of them were flat-faced Indians in shawls or felt hats."
          ],
          [
            1,
            '[12:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter011.html) - noon',
            "Nor is the landscape remarkable enough to intrude. Costa Rica\x{2019}s south-west is very different from the north-east. The land seems to slope away to the Pacific coast, from the coffee bushes in the high suburbs, to areas of light industry, the cement factories and timber yards that supply material for the country\x{2019}s growth. By the time we left these industrial suburbs it was not yet <<noon|13>>; but it was lunch-time, not only for the factory hands, but for office workers and managers too. Costa Rica has a large middle-class, but they go to bed early and rise at dawn; everyone \x{2013} student, labourer, businessman, estate manager, politician \x{2013} keeps farmer\x{2019}s hours."
          ],
          [
            1,
            '[ap ~ 11:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter011.html) - about eleven',
            "There was more. A young girl, <<about eleven|9:0>> \x{2013} perhaps another daughter \x{2013} rushed forward with a bottle of Coke. She shook the bottle and sprayed foam into the boy\x{2019}s face. Still, the two girls said nothing. The boy pulled a hanky out of his pocket and, wiping his face, made a pleading explanation: \x{2018}They said the seat was not occupied \x{2026} they said I could sit down \x{2026} ask them, go ahead, they\x{2019}ll tell you \x{2026}\x{2019}"
          ],
          [
            1,
            '[< 00:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter010.html) - nearly midnight',
            "He wanted to take me to what he said was the only good brothel in San Jos\x{e9}. It was too late, I said, <<nearly midnight|13>>. He said <<midnight|13>> was the best time \x{2013} the hookers were just waking up. \x{2018}How about tomorrow?\x{2019} I said, knowing that tomorrow I would be in Lim\x{f3}n. \x{2018}You\x{2019}re a chicken,\x{2019} he said, and I could hear him laughing as I descended the stairs to the street."
          ],
          [
            1,
            '[12:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter010.html) - noon',
            "A Lim\x{f3}n train leaves the Atlantic station every day at <<noon|13>>. It is not a great train, but by Central American standards it is the Brighton Belle. There are five passenger coaches, two classes, no freight cars. I had been eager to take this train, for the route has the reputation of being one of the most beautiful in the world, from the temperate capital in the mountains, through the deep valleys on the north-east, to the tropical coast which, because of its richly lush jungle, Columbus named Costa Rica when he touched there on his fourth voyage in 1502. He believed that he had arrived at the green splendour of Asia. (Columbus tacked up and down the coast and was ill for four months in Panama; cruelly, no one told him that there was another vast ocean on the other side of the mountains \x{2013} the local Indians were deaf to his appeal for this information.)"
          ],
          [
            1,
            '[< 00:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter010.html) - towards midnight',
            "The most scenic of Central American routes; but I had another good reason for wanting to take this train out of San Jos\x{e9}. Since arriving in Costa Rica I had spent much of my time in the company of hard-drinking American refugees \x{2013} Andy Ruggles and the diabolical Dibbs were but two. I was glad of their company; El Salvador hadn\x{2019}t been much fun. But now I was ready to set off alone. Travel is at its best a solitary enterprise: to see, to examine, to assess, you have to be alone and unencumbered. Other people can mislead you; they crowd your meandering impressions with their own; if they are companionable they obstruct your view, and if they are boring they corrupt the silence with non-sequiturs, shattering your concentration with Oh, look, it\x{2019}s raining and You see a lot of trees here. Travelling on your own can be terribly lonely (and it is not understood by Japanese who, coming across you smiling wistfully at an acre of Mexican buttercups, tend to say things like Where is the rest of your team?). I think of evening in the hotel room in the strange city; my diary has been brought up to date; I hanker for company: what do I do? I don\x{2019}t know anyone here, so I go out and walk and discover the three streets of the town and rather envy the strolling couples and the people with children. The museums and churches are closed, and <<towards midnight|13>> the streets are empty. Don\x{2019}t carry anything valuable, I was warned; it\x{2019}ll just get stolen. If I am mugged I will have to apologize in my politest Spanish: I am sorry, sir, but I have nothing valuable on my person. Is there a surer way of enraging a thief and driving him to violence? Walking these dark streets is dangerous, but the bars are open. Ruggles and Dibbs await. They take the curse off my boredom, but I have a nagging suspicion that if I had stayed home and lingered in downtown Boston until <<midnight|13>> I would have met Ruggles and Dibbs in the <<Two O\x{2019}Clock|6>> Lounge (\x{2018}20 Completely Nude College Girls!!!\x{2019}). I did not have to take the train to Costa Rica for that."
          ],
          [
            1,
            '[ap 06:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter010.html) - six',
            "He had missed his tour. It would have been all-inclusive, the train to Lim\x{f3}n, a boat-trip up the coast, a chef travelling with the party, some wonderful meals. He would have seen monkeys and parrots. Back to Lim\x{f3}n: some swimming, a four-star hotel, then a bus to the airport and a plane to San Jos\x{e9}. That was the tour. But (the river was dashing an old canoe to pieces, and those little boys \x{2013} surely they were fishing?) the hotel manager had gotten the time wrong and the tour had left at <<six|9c:1>>, not nine, so on the spur of the moment, and with nothing else to do in San Jos\x{e9}, the old man asked about the train and hopped on, just like that, and you never knew, maybe he\x{2019}d catch up with the rest of them; after all, he had paid his three hundred dollars and here was his receipt and his booklet of coupons."
          ],
          [
            1,
            '[ap > 03:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter010.html) - After three',
            "I walked to savour my freedom and stretch my legs. <<After three|9:0>> blocks the town didn\x{2019}t look any better, and wasn\x{2019}t that a rat nibbling near the tipped-over barrel of scraps? It\x{2019}s a white country, a man had told me in San Jos\x{e9}. But this was a black town, a beach-head of steaming trees and sea-stinks. I tried several hotels. They were wormy staircases with sweating people minding tables on the second-floor landings. No, they said, they had no rooms. And I was glad, because they looked so disgustingly dirty and the people were so rude; so I walked a few more blocks. I\x{2019}d find a better hotel. But they were smaller and smellier, and they too were full. At <<one|9e>>, as I stood panting \x{2013} the staircase had left me breathless \x{2013} a pair of cockroaches scuttled down the wall and hurried unimpeded across the floor. Cockroaches, I said. The man said, What do you want here? He too was full. I had been stopping at every second hotel. Now I stopped at each one. They were not hotels. They were nests of foul bedclothes, a few rooms and a portion of verandah. I should have known they were full: I met harassed families making their way down the stairs, the women and children carrying suitcases, the father sucking his teeth in dismay and muttering, \x{2018}We\x{2019}ll have to look somewhere else.\x{2019} It was necessary for me to back down the narrow stairs to let these families pass."
          ],
          [
            1,
            "[ap 09:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter010.html) - Nine o\x{2019}clock",
            "\x{2018}I\x{2019}m sick of thinking about it.\x{2019} He looked at his watch. \x{2018}<<Nine o\x{2019}clock|6>>. I\x{2019}m bushed. Shall we call it a day?\x{2019}"
          ],
          [
            1,
            "[ap 09:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter010.html) - nine o\x{2019}clock",
            "I said, \x{2018}I don\x{2019}t normally go to bed at <<nine o\x{2019}clock|6>>.\x{2019}"
          ],
          [
            1,
            '[ap 01:30] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter010.html) - one-thirty',
            "We reached the lagoon at <<one-thirty|5b>>, and moored the boat there because the black pilot feared that the tides at the estuary might drag us into the sea. We walked to the beach of grey lava. I swam. The black pilot screamed in Spanish for me to leave the water. There were sharks in the water, he said \x{2013} the hungriest, the fiercest of sharks. I asked him whether he had seen any sharks. No, he said, but he knew they were there. I plunged back into the water."
          ],
          [
            1,
            '[05:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter010.html) - five',
            "The train had left, too, at <<five that morning|9a>>. I said, \x{2018}We can take a taxi.\x{2019}"
          ],
          [
            1,
            '[ap 07:30] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter020.html) - seven-thirty',
            "\x{2018}Come tomorrow night,\x{2019} said Borges. \x{2018}Come at <<seven-thirty|5b>>. You can read me some chapters of Pym and then we\x{2019}ll have dinner.\x{2019}"
          ],
          [
            1,
            '[ap 09:30] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter020.html) - Nine-thirty',
            "\x{2018}How sad that is,\x{2019} said Borges. \x{2018}It is terrible. The man can do nothing. But notice how Kipling repeats the same lines. It has no plot at all, but it is lovely.\x{2019} He touched \x{2018}his suit jacket. \x{2018}What time is it?\x{2019} He drew out his pocket watch and touched the hands. \x{2018}<<Nine-thirty|5a:1>> \x{2013} we should eat.\x{2019}"
          ],
          [
            1,
            '[04:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter017.html) - 4:00 AM',
            "


    The Old Patagonian Express







Peru is the poorest country in South America. Peru is also the country most visited by tourists. The two facts are related; even the dimmest tourist can count in Spanish \x{2013} low numbers especially trip off his tongue \x{2013} and he knows that Peru\x{2019}s gigantic ruins and threadbare currency are a bargain. The student I had met in Huancayo was right: there were some Quechua Indians on the plane to Cuzco, but the others were all tourists. They had arrived in Lima the day before and had been whisked around the city. In their hotel was a schedule: \x{2018}<<4:00 AM|2a>> \x{2013} Wake-Up Call! <<4:45 AM|2a>> \x{2013} Luggage in Corridor! <<5:00|2>> \x{2013} Breakfast! <<5:30|2>> \x{2013} Meet in Lobby!\x{2026}\x{2019} At <<eight in the morning|9a>>, some men with shaving cream still stuck to their earlobes, they arrived in Cuzco and fought their way past the Indians (who carried tin pots and greasy bundles of food and lanterns, much as they had on the train) to a waiting bus, congratulating themselves on the cheapness of the place. They are unaware that it is almost axiomatic that air travel has wished tourists on only the most moth-eaten countries in the world: tourism, never more energetically pursued than in static societies, is usually the mobile rich making a blind blundering visitation on the inert poor."
          ],
          [
            1,
            '[04:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter017.html) - four in the morning',
            "The visitors wore badges, Samba South America; the badges also served as name-tags. At this early hour in the thin grey air and high altitude drizzle, the haggard faces did not match the tittupping names: Hildy Wicker, Bert and Elvera Howie, Charles P. Clapp, Morrie Upbraid, the Prells, the Goodchucks, Bernie Khoosh, the Avatarians, Jack Hammerman, Nick and Lurleen Poznan, Harold and Winnie Casey, the Lewgards, Wally Clemons, and little old Merry Mackworth. They were a certain age; they had humps and braces and wooden legs and two walked with crutches \x{2013} amazing to see this performance in the high Andes \x{2013} and none looked well. What with the heat in Lima and the cold here, the delays, the shuffling up and down stairs \x{2013} and they had yet to climb the vertical Inca staircases (\x{2018}I don\x{2019}t know which is worse, going up or going down\x{2019}) \x{2013} they were suffering. You had to admire them, because in two days they would be on the same plane flying back to Lima, waking again at <<four in the morning|9a>>, and that day arriving in another godawful place like Guayaquil or Cali."
          ],
          [
            1,
            'The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter017.html) - one',
            "Off they went, the three Mexicans. I entered the bar, and I understood their hurry. The bar was almost underground; it had a low ceiling and was lighted by six sooty lanterns. In this lantern light I could see ragged Indians, grinning drunkenly and guzzling maize beer from dented tankards. The bar was shaped like a trough. At one end an old man and a very small boy were playing stringed instruments; the boy was singing sweetly in Quechua. At the other end of the trough, a fat Indian woman was frying meat over a log fire \x{2013} the smoke circled in the room. She cooked with her hands, throwing the meat in, turning it with her hands, picking it up to examine it, then taking a cooked hunk in each hand and carrying it to a plate. An infant crawled near the fire; it was nearly naked, not more than six months old, and like a soft toy. I had had my look, but before I could leave I noticed three men beckoning to me."
          ],
          [
            1,
            "[ap 04:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter017.html) - four o\x{2019}clock",
            "
At <<four o\x{2019}clock|6>> every weekday morning the Cuzco church bells ring. They ring again at <<4:15|2>> and <<4:30|2>>. Because there are so many churches, and the valley is walled-in by mountains, the tolling of church bells, from <<four to five in the morning|10>>, has a celebratory sound. They summon all people to mass, but only Indians respond. They flock to <<five o\x{2019}clock|6>> mass in the Cathedral, and <<just before six|10>> the great doors of the Cathedral open on the cold cloudy mountain dawn and hundreds of Indians pour into the plaza, so many of them in bright red ponchos that the visual effect is of a fiesta about to begin. They look happy; they have performed a sacrament. All Catholics leave mass feeling light-hearted, and though these Indians are habitually dour \x{2013} their faces wrinkled into frowns \x{2013} at this early hour after mass most of them are smiling."
          ],
          [
            1,
            '[ap 06:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter017.html) - six',
            "The tourists wake with the Indians, but the tourists head for Santa Ana Station to catch the train to Machu Picchu. They carry packed lunches, umbrellas, raincoats and cameras. They are disgusted, and they have every right to be so. They were led to believe that if they got to the station at <<six|9c:1>>, they would have a seat on the <<seven o\x{2019}clock|6>> train. But now it was <<seven|9f>> and the station doors had not opened. A light rain had started and the crowd of tourists numbered two hundred or more. There is no order at the station."
          ],
          [
            1,
            '[19:11] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter017.html) - 1911',
            "Ahead, through a black gateway of pinnacles, was a wide flat valley filled with sunlight; birds were slanted in the sky and on ledges like the diacritical marks on vowels, and there were green streaks, wind-flattened bushes, on the steep mountains beyond. In the centre of the valley, coursing beside fuchsias and white orchids, was a turbulent brown river. This was the Vilcanota River, running north to Machu Picchu, where it becomes the Urubamba and continues north-east to join a tributary of the Amazon. The river flowed from Sicuani, past the glaciers above the crumbling town of Pisaq, and here, where our train was tooting, had formed the Sacred Valley of the Incas. The shape of this valley \x{2013} so flat and green and hidden \x{2013} in such a towering place, had attracted the Incas. Many had been here before the Spaniards entered Cuzco, and here others fled, fighting a rearguard action after Cuzco fell. The valley became an Inca stronghold, and long after the Spaniards believed they had wiped out or subdued this pious and highly civilized empire, the Incas continued to live on in the fastnesses of these canyons. In 1570, a pair of Augustinian missionaries \x{2013} the friars Marcos and Diego \x{2013} had the fanatical faith to take them over the mountains and through this valley. The friars led a motley band of Indian converts who carried torches and set fire to the shrines at which Incas were still worshipping. Their triumph was at Chuquipalta, near Vitcos, where for the greater glory of God (the Devil had made appearances here, so the Incas said) they put their torches to the House of the Sun. Some missions were established along the river (Marcos eventually suffered a horrendous martyrdom), but farther on, where the mountains and sky seemed scarcely distinguishable, the ruins were not re-entered. The valleys slept. They were not penetrated again until <<1911|9c:1>>, when the Yale man, Hiram Bingham, with the words of Kipling\x{2019}s \x{2018}Explorer\x{2019} running through his head (\x{2018}Something hidden. Go and find it. Go and look behind the Ranges \x{2013} / Something lost behind the ranges. Lost and waiting for you. Go!\x{2019}) found the vast mountain-top city he named Machu Picchu. He believed he had found the lost city of the Incas, but John Hemming writes in The Conquest of the Incas that an even more remote place to the west, Espiritu Pampa, has the greater claim to the title."
          ],
          [
            1,
            '[ap 01:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter018.html) - one',
            "\x{2018}Only <<one|9k:0>>?\x{2019} I asked."
          ],
          [
            1,
            '[~ 00:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter018.html) - about midnight',
            "While we were eating, I got a severe stomach cramp. I excused myself and went back to my compartment. The train had stopped. This was Oruro, a fairly large city, mostly Indian, near Lake Uru Uru. The rain had intensified; it beat against the window in a torrent made silver by the arc-lamps of the station. I got into bed and turned off the light and curled up to ease my cramp. I woke at <<about midnight|13>>. It was very cold in the compartment and so dusty \x{2013} the dust seemed an effect of the train\x{2019}s rapid motion \x{2013} I could barely breathe. I tried the lights, but they didn\x{2019}t work. I struggled to open the door \x{2013} it seemed locked from the outside. I was choking, freezing and doubled up with stomach pains. I had no choice but to remain calm. I took four swigs of my stomach cement, and then buried my face in my blanket and waited for the morphine to work."
          ],
          [
            1,
            '[> 00:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter018.html) - past midnight',
            'We were taken across the border to the Argentine station over the hill. Then the sleeping car was detached and we were again left on a siding. Three hours passed. There was no food at the station, but I found an Indian woman who was watching a teapot boil over a fire. She was surprised that I should ask her to sell me a cup, and she took the money with elaborate grace. It was <<past midnight|9f>>, and at the station there were people huddled in blankets and sitting on their luggage and holding children in their arms. Now it started to rain, but just as I began to be exasperated I remembered that these people were the Second Class passengers, and it was their cruel fate to have to sit at the dead centre of this continent waiting for the train to arrive. I was much luckier than they. I had a berth and a First Class ticket. And there was nothing to be done about the delay.'
          ],
          [
            1,
            '[06:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter018.html) - six in the morning',
            'I slept for twelve hours. I woke again at <<six in the morning|9a>>, and saw that we had come to a station. There were three poplars outside the window. In the early afternoon I woke again. The three poplars were still outside the window. We had not moved.'
          ],
          [
            1,
            '[ap 09:15] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/preface003.html) - nine-fifteen',
            "
\x{2018}Romance!\x{2019} the season-tickets mourn,

\x{a0}\x{a0} \x{a0} \x{2018}He never ran to catch his train,

But passed with coach and guard and horn \x{2013}

\x{a0}\x{a0} \x{a0} \x{2018}And left the local \x{2013} late again!\x{2019}

Confound Romance \x{2026} And all unseen

Romance brought up the <<nine-fifteen|5a:1>>."
          ],
          [
            1,
            '[ap 04:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter008.html) - Four',
            "Hog, sow, piglet, swine. I said, \x{2018}<<Four|9k:0>>.\x{2019}"
          ],
          [
            1,
            '[ap 04:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter008.html) - Four',
            "Puppy, mutt, mongrel, cur. \x{2018}<<Four|9k:0>>,\x{2019} I said. \x{2018}That is more than you have.\x{2019}"
          ],
          [
            1,
            '[ap ~ 03:30] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter008.html) - about three-thirty',
            'At <<about three-thirty|5a:0>> we came to the town of Quetzaltepeque. Seeing a church, Mario and Alfredo made the sign of the cross. The women in the railcar did the same. Some men removed their hats as well.'
          ],
          [
            1,
            "[ap 09:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter008.html) - nine o\x{2019}clock",
            "The San Salvador railway station was at the end of a torn-up section of road in a grim precinct of the city. My ticket was collected by a man in a pork-pie hat and sports shirt, who wore an old-fashioned revolver on his hip. The station was no more than a series of cargo sheds, where very poor people were camped, waiting for the morning train to Cutuco: the elderly and the very young \x{2013} it seemed to be the pattern of victims in Central American poverty. Alfredo had given me the name of a hotel and said he would meet me there an hour before kick-off, which was <<nine o\x{2019}clock|6>>. The games were played late, he said, because by then it wasn\x{2019}t so hot. But it was now after dark and the humid heat was choking me. I began to wish that I had not left Santa Ana. San Salvador, prone to earthquakes, was not a pretty place; it sprawled, it was noisy, its buildings were charmless, and in the glare of headlights were buoyant particles of dust. Why would anyone come here? \x{2018}Don\x{2019}t knock it,\x{2019} an American in San Salvador told me. \x{2018}You haven\x{2019}t seen Nicaragua yet!\x{2019}"
          ],
          [
            1,
            '[< 00:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter008.html) - towards midnight',
            "In all, five balls were lost this way. The fourth landed not far from where I sat, and I could see that real punches were being thrown, real blood spurting from Salvadorean noses, and the broken bottles and the struggle for the ball made it a contest all its own, more savage than the one on the field, played out with the kind of mindless ferocity you read about in books on gory medieval sports. The announcer\x{2019}s warning was merely ritual threat; the police did not intervene \x{2013} they stayed on the field and let the spectators settle their own scores. The players grew bored: they ran in place, they did push-ups. When play resumed and Mexico gained possession of the ball it deftly moved down the field and invariably made a goal. But this play, these goals \x{2013} they were no more than interludes in a much bloodier sport which, <<towards midnight|13>> (and the game was still not over!), was varied by Suns throwing firecrackers at each other and onto the field."
          ],
          [
            1,
            '[ap 00:54] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter008.html) - six to one',
            "Mexico won the game, <<six to one|10a:0>>. Alfredo said that El Salvador\x{2019}s goal was the best one of the game, a header from thirty yards. So he managed to rescue a shred of pride. But people had been leaving all through the second half, and the rest hardly seemed to notice or to care that the game had ended. Just before we left the stadium I looked up at the ant-hill. It was a hill once again; there were no people on it, and depopulated, it seemed very small."
          ],
          [
            1,
            '[> 00:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter008.html) - after midnight',
            "Outside, on the stadium slopes, the scene was like one of those lurid murals of Hell you see in Latin American churches. The colour was infernal, yellow dust sifted and whirled among crater-like pits, small cars with demonic headlights moved slowly from hole to hole like mechanical devils. And where, on the mural, you see the sins printed and dramatized, the gold lettering saying Lust, Anger, Avarice, Drunkenness, Gluttony, Theft, Pride, Jealousy, Usury, Gambling, and so on, here <<after midnight|9b>> were groups of boys lewdly snatching at girls, and knots of people fighting, counting the money they had won, staggering and swigging from bottles, shrieking obscenities against Mexico, thumping the hoods of cars or duelling with the branches they had yanked from trees and the radio aerials they had twisted from cars. They trampled the dust and howled. The car horns were like harsh moos of pain \x{2013} and one car was being overturned by a gang of shirtless, sweating youths. Many people were running to get free of the mob, holding handkerchiefs over their faces. But there were tens of thousands of people here, and animals, too, maimed dogs snarling and cowering as in a classic vision of Hell. And it was hot: dark grimy air that was hard to breathe, and freighted with the stinks of sweat; it was so thick it muted the light. It tasted of stale fire and ashes. The mob did not disperse; it was too angry to go home, too insulted by defeat to ignore its hurt. It was loud and it moved as if thwarted and pushed; it danced madly in what seemed a deep hole."
          ],
          [
            1,
            '[00:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter014.html) - midnight',
            'Armenia, Antioquia, and not far away the town of Circasia. The names were Asiatic and baffling, but I was too tired to wonder at them. The bus rumbled through town, and though it was dark I saw a large hotel in the middle of a block. I asked the driver to stop, then walked back to that hotel and checked in. I thought that working on my diary until <<midnight|13>> would put me to sleep, but the altitude and the cold made me wakeful. I decided to go for a walk and see a bit of Armenia.'
          ],
          [
            1,
            '[> 00:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter014.html) - past midnight',
            "It was <<past midnight|9f>>, but their replies were prompt; their intelligence was obvious and, for moments, it was possible to forget that they were small children. They were street-wise and as alert as adults; but there was nothing in this doorway they inhabited but that piece of cardboard. I had seen children begging in India, the mechanical request for a rupee, the rehearsed story; they were as poor and as lost. But the Indian beggar is unapproachable; he is fearful and cringing, and there is the language barrier. My Spanish was adequate for me to inquire about the lives of these little boys and every reply broke my heart. Though they spoke about themselves with an air of independence, they could not know how they looked, so sad and waif-like. What hope could they possibly have, living outside on this street? Of course, they would die; and anyone who used their small corpses to illustrate his outrage would be accused of having Bolshevik sympathies. This was a democracy, was it not? The election was last week; and there was no shortage of Colombians in Bogot\x{e1} to tell me what a rich and pleasant country this was if you were careful and steered clear of muggers and gamins. What utter crap that was, and how monstrous that children should be killed this way."
          ],
          [
            1,
            '[06:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter014.html) - six in the morning',
            "There were thieves, people told me, at the railway stations, at the bus stations, in the markets, the parks, on the hill paths, on the back streets, on the main streets. When I asked directions to a particular part of town, no directions were given. \x{2018}Do not go,\x{2019} they said. On the Expreso de Sol, I was told Bogot\x{e1} was dangerous. In Bogot\x{e1} I said I was going to Armenia. \x{2018}Do not go \x{2013} it is dangerous.\x{2019} The railway station? \x{2018}Dangerous.\x{2019} But the train was leaving at <<six in the morning|9a>>. \x{2018}That is the worst time \x{2013} the thieves will rob you in the dark.\x{2019} How, then, should I get to Cali? \x{2018}Do not go to Cali \x{2013} Cali is more dangerous than Armenia.\x{2019}"
          ],
          [
            1,
            "[ap 04:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter014.html) - four o\x{2019}clock",
            "After forty miles the hills became wilder still, and at sixty the climate had changed utterly. Now the hills were brown and over-grazed, and all the landscape sun-scorched, and no green thing anywhere. The bald hills, stripped of all foliage, were rounded on their slopes and had little wave-like shapes beating across them. It was a brown sea of hills, as if a tide of mud had been agitated and left to dry in plump peaks; this was the moment before they crumbled into cakes and dunes and dust slides. Glimmering beyond them was pastel flatness of diluted green \x{2013} the cane fields which lie between the two cordilleras. From here to Cali, the cane fields widened, and at level crossings there were cane-cutters standing \x{2013} there were too many of them to sit down \x{2013} on the backs of articulated trucks, like convict labour. They had been up before dawn. It was <<four o\x{2019}clock|6>>, and they were being taken home, through the fields they had cleared"
          ],
          [
            1,
            '[00:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter003.html) - midnight',
            "We had left Nuevo Laredo at twilight. The few stations we stopped at later in the evening were so poorly lighted I could not make out their names on the signboards. I stayed up late reading The Thin Man, which I had put aside in Texas. I had lost the plot entirely, but the drinking still interested me. All the characters drank \x{2013} they met for cocktails, they conspired in speakeasies, they talked about drinking, and they were often drunk. Nick Charles, Hammett\x{2019}s detective, drank the most. He complained about his hangovers, and then drank to cure his hangover. He drank before breakfast, and all day, and the last thing he did at night was have a drink. One morning he feels especially rotten; he says complainingly, \x{2018}I must have gone to bed sober,\x{2019} and then pours himself a stiff drink. The drinking distracted me from the clues in the way President Banda\x{2019}s facial tic prevented me from ever hearing anything he said. But why so much alcohol in this whodunnit? Because it was set \x{2013} and written \x{2013} during Prohibition. Evelyn Waugh once commented that the reason Brideshead Revisited had so many sumptuous meals in it was because it was written during a period of war-time rationing, when the talk was of all the wonderful things you could do with soya beans. By <<midnight|9e>>, I had finished The Thin Man and a bottle of tequila."
          ],
          [
            1,
            '[< 12:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter003.html) - towards noon',
            "Back in Texas, with a sweep of his hand, taking in Main Street and the new shopping centre and a score of finance companies, the Texan says, \x{2018}All this was nothing but desert a few years ago.\x{2019} The Mexican pursues a different line. He urges you to ignore the squalor of the present and reflect on the glories of the past. As we entered San Luis Potosi <<towards noon|13>> on the day that had started cold and was now cloudless in a parching heat, I noticed the naked children and the lamed dogs and the settlement in the train-yard, which was fifty boxcars. By curtaining the door with faded laundry, and adding a chicken coop and children, and turning up the volume on his radio, the Mexican makes a bungalow of his boxcar and pretends it is home. It is a frightful slum, and stinks of excrement, but the Mexican man standing at the door of the Aztec Eagle with me was smiling. \x{2018}Many years ago,\x{2019} he said, \x{2018}this was a silver mine.\x{2019}"
          ],
          [
            1,
            '[< 12:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter001.html) - towards noon',
            'It was <<towards noon|13>> on March 1, 1898, that I first found myself entering the narrow and somewhat dangerous harbour of Mombasa, on the east coast of Africa. (The Man-Eaters of Tsavo, by Lt Col J. H. Patterson)'
          ],
          [
            1,
            '[00:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter001.html) - midnight',
            "There was snow and ice outside. Each street-light illuminated its own post and, just in front, a round patch of snow \x{2013} nothing more. At <<midnight|9e>>, watching from my compartment, I saw a white house on a hill. In every window of this house there was a lighted lamp, and these bright windows seemed to enlarge the house and at the same time betray its emptiness."
          ],
          [
            1,
            '[ap 02:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter001.html) - two',
            "At <<two|9a>> the next morning we passed Syracuse. I was asleep or I would have been assailed by memories. But the city\x{2019}s name on the Amtrak timetable at breakfast brought forth Syracuse\x{2019}s relentless rain, a chance meeting at the Orange Bar with the by then derelict poet Delmore Schwartz, the classroom (it was Peace Corps training, I was learning Chinyanja) in which I heard the news of Kennedy\x{2019}s assassination, and the troubling recollection of a lady anthropologist who, unpersuaded by my ardour, had later \x{2013} though not as a consequence of this \x{2013} met a violent death when a tree toppled onto her car in a western state and killed her and her lover, a lady gym teacher with whom she had formed a Sapphic attachment."
          ],
          [
            1,
            '[ap 04:30] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter001.html) - four-thirty',
            "\x{2018}I have to catch a train at <<four-thirty|5b>> in Chicago.\x{2019}"
          ],
          [
            1,
            "[ap 09:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter001.html) - nine o\x{2019}clock",
            "\x{2018}We may not be there until <<nine o\x{2019}clock|6>>.\x{2019}"
          ],
          [
            1,
            '[ap 08:50] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter001.html) - ten to nine',
            "The conductor woke me at <<ten to nine|10>>. \x{2018}Chicago!\x{2019} I jumped up and grabbed my suitcase. As I hurried down the platform, through the billows of steam from the train\x{2019}s underside, which gave to my arrival that old-movie aura of mystery and glory, ice needles crystalized on the lenses of my glasses and I could hardly see."
          ],
          [
            1,
            '[00:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter009.html) - midnight',
            "Days were given to the study of the water level, the numbers of fish, the evidence of tremors. If the signs were still bad the \x{2018}wizards\x{2019} acted. They took a girl of from six to nine years old, decked her with flowers and \x{2018}at <<midnight|9m>> the wizards took her to the middle of the lake and cast her in, bound hand and foot, with a stone fast to her neck. The next day, if the child appeared upon the surface and the tremors continued, another victim was cast into the lake with the same ceremonies."
          ],
          [
            1,
            "[ap 09:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter002.html) - nine o\x{2019}clock",
            "I turned my attention to the three people at the next table, who were drawling away happily. A middle-aged couple had discovered that the stranger who had seated himself at their table was also a Texan. He was dressed in black and yet looked raffish, like one of those adulterous preachers who occur from time to time in worthy novels set in this neck of the woods \x{2013} it was <<nine o\x{2019}clock|6>>, we were in Fort Madison, Iowa, on the west bank of the Mississippi."
          ],
          [
            1,
            '[12:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter006.html) - noon',
            "We travelled parallel to a road, and crossed it occasionally, but for most of the time we were not near to places that were very densely inhabited. The towns were small and tumbledown and in this busriding country most of the people lived on the main roads. After a few stops I could see that this was regarded as a local train \x{2013} no one was going any great distance. Passengers who had got on at Tec\x{fa}n Um\x{e1}n were going to the market at Coatepeque, which was on a road, or to Retalhuleu to get to the coast, about twenty-five miles away. By <<noon|13>> we were at La Democracia. At the time I had concluded that this was an ironical name, but perhaps it was a fitting name for a place with a sweet-sour smell, and huts made out of sticks and cardboard and hammered-out tins, and howling radios and clamouring people \x{2013} some boarding buses, some selling fruit, but the majority merely standing wrapped in blankets and looking darkly at the train. And tired children were hunkered down in the mud. Here was a fancy car among the jalopies, and there a pretty house among the huts. Democracy is a messy system of government, and there was a helter-skelter appropriateness in the name of this disordered town. But how much democracy was there here?"
          ],
          [
            1,
            '[ap 03:20] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/chapter006.html) - 3:20',
            "It helps to take the train if one wishes to understand. Understanding was like a guarantee of depression, but it was an approach to the truth. For most tourists, Guatemala is a four-day affair with quaintness and ruins: veneration at the capital\x{2019}s churches, a day sniffing nosegays at Antigua, another at the colourful Indian market at Chichicastenango, a picnic at the Mayan temples of Tikal. I think I would have found this itinerary more depressing, and less rewarding, than my own meandering from the Mexican border through the coastal departments. The train creaked and whimpered but, incredibly, it kept to its schedule: at <<3:20|2>> we were at Santa Maria \x{2013} as promised in Cook\x{2019}s International Timetable \x{2013} and, eating my fifth banana of the day, I studied our progress on our climb to Escuintla and the greater heights of Guatemala City."
          ],
          [
            1,
            '[ap 07:30] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/toc.html) - 7:30',
            '6 The <<7:30|2>> to Guatemala City'
          ],
          [
            1,
            '[ap 07:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/toc.html) - 7:00',
            '7 The <<7:00|2>> to Zacapa'
          ],
          [
            1,
            '[ap 00:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/toc.html) - 12:00',
            "10 The Atlantic Railway: the <<12:00|2>> to Lim\x{f3}n"
          ],
          [
            1,
            '[ap 10:00] The Old Patagonian Express_ By Train Throu - Paul Theroux.epub (OPS/xhtml/toc.html) - 10:00',
            '11 The Pacific Railway: the <<10:00|2>> to Puntarenas'
          ],

          ## The Memoirs of Sherlock Holmes - Arthur Conan Doyle
          [
            1,
            '[ap 09:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_001.html) - nine o\'clock',
            '"On that evening the horses had been exercised and watered as usual, and the stables were locked up at <<nine o\'clock|6>>. Two of the lads walked up to the trainer\'s house, where they had supper in the kitchen, while the third, Ned Hunter, remained on guard. At <<a few minutes after nine|10>> the maid, Edith Baxter, carried down to the stables his supper, which consisted of a dish of curried mutton. She took no liquid, as there was a water-tap in the stables, and it was the rule that the lad on duty should drink nothing else. The maid carried a lantern with her, as it was very dark and the path ran across the open moor.',
          ],
          [
            1,
            '[01:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_001.html) - one in the morning',
            '"Hunter waited until his fellow-grooms had returned, when he sent a message to the trainer and told him what had occurred. Straker was excited at hearing the account, although he does not seem to have quite realized its true significance. It left him, however, vaguely uneasy, and Mrs. Straker, waking at <<one in the morning|9a>>, found that he was dressing. In reply to her inquiries, he said that he could not sleep on account of his anxiety about the horses, and that he intended to walk down to the stables to see that all was well. She begged him to remain at home, as she could hear the rain pattering against the window, but in spite of her entreaties he pulled on his large mackintosh and left the house.',
          ],
          [
            1,
            '[07:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_001.html) - seven in the morning',
            '"Mrs. Straker awoke at <<seven in the morning|9a>>, to find that her husband had not yet returned. She dressed herself hastily, called the maid, and set off for the stables. The door was open; inside, huddled together upon a chair, Hunter was sunk in a state of absolute stupor, the favorite\'s stall was empty, and there were no signs of his trainer.',
          ],
          [
            1,
            '[ap 05:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_001.html) - five o\'clock',
            '"I only wished to ask a question," said Holmes, with his finger and thumb in his waistcoat pocket. "Should I be too early to see your master, Mr. Silas Brown, if I were to call at <<five o\'clock|6>> to-morrow morning?"',
          ],
          [
            1,
            '[00:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_001.html) - midnight',
            '"Before deciding that question I had grasped the significance of the silence of the dog, for one true inference invariably suggests others. The Simpson incident had shown me that a dog was kept in the stables, and yet, though some one had been in and had fetched out a horse, he had not barked enough to arouse the two lads in the loft. Obviously the <<midnight|13>> visitor was some one whom the dog knew well.',
          ],
          [
            1,
            '[ap < 05:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_001.html) - nearly five',
            'One day in early spring he had so far relaxed as to go for a walk with me in the Park, where the first faint shoots of green were breaking out upon the elms, and the sticky spear-heads of the chestnuts were just beginning to burst into their five-fold leaves. For two hours we rambled about together, in silence for the most part, as befits two men who know each other intimately. It was <<nearly five|9:0>> before we were back in Baker Street once more.',
          ],
          [
            1,
            '[03:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_001.html) - three in the morning',
            '"I am usually an extremely sound sleeper. It has been a standing jest in the family that nothing could ever wake me during the night. And yet somehow on that particular night, whether it may have been the slight excitement produced by my little adventure or not I know not, but I slept much more lightly than usual. Half in my dreams I was dimly conscious that something was going on in the room, and gradually became aware that my wife had dressed herself and was slipping on her mantle and her bonnet. My lips were parted to murmur out some sleepy words of surprise or remonstrance at this untimely preparation, when suddenly my half-opened eyes fell upon her face, illuminated by the candle-light, and astonishment held me dumb. She wore an expression such as I had never seen before--such as I should have thought her incapable of assuming. She was deadly pale and breathing fast, glancing furtively towards the bed as she fastened her mantle, to see if she had disturbed me. Then, thinking that I was still asleep, she slipped noiselessly from the room, and an instant later I heard a sharp creaking which could only come from the hinges of the front door. I sat up in bed and rapped my knuckles against the rail to make certain that I was truly awake. Then I took my watch from under the pillow. It was <<three in the morning|9a>>. What on this earth could my wife be doing out on the country road at <<three in the morning|9a>>?',
          ],
          [
            1,
            '[ap 01:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_001.html) - one o\'clock',
            '"I went as far as the Crystal Palace, spent an hour in the grounds, and was back in Norbury by <<one o\'clock|6>>. It happened that my way took me past the cottage, and I stopped for an instant to look at the windows, and to see if I could catch a glimpse of the strange face which had looked out at me on the day before. As I stood there, imagine my surprise, Mr. Holmes, when the door suddenly opened and my wife walked out.',
          ],
          [
            1,
            '[ap 02:40] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_001.html) - 2.40',
            '"I had gone into town on that day, but I returned by the <<2.40|5a:1>> instead of the <<3.36|5a:1>>, which is my usual train. As I entered the house the maid ran into the hall with a startled face.',
          ],
          [
            1,
            '[ap 07:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_001.html) - seven o\'clock',
            'But we had not a very long time to wait for that. It came just as we had finished our tea. "The cottage is still tenanted," it said. "Have seen the face again at the window. Will meet the <<seven o\'clock|6>> train, and will take no steps until you arrive."',
          ],
          [
            1,
            '[ap 01:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_001.html) - one',
            '"\'Be in Birmingham to-morrow at <<one|9b>>,\' said he. \'I have a note in my pocket here which you will take to my brother. You will find him at 126b Corporation Street, where the temporary offices of the company are situated. Of course he must confirm your engagement, but between ourselves it will be all right.\'',
          ],
          [
            1,
            '[ap 01:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_001.html) - one o\'clock',
            '"\'Good! That\'s a promise,\' said he, rising from his chair. \'Well, I\'m delighted to have got so good a man for my brother. Here\'s your advance of a hundred pounds, and here is the letter. Make a note of the address, 126b Corporation Street, and remember that <<one o\'clock|6>> to-morrow is your appointment. Good-night; and may you have all the fortune that you deserve!\'',
          ],
          [
            1,
            '[ap 00:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_001.html) - twelve',
            '"\'Not reliable ones. Their system is different from ours. Stick at it, and let me have the lists by Monday, at <<twelve|9o>>. Good-day, Mr. Pycroft. If you continue to show zeal and intelligence you will find the company a good master.\'',
          ],
          [
            1,
            '[ap 07:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_001.html) - seven',
            '"\'And you can come up to-morrow evening, at <<seven|9e>>, and let me know how you are getting on. Don\'t overwork yourself. A couple of hours at Day\'s Music Hall in the evening would do you no harm after your labors.\' He laughed as he spoke, and I saw with a thrill that his second tooth upon the left-hand side had been very badly stuffed with gold."',
          ],
          [
            1,
            '[19:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_001.html) - seven o\'clock',
            'At <<seven o\'clock that evening|6>> we were walking, the three of us, down Corporation Street to the company\'s offices.',
          ],
          [
            1,
            '[12:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_001.html) - midday',
            '"It is customary at Mawson\'s for the clerks to leave at <<midday|9a>> on Saturday. Sergeant Tuson, of the City Police, was somewhat surprised, therefore to see a gentleman with a carpet bag come down the steps at <<twenty minutes past one|10>>. His suspicions being aroused, the sergeant followed the man, and with the aid of Constable Pollock succeeded, after a most desperate resistance, in arresting him. It was at once clear that a daring and gigantic robbery had been committed. Nearly a hundred thousand pounds\' worth of American railway bonds, with a large amount of scrip in mines and other companies, was discovered in the bag. On examining the premises the body of the unfortunate watchman was found doubled up and thrust into the largest of the safes, where it would not have been discovered until Monday morning had it not been for the prompt action of Sergeant Tuson. The man\'s skull had been shattered by a blow from a poker delivered from behind. There could be no doubt that Beddington had obtained entrance by pretending that he had left something behind him, and having murdered the watchman, rapidly rifled the large safe, and then made off with his booty. His brother, who usually works with him, has not appeared in this job as far as can at present be ascertained, although the police are making energetic inquiries as to his whereabouts."',
          ],
          [
            1,
            '[02:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_001.html) - two in the morning',
            "\"'I have said that the house is a rambling one. One day last week--on Thursday night, to be more exact--I found that I could not sleep, having foolishly taken a cup of strong caf\x{e9} noir after my dinner. After struggling against it until <<two in the morning|5>>, I felt that it was quite hopeless, so I rose and lit the candle with the intention of continuing a novel which I was reading. The book, however, had been left in the billiard-room, so I pulled on my dressing-gown and started off to get it.",
          ],
          [
            1,
            '[00:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_001.html) - midnight',
            '"And now how was I to proceed to reconstruct this <<midnight|13>> drama? Clearly, only one could fit into the hole, and that one was Brunton. The girl must have waited above. Brunton then unlocked the box, handed up the contents presumably--since they were not to be found--and then--and then what happened?',
          ],
          [
            1,
            '[~ 12:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_003.html) - about mid-day',
            '"My dear Watson, Professor Moriarty is not a man who lets the grass grow under his feet. I went out <<about mid-day|13>> to transact some business in Oxford Street. As I passed the corner which leads from Bentinck Street on to the Welbeck Street crossing a two-horse van furiously driven whizzed round and was on me like a flash. I sprang for the foot-path and saved myself by the fraction of a second. The van dashed round by Marylebone Lane and was gone in an instant. I kept to the pavement after that, Watson, but as I walked down Vere Street a brick came down from the roof of one of the houses, and was shattered to fragments at my feet. I called the police and had the place examined. There were slates and bricks piled up on the roof preparatory to some repairs, and they would have me believe that the wind had toppled over one of these. Of course I knew better, but I could prove nothing. I took a cab after that and reached my brother\'s rooms in Pall Mall, where I spent the day. Now I have come round to you, and on my way I was attacked by a rough with a bludgeon. I knocked him down, and the police have him in custody; but I can tell you with the most absolute confidence that no possible connection will ever be traced between the gentleman upon whose front teeth I have barked my knuckles and the retiring mathematical coach, who is, I dare say, working out problems upon a black-board ten miles away. You will not wonder, Watson, that my first act on entering your rooms was to close your shutters, and that I have been compelled to ask your permission to leave the house by some less conspicuous exit than the front door."',
          ],
          [
            1,
            '[ap 09:15] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_003.html) - quarter-past nine',
            '"Oh yes, it is most necessary. Then these are your instructions, and I beg, my dear Watson, that you will obey them to the letter, for you are now playing a double-handed game with me against the cleverest rogue and the most powerful syndicate of criminals in Europe. Now listen! You will dispatch whatever luggage you intend to take by a trusty messenger unaddressed to Victoria to-night. In the morning you will send for a hansom, desiring your man to take neither the first nor the second which may present itself. Into this hansom you will jump, and you will drive to the Strand end of the Lowther Arcade, handing the address to the cabman upon a slip of paper, with a request that he will not throw it away. Have your fare ready, and the instant that your cab stops, dash through the Arcade, timing yourself to reach the other side at a <<quarter-past nine|10>>. You will find a small brougham waiting close to the curb, driven by a fellow with a heavy black cloak tipped at the collar with red. Into this you will step, and you will reach Victoria in time for the Continental express."',
          ],
          [
            1,
            '[ap 08:09] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_003.html) - 809',
            'The Foundation\'s principal office is located at 4557 Melan Dr. S. Fairbanks, AK, 99712., but its volunteers and employees are scattered throughout numerous locations. Its business office is located at <<809|3:0>> North 1500 West, Salt Lake City, UT 84116, (801) 596-1887, email business@pglaf.org. Email contact links and up to date contact information can be found at the Foundation\'s web site and official page at http://pglaf.org',
          ],
          [
            1,
            '[ap 23:45] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - quarter to twelve',
            '"Yes, sir. But he was off like a deer after the shot that killed poor William Kirwan was fired. Mr. Cunningham saw him from the bedroom window, and Mr. Alec Cunningham saw him from the back passage. It was <<quarter to twelve|10>> when the alarm broke out. Mr. Cunningham had just got into bed, and Mr. Alec was smoking a pipe in his dressing-gown. They both heard William the coachman calling for help, and Mr. Alec ran down to see what was the matter. The back door was open, and as he came to the foot of the stairs he saw two men wrestling together outside. One of them fired a shot, the other dropped, and the murderer rushed across the garden and over the hedge. Mr. Cunningham, looking out of his bedroom, saw the fellow as he gained the road, but lost sight of him at once. Mr. Alec stopped to see if he could help the dying man, and so the villain got clean away. Beyond the fact that he was a middle-sized man and dressed in some dark stuff, we have no personal clue; but we are making energetic inquiries, and if he is a stranger we shall soon find him out."',
          ],
          [
            1,
            '[ap 23:45] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - quarter to twelve',
            'd at <<quarter to twelve|10>> learn what maybe',
          ],
          [
            1,
            '[ap ~ 00:45] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - about a quarter to one',
            '"You see you begin, \'Whereas, at <<about a quarter to one|10>> on Tuesday morning an attempt was made,\' and so on. It was at a <<quarter to twelve|10>>, as a matter of fact."',
          ],
          [
            1,
            '[ap ~ 10:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - About ten',
            '"<<About ten|9:0>>."',
          ],
          [
            1,
            '[ap ~ 01:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - about one o\'clock',
            'Sherlock Holmes was as good as his word, for <<about one o\'clock|6>> he rejoined us in the Colonel\'s smoking-room. He was accompanied by a little elderly gentleman, who was introduced to me as the Mr. Acton whose house had been the scene of the original burglary.',
          ],
          [
            1,
            '[ap 00:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - twelve',
            '"My dear sir," cried Holmes, "there cannot be the least doubt in the world that it has been written by two persons doing alternate words. When I draw your attention to the strong t\'s of \'at\' and \'to\', and ask you to compare them with the weak ones of \'quarter\' and \'<<twelve|9k:0>>,\' you will instantly recognize the fact. A very brief analysis of these four words would enable you to say with the utmost confidence that the \'learn\' and the \'maybe\' are written in the stronger hand, and the \'what\' in the weaker."',
          ],
          [
            1,
            '[ap 00:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - twelve',
            '"It is an art which is often useful," said he. "When I recovered I managed, by a device which had perhaps some little merit of ingenuity, to get old Cunningham to write the word \'<<twelve|9k:0>>,\' so that I might compare it with the \'<<twelve|9k:0>>\' upon the paper."',
          ],
          [
            1,
            '[ap 23:45] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - quarter to twelve',
            'I looked at the clock. It was a <<quarter to twelve|10>>. This could not be a visitor at so late an hour. A patient, evidently, and possibly an all-night sitting. With a wry face I went out into the hall and opened the door. To my astonishment it was Sherlock Holmes who stood upon my step.',
          ],
          [
            1,
            '[ap 11:10] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - 11.10',
            '"Very good. I want to start by the <<11.10|5c>> from Waterloo."',
          ],
          [
            1,
            '[ap 08:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - eight',
            '"Mrs. Barclay was, it appears, a member of the Roman Catholic Church, and had interested herself very much in the establishment of the Guild of St. George, which was formed in connection with the Watt Street Chapel for the purpose of supplying the poor with cast-off clothing. A meeting of the Guild had been held that evening at <<eight|9c:1>>, and Mrs. Barclay had hurried over her dinner in order to be present at it. When leaving the house she was heard by the coachman to make some commonplace remark to her husband, and to assure him that she would be back before very long. She then called for Miss Morrison, a young lady who lives in the next villa, and the two went off together to their meeting. It lasted forty minutes, and at a <<quarter-past nine|10>> Mrs. Barclay returned home, having left Miss Morrison at her door as she passed.',
          ],
          [
            1,
            '[ap 07:30] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - half-past seven',
            '"It is quite certain that when Mrs. Barclay left the house at <<half-past seven|10>> she was on good terms with her husband. She was never, as I think I have said, ostentatiously affectionate, but she was heard by the coachman chatting with the Colonel in a friendly fashion. Now, it was equally certain that, immediately on her return, she had gone to the room in which she was least likely to see her husband, had flown to tea as an agitated woman will, and finally, on his coming in to her, had broken into violent recriminations. Therefore something had occurred between <<seven-thirty|5a:1>> and <<nine o\'clock|6>> which had completely altered her feelings towards him. But Miss Morrison had been with her during the whole of that hour and a half. It was absolutely certain, therefore, in spite of her denial, that she must know something of the matter.',
          ],
          [
            1,
            '[ap ~ 08:45] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - about a quarter to nine o\'clock',
            '"\'We were returning from the Watt Street Mission <<about a quarter to nine o\'clock|10>>. On our way we had to pass through Hudson Street, which is a very quiet thoroughfare. There is only one lamp in it, upon the left-hand side, and as we approached this lamp I saw a man coming towards us with his back very bent, and something like a box slung over one of his shoulders. He appeared to be deformed, for he carried his head low and walked with his knees bent. We were passing him when he raised his face to look at us in the circle of light thrown by the lamp, and as he did so he stopped and screamed out in a dreadful voice, "My God, it\'s Nancy!" Mrs. Barclay turned as white as death, and would have fallen down had the dreadful-looking creature not caught hold of her. I was going to call for the police, but she, to my surprise, spoke quite civilly to the fellow.',
          ],
          [
            1,
            '[12:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - midday',
            'It was <<midday|9d>> when we found ourselves at the scene of the tragedy, and, under my companion\'s guidance, we made our way at once to Hudson Street. In spite of his capacity for concealing his emotions, I could easily see that Holmes was in a state of suppressed excitement, while I was myself tingling with that half-sporting, half-intellectual pleasure which I invariably experienced when I associated myself with him in his investigations.',
          ],
          [
            1,
            '[ap 10:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - ten o\'clock',
            '"We were shut up in Bhurtee, the regiment of us with half a battery of artillery, a company of Sikhs, and a lot of civilians and women-folk. There were ten thousand rebels round us, and they were as keen as a set of terriers round a rat-cage. About the second week of it our water gave out, and it was a question whether we could communicate with General Neill\'s column, which was moving up country. It was our only chance, for we could not hope to fight our way out with all the women and children, so I volunteered to go out and to warn General Neill of our danger. My offer was accepted, and I talked it over with Sergeant Barclay, who was supposed to know the ground better than any other man, and who drew up a route by which I might get through the rebel lines. At <<ten o\'clock|6>> the same night I started off upon my journey. There were a thousand lives to save, but it was of only one that I was thinking when I dropped over the wall that night.',
          ],
          [
            1,
            '[ap 10:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - ten o\'clock',
            'I was weary of our little sitting-room and gladly acquiesced. For three hours we strolled about together, watching the ever-changing kaleidoscope of life as it ebbs and flows through Fleet Street and the Strand. His characteristic talk, with its keen observance of detail and subtle power of inference held me amused and enthralled. It was <<ten o\'clock|6>> before we reached Baker Street again. A brougham was waiting at our door.',
          ],
          [
            1,
            '[ap ~ 06:15] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - about quarter past six',
            '"\'A Russian nobleman who is now resident in England,\' it runs, \'would be glad to avail himself of the professional assistance of Dr. Percy Trevelyan. He has been for some years a victim to cataleptic attacks, on which, as is well known, Dr. Trevelyan is an authority. He proposes to call at <<about quarter past six|10>> to-morrow evening, if Dr. Trevelyan will make it convenient to be at home.\'',
          ],
          [
            1,
            '[ap 07:30] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - half-past seven',
            'Sherlock Holmes\'s prophecy was soon fulfilled, and in a dramatic fashion. At <<half-past seven|10>> next morning, in the first glimmer of daylight, I found him standing by my bedside in his dressing-gown.',
          ],
          [
            1,
            '[ap ~ 07:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - about seven',
            '"He has a cup of tea taken in to him early every morning. When the maid entered, <<about seven|9e>>, there the unfortunate fellow was hanging in the middle of the room. He had tied his cord to the hook on which the heavy lamp used to hang, and he had jumped off from the top of the very box that he showed us yesterday."',
          ],
          [
            1,
            '[~ 05:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - about five in the morning',
            '"As far as I can see, the man has been driven out of his senses by fright. The bed has been well slept in, you see. There\'s his impression deep enough. It\'s <<about five in the morning|9h>>, you know, that suicides are most common. That would be about his time for hanging himself. It seems to have been a very deliberate affair."',
          ],
          [
            1,
            '[ap 03:45] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - quarter to four',
            'Our visitors arrived at the appointed time, but it was a <<quarter to four|10>> before my friend put in an appearance. From his expression as he entered, however, I could see that all had gone well with him.',
          ],
          [
            1,
            '[ap 04:45] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - quarter to five',
            '"The Diogenes Club is the queerest club in London, and Mycroft one of the queerest men. He\'s always there from <<quarter to five|10>> to <<twenty to eight|10a:1>>. It\'s <<six|9k:1>> now, so if you care for a stroll this beautiful evening I shall be very happy to introduce you to two curiosities."',
          ],
          [
            1,
            '[ap 07:15] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - quarter-past seven',
            '"For nearly two hours we drove without my having the least clue as to where we were going. Sometimes the rattle of the stones told of a paved causeway, and at others our smooth, silent course suggested asphalt; but, save by this variation in sound, there was nothing at all which could in the remotest way help me to form a guess as to where we were. The paper over each window was impenetrable to light, and a blue curtain was drawn across the glass work in front. It was a <<quarter-past seven|10>> when we left Pall Mall, and my watch showed me that it was <<ten minutes to nine|10>> when we at last came to a standstill. My companion let down the window, and I caught a glimpse of a low, arched doorway with a lamp burning above it. As I was hurried from the carriage it swung open, and I found myself inside the house, with a vague impression of a lawn and trees on each side of me as I entered. Whether these were private grounds, however, or bona-fide country was more than I could possibly venture to say.',
          ],
          [
            1,
            '[> 00:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - just after midnight',
            '"I was hurried through the hall and into the vehicle, again obtaining that momentary glimpse of trees and a garden. Mr. Latimer followed closely at my heels, and took his place opposite to me without a word. In silence we again drove for an interminable distance with the windows raised, until at last, <<just after midnight|10>>, the carriage pulled up.',
          ],
          [
            1,
            '[ap 09:45] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - quarter to ten',
            'Our hope was that, by taking train, we might get to Beckenham as soon or sooner than the carriage. On reaching Scotland Yard, however, it was more than an hour before we could get Inspector Gregson and comply with the legal formalities which would enable us to enter the house. It was a <<quarter to ten|10>> before we reached London Bridge, and half past before the four of us alighted on the Beckenham platform. A drive of half a mile brought us to The Myrtles--a large, dark house standing back from the road in its own grounds. Here we dismissed our cab, and made our way up the drive together.',
          ],
          [
            1,
            '[ap 11:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - eleven-o\'clock',
            '"I did exactly what he indicated, and waited until the other clerks had departed. One of them in my room, Charles Gorot, had some arrears of work to make up, so I left him there and went out to dine. When I returned he was gone. I was anxious to hurry my work, for I knew that Joseph--the Mr. Harrison whom you saw just now--was in town, and that he would travel down to Woking by the <<eleven-o\'clock|6>> train, and I wanted if possible to catch it.',
          ],
          [
            1,
            '[ap 09:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - nine o\'clock',
            '"It was a long document, written in the French language, and containing twenty-six separate articles. I copied as quickly as I could, but at <<nine o\'clock|6>> I had only done nine articles, and it seemed hopeless for me to attempt to catch my train. I was feeling drowsy and stupid, partly from my dinner and also from the effects of a long day\'s work. A cup of coffee would clear my brain. A commissionnaire remains all night in a little lodge at the foot of the stairs, and is in the habit of making coffee at his spirit-lamp for any of the officials who may be working over time. I rang the bell, therefore, to summon him.',
          ],
          [
            1,
            '[ap 09:45] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - quarter to ten',
            '"The commissionnaire, seeing by my pale face that something was to be feared, had followed me upstairs. Now we both rushed along the corridor and down the steep steps which led to Charles Street. The door at the bottom was closed, but unlocked. We flung it open and rushed out. I can distinctly remember that as we did so there came three chimes from a neighboring clock. It was <<quarter to ten|10>>."',
          ],
          [
            1,
            '[21:45] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - quarter to ten in the evening',
            'He handed over a sheet torn from a note-book. On it was scribbled in pencil: "L10 reward. The number of the cab which dropped a fare at or about the door of the Foreign Office in Charles Street at <<quarter to ten in the evening|10>> of May 23d. Apply 221 B, Baker Street."',
          ],
          [
            1,
            '[ap 03:20] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - twenty past three',
            'It was <<twenty past three|10>> when we reached our terminus, and after a hasty luncheon at the buffet we pushed on at once to Scotland Yard. Holmes had already wired to Forbes, and we found him waiting to receive us--a small, foxy man with a sharp but by no means amiable expression. He was decidedly frigid in his manner to us, especially when he heard the errand upon which we had come.',
          ],
          [
            1,
            '[~ 02:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - about two in the morning',
            '"You must know that last night was the very first night that I have ever slept without a nurse in the room. I was so much better that I thought I could dispense with one. I had a night-light burning, however. Well, <<about two in the morning|9h>> I had sunk into a light sleep when I was suddenly aroused by a slight noise. It was like the sound which a mouse makes when it is gnawing a plank, and I lay listening to it for some time under the impression that it must come from that cause. Then it grew louder, and suddenly there came from the window a sharp metallic snick. I sat up in amazement. There could be no doubt what the sounds were now. The first ones had been caused by some one forcing an instrument through the slit between the sashes, and the second by the catch being pressed back.',
          ],
          [
            1,
            '[ap 08:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - eight',
            '"There are one or two small points which I should desire to clear up before I go," said he. "Your absence, Mr. Phelps, will in some ways rather assist me. Watson, when you reach London you would oblige me by driving at once to Baker Street with our friend here, and remaining with him until I see you again. It is fortunate that you are old school-fellows, as you must have much to talk over. Mr. Phelps can have the spare bedroom to-night, and I will be with you in time for breakfast, for there is a train which will take me into Waterloo at <<eight|9c:1>>."',
          ],
          [
            1,
            '[ap 07:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - seven o\'clock',
            'It was <<seven o\'clock|6>> when I awoke, and I set off at once for Phelps\'s room, to find him haggard and spent after a sleepless night. His first question was whether Holmes had arrived yet.',
          ],
          [
            1,
            '[ap 10:15] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - quarter-past ten',
            '"The blind was not down in your room, and I could see Miss Harrison sitting there reading by the table. It was <<quarter-past ten|10>> when she closed her book, fastened the shutters, and retired.',
          ],
          [
            1,
            '[~ 02:00] The Memoirs of Sherlock Holmes - Arthur Conan Doyle.epub (The_Memoirs_of_Sherlock_Holmes_split_002.html) - about two in the morning',
            '"The night was fine, but still it was a very weary vigil. Of course it has the sort of excitement about it that the sportsman feels when he lies beside the water-course and waits for the big game. It was very long, though--almost as long, Watson, as when you and I waited in that deadly room when we looked into the little problem of the Speckled Band. There was a church-clock down at Woking which struck the quarters, and I thought more than once that it had stopped. At last however <<about two in the morning|9h>>, I suddenly heard the gentle sound of a bolt being pushed back and the creaking of a key. A moment later the servants\' door was opened, and Mr. Joseph Harrison stepped out into the moonlight."',
          ],

            ## The Name of the Rose - Umberto Eco
          [
            1,
            '[12:00] The Name of the Rose - Umberto Eco.epub (index_split_032.html) - noontime',
            "\x{201c}Yes, I was asking you about how they live in the valley, because today in the library I was meditating on the sermons to women by Humbert of Romans, and in particular on that chapter \x{2018}Ad mulieres pauperes in villulis,\x{2019} in which he says that they, more than others, are tempted to sins of the flesh because of their poverty, and wisely he says that they commit mortal sin when they sin with a layman, but the mortality of the sin becomes greater when it is committed with a priest, and greatest of all when the sin is with a monk, who is dead to the world. You know better than I that even in holy places such as abbeys the temptations of the <<noontime|13>> Devil are never wanting. I was wondering whether in our contacts with the people of the village you had heard that some monks, God forbid, had induced maidens into fornication.\x{201d}",
          ],
          [
            1,
            '[> 18:00] The Name of the Rose - Umberto Eco.epub (index_split_032.html) - after compline',
            "\x{201c}I\x{2019}ll tell you. That night, an hour <<after compline|13>>, I went into the kitchen. ...\x{201d}",
          ],
          [
            1,
            '[02:30] The Name of the Rose - Umberto Eco.epub (index_split_032.html) - matins',
            'In any case, we could learn no more for the moment. Having glanced at the corpse, terrified, Remigio asked himself what he should do and decided he would do nothing. If he sought help, he would have to admit he had been wandering around the Aedificium at night, nor would it do his now lost brother any good. Therefore, he resolved to leave things as they were, waiting for someone else to discover the body in the morning, when the doors were opened. He rushed to head off Salvatore, who was already bringing the girl into the abbey, then he and his accomplice went off to sleep, if their agitated vigil till <<matins|13>> could be called that. And at <<matins|9e>>, when the swineherds brought the news to the abbot, Remigio believed the body had been discovered where he had left it, and was aghast to find it in the jar. Who had spirited the corpse out of the kitchen? For this Remigio had no explanation.',
          ],
          [
            1,
            '[~ 09:00] The Name of the Rose - Umberto Eco.epub (index_split_032.html) - Terce',
            "<<Terce|13>> was ringing and I went to the choir, to recite with the others the hymn, the psalms, the verses, and the \x{201c}Kyrie.\x{201d} The others were praying for the soul of the dead Berengar. I was thanking God for having allowed us to find not one but two pairs of lenses.",
          ],
          [
            1,
            '[02:30] The Name of the Rose - Umberto Eco.epub (index_split_016.html) - MATINS',
            '<<MATINS|13>>',
          ],
          [
            1,
            '[02:30] The Name of the Rose - Umberto Eco.epub (index_split_016.html) - matins',
            '
Symbol sometimes of the Devil, sometimes of the Risen Christ, no animal is more untrustworthy than the cock. Our order knew some slothful ones who never crowed at sunrise. On the other hand, especially in winter, the office of <<matins|13>> takes place when night is still total and all nature is asleep, for the monk must rise in darkness and pray at length in darkness, waiting for day and illuminating the shadows with the flame of devotion. Therefore, custom wisely provided for some wakers, who were not to go to bed when their brothers did, but would spend the night reciting in cadence the exact number of psalms that would allow them to measure the time passed, so that, at the conclusion of the hours of sleep granted the others, they would give the signal to wake.',
          ],
          [
            1,
            '[ap > 06:00] The Name of the Rose - Umberto Eco.epub (index_split_016.html) - After six',
            "<<After six|9:0>> psalms, the reading of Holy Scripture began. Some monks were nodding with sleepiness, and one of the night wakers wandered among the stalls with a little lamp to wake any who had dozed off again. If a monk succumbed to drowsiness, as penance he would take the lamp and continue the round. The chanting of another six psalms continued. Then the abbot gave his benediction, the hebdomadary said the prayers, all bowed toward the altar in a moment of meditation whose sweetness no-one can comprehend who has not experienced those hours of mystic ardor and intense inner peace. Finally, cowls again over their faces, all sat and solemnly intoned the \x{201c}Te Deum.\x{201d} I, too, praised the Lord because He had released me from my doubts and freed me from the feeling of uneasiness with which my first day at the abbey had filled me. We are fragile creatures, I said to myself; even among these learned and devout monks the Evil One spreads petty envies, foments subtle hostilities, but all these are as smoke then dispersed by the strong wind of faith, the moment all gather in the name of the Father, and Christ descends into their midst.",
          ],
          [
            1,
            '[02:30] The Name of the Rose - Umberto Eco.epub (index_split_016.html) - matins',
            '
Between <<matins|13>> and <<lauds|13>> the monk does not return to his cell, even if the night is still dark. The novices followed their master into the chapter house to study the psalms; some of the monks remained in church to tend to the church ornaments, but the majority strolled in the cloister in silent meditation, as did William and I. The servants were asleep and they went on sleeping when, the sky still dark, we returned to the choir for <<lauds|13>>.',
          ],
          [
            1,
            '[~ 07:30] The Name of the Rose - Umberto Eco.epub (index_split_016.html) - Prime',
            "The chanting of the psalms resumed, and one in particular, among those prescribed for Mondays, plunged me again into my earlier fears: \x{201c}The transgression of the wicked saith within my heart, that there is no fear of God before his eyes. The words of his mouth are iniquity.\x{201d} It seemed to me an ill omen that the Rule should have set for that very day such a terrible admonition. Nor were my pangs of uneasiness eased, after the psalms of praise, by the usual reading of the Apocalypse; the figures of the doorway returned to my mind, the carvings that had so overwhelmed my heart and eyes the day before. But after the responsory, the hymn, and the versicle, as the chanting of the Gospel began, I glimpsed just above the altar, beyond the windows of the choir, a pale glow that was already making the panes shine in their various colors, subdued till then by the darkness. It was not yet dawn, which would triumph during <<Prime|16>>, just as we would be singing \x{201c}Deus qui est sanctorum splendor mirabilis\x{201d} and \x{201c}Iam lucis orto sidere.\x{201d} It was barely the first faint herald of a winter daybreak, but it was enough, and the dim penumbra now replacing the night\x{2019}s darkness in the nave was enough to relieve my heart.",
          ],
          [
            1,
            '[~ 09:00] The Name of the Rose - Umberto Eco.epub (index_split_025.html) - TERCE',
            '


    The Name of the Rose






<<TERCE|13>>',
          ],
          [
            1,
            '[> 18:00] The Name of the Rose - Umberto Eco.epub (index_split_038.html) - AFTER COMPLINE',
            '


    The Name of the Rose






<<AFTER COMPLINE|9b>>',
          ],
          [
            1,
            '[05:00] The Name of the Rose - Umberto Eco.epub (index_split_024.html) - LAUDS',
            'FROM <<LAUDS|13>> TO PRIME',
          ],
          [
            1,
            '[> 03:00] The Name of the Rose - Umberto Eco.epub (index_split_024.html) - After matins',
            "
In setting down these words, I feel weary, as I felt that night\x{2014}or, rather, that morning. What can be said? <<After matins|13>> the abbot sent most of the monks, now in a state of alarm, to seek everywhere; but without any result.",
          ],
          [
            1,
            '[< 05:00] The Name of the Rose - Umberto Eco.epub (index_split_024.html) - lauds',
            "<<Toward lauds|9e>>, searching Berengar\x{2019}s cell, a monk found under the pallet a white cloth stained with blood. He showed it to the abbot, who drew the direst omens from it. Jorge was present, and as soon as he was informed, he said, \x{201c}Blood?\x{201d} as if the thing seemed improbable to him. They told Alinardo, who shook his head and said, \x{201c}No, no, at the third trumpet death comes by water. ...\x{201d}",
          ],
          [
            1,
            '[~ 09:00] The Name of the Rose - Umberto Eco.epub (index_split_024.html) - terce',
            '<<Toward prime|16>>, when the sun was already up, servants were sent to explore the toot of the cliff, all around the walls. They came back at <<terce|13>>, having found nothing.',
          ],
          [
            1,
            '[~ 16:30] The Name of the Rose - Umberto Eco.epub (index_split_053.html) - VESPERS',
            '


    The Name of the Rose






BETWEEN <<VESPERS|13>> AND <<COMPLINE|13>>',
          ],
          [
            1,
            '[~ 16:30] The Name of the Rose - Umberto Eco.epub (index_split_053.html) - vespers',
            '
It is difficult for me to narrate what happened in the hours that followed, between <<vespers|13>> and <<compline|13>>.',
          ],
          [
            1,
            '[~ 16:30] The Name of the Rose - Umberto Eco.epub (index_split_053.html) - vespers',
            'The novices were bewildered; with their innocent, boyish sensitivity they felt the tension reigning in choir, as I felt it. Long moments of silence and embarrassment ensued. The abbot ordered some psalms to be recited and he picked at random three that were not prescribed for <<vespers|13>> by the Rule. All looked at one another, then began praying in low voices. The novice master came back, followed by Benno, who took his seat, his head bowed. Jorge was not in the scriptorium or in his cell. The abbot commanded that the office begin.',
          ],
          [
            1,
            '[~ 16:30] The Name of the Rose - Umberto Eco.epub (index_split_053.html) - vespers',
            'At the door of the refectory we saw Nicholas, who a few hours earlier had been accompanying Jorge. William asked him whether the old man had gone in immediately to see the abbot. Nicholas said Jorge had had to wait a long time outside the door, because Alinardo and Aymaro of Alessandria were in the hall. After Jorge was received, he remained inside for some time, while Nicholas waited for him. Then he came out and asked Nicholas to accompany him to the church, still deserted an hour before <<vespers|13>>.',
          ],
          [
            1,
            '[~ 18:00] The Name of the Rose - Umberto Eco.epub (index_split_053.html) - compline',
            'The supper was more silent than usual, and sad. The abbot ate listlessly, oppressed by grim thoughts. At the end he told the monks to hurry to <<compline|13>>.',
          ],
          [
            1,
            '[~ 09:00] The Name of the Rose - Umberto Eco.epub (index_split_018.html) - TERCE',
            '


    The Name of the Rose






<<TERCE|13>>',
          ],
          [
            1,
            '[~ 09:00] The Name of the Rose - Umberto Eco.epub (index_split_010.html) - TERCE',
            '


    The Name of the Rose






<<TERCE|13>>',
          ],
          [
            1,
            '[~ 18:00] The Name of the Rose - Umberto Eco.epub (index_split_010.html) - compline',
            'I felt the abbot was pleased to be able to conclude that discussion and return to his problem. He then began telling, with very careful choice of words and with long paraphrases, about an unusual event that had taken place a few days before and had left in its wake great distress among the monks. He was speaking of the matter with William, he said, because, since William had great knowledge both of the human spirit and of the wiles of the Evil One, Abo hoped his guest would be able to devote a part of his valuable time to shedding light on a painful enigma. What had happened, then, was this: Adelmo of Otranto, a monk still young though already famous as a master illuminator, who had been decorating the manuscripts of the library with the most beautiful images, had been found one morning by a goatherd at the bottom of the cliff below the Aedificium. Since he had been seen by other monks in choir during <<compline|13>> but had not reappeared at <<matins|13>>, he had probably fallen there during the darkest hours of the night. The night of a great snowstorm, in which flakes as sharp as blades fell, almost like hail, driven by a furious south wind. Soaked by that snow, which had first melted and then frozen into shards of ice, the body had been discovered at the foot of the sheer drop, torn by the rocks it had struck on the way down. Poor, fragile, mortal thing, God have mercy on him. Thanks to the battering the body had suffered in its broken fall, determining from which precise spot it had fallen was not easy: certainly from one of the windows that opened in rows on the three stories on the three sides of the tower exposed to the abyss.',
          ],
          [
            1,
            '[12:00] The Name of the Rose - Umberto Eco.epub (index_split_010.html) - midday',
            "The abbot asked him whether he wanted to join the community for the <<midday|13>> refection, <<after sext|13>>. William said he had only just eaten\x{2014}very well, too\x{2014}and he would prefer to see Ubertino at once. The abbot took his leave.",
          ],
          [
            1,
            '[ap 01:00] The Name of the Rose - Umberto Eco.epub (index_split_043.html) - one',
            'I looked at the cellarer. Remigio was in wretched shape. He looked around like a frightened animal, as if he recognized the movements and gestures of a liturgy he feared. Now I know he was afraid for two reasons, equally terrifying: <<one|9i:0>>, that he had been caught, to all appearances, in flagrant crime; the other, that the day before, when Bernard had begun his inquiry, collecting rumors and insinuations, Remigio had already been afraid his past would come to light; and his alarm had grown when he saw them arrest Salvatore.',
          ],
          [
            1,
            '[20:05] The Name of the Rose - Umberto Eco.epub (index_split_043.html) - twenty-five',
            "William returned his gaze. \x{201c}He did misunderstand me, in fact. We were referring to a copy of the treatise on canine hydrophobia by Ayyub al-Ruhawi, a remarkably erudite book that you must surely know of by reputation, and which must often have been of great use to you. Hydrophobia, Ayyub says, may be recognized by <<twenty-five|5b>> evident signs. ...\x{201d}",
          ],
          [
            1,
            '[00:00] The Name of the Rose - Umberto Eco.epub (index_split_043.html) - midnight',
            "\x{201c}You yourself know: it is impossible to traffic for so many years with the possessed and not wear their habit! You yourself know, butcher of apostles! You take a black cat\x{2014}isn\x{2019}t that it?\x{2014}that does not have even one white hair (you know this), and you bind his four paws, and then you take him at <<midnight|13>> to a crossroads and you cry in a loud voice: O great Lucifer, Emperor of Hell, I call you and I introduce you into the body of my enemy just as I now hold prisoner this cat, and if you will bring my enemy to death, then the following night at <<midnight|9b>>, in this same place, I will offer you this cat in sacrifice, and you will do what I command of you by the powers of the magic I now exercise according to the secret book of Saint Cyprian, in the name of all the captains of the great legions of hell, Adramelch, Alastor, and Azazel, to whom now I pray, with all their brothers. ...\x{201d} His lip trembled, his eyes seemed to bulge from their sockets, and he began to pray\x{2014}or, rather, he seemed to be praying, but he addressed his implorations to all the chiefs of the infernal legions: \x{201c}Abigor, pecca pro nobis ... Amon, miserere nobis ... Samael, libera nos a bono \x{2026} Belial eleison ... Focalor, in corruptionem meam intende ... Haborym, damnamus dominum \x{2026} Zaebos, anum meum aperies ... Leonard, asperge me spermate tuo et inquinabor. \x{2026}\x{201d}",
          ],
          [
            1,
            '[~ 18:00] The Name of the Rose - Umberto Eco.epub (index_split_022.html) - COMPLINE',
            '


    The Name of the Rose






<<COMPLINE|13>>',
          ],
          [
            1,
            '[~ 18:00] The Name of the Rose - Umberto Eco.epub (index_split_022.html) - compline',
            "
The supper was joyless and silent. It had been just over twelve ours since the discovery of Venantius\x{2019}s co r se. All the others stole glimpses at his empty place at table. When it was the hour for <<compline|13>>, the procession that marched into the choir seemed a funeral cort\x{e8}ge. We followed the office standing in the nave and keeping an eye on the third chapel. The light was scant, and when we saw Malachi emerge from the darkness to reach his stall, we could not tell exactly where he had come from. We moved into the shadows, hiding in the side nave, so that no one would see us stay behind when the office was over. Under my scapular I had the lamp I had purloined in the kitchen during supper. We would light it later at the great bronze tripod that burned all night. I had procured a new wick and ample oil. We would have light for a long time.",
          ],
          [
            1,
            '[12:00] The Name of the Rose - Umberto Eco.epub (index_split_026.html) - SEXT',
            '


    The Name of the Rose






<<SEXT|13>>',
          ],
          [
            1,
            '[02:30] The Name of the Rose - Umberto Eco.epub (index_split_040.html) - matins',
            "\x{201c}Clare gave off the odor of sanctity, but you were sniffing another odor when you sang <<matins|13>> to the nuns!\x{201d}",
          ],
          [
            1,
            '[> 18:00] The Name of the Rose - Umberto Eco.epub (index_split_054.html) - AFTER COMPLINE',
            '


    The Name of the Rose






<<AFTER COMPLINE|9b>>',
          ],
          [
            1,
            '[~ 16:30] The Name of the Rose - Umberto Eco.epub (index_split_054.html) - vespers',
            "We did not discover what he did. An hour went by and he still had not reappeared. He\x{2019}s gone into the finis Africae, I said. Perhaps, William answered. Eager to formulate more hypotheses, I added: Perhaps he came out again through the refectory and has gone to look for Jorge. And William answered: That is also possible. Perhaps Jorge is already dead, I imagined further. Perhaps he is to the Aedificium and is killing the abbot. Perhaps they are both in some other place and some other person is lying in wait for them. What did \x{201c}the Italians\x{201d} want? And why was Benno so frightened? Was it perhaps only a mask he had assumed, to mislead us? Why had he lingered in the scriptorium during <<vespers|13>>, if he didn\x{2019}t know how to close the scriptorium or how to get out? Did he want to essay the passages of the labyrinth?",
          ],
          [
            1,
            '[ap 04:00] The Name of the Rose - Umberto Eco.epub (index_split_054.html) - four',
            "\x{201c}Adso,\x{201d} he said to me, \x{201c} \x{2018}primum et septimum de quatuor\x{2019} does not mean the first and seventh of four, but of the four, the word \x{2018}<<four|9k:0>>\x{2019}!\x{201d} For a moment I still did not understand, but then I was enlightened: \x{201c}Super thronos viginti quatuor! The writing! The verse! The words are carved over the mirror!\x{201d}",
          ],
          [
            1,
            '[> 18:00] The Name of the Rose - Umberto Eco.epub (index_split_054.html) - after compline',
            'Two hours <<after compline|13>>, at the end of the sixth day, in the heart of the night that was giving birth to the seventh day, we entered the finis Africae.',
          ],
          [
            1,
            '[> 06:00] The Name of the Rose - Umberto Eco.epub (index_split_009.html) - after lauds',
            '
It was a beautiful morning at the end of November. During the night it had snowed, but only a little, and the earth was covered with a cool blanket no more than three fingers high. In the darkness, immediately <<after lauds|13>>, we heard Mass in a village in the valley. Then we set off toward the mountain, as the sun first appeared.',
          ],
          [
            1,
            '[ap 08:00] The Name of the Rose - Umberto Eco.epub (index_split_009.html) - Eight',
            "While we toiled up the steep path that wound around the mountain, I saw the abbey. I was amazed, not by the walls that girded it on every side, similar to others to be seen in all the Christian world, but by the bulk of what I later learned was the Aedificium. This was an octagonal construction that from a distance seemed a tetragon (a perfect form, which expresses the sturdiness and impregnability of the City of God), whose southern sides stood on the plateau of the abbey, while the northern ones seemed to grow from the steep side of the mountain, a sheer drop, to which they were bound. I might say that from below, at certain points, the cliff seemed to extend, reaching up toward the heavens, with the rock\x{2019}s same colors and material, which at a certain point became keep and tower (work of giants who had great familiarity with earth and sky). Three rows of windows proclaimed the triune rhythm of its elevation, so that what was physically squared on the earth was spiritually triangular in the sky. As we came closer, we realized that the quadrangular form included, at each of its corners, a heptagonal tower, five sides of which were visible on the outside\x{2014}four of the eight sides, then, of the greater octagon producing four minor heptagons, which from the outside appeared as pentagons. And thus anyone can see the admirable concord of so many holy numbers, each revealing a subtle spiritual significance. <<Eight|9i:0>>, the number of perfection for every tetragon; <<four|9i:0>>, the number of the Gospels; <<five|9i:0>>, the number of the zones of the world; <<seven|9i:0>>, the number of the gifts of the Holy Ghost. In its bulk and in its form, the Aedificium resembled Castel Ursino or Castel del Monte, which I was to see later in the south of the Italian peninsula, but its inaccessible position made it more awesome than those, and capable of inspiring fear in the traveler who approached it gradually. And it was fortunate that, since it was a very clear winter morning, I did not first see the building as it appears on stormy days.",
          ],
          [
            1,
            '[~ 16:30] The Name of the Rose - Umberto Eco.epub (index_split_044.html) - VESPERS',
            '


    The Name of the Rose






<<VESPERS|13>>',
          ],
          [
            1,
            '[~ 18:00] The Name of the Rose - Umberto Eco.epub (index_split_044.html) - compline',
            "\x{201c}The good of a book lies in its being read. A book is made up of signs that speak of other signs, which in their turn speak of things. Without an eye to read them, a book contains signs that produce no concepts; therefore it is dumb. This library was perhaps born to save the books it houses, but now it lives to bury them. This is why it has become a sink of iniquity. The cellarer says he betrayed. So has Benno. He has betrayed. Oh, what a nasty day, my good Adso! Full of blood and ruination. I have had enough of this day. Let us also go to <<compline|13>>, and then to bed.\x{201d}",
          ],
          [
            1,
            '[02:30] The Name of the Rose - Umberto Eco.epub (index_split_005.html) - Matins',
            "
<<Matins|13>>\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0} (which Adso sometimes refers to by the older expression \x{201c}Vigiliae\x{201d}) Between <<2:30|2>> and <<3:00 in the morning|2a>>.",
          ],
          [
            1,
            '[05:00] The Name of the Rose - Umberto Eco.epub (index_split_005.html) - Lauds',
            "<<Lauds|13>>\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0} (which in the most ancient tradition were called \x{201c}Matutini\x{201d} or \x{201c}<<Matins|13>>\x{201d}) Between <<5:00|2>> and <<6:00 in the morning|2a>>, in order to end at dawn.",
          ],
          [
            1,
            '[12:00] The Name of the Rose - Umberto Eco.epub (index_split_005.html) - Sext',
            "<<Sext|13>>\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0} <<Noon|13>> (in a monastery where the monks did not work in the fields, it was also the hour of the <<midday|13>> meal in winter).",
          ],
          [
            1,
            '[~ 16:30] The Name of the Rose - Umberto Eco.epub (index_split_005.html) - Vespers',
            "<<Vespers|13>>\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0} <<Around 4:30, at sunset|2a>> (the Rule prescribes eating supper before dark).",
          ],
          [
            1,
            '[~ 18:00] The Name of the Rose - Umberto Eco.epub (index_split_005.html) - Compline',
            "<<Compline|13>>\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0}\x{a0} <<Around 6:00|2>> (before <<7:00|2>>, the monks go to bed).",
          ],
          [
            1,
            '[~ 07:30] The Name of the Rose - Umberto Eco.epub (index_split_005.html) - around 7:30 A.M.',
            '
The calculation is based on the fact that in northern Italy at the end of November, the sun rises <<around 7:30 A.M.|2a>> and sets <<around 4:40 P.M.|2a>> ',
          ],
          [
            1,
            '[12:00] The Name of the Rose - Umberto Eco.epub (index_split_019.html) - SEXT',
            '


    The Name of the Rose






<<SEXT|13>>',
          ],
          [
            1,
            '[12:00] The Name of the Rose - Umberto Eco.epub (index_split_019.html) - noonday',
            "Berengar was consumed, as many of the monks now knew, by an insane passion for Adelmo, the same passion whose evils divine wrath had castigated in Sodom and Gomorrah. So Benno expressed himself, perhaps out of regard for my tender years. But anyone who has spent his adolescence in a monastery, even if he has kept himself chaste, often hears talk of such passions, and at times he has to protect himself from the snares of those enslaved by them. Little novice that I was, had I not already received from an aged monk, at Melk, scrolls with verses that as a rule a layman devotes to a woman? The monkish vows keep us far from that sink of vice that is the female body, but often they bring us close to other errors. Can I finally hide from myself the fact that even today my old age is still stirred by the <<noonday|13>> demon when my eyes, in choir, happen to linger on the beardless face of a novice, pure and fresh as a maiden\x{2019}s?",
          ],
          [
            1,
            '[> 18:00] The Name of the Rose - Umberto Eco.epub (index_split_019.html) - after compline',
            "Benno admitted that his enthusiasm had carried him away, and he resumed his story. The night before Adelmo\x{2019}s death, Benno followed the pair, driven by curiosity, and he saw them, <<after compline|9e>>, go off together to the dormitory. He waited a long time, holding ajar the door of his cell, not far from theirs, and when silence had fallen over the sleep of the monks, he clearly saw Adelmo slip into Berengar\x{2019}s cell. Benno remained awake, unable to fall asleep, until he heard Berengar\x{2019}s door open again and Adelmo flee, almost running, as his friend tried to hold him back. Berengar followed Adelmo down to the floor below. Cautiously Benno went after them, and at the mouth of the lower corridor he saw Berengar, trembling, huddled in a corner, staring at the door of Jorge\x{2019}s cell. Benno guessed that Adelmo had flung himself at the feet of the venerable brother to confess his sin. And Berengar was trembling, knowing his secret was being revealed, even if under the seal of the sacrament.",
          ],
          [
            1,
            '[~ 16:30] The Name of the Rose - Umberto Eco.epub (index_split_036.html) - VESPERS',
            '


    The Name of the Rose






<<VESPERS|13>>',
          ],
          [
            1,
            '[> 16:30] The Name of the Rose - Umberto Eco.epub (index_split_021.html) - AFTER VESPERS',
            '


    The Name of the Rose






<<AFTER VESPERS|9b>>',
          ],
          [
            1,
            '[~ 09:00] The Name of the Rose - Umberto Eco.epub (index_split_033.html) - TERCE',
            '


    The Name of the Rose






<<TERCE|13>>',
          ],
          [
            1,
            '[12:00] The Name of the Rose - Umberto Eco.epub (index_split_033.html) - noontime',
            'Now I know, as the doctor says, that love can harm the lover when it is excessive. And mine was excessive. I have tried to explain what I felt then, not in the least to justify what I felt. I am speaking of what were my sinful ardors of youth. They were bad, but truth obliges me to say that at the time I felt them to be extremely good. And let this serve to instruct anyone who may fall, as I did, into the nets of temptation. Today, an old man, I would know a thousand ways of evading such seductions. And I wonder how proud of them I should be, since I am free of the temptations of the <<noontime|13>> Devil; but not free from others, so that I ask myself whether what I am now doing is not a sinful succumbing to the terrestrial passion of recollection, a foolish attempt to elude the flow of time, and death.',
          ],
          [
            1,
            '[~ 18:00] The Name of the Rose - Umberto Eco.epub (index_split_015.html) - COMPLINE',
            '


    The Name of the Rose






<<COMPLINE|13>>',
          ],
          [
            1,
            '[~ 18:00] The Name of the Rose - Umberto Eco.epub (index_split_015.html) - compline',
            'Supper over, the monks prepared to go off to the choir for the office of <<compline|13>>. They again lowered their cowls over their faces and formed a line at the door. Then they moved in a long file, crossing the cemetery and entering the choir through the north doorway.',
          ],
          [
            1,
            '[~ 16:30] The Name of the Rose - Umberto Eco.epub (index_split_055.html) - vespers',
            "\x{201c}Is that you, William of Baskerville?\x{201d} he asked. \x{201c}I have been waiting for you since this afternoon before <<vespers|13>>, when I came and closed myself in here. I knew you would arrive.\x{201d}",
          ],
          [
            1,
            '[02:30] The Name of the Rose - Umberto Eco.epub (index_split_046.html) - MATINS',
            '<<MATINS|13>>',
          ],
          [
            1,
            '[02:30] The Name of the Rose - Umberto Eco.epub (index_split_046.html) - matins',
            '
We went down to <<matins|13>>. That last part of the night, virtually the first part of the imminent new day, was still foggy. As I crossed the cloister the dampness penetrated to my bones, aching after my uneasy sleep. Although the church was cold, I knelt under those vaults with a sigh of relief, sheltered from the elements, comforted by the warmth of other bodies, and by prayer.',
          ],
          [
            1,
            '[05:00] The Name of the Rose - Umberto Eco.epub (index_split_046.html) - lauds',
            'When we reached the end of the office, the abbot reminded monks and novices that it was necessary to prepare for the Christmas High Mass; therefore, as was the custom, the time before <<lauds|13>> would be spent assaying the accord of the whole community in the performance of some chants prescribed for the occasion. That assembly of devout men was in effect trained as a single body, a single harmonious voice; through a process that had gone on for years, they acknowledged their unification, into a single soul, in their singing.',
          ],
          [
            1,
            '[05:00] The Name of the Rose - Umberto Eco.epub (index_split_047.html) - LAUDS',
            '


    The Name of the Rose






<<LAUDS|13>>',
          ],
          [
            1,
            '[05:00] The Name of the Rose - Umberto Eco.epub (index_split_047.html) - lauds',
            "
Was it time for <<lauds|13>> already? Was it earlier or later? From that point on I lost all temporal sense. Perhaps hours went by, perhaps less, in which Malachi\x{2019}s body was laid out in church on a catafalque, while the brothers formed a semicircle around it. The abbot issued instructions for a prompt funeral. I heard him summon Benno and Nicholas of Morimondo. In less than a day, he said, the abbey had been deprived of its librarian and its cellarer. \x{201c}You,\x{201d} he said to Nicholas, \x{201c}will take over the duties of Remigio. You know the jobs of many, here in the abbey. Name someone to take your place in charge of the forges, and provide for today\x{2019}s immediate necessities in the kitchen, the refectory. You are excused from offices. Go.\x{201d} Then to Benno he said, \x{201c}Only yesterday evening you were named Malachi\x{2019}s assistant. Provide for the opening of the scriptorium and make sure no one goes up into the library alone.\x{201d} Shyly, Benno pointed out that he had not yet been initiated into the secrets of that place. The abbot glared at him sternly. \x{201c}No one has said you will be. You see that work goes on and is offered as a prayer for our dead brothers ... and for those who will yet die. Each monk will work only on the books already given him. Those who wish may consult the catalogue. Nothing else. You are excused from <<vespers|13>>, because at that hour you will lock up everything.\x{201d}",
          ],
          [
            1,
            '[12:00] The Name of the Rose - Umberto Eco.epub (index_split_034.html) - SEXT',
            '


    The Name of the Rose






<<SEXT|13>>',
          ],
          [
            1,
            '[> 18:00] The Name of the Rose - Umberto Eco.epub (index_split_023.html) - after compline',
            "\x{201c}We were pursuing a trail ...\x{201d} William said vaguely, with visible embarrassment. The abbot gave him a long look, then said in a slow and severe voice, \x{201c}I looked for you immediately <<after compline|13>>. Berengar was not in choir.\x{201d}",
          ],
          [
            1,
            '[~ 18:00] The Name of the Rose - Umberto Eco.epub (index_split_023.html) - compline',
            "\x{201c}He was not in choir at <<compline|13>>,\x{201d} the abbot repeated, and has not come back to his cell. <<Matins|13>> are about to ring, and we will now see if he reappears. Otherwise I fear some new calamity.\x{201d}",
          ],
          [
            1,
            '[02:30] The Name of the Rose - Umberto Eco.epub (index_split_023.html) - matins',
            'At <<matins|9m>> Berengar was absent.',
          ],
          [
            1,
            '[~ 16:30] The Name of the Rose - Umberto Eco.epub (index_split_028.html) - VESPERS',
            '


    The Name of the Rose






<<VESPERS|13>>',
          ],
          [
            1,
            '[~ 16:30] The Name of the Rose - Umberto Eco.epub (index_split_028.html) - vespers',
            'At that moment Nicholas of Morimondo came running toward us, bearer of very bad tidings. While he was trying to grind more finely the best lens, the one on which William had based such hope, it had broken. And another, which could perhaps have replaced it, had cracked as he was trying to insert it into the fork. Nicholas, disconsolately, pointed to the sky. It was already the hour of <<vespers|13>>, and darkness was falling. For that day no more work could be done. Another day lost, William acknowledged bitterly, suppressing (as he confessed to me afterward) the temptation to strangle the master glazier, though Nicholas was already sufficiently humiliated.',
          ],
          [
            1,
            '[ap > 02:00] The Name of the Rose - Umberto Eco.epub (index_split_028.html) - after two',
            "\x{201c}At this point it isn\x{2019}t difficult. With the map you\x{2019}ve drawn, which should more or less correspond to the plan of the library, as soon as we are m the first heptagonal room we will move immediately to reach one of the blind rooms. Then, always turning right, <<after two|9:0>> or three rooms we should again be in a tower, which can only be the north tower, until we come to another blind room, on the left, which will confine with the heptagonal room, and on the right will allow us to rediscover a route similar to what I have just described, until we arrive at the west tower.\x{201d}",
          ],
          [
            1,
            '[~ 18:00] The Name of the Rose - Umberto Eco.epub (index_split_028.html) - compline',
            "\x{201c}Ah, of course, supper. The hour has passed by now. The monks are already at <<compline|13>>. But perhaps the kitchen is still open. Go look for something.\x{201d}",
          ],
          [
            1,
            '[~ 18:00] The Name of the Rose - Umberto Eco.epub (index_split_037.html) - COMPLINE',
            '


    The Name of the Rose






<<COMPLINE|13>>',
          ],
          [
            1,
            '[~ 18:00] The Name of the Rose - Umberto Eco.epub (index_split_037.html) - compline',
            'In the end, all rose very happy, some mentioning vague ailments as an excuse not to go down to <<compline|13>>. But the abbot did not take offense. Not all have the privilege and the obligations we assume on being consecrated in our order.',
          ],
          [
            1,
            '[~ 18:00] The Name of the Rose - Umberto Eco.epub (index_split_037.html) - compline',
            'I joined William and we did what was to be done. That is, we prepared to follow <<compline|13>> at the rear of the nave, so that when the office ended we would be ready to undertake our second (for me, third) journey into the bowels of the labyrinth.',
          ],
          [
            1,
            '[~ 18:00] The Name of the Rose - Umberto Eco.epub (index_split_045.html) - COMPLINE',
            '


    The Name of the Rose






<<COMPLINE|13>>',
          ],
          [
            1,
            '[~ 16:30] The Name of the Rose - Umberto Eco.epub (index_split_045.html) - Vespers',
            "
<<Vespers|13>> had been sung in a confused fashion while the interrogation of the cellarer was still under way, with the curious novices escaping their master\x{2019}s control to observe through windows and cracks what was going on in the chapter hall. Now the whole community was to pray for the good soul of Severinus. Everyone expected the abbot to speak, and wondered what he would say. But instead, after the ritual homily of Saint Gregory, the responsory, and the three prescribed psalms, the abbot did step into the pulpit, but only to say he would remain silent this evening. Too many calamities had befallen the abbey, he said, to allow even the spiritual father to speak in a tone of reproach and admonition. Everyone, with no exceptions, should now make a strict examination of conscience. But since it was necessary for someone to speak, he suggested the admonition should come from the oldest of their number, now close to death, the brother who was the least involved of all in the terrestrial passions that had generated so many evils. By right of age Alinardo of Grottaferrata should speak, but all knew the fragile condition of the venerable brother\x{2019}s health. Immediately after Alinardo, in the order established by the inevitable progress of time, came Jorge. And the abbot now called upon him.",
          ],
          [
            1,
            '[02:30] The Name of the Rose - Umberto Eco.epub (index_split_045.html) - matins',
            "\x{201c}To bed, Adso,\x{201d} William said to me, climbing the stairs of the pilgrims\x{2019} hospice. \x{201c}This is not a night for roaming about. Bernard Gui might have the idea of heralding the end of the world by beginning with our carcasses. Tomorrow we must try to be present at <<matins|13>>, because immediately afterward Michael and the other Minorites will leave.\x{201d}",
          ],
          [
            1,
            '[12:00] The Name of the Rose - Umberto Eco.epub (index_split_020.html) - noon',
            "
We found the abbot in church, at the main altar. He was following the work of some novices who had brought forth from a secret place a number of sacred vessels, chalices, patens, and monstrances, and a crucifix I had not seen during the morning function. I could not repress a cry of wonder at the dazzling beauty of those holy objects. It was <<noon|9f>> and the light came in bursts through the choir windows, and even more through those of the fa\x{e7}ade, creating white cascades that, like mystic streams of divine substance, intersected at various points of the church, engulfing the altar itself.",
          ],
          [
            1,
            '[ap 01:00] The Name of the Rose - Umberto Eco.epub (index_split_020.html) - one',
            "\x{201c}Abo,\x{201d} William said, \x{201c}you live in the isolation of this splendid and holy abbey, far from the wickedness of the world. Life in the cities is far more complex than you believe, and there are degrees, you know, also in error and in evil. Lot was much less a sinner than his fellow citizens who conceived foul thoughts also about the angels sent by God, and the betrayal of Peter was nothing compared with the betrayal of Judas: <<one|9i:0>>, indeed, was forgiven, the other not. You cannot consider Patarines and Catharists the same thing. The Patarines were a movement to reform behavior within the laws of Holy Mother Church. They wanted always to improve the ecclesiastics\x{2019} behavior.\x{201d}",
          ],
          [
            1,
            '[~ 16:30] The Name of the Rose - Umberto Eco.epub (index_split_014.html) - VESPERS',
            '


    The Name of the Rose






<<VESPERS|13>>',
          ],
          [
            1,
            '[~ 16:30] The Name of the Rose - Umberto Eco.epub (index_split_014.html) - vespers',
            '
At that point the bell rang for <<vespers|13>> and the monks prepared to leave their desks. Malachi made it clear to us that we, too, should leave. He would remain with his assistant, Berengar, to put things back in order (those were his words) and arrange the library for the night. William asked him whether he would be locking the doors.',
          ],
          [
            1,
            '[~ 18:00] The Name of the Rose - Umberto Eco.epub (index_split_014.html) - compline',
            "\x{201c}There are no doors that forbid access to the scriptorium from the kitchen and the refectory, or to the library from the scriptorium. Stronger than any door must be the abbot\x{2019}s prohibition. And the monks need both the kitchen and the refectory until <<compline|13>>. At that point, to prevent entry into the Aedificium by outsiders or animals, for whom the interdiction is not valid, I myself lock the outside doors, which open into the kitchen and the refectory, and from that hour on the Aedificium remains isolated.\x{201d}",
          ],
          [
            1,
            '[~ 16:30] The Name of the Rose - Umberto Eco.epub (index_split_014.html) - Vespers',
            "Nicholas remained puzzled and uneasy. \x{201c}I hadn\x{2019}t thought of that. Perhaps. God protect us. It\x{2019}s late. <<Vespers|13>> have already begun. Farewell.\x{201d} And he headed for the church.",
          ],
          [
            1,
            '[~ 16:30] The Name of the Rose - Umberto Eco.epub (index_split_014.html) - vespers',
            'While we were talking in this fashion, the office of <<vespers|13>> ended. The servants were going back to their tasks before retiring for supper, the monks were heading for the refectory. The sky was now dark and it was beginning to snow. A light snow, in soft little flakes, which must have continued, I believe, for most of the night, because the next morning all the grounds were covered with a white blanket, as I shall tell.',
          ],
          [
            1,
            '[05:00] The Name of the Rose - Umberto Eco.epub (index_split_031.html) - LAUDS',
            '<<LAUDS|13>>',
          ],
          [
            1,
            '[12:00] The Name of the Rose - Umberto Eco.epub (index_split_011.html) - SEXT',
            '


    The Name of the Rose






<<SEXT|13>>',
          ],
          [
            1,
            '[ap 01:00] The Name of the Rose - Umberto Eco.epub (index_split_011.html) - one',
            "As this story continues, I shall have to speak again, and at length, of this creature and record his speech. I confess I find it very difficult to do so because I could not say now, as I could never understand then, what language he spoke. It was not Latin, in which the lettered men of the monastery expressed themselves, it was not the vulgar tongue of those parts, or any other I had ever heard. I believe I have given a faint idea of his manner of speech, reporting just now (as I remember them) the first words of his I heard. When I learned later about his adventurous life and about the various places where he had lived, putting down roots in none of them, I realized Salvatore spoke all languages, and no language. Or, rather, he had invented for himself a language which used the sinews of the languages to which he had been exposed\x{2014}and once I thought that his was, not the Adamic language that a happy mankind had spoken, all united by a single tongue from the origin of the world to the Tower of Babel, or one of the languages that arose after the dire event of their division, but precisely the Babelish language of the first day after the divine chastisement, the language of primeval confusion. Nor, for that matter, could I call Salvatore\x{2019}s speech a language, because in every human language there are rules and every term signifies ad placitum a thing, according to a law that does not change, for man cannot call the dog once dog and once cat, or utter sounds to which a consensus of people has not assigned a definite meaning, as would happen if someone said the word \x{201c}blitiri\x{201d} And yet, one way or another, I did understand what Salvatore meant, and so did the others. Proof that he spoke not one, but all languages, none correctly, taking words sometimes from <<one|9c:0>> and sometimes from another. I also noticed afterward that he might refer to something first in Latin and later in Proven\x{e7}al, and I realized that he was not so much inventing his own sentences as using the disiecta membra of other sentences, heard some time in the past, according to the present situation and the things he wanted to say, as if he could speak of a food, for instance, only with the words of the people among whom he had eaten that food, and express his joy only with sentences that he had heard uttered by joyful people the day when he had similarly experienced joy. His speech was somehow like his face, put together with pieces from other people\x{2019}s faces, or like some precious reliquaries I have seen (si licet magnis componere parva, if I may link diabolical things with the divine), fabricated from the shards of other holy objects. At that moment, when I met him for the first time, Salvatore seemed to me, because of both his face and his way of speaking, a creature not unlike the hairy and hoofed hybrids I had just seen under the portal. Later I realized that the man was probably good-hearted and humorous. Later still ... But we must not get ahead of our story. Particularly since, the moment he had spoken, my master questioned him with great curiosity.",
          ],
          [
            1,
            '[12:00] The Name of the Rose - Umberto Eco.epub (index_split_051.html) - SEXT',
            '


    The Name of the Rose






<<SEXT|13>>',
          ],
          [
            1,
            '[> 09:00] The Name of the Rose - Umberto Eco.epub (index_split_050.html) - AFTER TERCE',
            '


    The Name of the Rose






<<AFTER TERCE|9b>>',
          ],
          [
            1,
            '[~ 09:00] The Name of the Rose - Umberto Eco.epub (index_split_041.html) - TERCE',
            '


    The Name of the Rose






<<TERCE|13>>',
          ],
          [
            1,
            '[02:30] The Name of the Rose - Umberto Eco.epub (index_split_030.html) - matins',
            "\x{201c}And now we should go to bed, because in an hour it is <<matins|9f>>. But I see you are still agitated, my poor Adso, still fearful because of your sin. ... There is nothing like a good spell in church to calm the spirit. I have absolved you, but one never knows. Go and ask the Lord\x{2019}s confirmation.\x{201d} And he gave me a rather brisk slap on the head, perhaps as a show of paternal and virile affection, perhaps as an indulgent penance. Or perhaps (as I culpably thought at that moment) in a sort of good-natured envy, since he was a man who so thirsted for new and vital experiences.",
          ],
          [
            1,
            '[> 18:00] The Name of the Rose - Umberto Eco.epub (index_split_029.html) - AFTER COMPLINE',
            '


    The Name of the Rose






<<AFTER COMPLINE|9b>>',
          ],
          [
            1,
            '[12:00] The Name of the Rose - Umberto Eco.epub (index_split_029.html) - noontime',
            "O Lord, when the soul is transported, the only virtue lies in loving what you see (is that not true?), the supreme happiness in having what you have; there blissful life is drunk at its source (has this not been said?), there you savor the true life that we will live after this mortal life among the angels for all eternity. ... This is what I was thinking and it seemed to me the prophecies were being fulfilled at last, as the girl lavished indescribable sweetness on me, and it was as if my whole body were an eye, before and behind, and I could suddenly see all surrounding things. And I understood that from it, from love, unity and tenderness are created together, as are good and kiss and fulfillment, as I had already heard, believing I was being told about something else. And only for an instant, as my joy was about to reach its zenith, did I remember that perhaps I was experiencing, and at night, the possession of the <<noontime|13>> Devil, who was condemned finally to reveal himself in his true, diabolical nature to the soul that in ecstasy asks \x{201c}Who are you?,\x{201d} who knows how to grip the soul and delude the body. But I was immediately convinced that my scruples were indeed devilish, for nothing could be more right and good and holy than what I was experiencing, the sweetness of which grew with every moment. As a little drop of water added to a quantity of wine is completely dispersed and takes on the color and taste of wine, as red-hot iron becomes like molten fire losing its original form, as air when it is inundated with the sun\x{2019}s light is transformed into total splendor and clarity so that it no longer seems illuminated but, rather, seems to be light itself, so I felt myself die of tender liquefaction, and I had only the strength left to murmur the words of the psalm: \x{201c}Behold my bosom is like new wine, sealed, which bursts new vessels,\x{201d} and suddenly I saw a brilliant light and in it a saffron-colored form which flamed up in a sweet and shining fire, and that splendid light spread through all the shining fire, and this shining fire through that golden form and that brilliant light and that shining fire through the whole form.",
          ],
          [
            1,
            '[> 16:30] The Name of the Rose - Umberto Eco.epub (index_split_017.html) - after vespers',
            "Berengar staggered, as if he were about to fall in a faint. \x{201c}I?\x{201d} he asked in a weak voice. William had dropped his question as if by chance, perhaps because Benno had told him of seeing the two conferring in the cloister <<after vespers|13>>. But it must have struck home, and clearly Berengar was thinking of another, really final meeting, because he began to speak in a halting voice.",
          ],
          [
            1,
            '[~ 18:00] The Name of the Rose - Umberto Eco.epub (index_split_017.html) - compline',
            "\x{201c} \x{2018}I am damned!\x{2019} That is what he said to me. \x{2018}As you see me here, you see one returned from hell, and to hell I must go back.\x{2019} So he said to me. And I cried to him, \x{2018}Adelmo, have you really come from hell? What are the pains of hell like?\x{2019} And I was trembling, because I had just left the office of <<compline|13>> where I had heard read the terrible pages on the wrath of the Lord. And he said to me, \x{2018}The pains of hell are infinitely greater than our tongue can say. You see,\x{2019} he said, \x{2018}this cape of sophisms in which I have been dressed till today? It oppresses me and weighs on me as if I had the highest tower of Paris or the mountain of the world on my back, and nevermore shall I be able to set it down. And this pain was given me by divine justice for my vainglory, for having believed my body a place of pleasures, and for having thought to know more than others, and for having enjoyed monstrous things, which, cherished in my imagination, have produced far more monstrous things within my soul\x{2014}and now I must live with them in eternity. You see the lining of this cloak? It is as if it were all coals and ardent fire, and it is the fire that burns my body, and this punishment is given me for the dishonest sin of the flesh, whose vice I knew and cultivated, and this fire now unceasingly blazes and burns me! Give me your hand, my beautiful master,\x{2019} he said to me further, \x{2018}that my meeting with you may be a useful lesson, in exchange for many of the lessons you gave me. Your hand, my beautiful master!\x{2019} And he shook the finger of his burning hand, and on my hand there fell a little drop of his sweat and it seemed to pierce my hand. For many days I bore the sign, only I hid it from all. Then he disappeared among the graves, and the next morning I learned that his body, which had so terrified me, was now dead at the foot of the cliff.\x{201d}",
          ],
          [
            1,
            '[> 18:00] The Name of the Rose - Umberto Eco.epub (index_split_017.html) - after compline',
            "\x{201c}It was <<after compline|9f>>, immediately <<after compline|13>>, it was not snowing yet, the snow began later. ... I remember that the first flurries began as I was fleeing. toward the dormitory. I was fleeing toward the dormitory as the ghost went in the opposite direction. ... And after that I know nothing more; please, question me no further, if you will not confess me.\x{201d}",
          ],
          [
            1,
            '[05:00] The Name of the Rose - Umberto Eco.epub (index_split_017.html) - lauds',
            "\x{201c}Because someone said words of desperation to him. As I said, a page of a modern preacher must have prompted someone to repeat the words that frightened Adelmo and with which Adelmo frightened Berengar. In these last few years, as never before, to stimulate piety and terror and fervor in the populace, and obedience to human and divine law, preachers have used distressing words, macabre threats. Never before, as in our days, amid processions of flagellants, were sacred <<lauds|13>> heard inspired by the sorrows of Christ and of the Virgin, never has there been such insistence as there is today on strengthening the faith of the simple through the depiction of infernal torments.\x{201d}",
          ],
          [
            1,
            '[12:00] The Name of the Rose - Umberto Eco.epub (index_split_042.html) - SEXT',
            '


    The Name of the Rose






<<SEXT|13>>',
          ],
          [
            1,
            '[ap 04:00] The Name of the Rose - Umberto Eco.epub (index_split_027.html) - four',
            "\x{201c}I know. First of all we have to know what Venantius meant by \x{2018}idolum.\x{2019} An image, a ghost, a figure? And then what can this \x{2018}<<four|9k:0>>\x{2019} be that has a \x{2018}first\x{2019} and a \x{2018}seventh\x{2019}? And what is to be done with them? Move them, push them, pull them?\x{201d}",
          ],
          [
            1,
            '[~ 09:00] The Name of the Rose - Umberto Eco.epub (index_split_049.html) - TERCE',
            '


    The Name of the Rose






<<TERCE|13>>',
          ],
          [
            1,
            '[> 15:00] The Name of the Rose - Umberto Eco.epub (index_split_013.html) - AFTER NONES',
            '


    The Name of the Rose






<<AFTER NONES|16>>',
          ],
          [
            1,
            '[~ 09:00] The Name of the Rose - Umberto Eco.epub (index_split_013.html) - terce',
            'As it appeared to my eyes, at that afternoon hour, it seemed to me a joyous workshop of learning. I saw later at St. Gall a scriptorium of similar proportions, also separated from the library (in other convents the monks worked in the same place where the books were kept), but not so beautifully arranged as this one. Antiquarians, librarians, rubricators, and scholars were seated, each at his own desk, and there was a desk under each of the windows. And since there were forty windows (a number truly perfect, derived from the decupling of the quadragon, as if the Ten Commandments had been multiplied by the four cardinal virtues), forty monks could work at the same time, though at that moment there were perhaps thirty. Severinus explained to us that monks working in the scriptorium were exempted from the offices of <<terce|13>>, <<sext|13>>, and nones so they would not have to leave their work during the hours of daylight, and they stopped their activity only at sunset, for <<vespers|13>>.',
          ],
          [
            1,
            '[> 18:00] The Name of the Rose - Umberto Eco.epub (index_split_008.html) - after compline',
            'During our time together we did not have occasion to lead a very regular life: even at the abbey we remained up at night and collapsed wearily during the day, nor did we take part regularly in the holy offices. On our journey, however, he seldom stayed awake <<after compline|13>>, and his habits were frugal. Sometimes, also at the abbey, he would spend the whole day walking in the vegetable garden, examining the plants as if they were chrysoprases or emeralds; and I saw him roaming about the treasure crypt, looking at a coffer studded with emeralds and chrysoprases as if it were a clump of thorn apple. At other times he would pass an entire day in the great hall of the library, leafing through manuscripts as if seeking nothing but his own enjoyment (while, around us, the corpses of monks, horribly murdered, were multiplying). One day I found him strolling in the flower garden without any apparent aim, as if he did not have to account to God for his works. In my order they had taught me quite a different way of expending my time, and I said so to him. And he answered that the beauty of the cosmos derives not only from unity in variety, but also from variety in unity. This seemed to me an answer dictated by crude common sense, but I learned subsequently that the men of his land often define things in ways in which it seems that the enlightening power of reason has scant function.',
          ],
        ];

    ## End
}





sub get_csv_tests {
    return [
          [
            1,
            'Timestr [00:00]: midnight',
            'As <<midnight|13>> was striking bronze blows upon the dusky air, Dorian Gray, dressed commonly, and with a muffler wrapped round his throat, crept quietly out of his house.'
          ],
          [
            1,
            'Timestr [00:00]: midnight',
            '"But wait till I tell you," he said. :We had a <<midnight|13>> lunch too after all the jollification and when we sallied forth it was blue o\'clock the morning after the night before"'
          ],
          [
            1,
            'Timestr [00:00]: midnight',
            '"<<Midnight|13>>," you said. What is <<midnight|13>> to the young? And suddenly a festive blaze was flung Across five cedar trunks, snow patches showed, And a patrol car on our bumpy road Came to a crunching stop. Retake, retake!'
          ],
          [
            1,
            'Timestr [00:00]: 12.00 pm',
            'That a man who could hardly see anything more than two feet away from him could be employed as a security guard suggested to me that our job was not to secure anything but to report for work every night, fill the bulky ledger with cryptic remarks like \'Patrolled perimeter <<12.00 pm|2a>>, No Incident\' and go to the office every fortnight for our wages and listen to the talkative Ms Elgassier.'
          ],
          [
            1,
            'Timestr [00:00]: midnight',
            '\'Tis the year\'s <<midnight|13>>, and it is the day\'s, Lucy\'s, who scarce seven hours herself unmasks; The sun is spent, and now his flasks Send forth light squibs, no constant rays;'
          ],
          [
            1,
            'Timestr [00:00]: midnight',
            'At <<midnight|9m>> his wife and daughter might still be bustling about, preparing holiday delicacies in the kitchen, straightening up the house, or perhaps getting their kimonos ready or arranging flowers. Oki would sit in the living room and listen to the radio. As the bells rang he would look back at the departing year. He always found it a moving experience.'
          ],
          [
            1,
            'Timestr [00:00]: midnight',
            'Big Ben concluded the run-up, struck and went on striking. (...) But, odder still - Big Ben had once again struck <<midnight|13>>. The time outside still corresponded to that registered by the stopped gilt clock, inside. Inside and outside matched exactly, but both were badly wrong. H\'m.'
          ],
          [
            1,
            'Timestr [00:00]: midnight',
            'But in the end I understood this language. I understood it, I understood it, all wrong perhaps. That is not what matters. It told me to write the report. Does this mean I am freer now than I was? I do not know. I shall learn. Then I went back into the house and wrote, It is <<midnight|9f>>. The rain is beating on the windows. It was not <<midnight|13>>. It was not raining.'
          ],
          [
            1,
            'Timestr [00:02]: after 0000h',
            'Cartridges not allowed <<after 0000h|1>>., to encourage sleep.'
          ],
          [
            1,
            'Timestr [00:00]: twelve',
            'Francisco. You come most carefully upon your hour. Bernardo. \'Tis now struck <<twelve|11>>. Get thee to bed, Francisco.'
          ],
          [
            1,
            'Timestr [00:00]: around 0000h',
            'Gately can hear the horns and raised voices and u-turn squeals way down below on Wash. That indicate it\'s <<around 0000h|1>>., the switching hour.'
          ],
          [
            -1,
            'Timestr [00:00]: twelve',
            'Hamlet: What hour now? Horatio: I think it lacks of <<twelve|99>>. Marcellus: No, it is struck.'
          ],
          [
            1,
            'Timestr [00:00]: midnight',
            'He is certain he heard footsteps: they come nearer, and then die away. The ray of light beneath his door is extinguished. It is <<midnight|9f>>; some one has turned out the gas; the last servant has gone to bed, and he must lie all night in agony with no one to bring him any help.'
          ],
          [
            1,
            'Timestr [00:00]: midnight',
            'I am conceived to the chimes of <<midnight|13>> on the clock on the mantelpiece in the room across the hall. The clock once belonged to my great-grandmother (a woman called Alice) and its tired chime counts me into the world.'
          ],
          [
            1,
            'Timestr [00:00]: twelve',
            'I took her hand in mine, and bid her be composed; for a succession of shudders convulsed her frame, and she would keep straining her gaze towards the glass. \'There\'s nobody here!\' I insisted. \'It was YOURSELF, Mrs. Linton: you knew it a while since.\' \'Myself!\' she gasped, \'and the clock is striking <<twelve|11>>! It\'s true, then! that\'s dreadful!\''
          ],
          [
            1,
            'Timestr [00:00]: midnight',
            'I was born in the city of Bombay ... On the stroke of <<midnight|12>>, as a matter of fact. Clock-hands joined palms in respectful greeting as I came. Oh, spell it out, spell it out: at the precise instant of India\'s arrival at independence, I tumbled forth into the world.'
          ],
          [
            1,
            'Timestr [00:00]: midnight',
            'It is <<midnight|9f>>. The rain is beating on the windows. I am calm. All is sleeping. Nevertheless I get up and go to my desk. I can\'t sleep. ...'
          ],
          [
            1,
            'Timestr [00:00]: midnight',
            'It was nearing <<midnight|13>> and the Prime Minister was sitting alone in his office, reading a long memo that was slipping through his brain without leaving the slightest trace of meaning behind.'
          ],
          [
            1,
            'Timestr [00:00]: midnight',
            '<<Midnight|13>> had come upon the crowded city. The palace, the night-cellar, the jail, the madhouse; the chambers of birth and death, of health and sickness; the rigid face of the corpse and the calm sleep of the child - <<midnight|13>> was upon them all.'
          ],
          [
            1,
            'Timestr [00:00]: midnight',
            '<<Midnight|13>> is approaching, and while the peak of activity has passed, the basal metabolism that maintains life continues undiminished, producing the basso continuo of the city\'s moan, a monotonous sound that neither rises or falls but is pregnant with foreboding.'
          ],
          [
            1,
            'Timestr [00:00]: midnight',
            'Once upon a <<midnight|13>> dreary, while I pondered weak and weary, Over many a quaint and curious volume of forgotten lore, While I nodded, nearly napping, suddenly there came a tapping, As of some one gently rapping, rapping at my chamber door. `\'Tis some visitor,\' I muttered, `tapping at my chamber door - Only this, and nothing more.\''
          ],
          [
            1,
            'Timestr [00:00]: twelve',
            'The clock striketh <<twelve|11>> O it strikes, it strikes! Now body, turn to air, Or Lucifer will bear thee quick to hell. O soul, be changed into little water drops, And fall into the ocean, ne\'er to be found. My God, my God, look not so fierce on me!'
          ],
          [
            1,
            'Timestr [00:00]: midnight',
            'The first night, as soon as the corporal had conducted my uncle Toby up stairs, which was <<about 10|9e>> - Mrs. Wadman threw herself into her arm chair, and crossing her left knee with her right, which formed a resting-place for her elbow, she reclin\'d her cheek upon the palm of her hand, and leaning forwards, ruminated until <<midnight|13>> upon both sides of the question.\''
          ],
          [
            1,
            'Timestr [00:00]: twelve o\'clock at night',
            'To begin my life with the beginning of my life, I record that I was born (as I have been informed an believe) on a Friday, at <<twelve o\'clock at night|6>>. It was remarked that the clock began to strike, and I began to cry, simultaneously.'
          ],
          [
            1,
            'Timestr [00:00]: midnight',
            'We have heard the chimes at <<midnight|13>>.'
          ],
          [
            1,
            'Timestr [00:01]: one minute past midnight',
            'With the appointed execution time of <<one minute past midnight|10>> just seconds away, I knocked on the metal door twice. The lock turned and the door swiftly swung open.'
          ],
          [
            1,
            'Timestr [00:02]: two minutes past midnight',
            '<<Two minutes past midnight|10>>. With me in the lead the fourteen other men of Teams Yellow, White and Red moved out of the clearing and separated for points along the wall where they would cross over into the grounds.'
          ],
          [
            1,
            'Timestr [00:03]: after twelve o\'clock',
            'It was <<after twelve o\'clock|6>> when Easton came home. Ruth recognised his footsteps before he reached the house, and her heart seemed to stop beating when she heard the clang of the gate, as it closed after he had passed through.'
          ],
          [
            1,
            'Timestr [00:03]: three minutes past midnight',
            'It was just <<three minutes past midnight|10>> when I last saw Archer Harrison alive. I remember, because I said it was two minutes past and he looked at his watch and said it was three minutes past.'
          ],
          [
            1,
            'Timestr [00:03]: Three minutes after midnight',
            "Suddenly I felt a great stillness in the air, then a snapping of tension. I glanced at my watch. <<Three minutes after midnight|10>>. I was breathing normally and my pen moved freely across the page. Whatever stalked me wasn\x{2019}t quite as clever as I\x{2019}d feared, I thought, careful not to pause in my work."
          ],
          [
            1,
            'Timestr [00:04]: four minutes past midnight',
            'At <<four minutes past midnight|10>>, January 22, Admiral Lowry\'s armada of more than 250 ships reached the transport area off Anzio. The sea was calm, the night was black.'
          ],
          [
            1,
            'Timestr [00:05]: 0005h',
            "E.M. Security, normally so scrupulous with their fucking trucks at <<0005h|1>>., is nowhere around, lending weight to yet another clich\x{e9}. If you asked Gately what he was feeling right this second he'd have no idea."
          ],
          [
            1,
            'Timestr [00:06]: six minutes past midnight',
            'At <<six minutes past midnight|10>>, death relieved the sufferer.'
          ],
          [
            1,
            'Timestr [00:07]: seven minutes after midnight',
            'It was <<seven minutes after midnight|10>>. The dog was lying on the grass in the middle of the lawn in front of Mrs Shears\' house. Its eyes were closed. It looked as if it was running on its side, the way dogs run when they think they are chasing a cat in a dream.'
          ],
          [
            1,
            'Timestr [00:08]: eight past midnight',
            '"Hour of the night!" exclaimed the priest; "it is day, not night, and the hour is <<eight past midnight|10>>!"'
          ],
          [
            1,
            'Timestr [00:09]: 12.09am',
            'At <<12.09am|2a>> on 18 October, the cavalcade had reached the Karsaz Bridge, still ten kilometres from her destination.'
          ],
          [
            1,
            'Timestr [00:10]: ten minutes past midnight',
            'It was at <<ten minutes past midnight|10>>. Three police cars, Alsations and a black maria arrive at the farmhouse. The farmer clad only in a jock-strap, refused them entry.'
          ],
          [
            1,
            'Timestr [00:11]: eleven minutes past midnight',
            'The first incendiaries to hit St Thomas\'s Hospital had splattered Riddell House at <<eleven minutes past midnight|10>>, from where a few hours earlier the Archbishop of Canterbury had given \'an inspiring address\'.'
          ],
          [
            1,
            'Timestr [00:12]: 0 Hours, 12 Minutes',
            'Clock time is <<0 Hours, 12 Minutes|14>>, 0 Seconds. Twenty three minutes later, they have their first sight of Venus. Each lies with his Eye clapp\'d to the Snout of an identical two and a half foot Gregorian reflector made by Mr Short, with Darkening-Nozzles by Mr Bird.'
          ],
          [
            1,
            'Timestr [00:12]: twelve minutes past midnight',
            'It was <<twelve minutes past midnight|10>> when mother and daughter saw the first lightning strike. It hit the main barn with such force the ground trembled under their feet.'
          ],
          [
            1,
            'Timestr [00:14]: fourteen minutes past midnight',
            'It was exactly <<fourteen minutes past midnight|10>> when he completed the final call. Among the men he had reched were honourable men. Their voices would be heard by the President.'
          ],
          [
            1,
            'Timestr [00:15]: twelve-fifteen',
            'At <<twelve-fifteen|9m>> he got out of the van. He tucked the pistol under the waistband of his trousers and crossed the silent, deserted street to the Hudston house.'
          ],
          [
            1,
            'Timestr [00:15]: twelve-fifteen',
            'At <<twelve-fifteen|9m>> he got out of the van. He tucked the pistol under the waistband of his trousers and crossed the silent, deserted street to the Hudston house. He let himself through an unlocked wooden gate onto a side patio brightened only by moonlight filtered through the leafy branches of an enormous sheltering coral tree. He paused to pull on a pair of supple leather gloves.'
          ],
          [
            1,
            'Timestr [00:16]: sixteen minutes past midnight',
            'At <<sixteen minutes past midnight|10>>, Block 4 was hit and the roof set alight.'
          ],
          [
            1,
            'Timestr [00:17]: seventeen minutes after twelve',
            'Kava ordered two glasses of coffee for himself and his beloved and some cake. When the pair left, exactly <<seventeen minutes after twelve|10>>, the club began to buzz with excitement.'
          ],
          [
            1,
            'Timestr [00:18]: 12.18am',
            "21st December 1985, <<12.18am|2a>> [In bed] Michael doesn\x{2019}t believe in Heaven or Hell. He\x{2019}s got closer to death than most living people and he tells me there was no tunnel of light or dancing angels. I\x{2019}m a bit disappointed, to be honest."
          ],
          [
            1,
            'Timestr [00:20]: twelve-twenty',
            'Now she was kneading the little ball of hot paste on the convex margin of the bowl and I could smell the opium. There is no smell like it. Beside the bed the alarm-clock showed <<twelve-twenty|11>>, but already my tension was over. Pyle had diminished.'
          ],
          [
            1,
            'Timestr [00:21]: 12.21am',
            'Nobody had been one of Mycroft Ward\'s most important operatives and for sixty seconds every day, between <<12.21am|2a>> and <<12.22am|2a>>., his laptop was permitted to connect directly with the gigantic online database of self that was Mycroft Ward\'s mind.'
          ],
          [
            1,
            'Timestr [00:22]: 12.22am',
            'Nobody had been one of Mycroft Ward\'s most important operatives and for sixty seconds every day, between <<12.21am|2a>> and <<12.22am|2a>>., his laptop was permitted to connect directly with the gigantic online database of self that was Mycroft Ward\'s mind.'
          ],
          [
            1,
            'Timestr [00:23]: twenty-three minutes past midnight',
            "Oskar weighed the wristwatch in his hand, then gave the rather fine piece with its luminous dial showing <<twenty-three minutes past midnight|10>> to little Pinchcoal. He looked up inquiringly at his chief. St\x{f6}rtebeker nodded his assent. And Oskar said, as he adjusted his drum snugly for the trip home: 'Jesus will lead the way. Follow thou me!'"
          ],
          [
            1,
            'Timestr [00:24]: 12.24am',
            'Sanders with Sutton as his gunner began their patrol at <<12.24am|2a>>, turning south towards Beachy Head at 10,000 ft.'
          ],
          [
            1,
            'Timestr [00:25]: five-and-twenty minutes past midnight',
            'Charlotte remembered that she had heard Gregoire go downstairs again, almost immediately after entering his bedroom, and before the servants had even bolted the house-doors for the night. He had certainly rushed off to join Therese in some coppice, whence they must have hurried away to Vieux-Bourg station which the last train to Paris quitted at <<five-and-twenty minutes past midnight|10>>. And it was indeed this which had taken place.'
          ],
          [
            1,
            'Timestr [00:25]: twenty-five past midnight',
            'I mean, look at the time! <<Twenty-five past midnight|10>>! It was a triumph, it really was!'
          ],
          [
            1,
            'Timestr [00:26]: 12.26am',
            '"A Mr Dutta from King\'s Cross called and told me you were on your way. He said you wanted to see the arrival of yesterday\'s <<12.26am|2a>>. It\'ll take me a few minutes to cue up the footage. Our regular security bloke isn\'t here today; he\'s up before Haringey Magistrates\' Court for gross indecency outside the headquarters of the Dagenham Girl Pipers."'
          ],
          [
            1,
            'Timestr [00:28]: 12.28',
            'The DRINK CHEER-UP COFFEE wall clock read <<12.28|11>>.'
          ],
          [
            1,
            'Timestr [00:29]: twenty-nine minutes past twelve',
            "\"What time is it?\" asked Teeny-bits. The station agent hauled out his big silver watch, looked at it critically and announced: \"<<Twenty-nine minutes past twelve|10>>.\x{201d} \x{201c}<<Past twelve|9:1>>!\" repeated Teeny-bits. \"It can't be.\""
          ],
          [
            1,
            'Timestr [00:30]: half-past twelve',
            'It was <<half-past twelve|10>> when I returned to the Albany as a last desperate resort. The scene of my disaster was much as I had left it. The baccarat-counters still strewed the table, with the empty glasses and the loaded ash-trays. A window had been opened to let the smoke out, and was letting in the fog instead.'
          ],
          [
            1,
            'Timestr [00:31]: 00:31',
            'Third individual approaches unnoticed and without caution. Once within reach, individual reaches out toward subjects. Recording terminates: timecode: <<00:31|2>>:02.'
          ],
          [
            1,
            'Timestr [00:32]: thirty-two minutes past midnight',
            '<<Thirty-two minutes past midnight|10>>; the way things were going I could be at it all night. Before beginning a completely new search of the dial I had a thought: maybe this safe didn\'t open on zero as older models did, but on a factory-set number.'
          ],
          [
            1,
            'Timestr [00:33]: thirty-three minutes past midnight',
            '"So that at <<twelve-thirty-three|5b>> you bolted the south door?" "Yes," replied Stephen Maxie easily. "At <<thirty-three minutes past midnight|10>>."'
          ],
          [
            1,
            'Timestr [00:34]: thirty-four minutes past midnight',
            '<<Thirty-four minutes past midnight|10>>. \'We got ten minutes to be back here.\' LT didn\'t argue. Schoolboy knew his former trade. LT\'s eyes fretted over the museum. \'Not still worrying about the security, are you, because there ain\'t none.\''
          ],
          [
            1,
            'Timestr [00:40]: twenty to one',
            'We sat in the car park till <<twenty to one|10>>/ And now I\'m engaged to Miss Joan Hunter Dunn.'
          ],
          [
            1,
            'Timestr [00:42]: eighteen minutes to one',
            'The butt had been growing warm in her fingers; now the glowing end stung her skin. She crushed the cigarette out and stood, brushing ash from her black skirt. It was <<eighteen minutes to one|10>>. She went to the house phone and called his room. The telephone rang and rang, but there was no answer.'
          ],
          [
            1,
            'Timestr [00:43]: twelve-forty-three',
            'Died five minutes ago, you say? he asked. His eye went to the watch on his wrist. <<Twelve-forty-three|9j>>, he wrote on the blotter.'
          ],
          [
            1,
            'Timestr [00:45]: 12.45',
            'At <<12.45|9e>>, during a lull, Mr Yoshogi told me that owing to the war there were now many more women in England than men.'
          ],
          [
            1,
            'Timestr [00:45]: third quarter after midnight',
            'At the thought he jumped to his feet and took down from its hook the coat in which he had left Miss Viner\'s letter. The clock marked the <<third quarter after midnight|10>>, and he knew it would make no difference if he went down to the post-box now or early the next morning; but he wanted to clear his conscience, and having found the letter he went to the door.'
          ],
          [
            1,
            'Timestr [00:47]: 12:47a.m',
            'At <<12:47a.m|2a>>, Uncle Ho left us forever.'
          ],
          [
            1,
            'Timestr [00:50]: 12.50',
            'The packing was done at <<12.50|9c:0>>; and Harris sat on the big hamper, and said he hoped nothing would be found broken. George said that if anything was broken it was broken, which reflection seemed to comfort him. He also said he was ready for bed.'
          ],
          [
            1,
            'Timestr [00:54]: six minutes to one',
            "Everybody was happy; everybody was complimentary; the ice was soon broken; songs, anecdotes, and more drinks followed, and the pregnant minutes flew. At <<six minutes to one|10>>, when the jollity was at its highest\x{2014} BOOM! There was silence instantly."
          ],
          [
            1,
            'Timestr [00:55]: five to one in the morning',
            'He rolled one way, rolled the other, listened to the loud tick of the clock, and was asleep a minute later. <<Five to one in the morning|10>>. Fifty-one hours to go.'
          ],
          [
            1,
            'Timestr [00:56]: 12:56 A.M.',
            'It was <<12:56 A.M.|2a>> when Gerald drove up onto the grass and pulled the limousine right next to the cemetery.'
          ],
          [
            1,
            'Timestr [00:56]: 12:56',
            'Teacher used to lie awake at night facing that clock, batting his eyelashes against his pillowcase to mimic the sound of the rolling drop action. One night, and this first night is lost in the countless later nights of compounding wonder, he discovered a game. Say the time was <<12:56|2>>.'
          ],
          [
            1,
            'Timestr [00:57]: 12:57',
            'A minute had passed, and the roller dropped a new leaf. <<12:57|2>>. 12 + 57 = 69; 6 + 9 = 15; 1 + 5 = 6. 712 + 5 = 717; 71 + 7 = 78; 7 + 8 = 15; 1 + 5 = 6 again.'
          ],
          [
            1,
            'Timestr [00:58]: almost at one in the morning',
            'It was downright shameless on his part to come visiting them, especially at night, <<almost at one in the morning|9h>>, after all that had happened.'
          ],
          [
            1,
            "Timestr [00:59]: About one o\x{2019}clock",
            "\x{2018}What time is it now?\x{2019} she said. \x{2018}<<About one o\x{2019}clock|6>>\x{2019}. \x{2018}In the morning?\x{2019} Herera\x{2019}s friend leered at her. \x{2018}No, there\x{2019}s a total eclipse of the sun\x{2019}."
          ],
          [
            1,
            'Timestr [01:00]: 1.00 am',
            '<<1.00 am|2a>>. I felt the surrounding quietness suffocating me.'
          ],
          [
            1,
            "Timestr [01:00]: one o\x{2019}clock",
            "He didn\x{2019}t know what was at the end of the chute. The opening was narrow (though large enough to take the canary). He dreamed that the chute opened onto vast garbage bins filled with old coffee filters, ravioli in tomato sauce and mangled genitalia. Huge worms, as big as the canary, armed with terrible beaks, would attack the body. Tear off the feet, rip out its intestines, burst the eyeballs. He woke up, trembling; it was only <<one o\x{2019}clock|6>>. He swallowed three Xanax. So ended his first night of freedom."
          ],
          [
            1,
            'Timestr [00:58]: nearly one o\'clock',
            'I looked attentively at her, as she put that singular question to me. It was then <<nearly one o\'clock|6>>. All I could discern distinctly by the moonlight was a colourless, youthful face, meagre and sharp to look at about the cheeks and chin; large, grave, wistfully attentive eyes; nervous, uncertain lips; and light hair of a pale, brownish-yellow hue.'
          ],
          [
            1,
            'Timestr [01:00]: one in the morning',
            'I\'m the only one awake in this house on this night before the day that will change all our lives. Though it\'s already that day: the little luminous hands on my alarm clock (which I haven\'t set) show just gone <<one in the morning|5>>.'
          ],
          [
            1,
            'Timestr [01:00]: One am',
            'It was the thirtieth of May by now. <<One am|5>> on the thirtieth of May 1940. Quite a famous date on which to be lying awake and staring at the ceiling. Already in the creeks and tidal estuaries of England the pleasure-boats and paddle-steamers were casting their moorings for the day trip to Dunkirk. And, over on the other side, Ted stood as a good a chance as anyone else.'
          ],
          [
            1,
            'Timestr [01:00]: one',
            'Last night of all, When yon same star that\'s westward from the pole Had made his course t\'illume that part of heaven Where now it burns, Marcellus and myself, The bell then beating <<one|11>> -'
          ],
          [
            1,
            'Timestr [01:00]: one o\'clock in the morning',
            'The station was more crowded than he had expected to find it at - what was it? he looked up at the clock - <<one o\'clock in the morning|6>>. What in the name of God was he doing on King\'s Cross station at <<one o\'clock in the morning|6>>, with no cigarette and no home that he could reasonably expect to get into without being hacked to death by a homicidal bird?'
          ],
          [
            1,
            "Timestr [01:01]: About one o\x{2019}clock",
            "\x{2018}What time is it now?\x{2019} she said. \x{2018}<<About one o\x{2019}clock|6>>\x{2019}. \x{2018}In the morning?\x{2019} Herera\x{2019}s friend leered at her. \x{2018}No, there\x{2019}s a total eclipse of the sun\x{2019}."
          ],
          [
            1,
            'Timestr [01:06]: 1:06',
            'When he woke it was <<1:06|2>> by the digital clock on the bedside table. He lay there looking at the ceiling, the raw glare of the vaporlamp outside bathing the bedroom in a cold and bluish light. Like a winter moon.'
          ],
          [
            1,
            'Timestr [01:08]: 1.08a.m.',
            'It was <<1.08a.m.|2a>> but he had left the ball at the same time as I did, and had further to travel.'
          ],
          [
            1,
            'Timestr [01:09]: nine minutes past one o\'clock in the morning',
            'They made an unostentatious exit from their coach, finding themselves, when the express had rolled on into the west, upon a station platform in a foreign city at <<nine minutes past one o\'clock in the morning|10>> - but at length without their shadow.'
          ],
          [
            1,
            'Timestr [01:10]: 1.10am',
            'February 26, Saturday - Richards went out <<1.10am|2a>> and found it clearing a bit, so we got under way as soon as possible, which was <<2:10a.m.|2a>>'
          ],
          [
            -1,
            'Timestr [01:11]: nearer to one than half past',
            'Declares one of the waiters was the worse for liquor, and that he was giving him a dressing down. Also that it was <<nearer to one than half past|99>>.'
          ],
          [
            1,
            'Timestr [01:12]: 1:12am',
            'It was <<1:12am|2a>> when Father arrived at the police station. I did not see him until <<1:28am|2a>> but I knew he was there because I could hear him. He was shouting, \'I want to see my son,\' and \'Why the hell is he locked up?\' and, \'Of course I\'m bloody angry.\''
          ],
          [
            1,
            'Timestr [01:15]: about a quarter past one o\'clock in the morning',
            'I am sorry, therefore, as I have said, that I ever paid any attention to the footsteps. They began <<about a quarter past one o\'clock in the morning|10>>, a rhythmic, quick-cadenced walking around the dining-room table.'
          ],
          [
            1,
            'Timestr [01:15]: 1.15am',
            'Lily Chen always prepared an \'evening\' snack for her husband to consume on his return at <<1.15am|2a>>.'
          ],
          [
            1,
            'Timestr [01:15]: about a quarter past one o\'clock in the morning',
            'The ghost that got into our house on the night of November 17, 1915, raised such a hullabaloo of misunderstandings that I am sorry I didn\'t just let it keep on walking, and go to bed. Its advent caused my mother to throw a shoe through a window of the house next door and ended up with my grandfather shooting a patrolman. I am sorry, therefore, as I have said, that I ever paid any attention to the footsteps. They began <<about a quarter past one o\'clock in the morning|10>>, a rhythmic, quick-cadenced walking around the dining-room table.'
          ],
          [
            1,
            'Timestr [01:16]: sixteen past one',
            'At <<sixteen past one|10>>, they walked into the interview room.'
          ],
          [
            1,
            'Timestr [01:16]: 1.16am',
            'From <<1am|5>> to <<1.16am|2a>> vouched for by other two conductors.'
          ],
          [
            1,
            'Timestr [01:17]: seventeen minutes past one in the morning',
            'At that moment (it was <<seventeen minutes past one in the morning|10>>) Lieutenant Bronsfield was preparing to leave the watch and return to his cabin, when his attention was attracted by a distant hissing noise.'
          ],
          [
            1,
            'Timestr [01:17]: 1:17',
            'The clocks stopped at <<1:17|2>>. A long shear of light and then a series of low concussions. He got up and went to the window. What is it? she said. He didnt answer. He went into the bathroom and threw the lightswitch but the power was already gone. A dull rose glow in the windowglass. He dropped to one knee and raised the lever to stop the tub and then turned on both taps as far as they would go. She was standing in the doorway in her nightwear, clutching the jamb, cradling her belly in one hand. What is it? she said. What is happening?'
          ],
          [
            1,
            'Timestr [01:20]: twenty minutes past one o\'clock in the morning',
            '"Well!" she said, looking like a minor female prophet about to curse the sins of the people. "May I trespass on your valuable time long enough to ask what in the name of everything bloodsome you think you\'re playing at, young piefaced Bertie? It is now some <<twenty minutes past one o\'clock in the morning|10>>, and not a spot of action on your part."'
          ],
          [
            1,
            'Timestr [01:20]: 1.20am',
            'Then it was <<1.20am|2a>>, but I hadn\'t heard Father come upstairs to bed. I wondered if he was asleep downstairs or whether he was waiting to come in and kill me. So I got out my Swiss Army Knife and opened the saw blade so that I could defend myself.'
          ],
          [
            1,
            'Timestr [01:22]: 1:22',
            'It was <<1:22|2>> when we found Dad\'s grave.'
          ],
          [
            1,
            'Timestr [01:23]: twenty-three minutes past one',
            'The clock marked <<twenty-three minutes past one|10>>. He was suddenly full of agitation, yet hopeful. She had come! Who could tell what she would say? She might offer the most natural explanation of her late arrival.'
          ],
          [
            1,
            'Timestr [01:24]: 1.24am',
            'Larkin had died at <<1.24am|2a>>, turning to the nurse who was with him, squeezing her hand, and saying faintly, \'I am going to the inevitable.\''
          ],
          [
            1,
            'Timestr [01:25]: twenty-five minutes past one o\'clock',
            'He made a last effort; he tried to rise, and sank back. His head fell on the sofa cushions. It was then <<twenty-five minutes past one o\'clock|10>>.'
          ],
          [
            1,
            'Timestr [01:26]: one twenty-six A.M.',
            'When I reached the stop and got off, it was already <<one twenty-six A.M.|5>> by the bus\'s own clock. I had been gone over ten hours.'
          ],
          [
            1,
            'Timestr [01:27]: twenty-seven minutes past one',
            'At <<twenty-seven minutes past one|10>> she felt as if she was levitating out of her body.'
          ],
          [
            1,
            'Timestr [01:28]: 1:28 am',
            'It was <<1:12 am|2a>> when Father arrived at the police station. I did not see him until <<1:28 am|2a>> but I knew he was there because I could hear him. He was shouting, \'I want to see my son,\' and \'Why the hell is he locked up?\' and, \'Of course I\'m bloody angry.\''
          ],
          [
            1,
            'Timestr [01:29]: one-twenty-nine A.M.',
            'He exited the men\'s room at <<one-twenty-nine A.M.|5>>'
          ],
          [
            1,
            'Timestr [01:30]: half-past one',
            "\"<<Half-past one|10>>\x{201d}, The street lamp sputtered, The street lamp muttered, The street lamp said, \"Regard that woman ...\""
          ],
          [
            1,
            'Timestr [01:30]: Around 1:30 A.M.',
            '<<Around 1:30 A.M.|2a>> the door opened and I thought it was Karla, but it was Bug, saying Karla and Laura had gone out for a stag night after they ran out of paint.'
          ],
          [
            1,
            'Timestr [01:30]: one thirty in the morning',
            'The late hour helped. It simplified things. It categorized the population. Innocent bystanders were mostly home in bed. I walked for half an hour, but nothing happened. Until <<one thirty in the morning|5>>. Until I looped around to 22nd and Broadway.'
          ],
          [
            1,
            'Timestr [01:30]: 1:30 a.m.',
            'The radio alarm clock glowed <<1:30 a.m.|2a>> Bad karaoke throbbed through walls. I was wide awake, straightjacketed by my sweaty sheets. A headache dug its thumbs into my temples. My gut pulsed with gamma interference: I lurched to the toilet.'
          ],
          [
            1,
            'Timestr [01:32]: one-thirty-two',
            'She grinned at him with malicious playfulness, showing great square teeth, and then ran for the stairs. <<One-thirty-two|9j>>. She thought that she heard a whistle blown and took the last three steps in one stride.'
          ],
          [
            1,
            'Timestr [01:33]: one-thirty-three a.m.',
            'He looked at his watch. <<One-thirty-three a.m.|5>> He had been asleep on this bench for over an hour and a half.'
          ],
          [
            1,
            'Timestr [01:38]: one-thirty-eight am',
            'At <<one-thirty-eight am|5>> suspect left the Drive-In and drove to seven hundred and <<twenty three|5a:0>> North Walnut, to the rear of the residence, and parked the car.'
          ],
          [
            1,
            'Timestr [01:40]: one-forty am',
            'March twelfth, <<one-forty am|5>>, she leaves a group of drinking buddies to catch a bus home. She never makes it.'
          ],
          [
            1,
            'Timestr [01:44]: sixteen minutes to two',
            'She knew it was the stress, two long days of stress, and she looked at her watch, <<sixteen minutes to two|10>>, and she almost leaped with fright, a shock wave rippling through her body, where had the time gone?'
          ],
          [
            1,
            'Timestr [01:46]: one forty-six a.m.',
            'That particular phenomenom got Presto up at <<one forty-six a.m.|5>>; silently, he painted his face and naked body with camouflage paint. He opened the door to his room and stepped out into the common lobby.'
          ],
          [
            1,
            'Timestr [01:50]: ten minutes before two AM',
            "No, she thought: every spinster legal secretary, bartender, and orthodontist had a cat or two\x{2014}and she could not tolerate (not even as a lark, not even for a moment at <<ten minutes before two AM|10>>), embodying clich\x{e9}."
          ],
          [
            1,
            'Timestr [01:51]: nine minutes to two',
            'At <<nine minutes to two|10>> the other vehicle arrived. At first Milla didn\'t believe her eyes: that shape, those markings.'
          ],
          [
            1,
            'Timestr [01:54]: six minutes to two',
            '<<Six minutes to two|10>>. Janina Mentz watched the screen, where the small program window flickered with files scrolling too fast to read, searching for the keyword.'
          ],
          [
            1,
            'Timestr [02:00]: About two',
            '"The middle of the night?" Alec asked sharply."Can you be more definite?" "<<About two|9:0>>. Just past." Daisy noted that he expressed no concern for her safety.'
          ],
          [
            1,
            'Timestr [02:00]: two o\'clock',
            'As <<two o\'clock|6>> pealed from the cathedral bell, Jean Valjean awoke.'
          ],
          [
            1,
            'Timestr [02:00]: 2 A.M.',
            'Get on plane at <<2 A.M.|5>>, amid bundles, chickens, gypsies, sit opposite pair of plump fortune tellers who groan and (very discreetly) throw up all the way to Tbilisi.'
          ],
          [
            1,
            'Timestr [02:00]: two',
            "Lady Macbeth: Out, damned spot! out, I say!\x{2014}One: <<two|9k:0>>: why, then, 'tis time to do't.\x{2014}Hell is murky!\x{2014}Fie, my lord, fie! a soldier, and afeard? What need we fear who knows it, when none can call our power to account?\x{2014}Yet who would have thought the old man to have had so much blood in him."
          ],
          [
            1,
            'Timestr [02:00]: two',
            'Somewhere behind a screen a clock began wheezing, as though oppressed by something, as though someone were strangling it. After an unnaturally prolonged wheezing there followed a shrill, nasty, and as it were unexpectedly rapid, chime - as though someone were suddenly jumping forward. It struck <<two|11>>. I woke up, though I had indeed not been asleep but lying half-conscious.'
          ],
          [
            1,
            'Timestr [02:00]: around two o\'clock',
            'When all had grown quiet and Fyodor Pavlovich went to bed at <<around two o\'clock|6>>, Ivan Fyodorovich also went to bed with the firm resolve of falling quickly asleep, as he felt horribly exhausted.\''
          ],
          [
            1,
            'Timestr [02:01]: 2.01am',
            'I checked my watch. <<2.01am|2a>>. The cheeseburger Happy Meal was now only a distant memory. I cursed myself for not also ordering a breakfast sandwich for the morning.'
          ],
          [
            1,
            'Timestr [02:02]: almost 2:04',
            "\"Wake up.\" \"Having the worst dream.\" \"I should certainly say you were.\" \"It was awful. It just went on and on.\" \"I shook you and shook you and.\" \"Time is it.\" \"It's nearly - <<almost 2:04|2>>.\x{201d}"
          ],
          [
            1,
            'Timestr [02:04]: almost 2:04',
            "\"Wake up.\" \"Having the worst dream.\" \"I should certainly say you were.\" \"It was awful. It just went on and on.\" \"I shook you and shook you and.\" \"Time is it.\" \"It's nearly - <<almost 2:04|2>>.\x{201d}"
          ],
          [
            1,
            'Timestr [02:05]: 2.05',
            'At <<2.05|9m>> the fizzy tights came crackling off.'
          ],
          [
            1,
            'Timestr [02:05]: five minutes past two',
            "Then he began ringing the bell. In about ten minutes his valet appeared, half dressed, and looking very drowsy. \x{2018}I am sorry to have had to wake you up, Francis,\x{2019} he said, stepping in; \x{2018}but I had forgotten my latch-key. What time is it?\x{2019} \x{2018}<<Five minutes past two|10>>, sir,\x{2019} answered the man, looking at the clock and yawning. \x{2018}<<Five minutes past two|10>>? How horribly late! You must wake me at <<nine|9a>> to-morrow. I have some work to do.\x{2019}"
          ],
          [
            1,
            'Timestr [02:07]: 2:07 a.m.',
            'At <<2:07 a.m.|2a>> I decided that I wanted a drink of orange squash before I brushed my teeth and got into bed, so I went downstairs to the kitchen. Father was sitting on the sofa watching snooker on the television and drinking whisky. There were tears coming out of his eyes.'
          ],
          [
            1,
            'Timestr [02:07]: 2.07 am',
            'But I couldn\'t sleep. And I got out of bed at <<2.07 am|2a>> and I felt scared of Mr. Shears so I went downstairs and out of the front door into Chapter Road.'
          ],
          [
            1,
            'Timestr [02:07]: 2.07 a.m.',
            "Saturday, 17 November \x{2014} <<2.07 a.m.|2a>> I cannot sleep. Ben is upstairs, back in bed, and I am writing this in the kitchen. He thinks I am drinking a cup of cocoa that he has just made for me. He thinks I will come back to bed soon. I will, but first I must write again."
          ],
          [
            1,
            'Timestr [02:10]: ten minutes past two',
            "\x{201c}<<Ten minutes past two|10>>, sir,\" answered the man, looking at the clock and blinking. \"<<Ten minutes past two|10>>? How horribly late! ..\x{201d}"
          ],
          [
            1,
            'Timestr [02:10]: 2:10am',
            'Decided to get under way again as soon as there is any clearance. Snowing and blowing, force about fifty or sixty miles an hour. February 26, Saturday - Richards went out <<1:10am|2a>> and found it clearing a bit, so we got under way as soon as possible, which was <<2:10am|2a>>'
          ],
          [
            1,
            'Timestr [02:12]: 2.12am',
            'Then the lights went out all over the city. It happened at <<2.12am|2a>> according to power-house records, but Blake\'s diary gives no indication of the time. The entry is merely, \'Lights out - God help me.\''
          ],
          [
            1,
            'Timestr [02:13]: 02.13',
            'Now, listen: your destination is Friday, 4 August 1944, and the window will punch through at <<22.30 hours|1>>. You\'re going to a dimension that diverged from our own at <<02.13|3b>> on the morning of Wednesday 20 February 1918, over twenty-six years earlier. You don\'t know what it\'s going to be like...'
          ],
          [
            1,
            'Timestr [02:15]: 2.15am',
            'At <<2.15am|2a>> a policeman observed the place in darkness, but with the stranger\'s motor still at the curb.'
          ],
          [
            1,
            'Timestr [02:15]: two fifteen',
            'It did. When the alarm rang at <<two fifteen|5b>>, Lew shut it off, snapped on the little bedside lamp, then swung his feet to the floor to sit on the edge of the bed, holding his eyes open.'
          ],
          [
            1,
            'Timestr [02:17]: two-seventeen',
            '"What time is it now?" He turned her very dusty alarm clock to check. "<<Two-seventeen|9j>>," he marveled. It was the strangest time he\'d seen in his entire life. "I apologize that the room is so messy," Lalitha said. "I like it. I love how you are. Are you hungry? I\'m a little hungry." "No, Walter." She smiled. "I\'m not hungry. But I can get you something." "I was thinking, like, a glass of soy milk. Soy beverage."'
          ],
          [
            1,
            'Timestr [02:17]: 2.17',
            'One of the "choppers" stopped, did an about-turn and came back to me. The flare spluttered and faded, and now the glare of the spotlight blinded me. I sat very still. It was <<2.17|9f>>. Against the noise of the blades a deeper resonant sound bit into the chill black air.'
          ],
          [
            1,
            'Timestr [02:18]: 2:18 in the morning',
            'It was <<2:18 in the morning|2a>>, and Donna could see no one else in any other office working so late.'
          ],
          [
            1,
            'Timestr [02:20]: two-twenty',
            'She turned abruptly to the nurse and asked the time. \'<<Two-twenty|9j>>\' \'Ah...<<Two-twenty|5a:0>>!\' Genevieve repeated, as though there was something urgent to be done.'
          ],
          [
            1,
            'Timestr [02:20]: two twenty',
            'The night of his third walk Lew slept in his own apartment. When his eyes opened at <<two twenty|5b>>, by the green hands of his alarm, he knew that this time he\'d actually been waiting for it in his sleep.'
          ],
          [
            1,
            'Timestr [02:21]: 2:21 a.m.',
            '<<2:21 a.m.|2a>> Lance-Corporal Hartmann emerged from the house in the Rue de Londres.'
          ],
          [
            1,
            'Timestr [02:21]: two-twenty-one',
            'It was the urge to look up at the sky. But of course there was no sun nor moon nor stars overhead. Darkness hung heavy over me. Each breath I took, each wet footstep, everything wanted to slide like mud to the ground. I lifted my left hand and pressed on the light of my digital wristwatch. <<Two-twenty-one|9j>>. It was <<midnight|9d>> when we headed underground, so only a little over two hours had passed. We continued walking down, down the narrow trench, mouths clamped tight.'
          ],
          [
            1,
            'Timestr [02:24]: 2.24am',
            "It was <<2.24am|2a>>. She stumbled out of bed, tripping on her shoes that she\x{2019}d kicked off earlier and pulled on a jumper."
          ],
          [
            1,
            'Timestr [02:25]: 2.25am',
            'You see it is time: <<2.25am|2a>>. You get out of bed.'
          ],
          [
            1,
            'Timestr [02:26]: 2.26am',
            'Listened to a voicemail message left at <<2.26am|2a>> by Claude.'
          ],
          [
            1,
            'Timestr [02:27]: 2.27am',
            "The moon didn\x{2019}t shine again until <<2.27am|2a>>. It was enough to show Wallander that he was positioned some distance below the tree."
          ],
          [
            1,
            'Timestr [02:28]: 2.28am',
            '<<2.28am|2a>>: Ran out of sheep and began counting other farmyard animals.'
          ],
          [
            1,
            'Timestr [02:30]: 2:30 a.m.',
            '"Get into the mood, Shirl!" Lew said. "The party\'s already started! Yippee! You dressed for a party, Harry?" "Yep. Something told me to put on dinner clothes when I went to bed tonight." "I\'m in mufti myself: white gloves and matching tennis shoes. But I\'m sorry to report that Jo is still in her Dr. Dentons. What\'re you wearing, Shirl?" "My old drum majorette\'s outfit. The one I wore to the State Finals. Listen, we can\'t tie up the phones like this." "Why not?" said Harry. "Who\'s going to call at <<2:30 a.m.|2a>> with a better idea? Yippee, to quote Lew, we\'re having a party! What\'re we serving, Lew?" "Beer, I guess. Haven\'t got any wine, have we, Jo?" "Just for cooking."'
          ],
          [
            1,
            'Timestr [02:30]: about half past two',
            'At <<about half past two|10>> she had been woken by the creak of footsteps out on the stairs. At first she had been frightened.'
          ],
          [
            -1,
            'Timestr [02:30]: 0230',
            "Inc, I tried to pull her off about <<0230|99>>, and there was this fucking\x{2026} sound."
          ],
          [
            1,
            'Timestr [02:30]: 2.30am',
            'It is <<2.30am|2a>> and I am tight. As a tick, as a lord, as a newt. Must write this down before the sublime memories fade and blur.'
          ],
          [
            1,
            'Timestr [02:31]: 2.31am',
            'And then I woke up because there were people shouting in the flat and it was <<2.31am|2a>>. And one of the people was Father and I was frightened.'
          ],
          [
            1,
            'Timestr [02:32]: 2.32 a.m.',
            'The last guests departed at <<2.32 a.m.|2a>>, two hours and two minutes after the scheduled completion time.'
          ],
          [
            1,
            'Timestr [02:33]: two-thirty-three',
            'But it wasn\'t going on! It was <<two-thirty-four|9f>>, well. <<Two-thirty-three|5a:0>> and nothing had happened. Suppose he got a room call, or the elevator night-bell rang, now.'
          ],
          [
            1,
            'Timestr [02:34]: two-thirty-four',
            'But it wasn\'t going on! It was <<two-thirty-four|9f>>, well. <<Two-thirty-three|5a:0>> and nothing had happened. Suppose he got a room call, or the elevator night-bell rang, now.'
          ],
          [
            1,
            'Timestr [02:35]: 2.35',
            'For what happened at <<2.35|3:0>> we have the testimony of the priest, a young, intelligent, and well-educated person; of Patrolman William J. Monohan of the Central Station, an officer of the highest reliability who had paused at that part of his beat to inspect the crowd.'
          ],
          [
            1,
            'Timestr [02:36]: about 2.36am',
            'It was <<about 2.36am|2a>> when a provost colonel arrived to arrest me. At <<2.36|9m>> 1/2 I remembered the big insulating gauntlets. But even had I remembered before, what could I have done?'
          ],
          [
            1,
            'Timestr [02:37]: thirty-seven minutes past two in the morning',
            'June 13, 1990. <<Thirty-seven minutes past two in the morning|10>>. And sixteen seconds.'
          ],
          [
            1,
            'Timestr [02:43]: 2:43',
            'She settled back beside him. \'It\'s <<2:43|2a>>:12am, Case. Got a readout chipped into my optic nerve.\''
          ],
          [
            1,
            'Timestr [02:45]: 0245h',
            '<<0245h|1>>., Ennet House, the hours that are truly wee.'
          ],
          [
            1,
            'Timestr [02:46]: 2.46am',
            '<<2.46am|2a>>. The chain drive whirred and the paper target slid down the darkened range, ducking in and out of shafts of yellow incandescent light. At the firing station, a figure waited in the shadows. As the target passed the twenty-five-foot mark, the man opened fire: eight shots-rapid, unhesitating.'
          ],
          [
            1,
            'Timestr [02:46]: two forty-six',
            'Vicki shoved her glasses at her face and peered at the clock. <<Two forty-six|9j>>. \'I don\'t have time for this\' she muttered, sttling back against the pillows, heart still slamming against her ribs.'
          ],
          [
            1,
            'Timestr [02:47]: 2.47am',
            "The glowing numbers read <<2.47am|2a>>. Mois\x{e9}s sighs and turns back to the bathroom door. Finally, the doorknob turns and Conchita comes back to bed. She resumes her place next to Mois\x{e9}s. Relieved, he pulls her close."
          ],
          [
            1,
            'Timestr [02:55]: 2:55 a.m.',
            '"It\'s the way the world will end, Harry. Recorded cocktail music nuclear-powered to play on for centuries after all life has been destroyed. Selections from \'No, No, Nanette,\' throughout eternity. That do you for <<2:55 a.m.|2a>>?"'
          ],
          [
            1,
            'Timestr [02:55]: 2.55am',
            'Time to go: <<2.55am|2a>>. Two-handed, Cec lifted his peak cap from the chair.'
          ],
          [
            1,
            'Timestr [02:56]: 2:56',
            'It was <<2:56|2>> when the shovel touched the coffin. We all heard the sound and looked at each other.'
          ],
          [
            1,
            'Timestr [02:59]: 2.59',
            'I remembered arriving in this room at <<2.59|3b>> one night. I remembered the sergeant who called me names: mostly Anglo-Saxon monosyllabic four-letter ones with an odd "Commie" thrown in for syntax.'
          ],
          [
            1,
            'Timestr [03:00]: about three o\'clock',
            '"She died this morning, very early, <<about three o\'clock|6>>."'
          ],
          [
            1,
            'Timestr [03:00]: Three in the morn',
            "<<Three a.m.|5>> That\x{2019}s our reward. <<Three in the morn|5>>. The soul\x{2019}s <<midnight|13>>. The tide goes out, the soul ebbs. And a train arrives at an hour of despair. Why?"
          ],
          [
            1,
            'Timestr [03:01]: shortly after three o\'clock',
            'According to her watch it was <<shortly after three o\'clock|6>>, and according to everything else it was night-time.'
          ],
          [
            1,
            'Timestr [03:00]: three am',
            'At <<three am|5>> I was walking the floor and listening to Katchaturian working in a tractor factory. He called it a violin concerto. I called it a loose fan belt and the hell with it.'
          ],
          [
            1,
            'Timestr [03:00]: three o\' clock in the morning',
            'At <<three o\' clock in the morning|6>> Eurydice is bound to come into it. After all, why did I sit here like a telegrapher at a lost outpost if not to receive messages from everywhere about the lost Eurydice who was never mine to begin with but whom I lamented and sought continually both professionally and amateurishly. This is not a digression. Where I am at <<three o\' clock in the morning|6>> - and by now every hour is <<three o\' clock in the morning|6>> - there are no digressions, it\'s all one thing.'
          ],
          [
            1,
            "Timestr [03:00]: three o\x{2019}clock in the morning",
            "But at <<three o\x{2019}clock in the morning|6>>, a forgotten package has the same tragic importance as a death sentence, and the cure doesn\x{2019}t work -- and in a real dark night of the soul it is always <<three o\x{2019}clock in the morning|6>>, day after day."
          ],
          [
            1,
            'Timestr [03:00]: three o\'clock in the morning',
            'Early mornings, my mother is about, drifting in her pale nightie, making herself a cup of tea in the kitchen. Water begins to boil in the kettle; it starts as a private, secluded sound, pure as rain, and grows to a steady, solipsistic bubbling. Not till she has had one cup of tea, so weak that it has a colour accidentally golden, can she begin her day. She is an insomniac. Her nights are wide-eyed and excited with worry. Even at <<three o\'clock in the morning|6>> one might hear her eating a Bain Marie biscuit in the kitchen.'
          ],
          [
            1,
            'Timestr [03:00]: 3 a.m.',
            'I slam the phone down but it misses the base. I hit the clock instead, which flashes <<3 a.m.|5>>'
          ],
          [
            1,
            'Timestr [03:00]: 3 o\'clock in the morning',
            'In a real dark night of the soul it is always <<3 o\'clock in the morning|6>>.'
          ],
          [
            1,
            'Timestr [03:00]: three A.M.',
            "It was six untroubled days later \x{2013} the best days at the camp so far, lavish July light thickly spread everywhere, six masterpiece mountain midsummer days, one replicating the other \x{2013} that someone stumbled jerkily, as if his ankles were in chains, to the Comanche cabin\x{2019}s bathroom at <<three A.M.|5>>"
          ],
          [
            1,
            'Timestr [03:00]: three in the morning',
            'It was <<three in the morning|9a>> when his taxi stopped by giant mounds of snow outside his hotel. He had not eaten in hours.'
          ],
          [
            1,
            'Timestr [03:00]: three o\'clock at night',
            'Once I saw a figure I shall never forget. It was <<three o\'clock at night|6>>, as I was going home from Blacky as usual; it was a short-cut for me, and there would be nobody in the street at this time of night, I thought, especially not in this frightful cold.'
          ],
          [
            1,
            'Timestr [03:00]: Three AM',
            'Roused from her sleep, Freya Gaines groped for the switch of the vidphone; groggily she found it and snapped it on. \'Lo,\' she mumbled, wondering what time it was. She made out the luminous dial of the clock beside the bed. <<Three AM|5>>. Good grief.'
          ],
          [
            -1,
            'Timestr [03:00]: 0300',
            'Schact clears his mouth and swallows mightily. \'Tavis can\'t even regrout tile in the locker room without calling a Community meeting or appointing a committee. The Regrouting Committee\'s been dragging along since may. Suddenly they\'re pulling secret <<0300|99>> milk-switches? It doesn\'t ring true, Jim.'
          ],
          [
            1,
            'Timestr [03:00]: Three in the morning',
            "<<Three in the morning|5>>, thought Charles Halloway, seated on the edge of his bed. Why did the train come at that hour? For, he thought, it\x{2019}s a special hour. Women never wake then, do they? They sleep the sleep of babes and children. But men in middle age? They know that hour well."
          ],
          [
            -1,
            'Timestr [03:00]: three',
            'What\'s the time?" said the man, eyeing George up and down with evident suspicion; "why, if you listen you will hear it strike." George listened, and a neighbouring clock immediately obliged. "But it\'s only gone <<three|99>>!" said George in an injured tone, when it had finished.'
          ],
          [
            1,
            'Timestr [03:00]: 3:00 a.m.',
            'When Sophie awoke, it was <<3:00 a.m.|2a>>'
          ],
          [
            1,
            "Timestr [03:00]: three o\x{2019}clock in the morning",
            "You hearken, Missy. It\x{2019}s <<three o\x{2019}clock in the morning|6>> and I\x{2019}ve got all my faculties as well as ever I had in my life. I know all my property and where the money\x{2019}s put out. And I\x{2019}ve made everything ready to change my mind, and do as I like at the last. Do you hear, Missy? I\x{2019}ve got my faculties.\x{201d}"
          ],
          [
            1,
            'Timestr [03:01]: about three o\'clock in the morning',
            'It was now <<about three o\'clock in the morning|6>> and Francis Macomber, who had been asleep a little while after he had stopped thinking about the lion, wakened and then slept again.'
          ],
          [
            1,
            'Timestr [03:04]: 3.04',
            "\x{2026}his back-up alarm clock rang. He looked at his front-line clock on the bedside table and noted that it had stopped at <<3.04|9c:1>>. So, you couldn\x{2019}t even rely on alarm clocks."
          ],
          [
            1,
            'Timestr [03:05]: 3:05 a.m.',
            "On the Sunday before Christmas she awoke at <<3:05 a.m.|2a>> and though: Thirty-six hours. Four hours later she got up thinking: Thirty-two hours. Late in the day she took Alfred to the street-association Christmas party at Dale and Honey Driblett\x{2019}s, sat him down safely with Kirby Root, and proceeded to remind all her neighbors that her favorite grandson, who\x{2019}d been looking forward all year to a Christmas in St. Jude, was arriving tomorrow afternoon."
          ],
          [
            1,
            'Timestr [03:07]: 3.07am',
            'Wayne late-logged in: <<3.07am|2a>> -the late-late show. He parked. He dumped his milk can. He yawned, he stretched. He scratched.'
          ],
          [
            1,
            'Timestr [03:10]: ten-past three',
            'I think my credit card was in there too. I wrote down the words credit card and said that if they wouldn\'t let me cancel them I\'d demand that they registered the loss so you couldn\'t be charge for anything beyond the time of my calling them up. I looked at the clock. It was <<ten-past three|10>>.'
          ],
          [
            1,
            'Timestr [03:10]: ten past three',
            'Love again; wanking at <<ten past three|10>>'
          ],
          [
            1,
            'Timestr [03:14]: 3.14',
            'Since he had told the girl that it had to end, he\'d been waking up every morning at <<3.14|9c:1>>, without fail. Every morning his eyes would flick open, alert, and the red numerals on his electric alarm clock would read <<3.14|11>>.'
          ],
          [
            1,
            'Timestr [03:15]: 3:15',
            'Above the door of Room 69 the clock ticked on at <<3:15|2>>. The motion was accelerating. What had once been the gymnasium was now a small room, seven feet wide, a tight, almost perfect cube.'
          ],
          [
            1,
            'Timestr [03:17]: 3:17 in the morning',
            "The two of us sat there, listening\x{2014}Boris more intently than me. \x{201c}Who\x{2019}s that with him then?\x{201d} I said. \x{201c}Some whore.\x{201d} He listened for a moment, brow furrowed, his profile sharp in the moonlight, and then lay back down. \x{201c}Two of them.\x{201d} I rolled over, and checked my iPod. It was <<3:17 in the morning|2a>>."
          ],
          [
            1,
            'Timestr [03:17]: 3.17 a.m.',
            'He turned to the monitors again and flicked through the screens, each one able to display eight different camera mountings, giving Kurt 192 different still lives of Green Oaks at <<3.17 a.m.|2a>> this March night.'
          ],
          [
            1,
            'Timestr [03:19]: 3.19 A.M.',
            'The time stamp on Navidson\'s camcorder indicates that it is exactly <<3.19 A.M.|2a>>'
          ],
          [
            1,
            'Timestr [03:20]: 3.20am',
            'Prabath Kumara, 16. 17th November 1989. At <<3.20am|2a>> from the home of a friend.'
          ],
          [
            1,
            'Timestr [03:21]: twenty-one minutes past three',
            'Next, he remembered that the morrow of Christmas would be the twenty-seventh day of the moon, and that consequently high water would be at <<twenty-one minutes past three|10>>, the half-ebb at a <<quarter past seven|10>>, low water at <<thirty-three minutes past nine|10>>, and half flood at <<thirty-nine minutes past twelve|10>>.'
          ],
          [
            1,
            'Timestr [03:25]: 3:25 a.m.',
            'It was <<3:25 a.m.|2a>> A strange thrill, to think I was the only Mulvaney awake in the house.'
          ],
          [
            1,
            'Timestr [03:28]: 3.28',
            'Now somebody was running past his room. A door slammed. That foreign language again. What the devil was going on? he switched on his light and peered at his watch. <<3.28|9j>>. He got out of bed.'
          ],
          [
            1,
            'Timestr [03:30]: half past three',
            'At <<Half past Three|10>>, a single Bird Unto a silent Sky Propounded but a single term Of cautious melody.'
          ],
          [
            1,
            'Timestr [03:30]: half-past three A.M.',
            'At <<half-past three A.M.|10>> he lost one illusion: officers sent to reconnoitre informed him that the enemy was making no movement.'
          ],
          [
            1,
            'Timestr [03:30]: 3:30 A.M.',
            'It\'s <<3:30 A.M.|2a>> in Mrs. Ralph\'s finally quiet house when Garp decides to clean the kitchen, to kill the time until dawn. Familiar with a housewife\'s tasks, Garp fills the sink and starts to wash the dishes.'
          ],
          [
            1,
            'Timestr [03:30]: three-thirty',
            'Let\'s go to sleep, I say. "Look at what time it is." The clock radio is right there beside the bed. Anyone can see it says <<three-thirty|11>>.'
          ],
          [
            1,
            'Timestr [03:30]: three thirty in the morning',
            'Now, look. I am not going to call Dr. McGrath at <<three thirty in the morning|5>> to ask if it\'s all right for my son to eat worms. That\'s flat.'
          ],
          [
            1,
            'Timestr [03:33]: 3:33',
            'A draft whistled in around the kitchen window frame and I shivered. The digital clock on Perkus\'s stove read <<3:33|2>>.'
          ],
          [
            1,
            'Timestr [03:34]: 3:34 am',
            'It was <<3:34 am|2a>>. and he was wide-awake. He\'d heard the phone ring and the sound of his uncle\'s voice.'
          ],
          [
            1,
            'Timestr [03:35]: 3.35 a.m.',
            'He could just see the hands of the alarm clock in the darkness: <<3.35 a.m.|2a>> He adjusted his pillow and shut his eyes.'
          ],
          [
            1,
            'Timestr [03:36]: 3:36 a.m.',
            'As I near Deadhorse, it\'s <<3:36 a.m.|2a>> and seventeen below. Tall, sodium vapor lights spill on the road and there are no trees, only machines, mechanical shadows. There isn\'t even a church. It tells you everything.'
          ],
          [
            1,
            'Timestr [03:37]: three thirty-seven A.M.',
            'It was <<three thirty-seven A.M.|5>>, and for once Maggie was asleep. She had got to be a pretty good sleeper in the last few months. Clyde was prouder of this fact than anything.'
          ],
          [
            1,
            'Timestr [03:38]: 3.38am',
            'At <<3.38am|2a>>, it began to snow in Bowling Green, Kentucky. The geese circling the city flew back to the park, landed, and hunkered down to sit it out on their island in the lake.'
          ],
          [
            1,
            'Timestr [03:39]: 3.39am',
            '23 October 1893 <<3.39am|2a>>. Upon further thought, I feel it necessary to explain that exile into the Master\'s workshop is not an unpleasant fate. It is not simply some bare-walled cellar devoid of stimulation - quite the opposite.'
          ],
          [
            1,
            'Timestr [03:40]: three forty',
            'His bedside clock shows <<three forty|11>>. He has no idea what he\'s doing out of bed: he has no need to relieve himself, nor is he disturbed by a dream or some element of the day before, or even by the state of the world.'
          ],
          [
            1,
            'Timestr [03:41]: 3.41am',
            'The alarm clock said <<3.41am|2a>>. He sat up. Why was the alarm clock slow? He picked up the alarm clock and adjusted the hands to show the same time as his wristwatch: <<3.44am|2a>>'
          ],
          [
            1,
            'Timestr [03:42]: 3:42',
            '"We are due in Yellow Sky at <<3:42|5d>>," he said, looking tenderly into her eyes. ""Oh, are we?"" she said, as if she had not been aware of it. To evince surprise at her husband\'s statement was part of her wifely amiability.'
          ],
          [
            1,
            'Timestr [03:43]: 3.43am',
            'The clock says <<3.43am|2a>>. The thermometer says it\'s a chilly fourteen degrees Fahrenheit. The weatherman says the cold spell will last until Thursday, so bundle up and bundle up some more. There are icicles barring the window of the bat cave.'
          ],
          [
            1,
            'Timestr [03:44]: 3.44 a.m.',
            'It was dark. After she had switched the light on and been to the toilet, she checked her watch: <<3.44 a.m.|2a>> She undressed, put the cat out the door and returned to the twin bed.'
          ],
          [
            1,
            'Timestr [03:45]: quarter to four',
            'LORD CAVERSHAM: Well, sir! what are you doing here? Wasting your life as usual! You should be in bed, sir. You keep too late hours! I heard of you the other night at Lady Rufford\'s dancing till <<four o\' clock in the morning|6>>! LORD GORING: Only a <<quarter to four|10>>, father.'
          ],
          [
            1,
            'Timestr [03:47]: 3:47',
            'I stayed awake until <<3:47|2>>. That was the last time I looked at my watch before I fell asleep. It has a luminous face and lights up if you press a button so I could read it in the dark. I was cold and I was frightened Father might come out and find me. But I felt safer in the garden because I was hidden.'
          ],
          [
            1,
            'Timestr [03:49]: 3.49',
            'It was <<3.49|3b>> when he hit me because of the two hundred times I had said, "I don\'t know." He hit me a lot after that.'
          ],
          [
            1,
            'Timestr [03:50]: ten or five to four in the morning',
            'She had used her cell phone to leave several messages on the answering machine in Sao Paulo of the young dentist of the previous evening, whose name was Fernando. The first was recorded at <<ten or five to four in the morning|10>>. I\'m never going to forget you ... I\'m sure we\'ll meet again somewhere.'
          ],
          [
            1,
            'Timestr [03:51]: 3:51',
            'I lacked the will and physical strength to get out of bed and move through the dark house, clutching walls and stair rails. To feel my way, reinhabit my body, re-enter the world. Sweat trickled down my ribs. The digital reading on the clock-radio was <<3:51|2>>. Always odd numbered at times like this. What does it mean? Is death odd-numbered?'
          ],
          [
            1,
            'Timestr [03:51]: 3:51',
            'The digital reading on the clock-radio was <<3:51|2>>. Always odd numbers at times like this. What does it mean? Is death odd-numbered?'
          ],
          [
            1,
            'Timestr [03:54]: 3.54 a.m.',
            'The charter flight from Florida touched down at Aldergrove minutes earlier, at <<3.54 a.m.|2a>>'
          ],
          [
            1,
            'Timestr [03:55]: 3.55 a.m.',
            'Here in the cavernous basement at <<3.55 a.m.|2a>>, in a single pool of light, is Theo Perowne.'
          ],
          [
            1,
            'Timestr [03:57]: Nearly four',
            "Certain facts were apparent: dark; cold; thundering boots; quilts; pillow; light under the door \x{2013} the materials of reality - but I could not pin these materials down in time. And the raw materials of reality without that glue of time are materials adrift and reality is as meaningless as the balsa parts of a model airplane scattered to the wind...I am in my old room, yes, in the dark, certainly, and it is cold, obviously, but what time is it? \"<<Nearly four|9e>>, son.\" But I mean what time?"
          ],
          [
            1,
            'Timestr [03:58]: two minutes to four',
            'The ancient house was deserted, the crumbling garage padlocked, and one was just able to discern - by peering through a crack in the bubbling sun on the window - the face of a clock on the opposite wall. The clock had stopped at <<two minutes to four|10>> early in the morning, or who could tell, it may have been earlier still, yesterday in the afternoon, a couple of hours after Kaiser had left Kamaria for Bartica.'
          ],
          [
            1,
            'Timestr [03:58]: 3:58',
            'The clock atop the clubhouse reads <<3:58|2>>.'
          ],
          [
            1,
            'Timestr [03:59]: Nearly four',
            'And the raw materials of reality without that glue of time are materials adrift and reality is as meaningless as the balsa parts of a model airplane scattered to the wind...I am in my old room, yes, in the dark, certainly, and it is cold, obviously, but what time is it? "<<Nearly four|9e>>, son."'
          ],
          [
            1,
            'Timestr [04:00]: about four o\'clock',
            '"Nothing happened," he said wanly. "I waited, and <<about four o\'clock|6>> she came to the window and stood there for a minute and then turned out the light."'
          ],
          [
            1,
            'Timestr [04:00]: four am',
            'I looked at the clock and it was (yes, you guessed it) <<four am|5>>. I should have taken comfort from the fact that approximately quarter of the Greenwich Mean Time world had just jolted awake also and were lying, staring miserably into the darkness, worrying ..."'
          ],
          [
            1,
            'Timestr [04:02]: just after 4am',
            'Suddenly, he started to cry. Curled up on the sofa he sobbed loudly. Michel looked at his watch; it was <<just after 4am|10>>. On the screen a wild cat had a rabbit in its mouth.'
          ],
          [
            1,
            'Timestr [04:00]: four o\'clock',
            "The Birds begun at <<Four o'clock|6>>\x{2014} Their period for Dawn\x{2014}"
          ],
          [
            1,
            'Timestr [04:00]: four in the morning',
            'The night before Albert Kessler arrived in Santa Teresa, at <<four in the morning|9a>>, Sergio Gonzalez Rodriguez got a call from Azucena Esquivel Plata, reporter and PRI congresswoman.'
          ],
          [
            1,
            'Timestr [04:00]: four',
            'Waking at <<four|9b>> to soundless dark, I stare. In time the curtain-edges will grow light. Till then I see what\'s really always there: Unresting death, a whole day nearer now, Making all thought impossible but how And where and when I shall myself die.'
          ],
          [
            1,
            'Timestr [04:00]: four in the morning',
            'When he noticed that the chefs from the grand hotels and restaurants - a picky, impatient bunch - tended to move around from seller to seller, buying apples here and broccoli there, he asked if he could have tea available for them. Tommy agreed, and the chefs, grateful for a hot drink at <<four in the morning|9a>>, lingered and bought.'
          ],
          [
            1,
            'Timestr [04:01]: just after 4am',
            'Suddenly, he started to cry. Curled up on the sofa he sobbed loudly. Michel looked at his watch; it was <<just after 4am|10>>. On the screen a wild cat had a rabbit in its mouth.'
          ],
          [
            1,
            'Timestr [04:02]: 4:02',
            'I walked up and down the row. No one gave me a second look. Finally I sat down next to a man. He paid no attention. My watch said <<4:02|2>>. Maybe he was late.'
          ],
          [
            1,
            'Timestr [04:03]: 4:03 a.m.',
            'It\'s <<4:03 a.m.|2a>> on a supremely cold January morning and I\'m just getting home. I\'ve been out dancing and I\'m only half drunk but utterly exhausted.'
          ],
          [
            1,
            'Timestr [04:04]: Four minutes after four',
            '<<Four minutes after four|10>>! It\'s still very early and to get from here to there won\'t take me more than 15 minutes, even walking slowly. She told me <<around five o\'clock|6>>. Wouldn\'t it be better to wait on the corner?'
          ],
          [
            1,
            'Timestr [04:05]: 4.05am',
            'Leaves were being blown against my window. It was <<4.05am|2a>>. The moon had shifted in the sky, glaring through a clotted mass of clouds like a candled egg.'
          ],
          [
            1,
            'Timestr [04:06]: 4.06am',
            'Dexter looked at Kate\'s note, then her face, then the clock. It was <<4.06am|2a>>, the night before they would go to the restaurant.'
          ],
          [
            1,
            'Timestr [04:07]: 4.07am',
            '<<4.07am|2a>>. Why am I standing? My shoulders feel cold and I\'m shivering. I become aware that I\'m standing in the middle of the room. I immediately look at the bedroom door. Closed, with no signs of a break-in. Why did I get up?'
          ],
          [
            1,
            'Timestr [04:08]: 4:08 a.m.',
            'It was at <<4:08 a.m.|2a>> beneath the cool metal of a jungle gym that all Andrew\'s dreams came true. He kissed his one true love and swore up and down that it would last forever to this exhausted companion throughout their long trek home.'
          ],
          [
            1,
            'Timestr [04:11]: eleven minutes after four',
            'The next morning I awaken at exactly <<eleven minutes after four|10>>, having slept straight through my normal middle-of-the-night insomniac waking at <<three|9b>>.'
          ],
          [
            1,
            'Timestr [04:12]: four-twelve in the morning',
            'Finally, she signalled with her light that she\'d made it to the top. I signalled back, then shined the light downward to see how far the water had risen. I couldn\'t make out a thing. My watch read <<four-twelve in the morning|5>>. Not yet dawn. The morning papers still not delivered, trains not yet running, citizens of the surface world fast asleep, oblivious to all this. I pulled the rope taut with both hands, took a deep breath, then slowly began my climb.'
          ],
          [
            1,
            'Timestr [04:12]: 4:12',
            'Karen felt the bed move beneath Harry\'s weight. Lying on her side she opened her eyes to see digital numbers in the dark, <<4:12|2>> in pale green. Behind her Harry continued to move, settling in. She watched the numbers change to <<4:13|2>>.'
          ],
          [
            1,
            'Timestr [04:13]: 4:13',
            'Karen felt the bed move beneath Harry\'s weight. Lying on her side she opened her eyes to see digital numbers in the dark, <<4:12|2>> in pale green. Behind her Harry continued to move, settling in. She watched the numbers change to <<4:13|2>>.'
          ],
          [
            1,
            'Timestr [04:14]: 4:14 a.m.',
            'At <<4:14 a.m.|2a>>, the two men returned to the Jeep. After the passenger replaced the cans in the back of the Jeep, the driver backed out of the driveway and headed east. The last images found on the film appeared to be flames or smoke.'
          ],
          [
            1,
            'Timestr [04:15]: four-fifteen',
            'Alice wants to warn her that a defect runs in the family, like flat feet or diabetes: they\'re all in danger of ending up alone by their own stubborn choice. The ugly kitchen clock says <<four-fifteen|11>>.'
          ],
          [
            1,
            'Timestr [04:16]: four-sixteen',
            'I stooped to pick up my watch from the floor. <<Four-sixteen|9j>>. Another hour until dawn. I went to the telephone and dialled my own number. It\'d been a long time since I\'d called home, so I had to struggle to remember the number. I let it ring fifteen times; no answer. I hung up, dialled again, and let it ring another fifteen times. Nobody.'
          ],
          [
            1,
            'Timestr [04:16]: four sixteen',
            'They pulled into the visitor\'s carpark at <<four sixteen am|5>>. He knew it was <<four sixteen|5b>> because the entrance to the maternity unit sported a digital clock beneath the signage.'
          ],
          [
            1,
            'Timestr [04:17]: 4.17am',
            'He awoke at <<4.17am|2a>> in a sweat. He had been dreaming of Africa again, and then the dream had continued in the U.S. when he was a young man. But Inbata had been there, watching him.'
          ],
          [
            1,
            'Timestr [04:18]: four-eighteen',
            'I grabbed the alarm clock, threw it on my lap, and slapped the red and black buttons with both hands. The ringing didn\'t stop. The telephone! The clock read <<four-eighteen|11>>. It was dark outside. <<Four-eighteen a.m.|5>> I got out of bed and picked up the receiver. "Hello?"'
          ],
          [
            1,
            'Timestr [04:22]: 4.22',
            'He hurt me to the point where I wanted to tell him something. My watch said <<4.22|11>> now. It had stopped. It was smashed.'
          ],
          [
            1,
            'Timestr [04:23]: 4:23',
            '<<4:23|2>>, Monday morning, Iceland Square. A number of people in the vicinity of Bjornsongatan are awakened by loud screams.'
          ],
          [
            1,
            'Timestr [04:23]: 04:23',
            'Her chip pulsed the time. <<04:23|2>>:04. It had been a long day.'
          ],
          [
            1,
            'Timestr [04:25]: twenty-five minutes past four',
            'As I dressed I glanced at my watch. It was no wonder that no one was stirring. It was <<twenty-five minutes past four|10>>.'
          ],
          [
            1,
            'Timestr [04:30]: four thirty in the morning',
            'At the end of a relationship, it is the one who is not in love who makes the tender speeches. I was overwhelmed by a sense of betrayal, betrayal because a union in which I had invested so much had been declared bankrupt without my feeling it to be so. Chloe had not given it a chance, I argued with myself, knowing the hopelessness of these inner courts announcing hollow verdicts at <<four thirty in the morning|5>>.'
          ],
          [
            -1,
            'Timestr [04:30]: 0430',
            'Hester Thrale undulates in in a false fox jacket at 2330 as usual even though she has to be up at like <<0430|99>> for the breakfast shift at the Provident Nursing Home and sometimes eats breakfast with Gately, both their faces nodding perilously close to their Frosted Flakes.'
          ],
          [
            -1,
            'Timestr [04:30]: 0430',
            'Tonight Clenette H. and the deeply whacked out Yolanda W. come back in from Footprints around 2315 in purple skirts and purple lipstick and ironed hair, tottering on heels and telling each other what a wicked time they just had. Hester Thrale undulates in in a false fox jacket at 2330 as usual even though she has to be up at like <<0430|99>> for the breakfast shift at the Provident Nursing Home and sometimes eats breakfast with Gately, both their faces nodding perilously close to their Frosted Flakes.'
          ],
          [
            1,
            'Timestr [04:31]: 4:31',
            'An earthquake hit Los Angeles at <<4:31|2>> this morning and the images began arriving via CNN right away.'
          ],
          [
            1,
            'Timestr [04:32]: 4:32 a.m.',
            'On his first day of kindergarten, Peter Houghton woke up at <<4:32 a.m.|2a>> He padded into his parents\' room and asked if it was time yet to take the school bus.'
          ],
          [
            1,
            'Timestr [04:35]: 4:35',
            'No manner of exhaustion can keep a child asleep much later than <<six a.m.|5>> on Christmas Day. Colby awoke at <<4:35|2>>.'
          ],
          [
            1,
            'Timestr [04:36]: 4:36 that morning',
            'At <<4:36 that morning|2a>>, alone in my hotel room, it had been a much better scene. Spencer had blanched, confounded by the inescapable logic of my accusation. A few drops of perspiration had formed on his upper lip. A tiny vein had started to throb in his temple.'
          ],
          [
            1,
            'Timestr [04:38]: 4.38 a.m.',
            'At <<4.38 a.m.|2a>> as the sun is coming up over Gorley Woods, I hear a strange rustling in the grass beside me. I peer closely but can see nothing.'
          ],
          [
            1,
            'Timestr [04:40]: 4.40am',
            'I settled into a daily routine. Wake up at <<4.40am|2a>>, shower, get on the train north by <<ten after five|10>>.'
          ],
          [
            1,
            'Timestr [04:41]: 4:41',
            "At <<4:41|2>> Crane's voice crackled through the walkie-talkie as if he'd read their thoughts of mutiny. \x{201c}Everyone into the elevator. Now!\x{201d} Only moments before the call he and C.J. had finished what they hoped would be a successful diversion."
          ],
          [
            1,
            'Timestr [04:43]: four forty-three in the mornin',
            'The time is <<four forty-three in the mornin|5>> an it\'s almost light oot there.'
          ],
          [
            1,
            'Timestr [04:45]: 4:45 a.m.',
            'He lies still in the darkness and listens. His wife\'s breathing at his side is so faint that he can scarcely hear it. One of these mornings she\'ll be lying dead beside me and I won\'t even notice, he thinks. Or maybe it\'ll be me. Daybreak will reveal that one of us has been left alone. He checks the clock on the table next to the bed. The hands glow and register <<4:45 a.m.|2a>>'
          ],
          [
            1,
            'Timestr [04:45]: 4:45 a.m.',
            'His wife\'s breathing at his side is so faint that he can scarcely hear it. One of these mornings she\'ll be lying dead beside me and I won\'t even notice, he thinks. Or maybe it\'ll be me. Daybreak will reveal that one of us has been left alone. He checks the clock on the table next to the bed. The hands glow and register <<4:45 a.m.|2a>>'
          ],
          [
            1,
            'Timestr [04:46]: four-forty-six',
            'The phone rang again at <<four-forty-six|5b>>."Hello," I said. "Hello," came a woman\'s voice. "Sorry about the time before. There\'s a disturbance in the sound field. Sometimes the sound goes away." "The sound goes away?" "Yes," she said. "The sound field\'s slipping. Can you hear me?" "Loud and clear," I said. It was the granddaughter of that kooky old scientist who\'d given me the unicorn skull. The girl in the pink suit.'
          ],
          [
            1,
            'Timestr [04:48]: 4:48',
            'At <<4:48|2>> the happy hour when clarity visits warm darkness which soaks my eyes I know no sin'
          ],
          [
            1,
            'Timestr [04:50]: ten minutes to five',
            'Even the hands of his watch and the hands of all the thirteen clocks were frozen. They had all frozen at the same time, on a snowy night, seven years before, and after that it was always <<ten minutes to five|10>> in the castle.'
          ],
          [
            1,
            'Timestr [04:54]: six minutes to five',
            '<<Six minutes to five|10>>. Six minutes to go. Suddenly I felt quite clearheaded. There was an unexpected light in the cell; the boundaries were drawn, the roles well defined. The time of doubt and questioning and uncertainty was over.'
          ],
          [
            1,
            'Timestr [04:55]: 4:55',
            '<<4:55|2>> - Mank holding phone. Turns to Caddell - \'Who is this?\' Caddell: \'Jim.\' (shrugs) \'I think he\'s our man in Cincinnati.\''
          ],
          [
            1,
            'Timestr [04:57]: a few minutes before five',
            'The second said the same thing <<a few minutes before five|10>>, and mentioned eternity... I\'m sure I\'ll meet you in the other world. Four minutes later she left a last, fleeting message: My love. Fernando. It\'s Suzana. Then, it seemed, she had shot herself.'
          ],
          [
            1,
            'Timestr [04:58]: two minutes to five',
            'He wants to look death in the face. <<Two minutes to five|10>>. I took a handkerchief out of my pocket, but John Dawson ordered me to put it back. An Englishman dies with his eyes open. He wants to look death in the face.'
          ],
          [
            1,
            'Timestr [04:59]: 0459',
            'The whole place smells like death no matter what the fuck you do. Gately gets to the shelter at <<0459|1a>>.9h and just shuts his head off as if his head had a control switch.'
          ],
          [
            1,
            'Timestr [05:00]: five o\'clock',
            '<<Five o\'clock|6>> had hardly struck on the morning of the 19th of January, when Bessie brought a candle into my closet and found me already up and nearly dressed.'
          ],
          [
            1,
            'Timestr [05:00]: five o\'clock',
            '<<Five o\'clock|6>> had hardly struck on the morning of the 19th of January, when Bessie brought a candle into my closet and found me already up and nearly dressed. I had risen half-an-hour before her entrance, and had washed my face, and put on my clothes by the light of a half-moon just setting, whose rays streamed through the narrow window near my crib.'
          ],
          [
            1,
            'Timestr [05:00]: 5 a.m.',
            'It was in the township of Dunwich, in a large and hardly inhabited farmhouse set against a hillside 4 miles from the village and a mile and a half from any other dwelling, that Wilbur Whately was born at <<5 a.m.|5>> on Sunday, 2 February, 1913. The date was recalled because it was Candlemas, which people in Dunwich curiously observe under another name...'
          ],
          [
            1,
            'Timestr [05:01]: Just after five o\'clock',
            '<<Just after five o\'clock|10>> on this chill September morning, the fishmonger\'s cart, containing Kirsten and Emilia and such possessions as they have been able to assemble in the time allowed to them, is driven out of the gates of Rosenborg?'
          ],
          [
            1,
            'Timestr [05:00]: five',
            'The cold eye of the Duke was dazzled by the gleaming of a thousand jewels that sparkled on the table. His ears were filled with chiming as the clocks began to strike. "<<One|9k:0>>!" said Hark. "<<Two|9k:0>>!" cried Zorn of Zorna. "<<Three|9k:0>>!" the Duke\'s voice almost whispered. \'<<Four|9k:0>>!" sighed Saralinda. "<<Five|9k:0>>!" the Golux crowed, and pointed at the table. "The task is done, the terms are met," he said.'
          ],
          [
            1,
            'Timestr [05:00]: five o\'clock',
            'The day came slow, till <<five o\'clock|6>>. Then sprang before the hills. Like hindered rubies, or the light. A sudden musket spills'
          ],
          [
            1,
            'Timestr [05:00]: 5 a.m.',
            'There are worse things than having behaved foolishly in public. There are worse things than these miniature betrayals, committed or endured or suspected; there are worse things than not being able to sleep for thinking about them. It is <<5 a.m.|5>> All the worse things come stalking in and stand icily about the bed looking worse and worse and worse.'
          ],
          [
            1,
            'Timestr [05:00]: five o\'clock in the morning',
            'What causes young people to "come out," but the noble ambition of matrimony? What sends them trooping to watering-places? What keeps them dancing till <<five o\'clock in the morning|6>> through a whole mortal season?'
          ],
          [
            1,
            'Timestr [05:01]: one minute past five',
            '"Oh yes. His clocks were set at <<one minute past five|10>>, <<four minutes past five|10>> and <<seven minutes past five|10>>. That was the combination number of a safe, 515457. The safe was concealed behind a reproduction of the Mona Lisa. Inside the safe," continued Poirot, with distaste, "were the Crown Jewels of the Russian Royal Family."'
          ],
          [
            1,
            'Timestr [05:01]: Just after five o\'clock',
            '<<Just after five o\'clock|10>> on this chill September morning, the fishmonger\'s cart, containing Kirsten and Emilia and such possessions as they have been able to assemble in the time allowed to them, is driven out of the gates of Rosenborg?'
          ],
          [
            1,
            'Timestr [05:02]: 5:02 a.m.',
            'It was <<5:02 a.m.|2a>>, December 14. In another fifty-eight minutes he would set sail for America. He did not want to leave his bride; he did not want to go.'
          ],
          [
            1,
            'Timestr [05:03]: 5:03 a.m.',
            'It was <<5:03 a.m.|2a>> It didn\'t matter. She wasn\'t going to get back to sleep. She threw off her covers and, swearing at herself, Caleb and Mr. Griffin, she headed into the shower.'
          ],
          [
            1,
            'Timestr [05:04]: four minutes past five',
            '"Oh yes. His clocks were set at <<one minute past five|10>>, <<four minutes past five|10>> and <<seven minutes past five|10>>. That was the combination number of a safe, 515457. The safe was concealed behind a reproduction of the Mona Lisa. Inside the safe," continued Poirot, with distaste, "were the Crown Jewels of the Russian Royal Family."'
          ],
          [
            1,
            'Timestr [05:04]: 5.04 a.m.',
            '<<5.04 a.m.|2a>> on the substandard clock radio. Because why do people always say the day starts now? Really it starts in the middle of the night at a fraction of a second <<past midnight|13>>.'
          ],
          [
            1,
            'Timestr [05:04]: four minutes past five',
            'Oh yes. His clocks were set at <<one minute past five|10>>, <<four minutes past five|10>> and <<seven minutes past five|10>>. That was the combination number of a safe, 515457. The safe was concealed behind a reproduction of the Mona Lisa. Inside the safe, continued Poirot, with distaste, "were the Crown Jewels of the Russian Royal Family."'
          ],
          [
            1,
            'Timestr [05:05]: five past five in the morning',
            'The baby, a boy, is born at <<five past five in the morning|10>>.'
          ],
          [
            1,
            'Timestr [05:06]: 5:06 a.m.',
            '<<5:06 a.m.|2a>> I wake up strangely energized, my stomach growling. Upstairs, the overstocked fridge offers me its bounty of sympathy food.'
          ],
          [
            1,
            'Timestr [05:07]: seven minutes past five',
            '"Oh yes. His clocks were set at <<one minute past five|10>>, <<four minutes past five|10>> and <<seven minutes past five|10>>. That was the combination number of a safe, 515457. The safe was concealed behind a reproduction of the Mona Lisa. Inside the safe," continued Poirot, with distaste, "were the Crown Jewels of the Russian Royal Family."'
          ],
          [
            1,
            'Timestr [05:08]: 5:08',
            'Ambrose and I will marry at Fort McHenry at <<5:08|2>> EDST this coming Saturday, Rosh Hashanah!'
          ],
          [
            1,
            'Timestr [05:09]: 5:09',
            'The primal flush of triumph which had saturated the American\'s humor on this signal success, proved but fictive and transitory when inquiry of the station attendants educed the information that the two earliest trains to be obtained were the <<5:09|2>> to Dunkerque and the <<5:37|2>> for Ostend.'
          ],
          [
            1,
            'Timestr [05:10]: ten minutes past five',
            '"Oh, my husband, I have done the deed which will relieve you of the wife whom you hate! I have taken the poison--all of it that was left in the paper packet, which was the first that I found. If this is not enough to kill me, I have more left in the bottle. <<Ten minutes past five|10>>. "You have just gone, after giving me my composing draught. My courage failed me at the sight of you. I thought to myself, \'If he look at me kindly, I will confess what I have done, and let him save my life.\' You never looked at me at all. You only looked at the medicine. I let you go without saying a word.'
          ],
          [
            1,
            'Timestr [05:10]: ten after five',
            'I settled into a daily routine. Wake up at <<4:40am|2a>>, shower, get on the train north by <<ten after five|10>>.'
          ],
          [
            1,
            'Timestr [05:11]: eleven minutes past five',
            'Today was Tuesday, the fifteenth of August; the sun had risen at <<eleven minutes past five|10>> this morning and would set at <<two minutes before seven|10>> this evening.'
          ],
          [
            1,
            'Timestr [05:12]: twelve minutes and six seconds past five o\'clock',
            'At <<twelve minutes and six seconds past five o\'clock|10>> on the morning of April 18th, 1906, the San francisco peninsula began to shiver in the grip of an earthquake which, when its ultimate consequences are considered, was the most disastrous in the recorded history of the North American continent.'
          ],
          [
            1,
            'Timestr [05:13]: 5:13 am',
            'Lying on my side in bed, I stared at my alarm clock until it became a blemish, its red hue glowing like a welcome sign beckoning me into the depths of hell\'s crimson-colored cavities. <<5:13 am|2a>>. To describe this Monday as a blue Monday was an understatement.'
          ],
          [
            1,
            'Timestr [05:14]: 5.14am',
            'The time was <<5.14am|2a>>, a very strange time indeed for the sheriff to have seen what he claimed he saw as he made his early-morning rounds, first patrolling back and forth along the deserted, snowbound streets of Kingdom City before extending his vigilance northward, along County Road.'
          ],
          [
            1,
            'Timestr [05:15]: 5:15 a.m.',
            "By the first week of May, Ralph was waking up to birdsong at <<5:15 a.m.|2a>> He tried earplugs for a few nights, although he doubted from the outset that they would work. It wasn\x{2019}t the newly returned birds that were waking him up, nor the occasional delivery-truck backfire out on Harris Avenue. He had always been the sort of guy who could sleep in the middle of a brass marching bad, and he didn\x{2019}t think that had changed. What had changed was inside his head."
          ],
          [
            1,
            'Timestr [05:15]: 5:15',
            'Weird conversation with Brown, a tired & confused old man who\'s been jerked out of bed at <<5:15|2>>.'
          ],
          [
            1,
            'Timestr [05:16]: 5:16',
            '<<5:16|2>> - Mank on phone to Secretary of State Brown: \'Mr Brown, we\'re profoundly disturbed about this situation in the 21st. We can\'t get a single result out of there.'
          ],
          [
            1,
            'Timestr [05:16]: 5:16 a.m',
            'She could go back to sleep. But typical and ironic, she is completely awake. It is completely light outside now; you can see for miles. Except there is nothing to see here; trees and fields and that kind of thing. <<5:16 a.m|2a>> on the substandard clock radio. She is really awake.'
          ],
          [
            1,
            'Timestr [05:20]: five twenty',
            'He saw on the floor his cigarette reduced to a long thin cylinder of ash: it had smoked itself. It was <<five twenty|9f>>, dawn was breaking behind the shed of empty barrels, the thermometer pointed to 210 degrees.'
          ],
          [
            1,
            'Timestr [05:23]: 5.23am',
            'If I could count precisely to sixty between two passing orange minutes on her digital clock, starting at <<5.23am|9g>> and ending exactly as it melted into <<5:24|2>>, then when she woke she would love me and not say this had been a terrible mistake.'
          ],
          [
            1,
            'Timestr [05:24]: 5:24',
            'If I could count precisely to sixty between two passing orange minutes on her digital clock, starting at <<523am|9g>>. and ending exactly as it melted into <<5:24|2>>, then when she woke she would love me and not say this had been a terrible mistake.'
          ],
          [
            1,
            'Timestr [05:25]: 5.25',
            'George\'s train home from New Street leaves at <<5.25|9c:1>>. On the return journey, there are rarely schoolboys.'
          ],
          [
            1,
            'Timestr [05:26]: 05:26',
            "I think this is actually bump number 1,970. And the boy keeps plugging away at the same speed. There isn\x{2019}t a sound from them. Not a moan. Poor them. Poor me. I look at the clock. <<05:26|2>>."
          ],
          [
            1,
            'Timestr [05:28]: five-twenty-eight',
            'I pulled into the Aoyama supermarket parking garage at <<five-twenty-eight|5b>>. The sky to the east was getting light. I entered the store carrying my bag. Almost no one was in the place. A young clerk in a striped uniform sat reading a magazine; a woman of indeterminate age was buying a cartload of cans and instant food. I turned past the liquor display and went straight to the snack bar.'
          ],
          [
            1,
            'Timestr [05:30]: half-past five in the summer morning',
            'Gideon has been most unlike Gideon. As Walter Eastman is preoccupied himself, he has not had time, or more to the point, inclination, to notice aberrant behaviour. For instance, it is <<half-past five in the summer morning|10>>. Young Chase\'s narrow bachelor bed has evidently been slept in, for it is rumpled in that barely disturbed way which can never be counterfeited. His jug\'s empty and there\'s grey water in the basin, cleanly boy. The window is open, admitting the salubrious sea-breeze. He doesn\'t smoke anyway. What an innocent room it is.'
          ],
          [
            1,
            'Timestr [05:30]: half-past five',
            "It was by this time <<half-past five|10>>, and the sun was on the point of rising; but I found the kitchen still dark and silent. \x{2026} The stillness of early morning slumbered everywhere .. the carriage horses stamped from time to time in their closed stables: all else was still."
          ],
          [
            1,
            'Timestr [05:30]: five-thirty in the morning',
            'On the day they were going to kill him, Santiago Nasar got up at <<five-thirty in the morning|5>> to wait for the boat the bishop was coming on.'
          ],
          [
            1,
            'Timestr [05:31]: 5:31',
            '<<5:31|2>> - Mank on phone to lawyer: \'Jesus, I think we gotta go in there and get those ballots! Impound \'em! Every damn one!\''
          ],
          [
            1,
            'Timestr [05:34]: five-thirty-four',
            "I asked \"What time is sunrise?\x{201d}' A second's silence while the crestfallen Bush absorbed his rebuke, and then another voice answered: \x{2018}<<Five-thirty-four|9j>>, sir.'"
          ],
          [
            1,
            'Timestr [05:35]: 5:35',
            '<<5:35|2>> - All phones ringing now, the swing shift has shot the gap - now the others are waking up.'
          ],
          [
            1,
            'Timestr [05:35]: twenty-five before six',
            'I squinted at the clock. \'It says <<twenty-five before six|10>>,\' I said and rolled away from him.'
          ],
          [
            1,
            'Timestr [05:37]: 5:37',
            'Richard glanced at the clock on the microwave - <<5:37|2>> - almost twelve hours, almost one half-day since he\'d dialed 911.'
          ],
          [
            1,
            'Timestr [05:38]: 5.38 a.m.',
            "Kovac,\x{2019} said Johnny sleepily. It was very rare for the quantum computer and not Sol to wake him up. \x{2018}What\x{2019}s going on? What time is it?\x{2019} \x{2018}Good morning, Johnny,\x{2019} said the ship. \x{2018}It is <<5.38 a.m.|2a>>\x{2019} \x{2018}What?\x{2019} said Johnny. \x{2018}It\x{2019}s Saturday.\x{2019} \x{2018}I told you he wouldn\x{2019}t like it,\x{2019} said Sol, presumably to Kovac. \x{2018}It\x{2019}s hardly a matter of likes or dislikes,\x{2019} said the computer. \x{2018}I have information I deem important enough to pass on at the earliest opportunity \x{2013} whatever time it is.\x{2019}"
          ],
          [
            1,
            'Timestr [05:40]: twenty minutes to six',
            '<<Twenty minutes to six|10>>. \'Rob\'s boys were already on the platform, barrows ready. The only thing that ever dared to be late around here was the train. Rob\'s boys were in fact Bill Bing, thirty, sucking a Woodbine, and Arthur, sixty, half dead.'
          ],
          [
            1,
            'Timestr [05:43]: 5.43',
            '<<5.43|9j>> - Mank on phone to \'Mary\' in Washington; \'It now appears quite clear that we\'ll lead the state - without the 21st.\''
          ],
          [
            1,
            'Timestr [05:45]: 5:45',
            "At <<5:45|2>> a power-transformer on a pole beside the abandoned Tracker Brothers\x{2019} Truck Depot exploded in a flash of purple light, spraying twisted chunks of metal onto the shingled roof."
          ],
          [
            1,
            'Timestr [05:46]: 5.46am',
            'Herbert could feel nothing. He wrote a legal-sounding phrase to the effect that the sentence had been carried out at <<5.46am|2a>>, adding, \'without a snag\'. The burial party had cursed him quietly as they\'d hacked at the thick roots and tight soil.'
          ],
          [
            1,
            'Timestr [05:52]: 5.52am',
            'At <<5.52am|2a>> paramedics from the St. Petersburg Fire Department and SunStar Medic One ambulance service responded to a medical emergency call at 12201 Ninth Street North, St. Petersburg, apartment 2210.'
          ],
          [
            1,
            'Timestr [05:55]: 5.55am',
            'It was <<5.55am|2a>> and raining hard when I pedalled up to the bike stand just outside the forecourt of the station and dashed inside. I raced past the bookstall, where all the placards of the Yorkshire Post (a morning paper) read \'York Horror\', but also \'Terrific February Gales at Coast\'.'
          ],
          [
            1,
            'Timestr [05:58]: 5.58 a.m.',
            'Annika Giannini woke with a start. She saw that it was <<5.58 a.m.|2a>>'
          ],
          [
            1,
            "Timestr [06:00]: six o\x{2019}clock",
            "\x{2018}What\x{2019}s the time?\x{2019} I ask, and telling him so that he knows, \x{2018}My mother likes \x{201c}peace and quiet\x{201d} to sleep late on Saturday mornings.\x{2019} \x{2018}She does, does she? It\x{2019}s <<six o\x{2019}clock|6>>. I couldn\x{2019}t sleep,\x{2019} he says wearily, like an afterthought, as if it\x{2019}s what he expects. \x{2018}Why are you up so early?\x{2019} \x{2018}I woke up and needed my panda. I can\x{2019}t find him.\x{2019} \x{2018}Where do you think he can be?\x{2019} His face changes and he smiles again, bending down to look under the table and behind the curtain. But he isn\x{2019}t clowning or teasing. He\x{2019}s in earnest."
          ],
          [
            1,
            'Timestr [06:00]: six',
            'But every morning, even if there\'s been a nighttime session and he has only slept two hours, he gets up at <<six|9b>> and reads his paper while he drinks a strong cup of coffee. In this way Papa constructs himself every day.'
          ],
          [
            1,
            'Timestr [06:00]: six a.m.',
            'I had risen half-an-hour before her entrance, and had washed my face, and put on my clothes by the light of a half-moon just setting, whose rays streamed through the narrow window near my crib. I was to leave Gateshead that day by a coach which passed the lodge gates at <<six a.m.|5>>'
          ],
          [
            1,
            'Timestr [06:00]: six',
            'Lying awake in my attic room, i hear a clock strike <<six|11>> downstairs. It was fairly light and people were beginning to walk up and down the stairs...- i heard the clock strike <<eight|11>> downstairs before i rose and got dressed... I looked up - the clock tower of our saviour\'s showed ten.'
          ],
          [
            1,
            'Timestr [06:00]: about six o\'clock in the morning',
            'On the 15th of September 1840, <<about six o\'clock in the morning|6>>, the Ville-de-Montereau, ready to depart, pouring out great whirls of smoke by the quai Saint-Bernard.'
          ],
          [
            1,
            'Timestr [06:00]: 6.00 A.M.',
            'Rise from bed ............... . <<6.00 A.M.|2a>>'
          ],
          [
            1,
            'Timestr [06:00]: six in the morning',
            'The ball went on for a long time, until <<six in the morning|5>>; all were exhausted and wishing they had been in bed for at least three hours; but to leave early was like proclaiming the party a failure and offending the host and hostess who had taken such a lot of trouble, poor dears.'
          ],
          [
            1,
            'Timestr [06:02]: 6.02',
            'Bimingham New Street <<5.25|5a:1>>. Walsall <<5.55|5a:1>>. This train does not stop at Birchills, for reasons George has never been able to ascertain. Then it is Bloxwich <<6.02|5a:1>>, Wyrley & Churchbridge <<6.09|5a:1>>. At <<6.10|9m>> he nods to Mr Merriman the stationmaster.'
          ],
          [
            1,
            'Timestr [06:05]: five minutes past six',
            'A second man went in and found the shop empty, as he thought, at <<five minutes past six|10>>. That puts the time at between <<5:30|2>> and <<6:05|2>>.'
          ],
          [
            1,
            'Timestr [06:06]: 6:06',
            'At <<6:06|2>>, every toilet on Merit Street suddenly exploded in a geyser of shit and raw sewage as some unimaginable reversal took place in the pipes which fed the holding tanks of the new waste-treatment plant in the Barrens.'
          ],
          [
            1,
            'Timestr [06:08]: six oh-eight a.m.',
            'At <<six oh-eight a.m.|5>> two men wearing ragged trench coats approached the Casino. The shorter of the men burst into flames.'
          ],
          [
            1,
            'Timestr [06:10]: ten past six',
            'The bus left the station at <<ten past six|10>> - and she sat proud, like an accustomed traveller, apart from her father, John Henry, and Berenice. But after a while a serious doubt came in her, which even the answers of the bus-driver could not quite satisfy.'
          ],
          [
            1,
            'Timestr [06:13]: 06:13',
            'It\'s <<06:13|2>> .........Ma says I ought to be wrapped up in Rug already, Old Nick might possibly come.'
          ],
          [
            -1,
            'Timestr [06:15]: 6.15',
            'Dumbbell exercise and wall-scaling ..... . <<6.15|99>>-6.30'
          ],
          [
            1,
            'Timestr [06:15]: quarter past six',
            'Father expected his shaving-water to be ready at a <<quarter past six|10>>. Just seven minutes late, Dorothy took the can upstairs and knocked at her father\'s door.'
          ],
          [
            1,
            'Timestr [06:15]: 6.15 am',
            'It was <<6.15 am|2a>>. Just starting to get light. A small knot of older teenagers were leaning against a nearby wall. They looked as though they had been out all night.Two of the guys stared at us. Their eyes hard and threatening.'
          ],
          [
            1,
            'Timestr [06:15]: 6.15 am',
            'It was <<6.15 am|2a>>. Just starting to get light. A small knot of older teenagers were leaning against a nearby wall. They looked as though they had been out all night.Two of the guys stared at us. Their eyes hard and threatening.'
          ],
          [
            1,
            'Timestr [06:17]: six-seventeen',
            'Dizzy, come on.\' He turned slowly, coaxing the animal down on to the pillow. The clock read <<six-seventeen|11>>. A second cat, Miles, purred on contentedly from the patch in the covers where Resnick\'s legs had made a deep V.'
          ],
          [
            1,
            'Timestr [06:19]: 6.19 am',
            '<<6.19 am|2a>>, 8th June 2004, the jet of your pupil set in the gold of your eye.'
          ],
          [
            1,
            'Timestr [06:20]: 6:20 a.m.',
            'It was <<6:20 a.m.|2a>>, and my parents and I were standing, stunned and haf-awake, in the parking lot of a Howard Johnson\'s in Iowa.'
          ],
          [
            1,
            'Timestr [06:25]: 6.25',
            'Simon is happy to travel scum class when he\'s on his own and even sometimes deliberately aims for the <<6.25|5a:0>>. But today the .25 is delayed to <<6.44|5a:0>>.'
          ],
          [
            1,
            'Timestr [06:25]: six-twenty-five',
            'Still, it\'s your consciousness that\'s created it. Not somethin\' just anyone could do. Others could be wanderin\' around forever in who-knows-what contradictory chaos of a world. You\'re different. You seem t\'be the immortal type." "When\'s the turnover into that world going to take place?" asked the chubby girl. The Professor looked at his watch. I looked at my watch. <<Six-twenty-five|9j>>. Well past daybreak. Morning papers delivered. "According t\'my estimates, in another twenty-nine hours and thirty-five minutes," said the Professor. "Plus or minus forty-five minutes. I set it at twelve <<noon|13>> for easy reference. <<Noon|13>> tomorrow.'
          ],
          [
            1,
            'Timestr [06:27]: 06:27',
            '<<06:27|2>>:52 by the chip in her optic nerve; Case had been following her progress through Villa Straylight for over an hour, letting the endorphin analogue she\'d taken blot out his hangover.'
          ],
          [
            1,
            'Timestr [06:27]: 0627 hours',
            'Early in the morning, late in the century, Cricklewood Broadway. At <<0627 hours|1>> on January 1, 1975, Alfred Archibald Jones was dressed in corduroy and sat in a fume-filled Cavalier Musketeer Estate, facedown on the steering wheel, hoping the judgment would not be too heavy upon him.'
          ],
          [
            1,
            'Timestr [06:29]: a minute short of six-thirty',
            'I sat up. There was a rug over me. I threw that off and got my feet on the floor. I scowled at a clock. The clock said <<a minute short of six-thirty|11>>.'
          ],
          [
            1,
            'Timestr [06:30]: 6.30 am',
            'Inside now MJ ordered. She pushed the three of us into the hotel room, thern shut the soor. I glanced at the clock by the bed. <<6.30 am|2a>>. Why were they waking Mum and Dad up this early?'
          ],
          [
            1,
            'Timestr [06:30]: six-thirty',
            'Daniel and the FBI men listened to the sounds of his mother waking up his father. Daniel still held the door-knob. He was ready to close the door the second he was told to."What time is it?" said his father in a drugged voice. "Oh my God, it\'s <<six-thirty|5a:1>>," his mother said.'
          ],
          [
            1,
            'Timestr [06:30]: six-thirty',
            'It was <<six-thirty|9f>>. When the baby\'s cry came, they could not pick it out, and Sam, eagerly thrusting his face amongst their ears, said, "Listen, there, there, that\'s the new baby." He was red with delight and success.'
          ],
          [
            1,
            'Timestr [06:30]: six-thirty',
            "It was very cold sitting in the truck and after a while he got out and walked around and flailed at himself with his arms and stamped his boots. Then he got back in the truck. The bar clock said <<six-thirty|11>>...By <<eight-thirty|5b>> he\x{2019}d decided that it that was it would take to make the cab arrive then that\x{2019}s what he would do and he started the engine."
          ],
          [
            1,
            'Timestr [06:30]: half-past six',
            "Nervously she jumped up and listened; the house itself was as still as ever; the footsteps had retreated. Through her wide-open window the brilliant rays of the morning sun were flooding her room with light. She looked up at the clock; it was <<half-past six|10>>\x{2014}too early for any of the household to be already astir."
          ],
          [
            1,
            'Timestr [06:30]: six-thirty',
            '<<Six-thirty|5a:1>> was clearly a preposterous time and he, the client, obviously hadn\'t meant it seriously. A civilised <<six-thirty|5a:1>> for twelve <<noon|13>> was almost certainly what he had in mind, and if he wanted to cut up rough about it, Dirk would have no option but to start handing out some serious statistics. Nobody got murdered before lunch. But nobody. People weren\'t up to it. You needed a good lunch to get both the blood-sugar and blood-lust levels up. Dirk had the figures to prove it.'
          ],
          [
            1,
            'Timestr [06:30]: 6.30 in the morning',
            'Sometimes they were hooded carts, sometimes they were just open carts, with planks for seats, on which sat twelve cloaked and bonneted women, six a side, squeezed together, for the interminable journey. As late as 1914 I knew the carrier of Croydon-cum-Clopton, twelve miles from Cambridge; his cart started at <<6.30 in the morning|2a>> and got back at <<about ten at night|9h>>. Though he was not old, he could neither read nor write; but he took commissions all along the road - a packet of needles for Mrs. This, and a new teapot for Mrs. That - and delivered them all correctly on the way back.'
          ],
          [
            1,
            'Timestr [06:32]: twenty-eight minutes to seven',
            'The familiar radium numerals on my left wrist confirmed the clock tower. It was <<twenty-eight minutes to seven|10>>. I seemed to be filling a set of loud maroon pajamas which were certainly not mine. My vis-a-vis was wearing a little number in yellow.'
          ],
          [
            1,
            'Timestr [06:33]: 6.33 a.m.',
            'Woke <<6.33 a.m.|2a>> Last session with Anderson. He made it plain he\'s seen enough of me, and from now on I\'m better alone. To sleep <<8:00|2>>? (These count-downs terrify me.) He paused, then added: Goodbye, Eniwetok.'
          ],
          [
            1,
            'Timestr [06:35]: twenty-five minutes to seven',
            'My watch lay on the dressing-table close by; glancing at it, I saw that the time was <<twenty-five minutes to seven|10>>. I had been told that the family breakfasted at <<nine|9c:1>>, so I had nearly two-and-a-half hours of leisure. Of course, I would go out, and enjoy the freshness of the morning.'
          ],
          [
            1,
            'Timestr [06:36]: 6:36',
            'Kaldren pursues me like luminescent shadow. He has chalked up on the gateway \'96,688,365,498,702\'. Should confuse the mail man. Woke <<9:05|2>>. To sleep <<6:36|2>>.'
          ],
          [
            1,
            'Timestr [06:37]: 6.37am',
            'The dashboard clock said <<6.37am|2a>> Town frowned, and checked his wristwatch, which blinked that it was <<1.58pm|2a>>. Great, he thought. I was either up on that tree for eight hours, or for minus a minute.'
          ],
          [
            1,
            'Timestr [06:38]: 6.38am',
            'The clock on the dashboard said it was <<6.38am|2a>>. He left the keys in the car, and walked toward the tree.'
          ],
          [
            1,
            'Timestr [06:40]: twenty to seven',
            'At <<eleven o\'clock|6>> the phone rang, and still the figure did not respond, any more than it has responded when the phone had rung at <<twenty-five to seven in the morning|10>>, and again at <<twenty to seven|10>>'
          ],
          [
            1,
            'Timestr [06:43]: 6.43am',
            'To London on the <<6.43am|2a>>. Jessica is back from her holiday. Things are looking up, she called me Chris, instead of Minister, when we talked on the phone this afternoon.'
          ],
          [
            1,
            'Timestr [06:44]: 6.44',
            'Simon is happy to travel scum class when he\'s on his own and even sometimes deliberately aims for the <<6.25|5a:0>>. But today the .25 is delayed to <<6.44|5a:0>>.'
          ],
          [
            1,
            'Timestr [06:45]: quarter to seven',
            'As the clock pointed to a <<quarter to seven|10>>, the dog woke and shook himself. After waiting in vain for the footman, who was accustomed to let him out, the animal wandered restlessly from one closed door to another on the ground floor; and, returning to his mat in great perplexity, appealed to the sleeping family, with a long and melancholy howl.\''
          ],
          [
            1,
            'Timestr [06:45]: quarter to seven',
            'He was still hurriedly thinking all this through, unable to decide to get out of the bed, when the clock struck <<quarter to seven|10>>. There was a cautious knock at the door near his head. "Gregor", somebody called - it was his mother - "it\'s <<quarter to seven|10>>. Didn\'t you want to go somewhere?"'
          ],
          [
            1,
            'Timestr [06:46]: one minute after the quarter to seven',
            'At <<one minute after the quarter to seven|10>> I heard the rattle of the cans outside. I opened the front door, and there was my man, singling out my cans from a bunch he carried and whistling through his teeth.'
          ],
          [
            1,
            'Timestr [06:46]: one minute after the quarter to seven',
            'Then I hung about in the hall waiting for the milkman. That was the worst part of the business, for I was fairly choking to get out of doors. <<Six-thirty|5a:1>> passed, then <<six-forty|5a:1>>, but still he did not come. The fool had chosen this day of all days to be late. At <<one minute after the quarter to seven|10>> I heard the rattle of the cans outside. I opened the front door, and there was my man, singling out my cans from a bunch he carried and whistling through his teeth. He jumped a bit at the sight of me.'
          ],
          [
            1,
            'Timestr [06:49]: 6:49',
            'Night ends, <<6:49|2>>. Meet in the coffee shop at <<7:30|2>>; press conference at <<10:00|2>>.'
          ],
          [
            1,
            'Timestr [06:50]: six-fifty',
            "Will, my fianc\x{e9}, was coming from Boston on the <<six-fifty|5a:1>> train - the dawn train, the only train that still stopped in the small Ohio city where I lived."
          ],
          [
            1,
            'Timestr [06:55]: 6:55 am',
            'At <<6:55 am|2a>> Lisa parked and took the lift from the frozen underground car park up to level 1 of Green Oaks Shopping Centre.'
          ],
          [
            1,
            'Timestr [06:59]: 6.59 a.m.',
            'It was <<6.59 a.m.|2a>> on Maundy Thursday as Blomkvist and Berger let themselves into the "Millennium" offices.'
          ],
          [
            1,
            'Timestr [07:00]: seven o\'clock',
            '"<<Seven o\'clock|6>>, already", he said to himself when the clock struck again, "<<seven o\'clock|6>>, and there\'s still a fog like this."'
          ],
          [
            1,
            "Timestr [07:00]: seven o\x{2019}clock in the morning",
            "At <<seven o\x{2019}clock in the morning|6>>, Rubashov was awakened by a bugle, but he did not get up. Soon he heard sounds in the corridor. He imagined that someone was to be tortured, and he dreaded hearing the first screams of pain. When the footsteps reached his own section, he saw through the eye hole that guards were serving breakfast. Rubashov did not receive any breakfast because he had reported himself ill. He began to pace up and down the cell, six and a half steps to the window, six and a half steps back."
          ],
          [
            1,
            'Timestr [07:00]: seven',
            'I had left directions that I was to be called at <<seven|9f>>; for it was plain that I must see Wemmick before seeing any one else, and equally plain that this was a case in which his Walworth sentiments, only, could be taken. It was a relief to get out of the room where the night had been so miserable, and I needed no second knocking at the door to startle me from my uneasy bed.'
          ],
          [
            1,
            'Timestr [07:00]: seven o\'clock',
            'She locked herself in, made no reply to my bonjour through the door; she was up at <<seven o\'clock|6>>, the samovar was taken in to her from the kitchen.'
          ],
          [
            1,
            'Timestr [07:02]: 07:02',
            '<<07:02|2>>:18 One and a half hours. \'Case,\' she said, \'I wanna favour.\''
          ],
          [
            1,
            'Timestr [07:03]: 7:03am',
            '<<7:03am|2a>> General Tanz woke up as though aroused by a mental alarm-clock.'
          ],
          [
            1,
            'Timestr [19:04]: about 7:04 p.m.',
            'Sunday evening at almost the same hour (to be precise, at <<about 7:04 p.m.|2a>>) she rings the front door bell at the home of Walter Moeding, Crime Commissioner, who is at that moment engaged, for professional rather than private reasons, in disguising himself as a sheikh.'
          ],
          [
            1,
            'Timestr [07:05]: five minutes after seven o\'clock',
            'He really couldn\'t believe that the old woman who\'d phoned him last night would show up this morning, as she\'d said she would. He decided he\'d wait until <<five minutes after seven o\'clock|10>>, and then he\'d call in, take the day off, and make every effort in the book to locate someone reliable.'
          ],
          [
            1,
            'Timestr [07:05]: five after seven',
            'Outside my window the sky hung low and gray. It looked like snow, which added to my malaise. The clock read <<five after seven|10>>. I punched the remote control and watched the morning news as I lay in bed.'
          ],
          [
            1,
            'Timestr [07:05]: 7:05 A.M.',
            'Ryan missed the dawn. He boarded a TWA 747 that left Dulles on time, at <<7:05 A.M.|2a>> The sky was overcast, and when the aircraft burst through the cloud layer into sunlight, Ryan did something he had never done before. For the first time in his life, Jack Ryan fell asleep on an airplane.'
          ],
          [
            1,
            'Timestr [07:06]: six minutes past seven',
            'So far so good. There followed a little passage of time when we stood by the duty desk, drinking coffee and studiously not mentioning what we were all thinking and hoping: that Percy was late, that maybe Percy wasn\'t going to show up at all. Considering the hostile reviews he\'d gotten on the way he\'d handled the electrocution, that seemed at least possible. But Percy subscribed to that old axiom about how you should get right back on the horse that had thrown you, because here he came through the door at <<six minutes past seven|10>>, resplendent in his blue uniform with his sidearm on one hip and his hickory stick in its ridiculous custom-made holster on the other.'
          ],
          [
            1,
            'Timestr [07:06]: six minutes past seven',
            'Percy subscribed to that old axiom about how you should get right back on the horse that had thrown you, because here he came through the door at <<six minutes past seven|10>>, resplendent in his blue uniform with his sidearm on one hip and his hickory stick in its ridiculous custom-made holster on the other.'
          ],
          [
            1,
            'Timestr [07:08]: between eight and nine minutes after seven o\'clock',
            'Reacher had no watch but he figured when he saw Gregory it must have been <<between eight and nine minutes after seven o\'clock|10>>.'
          ],
          [
            1,
            'Timestr [07:09]: seven-nine',
            'In the living room the voice-clock sang, Tick-tock, <<seven o\'clock|6>>, time to get up, time to get up, seven o \'clock! as if it were afraid that nobody would. The morning house lay empty. The clock ticked on, repeating and repeating its sounds into the emptiness. <<Seven-nine|9j>>, breakfast time, <<seven-nine|5a:1>>!'
          ],
          [
            1,
            'Timestr [07:09]: seven-nine',
            '<<Seven-nine|9j>>, breakfast time, <<seven-nine|5a:0>>!'
          ],
          [
            1,
            'Timestr [07:10]: 7.10',
            'A search in Bradshaw informed me that a train left St Pancras at <<7.10|9c:1>>, which would land me at any Galloway station in the late afternoon.'
          ],
          [
            1,
            'Timestr [07:10]: 7:10 in the morning',
            'There were many others waiting to execute the same operation, so she would have to move fast, elbow her way to the front so that she emerged first. The time was <<7:10 in the morning|2a>>. The manoeuvre would start at <<7:12|9g>>. She looked apprehensively at the giant clock at the railway station.'
          ],
          [
            1,
            'Timestr [07:12]: 7:12',
            'He taught me that if I had to meet someone for an appointment, I must refuse to follow the \'stupid human habit\' of arbitrarily choosing a time based on fifteen-minute intervals. \'Never meet people at <<7:45|2>> or <<6:30|2>>, Jasper, but pick times like <<7:12|2>> and <<8:03|2>>!\''
          ],
          [
            1,
            'Timestr [07:13]: seven-thirteen',
            'It was all the more surprising and indeed alarming a little later, said Austerlitz, when I looked out of the corridor window of my carriage just before the train left at <<seven-thirteen|5b>>, to find it dawning upon me with perfect certainty that I had seen the pattern of glass and steel roof above the platforms before.'
          ],
          [
            1,
            'Timestr [07:14]: 7.14',
            'At <<7.14|9m>> Harry knew he was alive. He knew that because the pain could be felt in every nerve fibre.'
          ],
          [
            1,
            'Timestr [07:15]: 7:15 A.M.',
            'At <<7:15 A.M.|2a>>, January 25th, we started flying northwestward under McTighe\'s pilotage with ten men, seven dogs, a sledge, a fuel and food supply, and other items including the plane\'s wireless outfit.'
          ],
          [
            1,
            'Timestr [07:15]: 7.15',
            'Gough again knocked on Mr and Mrs Kent\'s bedroom door. This time it was opened - Mary Kent had got out of bed and put on her dressing gown, having just checked her husband\'s watch: it was <<7.15|9f>>. A confused conversation ensued, in which each woman seemed to assume Saville was with the other.'
          ],
          [
            1,
            'Timestr [07:15]: 7.15',
            'Gough again knocked on Mr and Mrs Kent\'s bedroom door. This time it was opened - Mary Kent had got out of bed and put on her dressing gown, having just checked her husband\'s watch: it was <<7.15|9f>>. A confused conversation ensued, in which each woman seemed to assume Saville was with the other.'
          ],
          [
            1,
            'Timestr [07:15]: quarter-past seven',
            "It was early in April in the year \x{2019}83 that I woke one morning to find Sherlock Holmes standing, fully dressed, by the side of my bed. He was a late riser, as a rule, and as the clock on the mantelpiece showed me that it was only a <<quarter-past seven|10>>, I blinked up at him in some surprise, and perhaps just a little resentment, for I was myself regular in my habits."
          ],
          [
            1,
            'Timestr [07:17]: 7.17am',
            'As of <<7.17am|2a>> local time on 30 June 1908, Padzhitnoff had been working for nearly a year as a contract employee of the Okhrana, receiving five hundred rubles a month, a sum which hovered at the exorbitant end of spy-budget outlays for those years.'
          ],
          [
            1,
            'Timestr [07:19]: 7.19am',
            'I opened the sunroof and turned up the CD player volume to combat fatigue, and at <<7.19am|2a>> on Saturday, with the caffeine still running all around my brain, Jackson Browne and I pulled into Moree.'
          ],
          [
            1,
            'Timestr [07:20]: 7.20 a.m.',
            'And this was my timetable when I lived at home with Father and I thought that Mother was dead from a heart attack (this was the timetable for a Monday and also it is an approximation). <<7.20 a.m.|2a>> Wake up'
          ],
          [
            1,
            'Timestr [07:20]: seven-twenty',
            'He who had been a boy very credulous of life was no longer greatly interested in the possible and improbable adventures of each new day. He escaped from reality till the alarm-clock rang, at <<seven-twenty|5b>>.'
          ],
          [
            1,
            'Timestr [07:25]: 7.25 a.m.',
            '<<7.25 a.m.|2a>> clean teeth and wash face'
          ],
          [
            1,
            'Timestr [07:27]: 7.27',
            'His appointment with the doctor was for <<8.45|5a:0>>. It was <<7.27|9f>>.'
          ],
          [
            1,
            'Timestr [07:29]: 7.29 in the morning',
            'At <<7.29 in the morning|2a>> of 1 July, the cinematographer finds himself filming silence itself.'
          ],
          [
            1,
            'Timestr [07:30]: half-past seven',
            'At <<half-past seven|10>> the next morning he rang the bell of 21 Blenheim Avenue.'
          ],
          [
            1,
            'Timestr [07:30]: half past seven',
            'Precisely at <<half past seven|10>> the station-master came into the traffic office. He weighed almost sixteen stone, but women always said that he was incredibly light on his feet when he danced.'
          ],
          [
            1,
            'Timestr [07:32]: 7:32',
            'At <<7:32|2>>, he suffered a fatal stroke.'
          ],
          [
            1,
            'Timestr [07:34]: 7:34',
            '<<7:34|2>>. Monday morning, Blackeberg. The burglar alarm at the ICA grocery store on Arvid Morne\'s way is set off.'
          ],
          [
            1,
            'Timestr [07:35]: 7:35am',
            'At <<7:35am|2a>> Ishigami left his apartment as he did every weekday morning.'
          ],
          [
            1,
            'Timestr [07:35]: seven thirty-five',
            'I looked at my watch. <<Seven thirty-five|9j>>.'
          ],
          [
            1,
            'Timestr [07:36]: 7:36',
            '<<7:36|2>>, sunrise. The hospital blinds were much better, darker than her own.'
          ],
          [
            1,
            'Timestr [07:39]: 7.39',
            'Now, at the station, do you recall speaking to Mr Joseph Markew?\' \'Yes, indeed. I was standing on the platform waiting for my usual train - the <<7.39|9j>> - when he accosted me.\''
          ],
          [
            1,
            'Timestr [07:40]: 7.40 a.m.',
            '<<7.40 a.m.|2a>> Have breakfast.'
          ],
          [
            1,
            'Timestr [07:42]: seven forty-two am',
            '<<Seven forty-two am|5>>., Mr Gasparian: I curse you. I curse your arms so they will wither and die and fall off your body...'
          ],
          [
            1,
            'Timestr [07:44]: seven forty-four',
            'And there I was, complaining that all this was just inconvenient, Anna castigates herself. The Goth was obviously right. What does it matter, really, if I\'m a bit late for work? She voices her thoughts: "It\'s not exactly how you\'d choose to go, is it? You\'d rather die flying a kite with your grandchildren, or at a great party or something. Not on the <<seven forty-four|5a:0>>."'
          ],
          [
            1,
            'Timestr [07:44]: seven forty-four',
            'The Goth was obviously right. What does it matter, really, if I\'m a bit late for work? She voices her thoughts: "It\'s not exactly how you\'d choose to go, is it? You\'d rather die flying a kite with your grandchildren, or at a great party or something. Not on the <<seven forty-four|5a:0>>."'
          ],
          [
            1,
            'Timestr [07:45]: quarter to eight',
            'Mr Green left for work at a <<quarter to eight|10>>, as he did every morning. He walked down his front steps carrying his empty-looking leatherette briefcase with the noisy silver clasps, opened his car door, and ducked his head to climb into the driver\'s seat.'
          ],
          [
            1,
            'Timestr [07:45]: quarter to eight',
            'Mr Green left for work at a <<quarter to eight|10>>, as he did every morning. He walked down his front steps carrying his empty-looking leatherette briefcase with the noisy silver clasps, opened his car door, and ducked his head to climb into the driver\'s seat.'
          ],
          [
            1,
            'Timestr [07:46]: 7.46 a.m.',
            'He awoke with a start. The clock on his bedside table said <<7.46 a.m.|2a>> He cursed, jumped out of bed and dressed. He stuffed his toothbrush and toothpaste in his jacket pocket, and parked outside the station <<just before 8 a.m.|10>> In reception, Ebba beckoned to him.'
          ],
          [
            1,
            'Timestr [07:50]: about ten minutes to eight',
            'At <<about ten minutes to eight|10>>, Jim had squared the part of the work he had been doing - the window - so he decided not to start on the door or the skirting until after breakfast.'
          ],
          [
            1,
            'Timestr [07:51]: nine minutes to eight',
            'Vimes fished out the Gooseberry as a red-hot cabbage smacked into the road behind him. "Good morning!" he said brightly to the surprised imp. "What is the time, please?" "Er...<<nine minutes to eight|10>>, Insert Name Here," said the imp.'
          ],
          [
            1,
            'Timestr [07:53]: seven to eight',
            '"What time is it?" "<<Seven to eight|10a:1>>. Won\'t be long now ..."'
          ],
          [
            1,
            'Timestr [07:55]: 7.55',
            'at <<7.55|3b>> this morning the circus ran away to join me.'
          ],
          [
            1,
            'Timestr [07:56]: seven fifty-six',
            'I sit by the window, crunching toast, sipping coffee, and leafing through the paper in a leisurely way. At last, after devouring three slices, two cups of coffee, and all the Saturday sections, I stretch my arms in a big yawn and glance at the clock. I don\'t believe it. It\'s only <<seven fifty-six|5a:1>>.'
          ],
          [
            1,
            'Timestr [07:56]: four minutes to eight',
            'The Castle Gate - only the Castle Gate - and it was <<four minutes to eight|10>>.'
          ],
          [
            1,
            'Timestr [07:59]: 7.59 in the morning',
            'I\'d spent fifty two days in 1958, but here it was <<7.59 in the morning|2a>>.'
          ],
          [
            1,
            'Timestr [08:00]: 8 a.m.',
            '"I\'m not crying," Maria said when Carter called from the desert at <<8 a.m.|5>> "I\'m perfectly alright". "You don\'t sound perfectly alright'
          ],
          [
            1,
            'Timestr [08:00]: 8.00 a.m.',
            '<<8.00 a.m.|2a>> Put school clothes on'
          ],
          [
            1,
            'Timestr [08:00]: 8 o\'clock',
            'At <<8 o\'clock|6>> on Thursday morning Arthur didn\'t feel very good.'
          ],
          [
            1,
            'Timestr [08:00]: eight o\'clock',
            'At <<eight o\'clock|6>> on Thursday morning Arthur didn\'t feel very good. He woke up blearily, got up, wandered blearily round his room, opened a window, saw a bulldozer, found his slippers and stomped off to the bathroom to wash.'
          ],
          [
            1,
            "Timestr [08:00]: eight o\x{2019}clock",
            "At <<eight o\x{2019}clock|6>>, a shaft of daylight came to wake us. The thousand facets of the lava on the rock face picked it up as it passed, scattering like a shower of sparks."
          ],
          [
            1,
            'Timestr [08:00]: eight o\'clock',
            'But for now it was still <<eight o\'clock|6>>, and as I walked along the avenue under that brilliant blue sky, I was happy, my friends, as happy as any man who had ever lived.'
          ],
          [
            1,
            'Timestr [08:00]: eight o\'clock',
            'By <<eight o\'clock|6>> Stillman would come out, always in his long brown overcoat, carrying a large, old-fashioned carpet bag. For two weeks this routine did not vary. The old man would wander through the streets of the neighbourhood, advancing slowly, sometimes by the merest of increments, pausing, moving on again, pausing once more, as though each step had to be weighed and measured before it could take its place among the sum total of steps.'
          ],
          [
            1,
            'Timestr [08:00]: eight',
            'Dressed in sweater, anorak and long johns, he lay in bed, hemmed in on three sides by chunky wooden beams, and ate all the salted snacks in the minibar, and then all the sugary snacks, and when he was woken by reception at <<eight|9a>> the following morning to be told that everyone was waiting for him downstairs, the wrapper of a Mars bar was still folded in his fist.'
          ],
          [
            1,
            'Timestr [08:00]: eight',
            'I hear noise at the ward door, off up the hall out of my sight. That ward door starts opening at <<eight|9c:0>> and opens and closes a thousand times a day, kashash, click.'
          ],
          [
            1,
            'Timestr [08:00]: eight o\'clock in the morning',
            'It was dated from Rosings, at <<eight o\'clock in the morning|6>>, and was as follows: - "Be not alarmed, madam, on receiving this letter, by the apprehension of its containing any repetition of those sentiments or renewal of those offerings which were last night so disgusting to you.'
          ],
          [
            1,
            'Timestr [08:00]: eight o\'clock',
            'Mr. Pumblechook and I breakfasted at <<eight o\'clock|6>> in the parlour behind the shop, while the shopman took his mug of tea and hunch of bread-and-butter on a sack of peas in the front premises.'
          ],
          [
            1,
            'Timestr [08:02]: after eight o\'clock a.m.',
            'Mrs. Rochester! She did not exist: she would not be born till to-morrow, some time <<after eight o\'clock a.m.|6>>; and I would wait to be assured she had come into the world alive, before I assigned to her all that property.'
          ],
          [
            1,
            'Timestr [08:00]: eight',
            'So here I\'ll watch the night and wait To see the morning shine, When he will hear the stroke of <<eight|12>> And not the stroke of <<nine|12>>;'
          ],
          [
            1,
            'Timestr [08:00]: eight o\'clock',
            'Someone must have been telling lies about Joseph K. for without having done anything wrong he was arrested one fine morning. His landlady\'s cook, who always brought him breakfast at <<eight o\'clock|6>>, failed to appear on this occasion.'
          ],
          [
            -1,
            'Timestr [08:00]: oh eight oh oh hours',
            'The next morning I woke up at <<oh eight oh oh hours|99>>, my brothers, and as I still felt shagged and fagged and fashed and bashed and as my glazzies were stuck together real horrorshow with sleepglue, I thought I would not go to school .'
          ],
          [
            1,
            'Timestr [08:00]: eight o\'clock in the morning',
            'Three days after the quarrel, Prince Stepan Arkadyevitch Oblonsky--Stiva, as he was called in the fashionable world-- woke up at his usual hour, that is, at <<eight o\'clock in the morning|6>>, not in his wife\'s bedroom, but on the leather-covered sofa in his study.'
          ],
          [
            1,
            'Timestr [08:00]: eight',
            'Through the curtained windows of the furnished apartment which Mrs. Horace Hignett had rented for her stay in New York rays of golden sunlight peeped in like the foremost spies of some advancing army. It was a fine summer morning. The hands of the Dutch clock in the hall pointed to <<thirteen minutes past nine|10>>; those of the ormolu clock in the sitting-room to <<eleven minutes past ten|10>>; those of the carriage clock on the bookshelf to <<fourteen minutes to six|10>>. In other words, it was exactly <<eight|9f>>; and Mrs. Hignett acknowledged the fact by moving her head on the pillow, opening her eyes, and sitting up in bed. She always woke at <<eight|9b>> precisely.'
          ],
          [
            1,
            'Timestr [08:00]: eight',
            'When he opened the windows in the morning, the sky was as overcast as it had been, but the air seemed fresher, and regret set in. Had giving notice not been impetuous and wrongheaded, the result of an inconsequential indisposition? If he had held off a bit, if he had not been so quick to lose heart, if he had instead tried to adjust to the air or wait for the weather to improve, he would now have been free of stress and strain and looking forward to a morning on the beach like the one the day before. Too late. He must go on wanting what he had wanted yesterday. He dressed and rode down to the ground floor at <<eight|9a>> for breakfast.'
          ],
          [
            1,
            'Timestr [08:01]: eight-one',
            '<<Eight-one|9j>>, tick-tock, <<eight-one o\'clock|6>>, off to school, off to work, run, run, <<eight-one|5a:1>>!'
          ],
          [
            1,
            'Timestr [08:02]: Eight oh two',
            '... bingeley ... <<Eight oh two|5a:0>> eh em, Death of Corporal Littlebottombottom ... <<Eight oh three|5a:0>> eh em ... Death of Sergeant Detritus ... Eight oh threethreethree eh em and seven seconds seconds ... Death of Constable Visit ... <<Eight oh three|5a:0>> eh em and nineninenine seconds ... Death of death of death of ...'
          ],
          [
            1,
            'Timestr [08:03]: Eight oh three',
            '... bingeley ... <<Eight oh two|5a:0>> eh em, Death of Corporal Littlebottombottom ... <<Eight oh three|5a:0>> eh em ... Death of Sergeant Detritus ... Eight oh threethreethree eh em and seven seconds seconds ... Death of Constable Visit ... <<Eight oh three|5a:0>> eh em and nineninenine seconds ... Death of death of death of ...'
          ],
          [
            1,
            'Timestr [08:03]: 8:03',
            'He taught me that if I had to meet someone for an appointment, I must refuse to follow the \'stupid human habit\' of arbitrarily choosing a time based on fifteen-minute intervals. \'Never meet people at <<7:45|2>> or <<6:30|2>>, Jasper, but pick times like <<7:12|2>> and <<8:03|2>>!\''
          ],
          [
            1,
            'Timestr [08:04]: 8:04',
            '... every clerk had his particular schedule of hours, which coincided with a single pair of tram runs coming from the city: A had to come in at <<8|9c:0>>, B at <<8:04|2>>, C at <<8:08|2>> and so on, and the same for quitting times, in such a manner that never would two colleagues have the opportunity to travel in the same tramcar.'
          ],
          [
            1,
            'Timestr [08:05]: 8.05 a.m.',
            '<<8.05 a.m.|2a>> Pack school bag'
          ],
          [
            1,
            'Timestr [08:08]: 8:08',
            '... every clerk had his particular schedule of hours, which coincided with a single pair of tram runs coming from the city: A had to come in at <<8|9c:0>>, B at <<8:04|2>>, C at <<8:08|2>> and so on, and the same for quitting times, in such a manner that never would two colleagues have the opportunity to travel in the same tramcar.'
          ],
          [
            1,
            'Timestr [08:09]: 8:09',
            'He followed the squeals down a hallway. A wall clock read <<8:09|2>> - <<10:09|2>> Dallas time.'
          ],
          [
            1,
            'Timestr [08:10]: 8.10 a.m.',
            '<<8.10 a.m.|2a>> Read book or watch video'
          ],
          [
            1,
            'Timestr [08:10]: 8:10',
            'Amory rushed into the house and the rest followed with a limp mass that they laid on the sofa in the shoddy little front parlor. Sloane, with his shoulder punctured, was on another lounge. He was half delirious, and kept calling something about a chemistry lecture at <<8:10|2>>.'
          ],
          [
            1,
            'Timestr [08:10]: 8:10',
            'Cell count down to 400,000. Woke <<8:10|2>>. To sleep <<7:15|2>>. (Appear to have lost my watch without realising it, had to drive into town to buy another.)'
          ],
          [
            1,
            'Timestr [08:11]: eight-eleven',
            '\'Care for a turn on the engine?\' he called to the doxies, and pointed up at the footplate. They laughed but voted not to, climbing up with their bathtub into one of the rattlers instead. They both had very fetching hats, with one flower apiece, but the prettiness of their faces made you think it was more. For some reason they both wore white rosettes pinned to their dresses. I looked again at the clock: <<eight-eleven|9j>>.'
          ],
          [
            1,
            'Timestr [08:12]: 8:12 a.m.',
            'At <<8:12 a.m.|2a>>, just before the moment of pff, all the business of the cellars was being transacted - garbage transferred from small cans into large ones; early wide-awake grandmas, rocky with insomnia, dumped wash into the big tubs; boys in swimming trunks rolled baby carriages out into the cool morning.'
          ],
          [
            1,
            'Timestr [08:13]: 8:13 a.m.',
            'At <<8:13 a.m.|2a>> the alarm clock in the laboratory gave the ringing word. Eddie touched a button in the substructure of an ordinary glass coffeepot, from whose spout two tubes proceeded into the wall.'
          ],
          [
            1,
            'Timestr [08:15]: quarter-past eight',
            'It was in the winter when this happened, very near the shortest day, and a week of fog into the bargain, so the fact that it was still very dark when George woke in the morning was no guide to him as to the time. He reached up, and hauled down his watch. It was a <<quarter-past eight|10>>.'
          ],
          [
            1,
            'Timestr [08:15]: eight fifteen',
            'You scrutinized your wrist: "It\'s <<eight fifteen|9f>>. (And here time forked.) I\'ll turn it on." The screen In its blank broth evolved a lifelike blur, And music welled.'
          ],
          [
            1,
            'Timestr [08:16]: eight sixteen',
            'I walk through the fruit trees toward a huge, square, brown patch of earth with vegetation growing in serried rows. These must be the vegetables. I prod one of them cautiously with my foot. It could be a cabbage or a lettuce. Or the leaves of something growing underground, maybe. To be honest, it could be an alien. I have no idea. I sit down on a mossy wooden bench and look at a nearby bush covered in white flowers. Mm. Pretty. Now what? What do people do in their gardens? I feel I should have something to read. Or someone to call. My fingers are itching to move. I look at my watch. Still only <<eight sixteen|5a:1>>. Oh God.'
          ],
          [
            1,
            'Timestr [08:17]: 8.17 a.m.',
            "Breakfast over, my uncle drew from his pocket a small notebook, intended for scientific observations. He consulted his instruments, and recorded:
\x{201c}Monday, July 1.
\x{201c}Chronometer, <<8.17 a.m.|2a>>; barometer, 297 in.; thermometer, 6\x{b0} (43\x{b0} F.). Direction, E.S.E.\x{201d}
This last observation applied to the dark gallery, and was indicated by the compass."
          ],
          [
            1,
            'Timestr [08:17]: eight seventeen',
            'Come on, I can\'t give up yet. I\'ll just sit here for a bit and enjoy the peace. I lean back and watch a little speckled bird pecking the ground nearby for a while. Then I look at my watch again: <<eight seventeen|9j>>. I can\'t do this.'
          ],
          [
            1,
            'Timestr [08:19]: 8.19',
            'I had arranged to meet the Occupational Health Officer at <<10:30|2>>. I took the train from Watford Junction at <<8.19|9c:1>> and arrived at London Euston seven minutes late, at <<8.49|9:1>>.'
          ],
          [
            1,
            'Timestr [08:20]: 8:20',
            'When the typewriters happen to pause (<<8:20|2>> and other mythical hours), and there are no flights of American bombers in the sky, and the motor traffic\'s not too heavy in Oxford Street, you can hear winter birds cheeping outside, busy at the feeders the girls have put up.'
          ],
          [
            1,
            'Timestr [08:23]: twenty-three minutes past eight',
            "And then Wedderburn looked at his watch. \"<<Twenty-three minutes past eight|10>>. I am going up by the <<quarter to twelve|10>> train, so that there is plenty of time. I think I shall wear my alpaca jacket - it is quite warm enough - and my grey felt hat and brown shoes. I suppose\x{201d}"
          ],
          [
            1,
            'Timestr [08:23]: 8:23',
            'At <<8:23|2>> there seemed every chance of a lasting alliance starting between Florin and Guilder. At <<8:24|2>> the two nations were very close to war.'
          ],
          [
            1,
            'Timestr [08:24]: 8:24',
            'At <<8:23|2>> there seemed every chance of a lasting alliance starting between Florin and Guilder. At <<8:24|2>> the two nations were very close to war.'
          ],
          [
            1,
            'Timestr [08:26]: twenty-six minutes past eight',
            'It exploded much later than intended, probably a good twelve hours later, at <<twenty-six minutes past eight|10>> on Monday morning. Several defunct wristwatches, the property of victims, confirmed the time. As with its predecessors over the last few months, there had been no warning.'
          ],
          [
            1,
            'Timestr [08:27]: almost eight-thirty',
            'The lecture was to be given tomorrow, and it was now <<almost eight-thirty|5a:0>>.'
          ],
          [
            1,
            'Timestr [08:28]: 8.28',
            'And at <<8.28|3:0>> on the following morning, with a novel chilliness about the upper lip, and a vast excess of strength and spirits, I was sitting in a third-class carriage, bound for Germany, and dressed as a young sea-man, in a pea-jacket, peaked cap, and comforter.'
          ],
          [
            1,
            'Timestr [08:29]: 8.29',
            'At <<8.29|9m>> I punched the front doorbell in Elgin Crescent. It was opened by a small oriental woman in a white apron. She showed me into a large, empty sitting room with an open fire and a couple of huge oil paintings.'
          ],
          [
            1,
            'Timestr [08:30]: half past eight',
            'At <<half past eight|10>>, Mr. Dursley picked up his briefcase, pecked Mrs. Dursley on the cheek, and tried to kiss Dudley good-bye but missed, because Dudley was now having a tantrum and throwing his cereal at the walls.'
          ],
          [
            1,
            'Timestr [08:30]: around 8:30',
            'It is <<around 8:30|9f>>. Sunshine comes through the windows at right. As the curtain rises, the family has just finished breakfast.'
          ],
          [
            1,
            'Timestr [08:30]: 8:30 a.m.',
            'On July 25th, <<8:30 a.m.|2a>> the bitch Novaya dies whelping. At <<10 o\'clock|6>> she is lowered into her cool grave, at <<7:30 that same evening|2a>> we see our first floes and greet them wishing they were the last.'
          ],
          [
            1,
            'Timestr [08:30]: almost eight-thirty',
            'The lecture was to be given tomorrow, and it was now <<almost eight-thirty|5a:0>>.'
          ],
          [
            1,
            'Timestr [08:30]: eight-thirty',
            'When he woke, at <<eight-thirty|5b>>, he was alone in the bedroom. He put on his dressing gown and put in his hearing aid and went into the living room.'
          ],
          [
            -1,
            'Timestr [08:32]: 0832',
            '\'Does anybody know the time a little more exactly is what I\'m wondering, Don, since Day doesn\'t.\' Gately checks his cheap digital, head still hung over the sofa\'s arm. \'I got <<0832|99>>:14, 15, 16, Randy.\' \'\'ks a lot, D.G. man.\''
          ],
          [
            1,
            'Timestr [08:32]: 8.32 a.m.',
            '<<8.32 a.m.|2a>> Catch bus to school'
          ],
          [
            1,
            'Timestr [08:35]: thirty-five minutes past eight',
            'It was <<thirty-five minutes past eight|10>> by the big clock of the central building when Mathieu crossed the yard towards the office which he occupied as chief designer. For eight years he had been employed at the works where, after a brilliant and special course of study, he had made his beginning as assistant draughtsman when but nineteen years old, receiving at that time a salary of one hundred francs a month.'
          ],
          [
            1,
            'Timestr [08:35]: 8.35 a.m.',
            'Old gummy granny (thrusts a dagger towards Stephen\'s hand) Remove him, acushla. At <<8.35 a.m.|2a>> you will be in heaven and Ireland will be free (she prays) O good God take him!'
          ],
          [
            1,
            'Timestr [08:37]: eight thirty-seven am',
            '<<Eight thirty-seven am|5>>., Patrice Lane, Biohazard: The dog\'s clean. The Good Samaritan was a woman with an accent of some sort. Why haven\'t you called me?'
          ],
          [
            1,
            'Timestr [08:39]: 8:39 A.M.',
            'Doug McGuire noticed the early hour, <<8:39 A.M.|2a>> on the one wall clock that gave Daylight Savings Time for the East Coast.'
          ],
          [
            1,
            'Timestr [08:40]: 8.40',
            'At this moment the clock indicated <<8.40|5a:1>>. \'Five minutes more,\' said Andrew Stuart. The five friends looked at each other. One may surmise that their heart-beats were slightly accelerated, for, even for bold gamblers, the stake was a large one.\''
          ],
          [
            1,
            'Timestr [08:40]: twenty minutes to nine',
            'It was when I stood before her, avoiding her eyes, that I took note of the surrounding objects in detail, and saw that her watch had stopped at <<twenty minutes to nine|10>>, and that a clock in the room had stopped at <<twenty minutes to nine|10>>.'
          ],
          [
            1,
            'Timestr [08:41]: forty-one minutes past eight',
            "By <<forty-one minutes past eight|10>> we are five hundred yards from the water\x{2019}s edge, and between our road and the foot of the mountain we descry the piled-up remains of a ruined tower."
          ],
          [
            1,
            "Timestr [08:43]: eight forty-three in the mornin\'",
            '"You understand this tape recorder is on?" "Uh huh" "And it\'s Wednesday, May 15, at <<eight forty-three in the mornin\'|5>>." "If you say so"'
          ],
          [
            1,
            'Timestr [08:43]: 8.43 a.m.',
            '<<8.43 a.m.|2a>> Go past tropical fish shop'
          ],
          [
            1,
            'Timestr [08:44]: eight forty-four',
            'Several soldiers - some with their uniforms unbuttoned - were looking over a motorcycle, arguing about it. The sergeant looked at his watch; it was <<eight forty-four|9f>>. They had to wait until <<nine|9c:1>>. Hladik, feeling more insignificant than ill-fortuned, sat down on a pile of firewood.'
          ],
          [
            1,
            'Timestr [08:45]: 8:45',
            "He paid the waitress and left the caf\x{e9}. It was <<8:45|9f>>. The sun pressed against the inside of a thin layer of cloud. He unbuttoned his jacket as he hurried down Queensway. His mind, unleashed, sprang forwards."
          ],
          [
            1,
            'Timestr [08:47]: 8.47',
            '"Just on my way to the cottage. It\'s, er, ..<<8.47|5a:0>>. Bit misty on the roads....."'
          ],
          [
            1,
            'Timestr [08:47]: 8.47',
            '<<8.47|9j>>. Bit misty on the roads'
          ],
          [
            1,
            'Timestr [08:49]: 8.49',
            'I had arranged to meet the Occupational Health Officer at <<10:30|2>>. I took the train from Watford Junction at <<8.19|9c:1>> and arrived at London Euston seven minutes late, at <<8.49|9:1>>.'
          ],
          [
            1,
            'Timestr [08:50]: ten to nine',
            'At <<ten to nine|10>> the clerks began to arrive. When they had hung up their coats and hates they came to the fireplace and stood warming themselves. If there was no fire, they stood there all the same'
          ],
          [
            1,
            'Timestr [08:50]: 8:50 in the morning',
            'It was <<8:50 in the morning|2a>> and Bernie and I were alone on an Astoria side street, not far from a sandwich shop that sold a sopressatta sub called "The Bypass". I used to eat that sandwich weekly, wash it down with espresso soda, smoke a cigarette, go for a jog. Now I was too near the joke to order the sandwich, and my son\'s preschool in the throes of doctrinal schism.'
          ],
          [
            1,
            'Timestr [08:50]: ten minutes to nine',
            'Punctually at <<ten minutes to nine|10>>, a quarter hour after early mass, the boy stood in his Sunday uniform outside his father\'s door.'
          ],
          [
            1,
            'Timestr [08:51]: 8.51 a.m.',
            '<<8.51 a.m.|2a>> Arrive at school'
          ],
          [
            1,
            'Timestr [08:52]: 8.52am',
            'Message one. Tuesday, <<8.52am|2a>>. Is anybody there? Hello?'
          ],
          [
            1,
            "Timestr [08:54]: nearly nine o\x{2019}clock",
            "It was Mrs. Poppets that woke me up next morning. She said: \x{201c}Do you know that it\x{2019}s <<nearly nine o\x{2019}clock|6>>, sir?\x{201d} \x{201c}Nine o\x{2019} what?\x{201d} I cried, starting up. \x{201c}<<Nine o\x{2019}clock|6>>,\x{201d} she replied, through the keyhole. \x{201c}I thought you was a- oversleeping yourselves.\x{201d}"
          ],
          [
            1,
            'Timestr [08:55]: five minutes to nine',
            "At <<five minutes to nine|10>>, Jacques, in his gray butler's livery, came down the stairs and said, \"Young master, your Herr Pap\x{e1} is coming.\""
          ],
          [
            1,
            'Timestr [08:55]: five minutes to nine',
            'George pulled out his watch and looked at it: it was <<five minutes to nine|10>>!'
          ],
          [
            1,
            'Timestr [08:56]: nearly nine o\'clock',
            'It was <<nearly nine o\'clock|6>> and the sun was fiercer every minute.\''
          ],
          [
            1,
            'Timestr [08:57]: three minutes before nine o\'clock',
            'You\'ll have to hurry. Many a long year before that, in one of the bygone centuries, a worthy citizen of Wrychester, Martin by name, had left a sum of money to the Dean and Chapter of the Cathedral on condition that as long as ever the Cathedral stood, they should cause to be rung a bell from its smaller bell-tower for <<three minutes before nine o\'clock|10>> every morning, all the year round.'
          ],
          [
            1,
            'Timestr [08:58]: two minutes of nine',
            'It was <<two minutes of nine|10>> now - two minutes before the bombs were set to explode - and three or four people were gathered in front of the bank waiting for it to open.'
          ],
          [
            1,
            'Timestr [08:59]: 8:59',
            'She had been lying in bed reading about Sophie and Alberto\'s conversation on Marx and had fallen asleep. The reading lamp by the bed had been on all night. The green glowing digits on her desk alarm clock showed <<8:59|2>>.'
          ],
          [
            1,
            'Timestr [09:00]: nine o\'clock',
            '\'I could never get all the way down there before <<nine o\'clock|6>>.\''
          ],
          [
            1,
            'Timestr [09:00]: nine o\'clock',
            '\'Look. Ignatius. I\'m beat. I\'ve been on the road since <<nine o\'clock|6>> yesterday morning.\''
          ],
          [
            1,
            'Timestr [09:00]: nine',
            'On the third morning after their arrival, just as all the clocks in the city were striking <<nine|11>> individually, and somewhere about nine hundred and ninety-nine collectively, Sam was taking the air in George Yard, when a queer sort of fresh painted vehicle drove up, out of which there jumped with great agility, throwing the reins to a stout man who sat beside him, a queer sort of gentleman, who seemed made for the vehicle, and the vehicle for him.'
          ],
          [
            1,
            'Timestr [09:00]: 9:00 am',
            '14 June <<9:00 am|2a>> woke up'
          ],
          [
            1,
            'Timestr [09:00]: 9.00 a.m.',
            '<<9.00 a.m.|2a>> School assembly'
          ],
          [
            -1,
            'Timestr [09:00]: nine',
            "A fly buzzed, the wall clock began to strike. After the <<nine|99>> golden strokes faded, the district captain began. \"How is Herr Colonel Marek?\" \"Thank you, Pap\x{e1}, he's fine.\" \"Still weak in geometry?\" \"Thank you, Pap\x{e1}, a little better.\" \"Read any books?\" \"Yessir, Pap\x{e1}.\""
          ],
          [
            1,
            'Timestr [09:00]: nine o\' clock',
            'As <<nine o\' clock|6>> was left behind, the preposterousness of the delay overwhelmed me, and I went in a kind of temper to the owner and said that I thought he should sign on another cook and weigh spars and be off.'
          ],
          [
            1,
            'Timestr [09:00]: nine o\'clock',
            'At <<nine o\'clock|6>>, one morning late in July, Gatsby\'s gorgeous car lurched up the rocky drive to my door and gave out a burst of melody from its three-noted horn'
          ],
          [
            1,
            'Timestr [09:00]: nine',
            'He was at breakfast at <<nine|9c:1>>, and for the twentieth time consulted his "Bradshaw," to see at what earliest hour Dr. Grantly could arrive from Barchester.'
          ],
          [
            1,
            'Timestr [09:00]: nine o\'clock in the morning',
            'He won\'t stand beating. Now, if you only kept on good terms with him, he\'d do almost anything you liked with the clock. For instance, suppose it were <<nine o\'clock in the morning|6>>, just time to begin lessons: you\'d only have to whisper a hint to Time, and round goes the clock in a twinkling! <<Half-past one|10>>, time for dinner!'
          ],
          [
            1,
            'Timestr [09:00]: around nine o\'clock',
            'It was <<around nine o\'clock|6>> that I crossed the border into Cornwall. This was at least three hours before the rain began and the clouds were still all of a brilliant white. In fact, many of the sights that greeted me this morning were among the most charming I have so far encountered. It was unfortunate, then, that I could not for much of the time give to them the attention they warranted; for one may as well declare it, one was in a condition of some preoccupation with the thought that - barring some unseen complication - one would be meeting Miss Kenton again before the day\'s end.'
          ],
          [
            1,
            'Timestr [09:00]: nine',
            'Opening his window, Aschenbach thought he could smell the foul stench of the lagoon. A sudden despondency came over him. He considered leaving then and there. Once, years before, after weeks of a beautiful spring, he had been visited by this sort of weather and it so affected his health he had been obliged to flee. Was not the same listless fever setting in? The pressure in the temples, the heavy eyelids? Changing hotels again would be a nuisance, but if the wind failed to shift he could not possibly remain here. To be on the safe side, he did not unpack everything. At <<nine|9m>> he went to breakfast in the specially designated buffet between the lobby and the dining room.'
          ],
          [
            1,
            'Timestr [09:00]: 9.00am',
            'Sometimes what I wouldn\'t give to have us sitting in a bar again at <<9.00am|2a>> telling lies to one another, far from God.'
          ],
          [
            1,
            'Timestr [09:00]: nine',
            'The clock struck <<nine|11>> when I did send the nurse; In half an hour she promised to return. Perchance she cannot meet him: that\'s not so.'
          ],
          [
            1,
            'Timestr [09:00]: nine',
            'To where Saint Mary Woolnoth kept the hours With a dead sound on the final stroke of <<nine|12>>.'
          ],
          [
            1,
            'Timestr [09:00]: nine',
            'Unreal City, Under the brown fog of a winter dawn, A crowd flowed over London Bridge, so many, I had not thought death had undone so many. Sighs, short and infrequent, were exhaled, And each man fixed his eyes before his feet. Flowed up the hill and down King William Street, To where Saint Mary Woolnoth kept the hours With a dead sound on the final stroke of <<nine|12>>.'
          ],
          [
            1,
            'Timestr [09:01]: 9:01am',
            '<<9:01am|2a>> lay in bed, staring at ceiling.'
          ],
          [
            1,
            'Timestr [09:02]: 9:02am',
            '<<9:02am|2a>> lay in bed, staring at ceiling.'
          ],
          [
            1,
            'Timestr [09:03]: 9:03am',
            '<<9:03am|2a>> lay in bed, staring at ceiling.'
          ],
          [
            1,
            'Timestr [09:03]: three minutes past nine',
            'This isn\'t a very good start to the new school year." I stared at her. What was she talking about? Why was she looking at her watch? I wasn\'t late. Okay, the school bell had rung as I was crossing the playground, but you always get five minutes to get to your classroom. "It\'s <<three minutes past nine|10>>," Miss Beckworth announced. "You\'re late."'
          ],
          [
            1,
            'Timestr [09:04]: 9:04am',
            '<<9:04am|2a>> lay in bed, staring at ceiling'
          ],
          [
            1,
            'Timestr [09:04]: 9.04',
            'In the light of a narrow-beam lantern, Pierce checked his watch. It was <<9.04|9f>>.'
          ],
          [
            1,
            'Timestr [09:05]: 9:05am',
            '<<9:05am|2a>> lay in bed, staring at ceiling'
          ],
          [
            1,
            'Timestr [09:05]: 9:05',
            'Kaldren pursues me like luminescent shadow. He has chalked up on the gateway \'96,688,365,498,702\'. Should confuse the mail man. Woke <<9:05|2>>. To sleep <<6:36|2>>.'
          ],
          [
            1,
            'Timestr [09:05]: 9:05 a.m.',
            "The tour of the office doesn't take that long. In fact, we're pretty much done by <<9:05 a.m.|2a>> \x{2026} and even though it's just a room with a window and a pin board and two doors and two desks... I can't help feeling a buzz as I lead them around. It's mine. My space. My company."
          ],
          [
            1,
            'Timestr [09:05]: 9:05 a.m.',
            'The tour of the office doesn\'t take that long. In fact, we\'re pretty much done by <<9:05 a.m.|2a>> Ed looks at everything twice and says it\'s all great, and gives me a list of contacts who might be helpful, then has to leave for his own office.'
          ],
          [
            1,
            'Timestr [09:06]: 9:06am',
            '<<9:06am|2a>> lay in bed, staring at ceiling'
          ],
          [
            1,
            'Timestr [09:07]: 9:07am',
            '<<9:07am|2a>> lay in bed, staring at ceiling'
          ],
          [
            1,
            'Timestr [09:07]: 9:07',
            'It was a sparkling morning, <<9:07|2>> by the clock when Mrs. Flett stepped aboard the Imperial Limited at the Tyndall station, certain that her life was ruined, but managing, through an effort of will, to hold herself erect and to affect an air of preoccupation and liveliness.'
          ],
          [
            1,
            'Timestr [09:08]: 9.08am',
            '<<9.08am|2a>> rolled over onto left side.'
          ],
          [
            1,
            'Timestr [09:09]: 9.09am',
            '<<9.09am|2a>> lay in bed, staring at wall.'
          ],
          [
            1,
            'Timestr [09:10]: 9.10am',
            '<<9.10am|2a>> lay in bed, staring at wall.'
          ],
          [
            1,
            'Timestr [09:11]: 9:11am',
            '<<9:11am|2a>> lay in bed, staring at wall'
          ],
          [
            1,
            'Timestr [09:12]: 9.12am',
            '<<9.12am|2a>> lay in bed, staring at wall.'
          ],
          [
            1,
            'Timestr [09:13]: 9:13am',
            '<<9:13am|2a>> lay in bed, staring at wall'
          ],
          [
            1,
            'Timestr [09:13]: 9:13 A.M.',
            'She tucked the phone in the crook of her neck and thumbed hurriedly through her pink messages. Dr. Provetto, at <<9:13 A.M.|2a>>'
          ],
          [
            1,
            'Timestr [09:14]: 9.14am',
            '<<9.14am|2a>> lay in bed, staring at wall.'
          ],
          [
            1,
            'Timestr [09:15]: 0915',
            '"Great!" Jones commented. "I\'ve never seen it do that before. That\'s all right. Okay." Jones pulled a handful of pencils from his back pocket. "Now, I got the contact first at <<0915|9c:0>> or so, and the bearing was about two-six-nine."'
          ],
          [
            1,
            'Timestr [09:15]: 9:15am',
            '<<9:15am|2a>> doubled over pillow, sat up to see out window'
          ],
          [
            1,
            'Timestr [09:15]: 9.15 a.m.',
            '<<9.15 a.m.|2a>> First morning class'
          ],
          [
            1,
            'Timestr [09:15]: quarter past nine',
            'Miss Pettigrew pushed open the door of the employment agency and went in as the clock struck a <<quarter past nine|10>>.'
          ],
          [
            1,
            'Timestr [09:16]: 9.16am',
            '<<9.16am|2a>> sat in bed, staring out window.'
          ],
          [
            1,
            'Timestr [09:17]: 9.17am',
            '<<9.17am|2a>> sat in bed, staring out window.'
          ],
          [
            1,
            'Timestr [09:18]: 9.18am',
            '<<9.18am|2a>> sat in bed, staring out window.'
          ],
          [
            1,
            'Timestr [09:19]: 9.19am',
            '<<9.19am|2a>> sat in bed, staring out window.'
          ],
          [
            1,
            'Timestr [09:20]: nine-twenty',
            'I\'ll compromise by saying that I left home at <<eight|9c:1>> and spent an hour travelling to a <<nine o\'clock|6>> appointment. Twenty minutes later is <<nine-twenty|5a:1>>.'
          ],
          [
            1,
            'Timestr [09:20]: twenty minutes past nine',
            'At <<twenty minutes past nine|10>>, the Duke of Dunstable, who had dined off a tray in his room, was still there, waiting for his coffee and liqueur.'
          ],
          [
            1,
            'Timestr [09:20]: 9.20',
            'The following morning at <<9.20|3:0>> Mr Cribbage straightened his greasy old tie, combed his Hitler moustache and arranged the few strands of his hair across his bald patch.'
          ],
          [
            1,
            'Timestr [09:21]: nine twenty-one',
            'It was <<nine twenty-one|9f>>. With one minute to go, there was no sign of Herbert\'s mother.'
          ],
          [
            1,
            'Timestr [09:22]: nine twenty-two',
            'No more throwing stones at him, and I\'ll see you back here exactly one week from now. She looked at her watch. \'At <<nine twenty-two|9m>> next Wednesday.\''
          ],
          [
            1,
            'Timestr [09:23]: 9.23',
            '<<9.23|9j>>. What possessed me to buy this comb?'
          ],
          [
            1,
            'Timestr [09:24]: 9.24',
            '<<9.24|5a:0>> I\'m swelled after that cabbage. A speck of dust on the patent leather of her boot.'
          ],
          [
            1,
            'Timestr [09:25]: nine twenty-five',
            'A man I would cross the street to avoid at <<nine o\'clock|6>> - by <<nine twenty-five|5b>> I wanted to fuck him until he wept. My legs trembled with it. My voice floated out of my mouth when I opened it to speak. The glass wall of the meeting room was huge and suddenly too transparent.'
          ],
          [
            1,
            'Timestr [09:27]: twenty-seven minutes past nine',
            'From <<twenty minutes past nine|10>> until <<twenty-seven minutes past nine|10>>, from <<twenty-five minutes past eleven|10>> until <<twenty-eight minutes past eleven|10>>, from <<ten minutes to three|10>> until <<two minutes to three|10>> the heroes of the school met in a large familiarity whose Olympian laughter awed the fearful small boy that flitted uneasily past and chilled the slouching senior that rashly paused to examine the notices in assertion of an unearned right.'
          ],
          [
            1,
            'Timestr [09:28]: twenty-eight minutes past nine',
            '"This clock right?" he asked the butler in the hall. "Yes, sir." The clock showed <<twenty-eight minutes past nine|10>>. "The clocks here have to be right, sir," the butler added with pride and a respectful humour, on the stairs.'
          ],
          [
            1,
            'Timestr [09:28]: twenty-eight minutes past nine',
            'He entered No. 10 for the first time, he who had sat on the Government benches for eight years and who had known the Prime Minister from youth up. "This clock right?" he asked the butler in the hall. "Yes, sir." The clock showed <<twenty-eight minutes past nine|10>>. "The clocks here have to be right, sir," the butler added with pride and a respectful humour, on the stairs.'
          ],
          [
            1,
            'Timestr [09:30]: half-past nine',
            'he looked at his watch; it was <<half-past nine|10>>'
          ],
          [
            1,
            'Timestr [09:30]: nine-thirty',
            "It was <<nine-thirty|9f>>. In another ten minutes she would turn off the heat; then it would take a while for the water to cool. In the meantime there was nothing to do but wait. \x{201c}Have you thought it through April?\x{201d} Never undertake to do a thing until you\x{2019}ve \x{2013}\x{201c} But she needed no more advice and no more instruction. She was calm and quiet now with knowing what she had always known, what neither her parents not Aunt Claire not Frank nor anyone else had ever had to teach her: that if you wanted to do something absolutely honest, something true, it always turned out to be a thing that had to be done alone."
          ],
          [
            1,
            'Timestr [09:30]: nine-thirty',
            'The body came in at <<nine-thirty|3b>> this morning. One of Holding\'s men went to the house and collected it. There was nothing particularly unusual about the death. The man had had a fear of hospitals and had died at home, being cared for more than adequately by his devoted wife.'
          ],
          [
            1,
            'Timestr [09:30]: 9.30',
            'Up the welcomingly warm morning hill we trudge, side by each, bound finally for the Hall of Fame. It\'s <<9.30|9f>>, and time is in fact a-wastin\'.'
          ],
          [
            1,
            'Timestr [09:32]: 9.32',
            'He said he couldn\'t say for certain of course, but that he rather thought he was. Anyhow, if he wasn\'t the 11.5 for Kingston, he said he was pretty confident he was the <<9.32|5a:0>> for Virginia Water, or the <<10 a.m.|5>> express for the Isle of Wight, or somewhere in that direction, and we should all know when we got there.'
          ],
          [
            1,
            'Timestr [09:32]: nine-thirty-two',
            'Sandy barely made the <<nine-thirty-two|5a:0>> and found a seat in no-smoking. She\'d been looking forward to this visit with Lisbeth. They hadn\'t seen each other in months, not since January, when Sandy had returned from Jamaica. And on that day Sandy was sporting a full-blown herpes virus on her lower lip.'
          ],
          [
            1,
            'Timestr [09:33]: thirty-three minutes past nine',
            'Next, he remembered that the morrow of Christmas would be the twenty-seventh day of the moon, and that consequently high water would be at <<twenty-one minutes past three|10>>, the half-ebb at a <<quarter past seven|10>>, low water at <<thirty-three minutes past nine|10>>, and half flood at <<thirty-nine minutes past twelve|10>>.'
          ],
          [
            1,
            'Timestr [09:35]: nine-thirty-five',
            '<<Nine-thirty-five|9j>>. He really must be gone. The bird is no longer feeding but sitting at the apex of a curl of razor wire.'
          ],
          [
            1,
            'Timestr [09:35]: nine-thirty-five',
            '<<Nine-thirty-five|9j>>. He really must be gone. The bird is no longer feeding but sitting at the apex of a curl of razor wire.'
          ],
          [
            1,
            'Timestr [09:36]: 9:36',
            'I grab a pen and the pad of paper by the phone and start scribbling a list for the day. I have an image of myself moving smoothly from task to task, brush in one hand, duster in the other, bringing order to everything. Like Mary Poppins. <<9:30|2>>-<<9:36|2>> Make Geigers\' bed <<9:36|2>>-<<9:42|2>> Take laundry out of machine and put in dryer <<9:42|2>>-<<10:00|2>> Clean bathrooms I get to the end and read it over with a fresh surge of optimism. At this rate I should be done easily by lunchtime. <<9:36|2>> Fuck. I cannot make this bed. Why won\'t this sheet lie flat? <<9:42|2>> And why do they make mattresses so heavy?'
          ],
          [
            1,
            'Timestr [09:36]: 9.36am',
            'Monday February 6th. \'<<9.36am|2a>>. Oh god, Oh god. Maybe he\'s fallen in love in New York and stayed there\'.'
          ],
          [
            1,
            'Timestr [09:37]: thirty-seven minutes past nine',
            'It comprised all that was required of the servant, from <<eight in the morning|5>>, exactly at which hour Phileas Fogg rose, till <<half-past eleven|10>>, when he left the house for the Reform Club - all the details of service, the tea and toast at <<twenty-three minutes past eight|10>>, the shaving-water at <<thirty-seven minutes past nine|10>>, and the toilet at <<twenty minutes before ten|10>>.'
          ],
          [
            1,
            'Timestr [09:40]: twenty minutes before ten',
            "It comprised all that was required of the servant, from <<eight in the morning|5>>, exactly at which hour Phileas Fogg rose, till <<half-past eleven|10>>, when he left the house for the Reform Club\x{2014}all the details of service, the tea and toast at <<twenty-three minutes past eight|10>>, the shaving-water at <<thirty-seven minutes past nine|10>>, and the toilet at <<twenty minutes before ten|10>>."
          ],
          [
            1,
            'Timestr [09:40]: 9:40',
            'Must have the phone disconnected. Some contractor keeps calling me up about payment for 50 bags of cement he claims I collected ten days ago. Says he helped me load them onto a truck himself. I did drive Whitby\'s pick-up into town but only to get some lead screening. What does he think I\'d do with all that cement? Just the sort of irritating thing you don\'t expect to hang over your final exit. (Moral: don\'t try too hard to forget Eniwetok.) Woke <<9:40|2>>. To sleep <<4:15|2>>.'
          ],
          [
            1,
            'Timestr [09:42]: 9:42',
            'I grab a pen and the pad of paper by the phone and start scribbling a list for the day. I have an image of myself moving smoothly from task to task, brush in one hand, duster in the other, bringing order to everything. Like Mary Poppins. <<9:30|2>>-<<9:36|2>> Make Geigers\' bed <<9:36|2>>-<<9:42|2>> Take laundry out of machine and put in dryer <<9:42|2>>-<<10:00|2>> Clean bathrooms I get to the end and read it over with a fresh surge of optimism. At this rate I should be done easily by lunchtime. <<9:36|2>> Fuck. I cannot make this bed. Why won\'t this sheet lie flat? <<9:42|2>> And why do they make mattresses so heavy?'
          ],
          [
            1,
            'Timestr [09:45]: 9.45',
            '<<9.15|9j>>, <<9.30|9j>>, <<9.45|9j>>, 10! Bond felt the excitement ball up inside him like cat\'s fur.'
          ],
          [
            1,
            'Timestr [09:47]: 9.47am',
            'Monday February 6th. \'<<9.47am|2a>>. Or gone to Las Vegas and got married\'.'
          ],
          [
            1,
            'Timestr [09:50]: 9.50am',
            '<<9.50am|2a>>. Hmmm. Think will go inspect make-up in case he does come in'
          ],
          [
            1,
            'Timestr [09:50]: ten minutes to ten',
            '<<Ten minutes to ten|10>>. "I had just time to hide the bottle (after the nurse had left me) when you came into my room."'
          ],
          [
            1,
            'Timestr [09:52]: 9:52',
            '"She caught the <<9:52|2>> to Victoria. I kept well clear of her on the train and picked her up as she went through the barrier. Then she took a taxi to Hammersmith." "A taxi?" Smiley interjected. "She must be out of her mind."'
          ],
          [
            1,
            'Timestr [09:53]: seven minutes to ten',
            'Miss Pettigrew went to the bus-stop to await a bus. She could not afford the fare, but she could still less afford to lose a possible situation by being late. The bus deposited her about five minutes\' walk from Onslow Mansions, an at <<seven minutes to ten|10>> precisely she was outside her destination.'
          ],
          [
            1,
            'Timestr [09:54]: 9:54',
            '<<9:54|2>> This is sheer torture. My arms have never ached so much in my entire life. The blankets weigh a ton, and the sheets won\'t go straight and I have no idea how to do the wretched corners. How do chambermaids do it?'
          ],
          [
            1,
            'Timestr [09:55]: five to ten',
            'At <<five to ten|10>> I\'m ready in the hall. Nathaniel\'s mother\'s house is nearby but apparently tricky to find, so the plan is to meet here and he\'ll walk me over. I check my reflection in the hall mirror and wince. The streak of bleach in my hair is as obvious as ever. Am I really going out in public like this?'
          ],
          [
            1,
            'Timestr [09:55]: five minutes to ten',
            'Good-morning, Lucien, good-morning, said Albert; "your punctuality really alarms me. What do I say? punctuality! You, whom I expected last, you arrive at <<five minutes to ten|10>>, when the time fixed was half-past! Has the ministry resigned?"'
          ],
          [
            1,
            "Timestr [09:58]: around ten o\'clock",
            'I didn\'t sleep too long, because I think it was only <<around ten o\'clock|6>> when I woke up. I felt pretty hungry as soon as I had a cigarette. The last time I\'d eaten was those two hamburgers I had with Brossard and Ackley when we went in to Agerstown to the movies. That was a long time ago. It seemed like fifty years ago.'
          ],
          [
            1,
            'Timestr [09:59]: One minute to ten',
            '<<One minute to ten|10>>. With a heavy heart Bert watched the clock. His legs were still aching very badly. He could not see the hands of the clock moving, but they were creeping on all the same.'
          ],
          [
            1,
            'Timestr [10:00]: ten o\'clock',
            "\x{2013}\x{2013}In assaying to put on his regimental coat and waistcoat, my uncle Toby found the same objection in his wig, \x{2013}\x{2013}so that went off too: \x{2013}\x{2013}So that with one thing and what with another, as always falls out when a man is in the most haste, \x{2013}\x{2013}'twas <<ten o'clock|6>>, which was half an hour later than his usual time before my uncle Toby sallied out."
          ],
          [
            -1,
            'Timestr [10:00]: an hour ago since it was nine',
            "\x{2019}Tis but <<an hour ago since it was nine|99>>, And after one hour more \x{2018}twill be <<eleven|9c:1>>."
          ],
          [
            -1,
            'Timestr [10:00]: ten',
            'For some seconds the light went on becoming brighter and brighter, and she saw everything more and more clearly and the clock ticked louder and louder until there was a terrific explosion right in her ear. Orlando leapt as if she had been violently struck on the head. <<Ten|99>> times she was struck. In fact it was <<ten o\'clock in the morning|6>>. It was the eleventh of October. It was <<1928|9d>>. It was the present moment.'
          ],
          [
            1,
            'Timestr [10:00]: 10:00',
            'The trial was irretrievably over; everything that could be said had been said, but he had never doubted that he would lose. The written verdict was handed down at <<10:00|2>> on Friday morning, and all that remained was a summing up from the reporters waiting in the corridor outside the district court.'
          ],
          [
            1,
            'Timestr [10:00]: around 10 am',
            'According to military records no US bombers or any other kind of aircraft were flying over that region at the time, that is <<around 10 am|5>> on November 7,1944.'
          ],
          [
            1,
            'Timestr [10:00]: about ten o\'clock in the morning',
            'At <<about ten o\'clock in the morning|6>> the sun threw a bright dust-laden bar through one of the side windows, and in and out of the beam flies shot like rushing stars.'
          ],
          [
            1,
            'Timestr [10:00]: ten o\' clock in the morning',
            'I went to bed and the next thing I knew I was awake again and it was getting on for <<ten o\' clock in the morning|6>>. Ring, ring, said the telephone, ring, ring.'
          ],
          [
            1,
            'Timestr [10:00]: ten o\'clock',
            'If Wednesday should ever come! It did come, and exactly when it might be reasonably looked for. It came - it was fine - and Catherine trod on air. By <<ten o\'clock|6>>, the chaise and four conveyed the two from the abbey; and, after an agreeable drive of almost twenty miles, they entered Woodston, a large and populous village, in a situation not unpleasant.'
          ],
          [
            1,
            'Timestr [10:00]: ten',
            'King Richard: Well, but what\'s o\'clock? Buckingham: Upon the stroke of <<ten|12>>.'
          ],
          [
            1,
            "Timestr [10:00]: about 10 o\x{2019}clock",
            "Monday 30 March 1668 Up betimes, and so to the office, there to do business till <<about 10 o\x{2019}clock|6>>"
          ],
          [
            1,
            'Timestr [10:00]: 10 o\'clock',
            'On July 25th, <<8:30 a.m.|2a>> the bitch Novaya dies whelping. At <<10 o\'clock|6>> she is lowered into her cool grave, at <<7:30 that same evening|2a>> we see our first floes and greet them wishing they were the last.'
          ],
          [
            1,
            'Timestr [10:00]: Ten-thirty',
            'The pundit sighed. \'Only a fool like me would leave his door open when a riot can occur at any moment, and only a fool like me would say yes to you,\' he said. \'What time?\' Just his head was sticking out of the partially opened door. The money from blessing the ice-cream factory must have dulled his desire for work, I thought. \'<<Ten|9k:1>>.\' \'<<Ten-thirty|9j>>.\' Without another word, he closed the door.'
          ],
          [
            1,
            'Timestr [10:00]: ten o\' clock',
            'The Saturday immediately preceding the examinations was a very busy day for Kennedy. At <<ten o\' clock|6>> he was entering Willey\'s room; the latter had given him a key and left the room vacant by previous arrangement - in fact he had taken Olivia on another house hunting trip.'
          ],
          [
            1,
            'Timestr [10:00]: ten in the morning',
            'The summer holidays were near at hand when I made up my mind to break out of the weariness of school-life for one day at least. With Leo Dillon and a boy named Mahoney I planned a day\'s mitching. Each of us saved up sixpence. We were to meet at <<ten in the morning|9g>> on the Canal Bridge.'
          ],
          [
            1,
            'Timestr [10:00]: 10:00',
            'The written verdict was handed down at <<10:00|2>> on Friday morning, and allthat remained was a summing up from the reporters waiting in the corridor outside the district court.'
          ],
          [
            1,
            'Timestr [10:01]: about ten o\'clock in the morning',
            'At <<about ten o\'clock in the morning|6>> the sun threw a bright dust-laden bar through one of the side windows, and in and out of the beam flies shot like rushing stars.\''
          ],
          [
            1,
            'Timestr [10:02]: two minutes after ten',
            'It was <<two minutes after ten|10>>; she was not satisfied with her clothes, her face, her apartment. She heated the coffee again and sat down in the chair by the window. Can\'t do anything more now, she thought, no sense trying to improve anything the last minute.'
          ],
          [
            1,
            'Timestr [10:03]: 10.03',
            'It\'s <<10.03|9d>> according to his watch, and he is travelling down through the Scottish highlands to Inverness, tired and ever-so-slightly anxious in case he falls asleep between now and when the train reaches the station, and misses his cue to say to Alice, Drew and Aleesha: \'OK, this is Inverness, let\'s move it.\''
          ],
          [
            1,
            'Timestr [10:03]: 10.03',
            'The date was the 14th of May and the clock on his desk said the time was <<twenty three minutes past ten|10>>, so he tapped in the numbers <<10.23|5a:1>>. At least, that\'s what he meant to do. In fact he typed in the numbers <<10.03|5a:1>>.'
          ],
          [
            1,
            'Timestr [10:05]: five past ten',
            "We both watch as a pair of swans sail regally under the little bridge. Then I glance at my watch. It's already <<five past ten|10>>. \x{201c}We should get going,\x{201d} I say with a little start. Your mother will be waiting.\x{201d} \x{201c}There's no rush,\x{201d} Nathaniel calls as I hasten down the other side of the bridge. \x{201c}We've got all day.\x{201d} He lopes down the bridge. \x{201c}It's OK. You can slow down.\x{201d} I try to match his relaxed pace. But I'm not used to this easy rhythm. I'm used to striding along crowded pavements, fighting my way, pushing and elbowing."
          ],
          [
            1,
            'Timestr [10:07]: 10.07 am',
            '<<10.07 am|2a>>: In a meeting with Rod, Momo and Guy. We are rehearsing the final for the third time, with Rod and Guy taking the parts of the clients, when Rod\'s secretary, Lorraine, bursts in.'
          ],
          [
            1,
            'Timestr [10:09]: 10:09',
            'He followed the squeals down a hallway. A wall clock read <<8:09|2>>-<<10:09|2>> Dallas time.'
          ],
          [
            1,
            'Timestr [10:10]: 10:10',
            '<<10:10|2>> Shot is fired.'
          ],
          [
            1,
            'Timestr [10:10]: ten minutes past 10',
            'Saturday morning was bright and sunny, and at <<ten minutes past 10|10>> Donald arrived at the Embankment entrance of Charing Cross Underground Station, carrying a small suitcase full of clothes suitable for outdoor sports and pastimes.'
          ],
          [
            1,
            'Timestr [10:11]: eleven minutes past ten',
            'Through the curtained windows of the furnished apartment which Mrs. Horace Hignett had rented for her stay in New York rays of golden sunlight peeped in like the foremost spies of some advancing army. It was a fine summer morning. The hands of the Dutch clock in the hall pointed to <<thirteen minutes past nine|10>>; those of the ormolu clock in the sitting-room to <<eleven minutes past ten|10>>; those of the carriage clock on the bookshelf to <<fourteen minutes to six|10>>. In other words, it was exactly <<eight|9f>>; and Mrs. Hignett acknowledged the fact by moving her head on the pillow, opening her eyes, and sitting up in bed. She always woke at <<eight|9b>> precisely.'
          ],
          [
            1,
            'Timestr [10:12]: ten twelve',
            "\x{201c}I'll take the coffee tray out,\x{201d} I suggest humbly. As I pick it up I glance again at my watch. <<Ten twelve|9j>>. I wonder if they've started the meeting."
          ],
          [
            1,
            'Timestr [10:12]: 10:12 a.m.',
            'He stood up once, early on, to lock his office door, and then he was reading the last page, and it was exactly <<10:12 a.m.|2a>>, and the sun beating on his office windows was a different sun from the one he\'d always known.'
          ],
          [
            1,
            'Timestr [10:13]: thirteen minutes past ten',
            '"By the bye," said the first, "I was able this morning to telegraph the very words of the order to my cousin at <<seventeen minutes past ten|10>>." "And I sent it to the Daily Telegraph at <<thirteen minutes past ten|10>>." "Bravo, Mr. Blount!" "Very good, M. Jolivet."'
          ],
          [
            1,
            'Timestr [10:14]: ten fourteen',
            "\x{201c}Okay. <<Ten fourteen|9j>>: Mrs. Narada reports that her cat has been attacked by a large dog. Now I send all the boys out looking, but they don't find anything until <<eleven|9c:0>>. Then one of them calls in that a big dog has just bitten holes in the tires on his golf cart and run off. <<Eleven thirty|9j>>: Dr. Epstein makes his first lost-nap call: dog howling. <<Eleven thirty-five|9j>>: Mrs. Norcross is putting the kids out on the deck for some burgers when a big dog jumps over the rail, eats the burgers, growls at the kids, runs off. First mention of lawsuit.\x{201d}"
          ],
          [
            1,
            'Timestr [10:15]: 10.15',
            'At <<10.15|9m>> Arlena departed from her rondezvous, a minute or two later Patrick Redfern came down and registered surprise, annoyance, etc. Christine\'s task was easy enough. Keeping her own watch concealed she asked she asked Linda at <<twenty-five past eleven|10>> what time it was. Linda looked at her watch and replied that it was a <<quarter to twelve|10>>.'
          ],
          [
            1,
            'Timestr [10:16]: 10:16',
            '<<10:16|2>> At last. Forty minutes of hard work and I have made precisely one bed. I\'m way behind. But never mind. Just keep moving. Laundry next.'
          ],
          [
            1,
            'Timestr [10:17]: seventeen minutes past ten',
            '"By the bye," said the first, "I was able this morning to telegraph the very words of the order to my cousin at <<seventeen minutes past ten|10>>." "And I sent it to the Daily Telegraph at <<thirteen minutes past ten|10>>."n "Bravo, Mr. Blount!" "Very good, M. Jolivet." "I will try and match that!"'
          ],
          [
            1,
            'Timestr [10:18]: 10:18',
            'I know that it was <<10:18|2>> when I got home because I look at my watch a lot.'
          ],
          [
            1,
            'Timestr [10:20]: twenty past ten',
            'How much is the clock fast now? His mother straightened the battered alarm clock that was lying on its side in the middle of the mantelpiece until its dial showed a <<quarter to twelve|10>> and then laid it once more on its side. An hour and twenty-five minutes, she said. The right time now is <<twenty past ten|10>>.'
          ],
          [
            1,
            'Timestr [10:21]: 10.21',
            'Liz Headleand stares into the mirror, as though entranced. She does not see herself or the objects on her dressing-table. The clock abruptly jerks to <<10.21|5a:1>>.'
          ],
          [
            1,
            'Timestr [10:22]: 10:22',
            'I listened to them, and listened to them again, and then before I had time to figure out what to do, or even what to think or feel, the phone started ringing. It was <<10:22|2>>:27. I looked at the caller ID and saw that it was him.'
          ],
          [
            1,
            'Timestr [10:23]: twenty three minutes past ten',
            'The date was the 14th of May and the clock on his desk said the time was <<twenty three minutes past ten|10>>, so he tapped in the numbers <<10.23|5a:1>>. At least, that\'s what he meant to do. In fact he typed in the numbers <<10.03|5a:1>>'
          ],
          [
            1,
            'Timestr [10:25]: 10:25',
            "<<10:25|2>>: Phone call from L\x{fc}ding, very worked up, urging me to return at once and get in touch with Alois, who was equally worked up."
          ],
          [
            1,
            'Timestr [10:25]: 10:25',
            'One meal is enough now, topped up with a glucose shot. Sleep is still \'black\', completely unrefreshing. Last night I took a 16 mm. film of the first three hours, screened it this morning at the lab. The first true-horror movie. I looked like a half-animated corpse. Woke <<10:25|2>>. To sleep <<3:45|2>>.'
          ],
          [
            1,
            'Timestr [10:26]: 10:26',
            '<<10:26|2>> No. Please, no. I can hardly bear to look. It\'s a total disaster. Everything in the washing machine has gone pink. Every single thing. What happened? With trembling fingers I pick out a damp cashmere cardigan. It was a cream when I put it in. It\'s now a sickly shade of candy floss. I knew K3 was bad news. I knew it -'
          ],
          [
            1,
            'Timestr [10:26]: ten-twenty-six',
            'In the exact centre of my visual field was the alarm clock, hands pointing to <<ten-twenty-six|11>>. An alarm clock I received as a memento of somebody\'s wedding.'
          ],
          [
            1,
            'Timestr [10:27]: twenty-seven minutes past 10',
            'Mr. Harcourt woke up with mysterious suddenness at <<twenty-seven minutes past 10|10>>, and, by a curious coincidence, it was at that very instant that the butler came in with two footmen laden with trays of whisky, brandy, syphons, glasses, and biscuits.'
          ],
          [
            1,
            'Timestr [10:27]: 10:27 a.m.',
            'She is on holiday in Norfolk. The substandard clock radio says <<10:27 a.m.|2a>> The noise is Katrina the Cleaner thumping the hoover against the skirting boards and the bedroom doors. Her hand is asleep. It is still hooked through the handstrap of the camera. She unhooks it and shakes it to get the blood back into it. She puts her feet on top of her trainers and slides them across the substandard carpet. It has the bare naked feet of who knows how many hundreds of dead or old people on it.'
          ],
          [
            1,
            'Timestr [10:30]: 10.30 a.m.',
            '<<10.30 a.m.|2a>> Break'
          ],
          [
            1,
            'Timestr [10:30]: ten thirty',
            'according to the clock on the wall, it is barely <<ten thirty|5a:1>>.'
          ],
          [
            1,
            'Timestr [10:30]: ten-thirty',
            'At <<ten-thirty|9m>> I\'m cleaned up, shaved and dressed in my Easter best - a two-piece seersucker Palm Beach I\'ve had since college.'
          ],
          [
            1,
            'Timestr [10:31]: Just after half past ten',
            '"If you please. You went to bed at what time, Madame?" "<<Just after half past ten|10>>."'
          ],
          [
            1,
            'Timestr [10:32]: Just after half past ten',
            '"If you please. You went to bed at what time, Madame?" "<<Just after half past ten|10>>."'
          ],
          [
            1,
            'Timestr [10:35]: Five-and-twenty to eleven',
            '<<Five-and-twenty to eleven|10>>. A horrible hour - a macabre hour, for it is not only the hour of pleasure ended, it is the hour when pleasure itself has been found wanting.'
          ],
          [
            1,
            'Timestr [10:36]: ten thirty-six',
            '"Strand post mark and dispatched <<ten thirty-six|5a:0>>" said Holmes reading it over and over. "Mr Overton was evidently considerably excited when he sent it over and somewhat incoherent in consequence."'
          ],
          [
            1,
            'Timestr [10:37]: 10.37 a.m.',
            'I quite agree with you,\' said Mr Murbles. \'It is a most awkward situation. Lady Dormer died at precisely <<10.37 a.m.|2a>> on November 11th.\''
          ],
          [
            1,
            'Timestr [10:38]: 10:38',
            "There must be a solution, there must be. Frantically I scan the cans of products stacked on the shelves. Stain Away. Vanish. There has to be a remedy. ... I just need to think. ... <<10:38|2>> OK, I have the answer. It may not totally work\x{2014}but it's my best shot."
          ],
          [
            1,
            'Timestr [10:40]: 10:40',
            '<<10:40|2>>: Call from Katharina asking me whether I had really said what was in the News.'
          ],
          [
            1,
            'Timestr [10:43]: 10.43 a.m',
            '24 January, <<10.43 a.m|2a>>: one month and two days later I wonder if I should worry about the fact that my darling boyfriend bought me a birthday present that has the potential to cause instant death...'
          ],
          [
            1,
            'Timestr [10:45]: quarter to eleven',
            'If this is so, we have now to determine what Barker and Mrs. Douglas, presuming they are not the actual murderers, would have been doing from <<quarter to eleven|10>>, when the sound of the shot brought them down, until <<quarter past eleven|10>>, when they rang for the bell and summoned the servants\'.'
          ],
          [
            1,
            'Timestr [10:45]: quarter to eleven',
            'They reached King\'s Cross at a <<quarter to eleven|10>>. Mr Weasley dashed across the road to get trolleys for their trunks and they all hurried into the station.'
          ],
          [
            1,
            'Timestr [10:47]: 10.47',
            'He whistles in the shower. It is <<10.47|9f>> and he is ready for the off.'
          ],
          [
            1,
            'Timestr [10:48]: 10.48am',
            'At <<10.48am|2a>>, I closed my folder but didn\'t bother putting it back in my bag, so you knew I was on my way to a committee or meeting room nearby. Before I stood up, I folded my paper napkin and put it and the spoon into my coffee cup, a neat sort of person, you thought.'
          ],
          [
            1,
            'Timestr [10:49]: forty-nine minutes past ten',
            'By <<forty-nine minutes past ten|10>>, we fall in again with a fine portion of the ancient road, which the modern track constantly follows, and descend by some steep windings, hewn in the side of a precipitous cliff, to the place where the Ouad-el-Haoud commences.'
          ],
          [
            1,
            'Timestr [10:50]: 10.50 a.m.',
            '<<10.50 a.m.|2a>> Art class with Mrs Peters'
          ],
          [
            1,
            'Timestr [10:50]: ten to eleven',
            'As he walked back to the flight office, airmen were forming a line to await the arrival of the NAAFI van with morning tea and cakes. Lambert looked at his watch; it was <<ten to eleven|10>>.'
          ],
          [
            1,
            'Timestr [10:53]: 10.53 hrs',
            'He begins to make a record of our observations.\'<<10.53 hrs|1>>,\' he writes, as we crouch at the top of the stairs, listening to his mother in the hall below.'
          ],
          [
            1,
            'Timestr [10:53]: 10:53',
            'I gaze and gaze again at that face, which seems to me both strange and familiar, said Austerlitz, I run the tape back repeatedly, looking at the time indicator in the top left-hand corner of the screen, where the figures covering part of her forehead show the minutes and seconds, from <<10:53|2>> to <<10:57|2>>, while the hundredths of a second flash by so fast that you cannot read and capture them.'
          ],
          [
            1,
            'Timestr [10:55]: five minutes to eleven',
            'The clock was still saying <<five minutes to eleven|10>> when Pooh and Piglet set out on their way half an hour later.'
          ],
          [
            1,
            'Timestr [10:57]: 10.57',
            'I run the tape back repeatedly, looking at the time indicator in the top left-hand corner of the screen, where the figures covering part of her forehead show the minutes and seconds, from <<10.53|5a:0>> to <<10.57|5a:0>>.'
          ],
          [
            1,
            'Timestr [10:58]: 10:58',
            'One day Joe was sitting in the office waiting for his <<11 o\'clock|6>> appointment, and at <<10:58|2>> this black gal came in.'
          ],
          [
            1,
            'Timestr [10:59]: one minute to eleven',
            'Harry grunted in his sleep and his face slid down the window an inch or so, making his glasses still more lopsided, but he did not wake up. An alarm clock, repaired by Harry several years ago, ticked loudly on the sill, showing <<one minute to eleven|10>>.'
          ],
          [
            1,
            'Timestr [11:00]: eleven o\'clock',
            "'Who can - what can -\x{201d} asked Mrs Dalloway (thinking it was outrageous to be interrupted at <<eleven o'clock|6>> on the morning of the day she was giving a party), hearing a step on the stairs."
          ],
          [
            1,
            'Timestr [11:00]: 11 o\'clock',
            '"By <<11 o\'clock|6>> I have finished the first chapter of Mr Y. The winter sun is peeping meekly through the thin curtains and I decide to get up"'
          ],
          [
            1,
            'Timestr [11:00]: eleven in the morning',
            'He was rather a long time, and I began to feel muffled, weighed down by thick stuffs and silence. I thought: He\'ll never come back; and when he did his figure seemed to come at me from very far away, dream-like and dwindled, making his way back along a tunnel...I dare say it was champagne at <<eleven in the morning|9a>>.'
          ],
          [
            1,
            'Timestr [11:01]: past 11 o\'clock',
            'As her husband had told him, she was still in bed although it was <<past 11 o\'clock|6>>. Her normally mobile face was encased in clay, rigid and menacing as an Aztec mask.'
          ],
          [
            1,
            'Timestr [11:00]: eleven',
            'As they looked the whole world became perfectly silent, and a flight of gulls crossed the sky, first one gull leading, then another, and in this extraordinary silence and peace, in this pallor, in this purity, bells struck <<eleven|11>> times the sound fading up there among the gulls.'
          ],
          [
            1,
            'Timestr [11:00]: eleven o\'clock in the morning',
            'At <<eleven o\'clock in the morning|6>>, large flakes had appeared from a colourless sky and invaded the fields, gardens and lawns of Romerike like an armada from outer space.'
          ],
          [
            1,
            'Timestr [11:00]: eleven o\'clock',
            'At <<eleven o\'clock|6>> the phone rang, and still the figure did not respond, any more than it had responded when the phone had rung at <<twenty-five to seven|10>>, and again for ten minutes continuously starting at <<five to seven|10>>...'
          ],
          [
            1,
            'Timestr [11:00]: eleven o\'clock',
            'Big Ben was striking as she stepped out into the street. It was <<eleven o\'clock|6>> and the unused hour was fresh as if issued to children on a beach.'
          ],
          [
            1,
            'Timestr [11:00]: about eleven o\'clock in the morning',
            'It was <<about eleven o\'clock in the morning|6>>, mid October, with the sun not shining and a look of hard wet rain in the clearness of the foothills. I was wearing my powder-blue suit, with dark blue shirt, tie and display handkerchief, black brogues, black wool socks with dark blue clocks on them. I was neat, clean, shaved and sober, and I didn\'t care who knew it. I was everything the well-dressed private detective ought to be. I was calling on four millon dollars.'
          ],
          [
            1,
            "Timestr [11:00]: eleven o\x{2019}clock",
            "My sister is terrified that I might write and tell all the family secrets. Why do I feel like a rebel, like an iconoclast? I am only trying to do a writing class, what is wrong with that? I keep telling myself that once in the car I will be fine, I can listen to Radio Four Woman\x{2019}s Hour and that will take me till <<eleven o\x{2019}clock|6>> when the class starts."
          ],
          [
            1,
            'Timestr [11:00]: about eleven o\'clock',
            "ON the morning following the events just narrated, Mrs. Arlington was seated at breakfast in a sweet little parlour of the splendid mansion which the Earl of Warrington had taken and fitted up for her in Dover Street, Piccadilly. It was <<about eleven o'clock|6>>; and the Enchantress was attired in a delicious deshabill\x{e9}. With her little feet upon an ottoman near the fender, and her fine form reclining in a luxurious large arm-chair, she divided her attention between her chocolate and the columns of the Morning Herald. She invariably prolonged the morning's repast as much as possible, limply because it served to wile away the time until the hour for dressing arrived."
          ],
          [
            1,
            'Timestr [11:00]: Eleven o\'Clock in the Morning',
            'Quiet as I am, I become at <<Eleven o\'Clock in the Morning|6>> on every day of the week save Sunday a raving, ranting maniac -- a dangerous lunatic, panting with insane desires to do, not only myself but other people, a mischief, and possessed less by hallucination than by rabies.'
          ],
          [
            1,
            'Timestr [11:00]: eleven',
            "Though perhaps' \x{2013} but here the bracket clock whirred and then hectically struck <<eleven|11>>, its weights spooling downwards at the sudden expense of energy. She had to sit for a moment, when the echo had vanished, to repossess her thoughts."
          ],
          [
            1,
            'Timestr [11:00]: eleven',
            'We got to Waterloo at <<eleven|9c:1>>, and asked where the <<eleven-five|5a:1>> started from. Of course nobody knew; nobody at Waterloo ever does know where a train is going to start from, or where a train when it does start is going to, or anything about it.'
          ],
          [
            1,
            'Timestr [11:00]: eleven o\'clock',
            'We passed a few sad hours until <<eleven o\'clock|6>>, when the trial was to commence. My father and the rest of the family being obliged to attend as witnesses, I accompanied them to the court. During the whole of this wretched mockery of justice I suffered living torture.'
          ],
          [
            1,
            'Timestr [11:01]: just past eleven',
            'O\'Neil rises and takes the tray. He has finished the tea, but the muffins are still here in a wicker basket covered with a blue napkin. The clock above the stove says that it is <<just past eleven|10>>, and guests will be arriving at the house now.'
          ],
          [
            1,
            'Timestr [11:02]: 11.02am',
            "On August 9th, three days later, at <<11.02am|2a>>, another B\x{2212}29 dropped the second bomb on the industrial section of the city of Nagasaki, totally destroying 1 1/2 square miles of the city, killing 39,000 persons and injuring 25,000 more."
          ],
          [
            1,
            'Timestr [11:03]: Eleven oh-three',
            '"What makes you think it\'s for real?" "Just a hunch, really. He sounded for real. Sometimes you can just tell about people"-he smiled-"even if you\'re a dull old WASP." "I think it\'s a setup." "Why?" "I just do. Why would someone from the government want to help you?" "Good question. Guess I\'ll find out." She went back into the kitchen."What time are you meeting him?" she called out. "<<Eleven oh-three|9j>>," he said. "That made me think he\'s for real. Military and intelligence types set precise appointment times to eliminate confusion and ambiguity. Nothing ambiguous <<about eleven oh-three|5a:1>>."'
          ],
          [
            1,
            'Timestr [11:03]: 11.03am',
            'On the fourth, at <<11.03am|2a>>, the editor of the Yidische Zaitung put in a call to him; Doctor Yarmolinsky did not answer. He was found in his room, his face already a little dark, nearly nude beneath a large, anachronistic cape.'
          ],
          [
            1,
            'Timestr [11:04]: past 11 o\'clock',
            'As her husband had told him, she was still in bed although it was <<past 11 o\'clock|6>>. Her normally mobile face was encased in clay, rigid and menacing as an Aztec mask.'
          ],
          [
            1,
            'Timestr [11:05]: 11:05',
            'July 3: 5 3/4 hours. Little done today. Deepening lethargy, dragged myself over to the lab, nearly left the road twice. Concentrated enough to feed the zoo and get the log up to date. Read through the operating manuals Whitby left for the last time, decided on a delivery rate of 40 rontgens/min., target distance of 530 cm. Everything is ready now. Woke <<11:05|2>>. To sleep <<3:15|2>>.'
          ],
          [
            1,
            'Timestr [11:05]: five past eleven',
            'Sansom arrived in a Town Car at <<five past eleven|10>>. Local plates, which meant he had ridden up most of the way on the train. Less convenient for him, but a smaller carbon footprint than driving all the way, or flying. Every detail mattered, in a campaign.'
          ],
          [
            1,
            'Timestr [11:06]: 11:06',
            '<<11:06|2>> And ... oh. The ironing. What am I going to do about that?'
          ],
          [
            1,
            'Timestr [11:06]: 11.06am',
            'Despite the remaking of the BookWorld, some books remained tantalisingly out of reach [...] It was entirely possible that they didn\'t know there was a BookWorld, and still they thought they were real. A fantastic notion, until you consider that up until <<11.06am|2a>> on 12 April 1948, everyone else had thought the same.'
          ],
          [
            1,
            'Timestr [11:07]: seven minutes past eleven',
            'At exactly <<seven minutes past eleven|10>> by the ship\'s clock the Adventurer gave a prolonged screech and, moorings cast off, edged her way out of the basin and dipped her nose in the laughing waters of the bay, embarked at last on a voyage that was destined to fully vindicate her new name.'
          ],
          [
            1,
            'Timestr [11:08]: eight minutes past eleven',
            'The bursar was standing in the hall with his arms folded across his chest and when he caught sight of the fat young man he looked significantly at the clock. It was <<eight minutes past eleven|10>>.'
          ],
          [
            1,
            'Timestr [11:06]: around eleven',
            'The first time I saw them it was <<around eleven|9f>>, <<eleven-fifteen|9j>>, a Saturday morning, I was about two thirds through my route when I turned onto their block and noticed a \'56 Ford sedan pulled up in the yard with a big open U-Haul behind.'
          ],
          [
            1,
            'Timestr [11:10]: Ten minutes after eleven',
            '<<Ten minutes after eleven|10>> in Archie McCue\'s room on the third floor of the extension to the Robert Matthews\' soaring sixties\' tower - The Queen\'s Tower, although no queen was ever likely to live in it.'
          ],
          [
            1,
            'Timestr [11:12]: 11:12',
            "<<11:12|2>> I have a solution, via the local paper. A girl from the village will collect it, iron it all overnight at \x{a3}3 a shirt, and sew on Eddie's button."
          ],
          [
            1,
            'Timestr [11:12]: 11:12',
            'I squinted down the street at the bank clock: <<11:12|2>>, 87 degrees. "It\'s only a block and a half and it\'s not that hot, Daddy. The walk will do you good." This conversation made me breathless, as if I were wearing a girdle with tight stays.'
          ],
          [
            1,
            'Timestr [11:14]: 11.14am',
            'The report was dated Sunday, 25 September, 1966, at <<11.14am|2a>>. The text was laconic. Call from Hrk Vanger; stating that his brother\'s daughter (?) Harriett Ulrika Vanger, born 15 June 1960 (age 1960) has been missing from her home on Hedley Island since Saturday afternoon.'
          ],
          [
            1,
            'Timestr [11:15]: 11:15',
            '"Have you a couple of days to spare? Have just been wired for from the west of England in connection with Boscombe Valley tragedy. Shall be glad if you will come with me. Air and scenery perfect. Leave Paddington by the <<11:15|2>>."'
          ],
          [
            1,
            'Timestr [11:15]: eleven-fifteen',
            'The first time I saw them it was <<around eleven|9f>>, <<eleven-fifteen|9j>>, a Saturday morning, I was about two thirds through my route when I turned onto their block and noticed a \'56 Ford sedan pulled up in the yard with a big open U-Haul behind. There are only three houses on Pine, and theirs was the last house,the others being the Murchisons, who\'d been in Arcata a little less than a year, and the Grants, who\'d been here about two years. Murchison worked at Simpson Redwood, and Gene Grant was a cook on the morning shift at Denny\'s. Those two, then a vacant lot, then the house on the end that used to belong to the Coles.'
          ],
          [
            1,
            'Timestr [11:17]: seventeen minutes past eleven',
            'Mrs. Mooney glanced instinctively at the little gilt clock on the mantelpiece as soon as she had become aware through her revery that the bells of George\'s Church had stopped ringing. It was <<seventeen minutes past eleven|10>>: she would have lots of time to have the matter out with Mr. Doran and then catch short twelve at Marlborough Street. She was sure she would win.'
          ],
          [
            1,
            'Timestr [11:18]: 11.18',
            'It is <<11.18|9f>>. A row of bungalows in a round with a clump of larch tree in the middle.'
          ],
          [
            1,
            'Timestr [11:19]: 11:19',
            'A whistle cut sharply across his words. Peter got onto his knees to look out the window, and Miss Fuller glared at him. Polly looked down at her watch: <<11:19|2>>. The train. But the stationmaster had said it was always late.'
          ],
          [
            1,
            'Timestr [11:20]: 11h20',
            'OFFICER\'S NOTES Disruption alert logged <<11h20|1b>> from Stones\' Pool Hall (Premises ID 33CBD-Long181). Officer and Aito /379 responded. On arrival found subject shouting threats and acting in aggressive manner. A scan of the subject\'s SIM ID register revealed that the subject has recent priors including previous public disruptions and a juvenile record.'
          ],
          [
            1,
            'Timestr [11:20]: 11.20',
            'Sweeney pointed to the clock above the bar, held in the massive and indifferent jaws of a stuffed alligator head. The time was <<11.20|9c:1>>.'
          ],
          [
            1,
            'Timestr [11:25]: twenty-five past eleven',
            'At <<10.15|9m>> Arlena departed from her rondezvous, a minute or two later Patrick Redfern came down and registered surprise, annoyance, etc. Christine\'s task was easy enough. Keeping her own watch concealed she asked Linda at <<twenty-five past eleven|10>> what time it was. Linda looked at her watch and replied that it was a <<quarter to twelve|10>>.'
          ],
          [
            1,
            'Timestr [11:25]: about 11.25am',
            'When, at <<about 11.25am|2a>>, Katharina Blum was finally taken from her apartment for questioning, it was decided not to handcuff her at all.'
          ],
          [
            1,
            'Timestr [11:27]: 11.27 in the morning',
            'It\'s from one of the more recent plates the tree has scanned: <<11.27 in the morning|2a>> of 4 April 1175'
          ],
          [
            1,
            'Timestr [11:28]: twenty-eight minutes past eleven',
            'From <<twenty minutes past nine|10>> until <<twenty-seven minutes past nine|10>>, from <<twenty-five minutes past eleven|10>> until <<twenty-eight minutes past eleven|10>>, from <<ten minutes to three|10>> until <<two minutes to three|10>> the heroes of the school met in a large familiarity whose Olympian laughter awed the fearful small boy that flitted uneasily past and chilled the slouching senior that rashly paused to examine the notices in assertion of an unearned right.'
          ],
          [
            1,
            'Timestr [11:29]: twenty-nine minutes after eleven, a.m.',
            'You are four minutes too slow. No matter; it\'s enough to mention the error. Now from this moment, <<twenty-nine minutes after eleven, a.m.|10>>, this Wednesday, 2nd October, you are in my service.'
          ],
          [
            1,
            'Timestr [11:30]: 11.30',
            '\'It is now <<11.30|5a:0>>. The door to this room is shut, and will remain shut, barring emergencies, <<until 12.00|9:0>>. I am authorised to inform you that we are now under battle orders.'
          ],
          [
            1,
            'Timestr [11:30]: half-past eleven',
            '"O, Frank - I made a mistake! - I thought that church with the spire was All Saints\', and I was at the door at <<half-past eleven|10>> to a minute as you said..."'
          ],
          [
            1,
            'Timestr [11:32]: a little after half-past eleven',
            '"Thank-you," said C.B. quietly; but as he hung up his face was grim. In a few minutes he would have to break it to John that, although they had braved such dredful perils dring the earlier part of the night they had, after all, failed to save Christina. Beddows had abjured Satan at <<a little after half-past eleven|10>>. By about eighteen minutes the Canon had beaten them to it again."'
          ],
          [
            1,
            'Timestr [11:30]: 11.30',
            'This time it was Kumiko. The wall clock said <<11.30|11>>.'
          ],
          [
            1,
            'Timestr [11:31]: 1131',
            'Albatross 8 passed over Pamlico Sound at <<1131|3:0>> local time. Its on-board programming was designed to trace thermal receptors over the entire visible horizon, interrogating everything in sight and locking on any signature that fit its acquisition parameters.'
          ],
          [
            1,
            'Timestr [11:32]: about eleven thirty two',
            'And after that, not forgetting, there was the Flemish armada, all scattered, and all officially drowned, there and then, on a lovely morning, after the universal flood, at <<about eleven thirty two|5a:0>> was it? Off the coast of Cominghome...'
          ],
          [
            1,
            'Timestr [11:34]: 11.34am',
            'Christmas Eve 1995. <<11.34am|2a>>. The first time, Almasa says it slowly and softly, as if she is really looking for an answer, "Are you talking to me?" She peers into the small, grimy mirror in a train toilet.'
          ],
          [
            1,
            'Timestr [11:35]: 11.35',
            'At <<11.35|9m>> the Colonel came out; he looked hot and angry as he strode towards the lift. There goes a hanging judge, thought Wormold.'
          ],
          [
            1,
            'Timestr [11:36]: eleven thirty-six',
            'I ran up the stairs, away from the heat and the noise, the mess and the confusion. I saw the clock radio by my bed. <<Eleven thirty-six|9j>>.'
          ],
          [
            1,
            'Timestr [11:38]: 11:38',
            'At <<11:38|2>>, she left her desk and walked to the side door of the auditorium, arriving <<ten minutes before noon|10>>.'
          ],
          [
            1,
            'Timestr [11:40]: 11.40am',
            "Did escape occur to him? \x{2026} But the door was locked, and the window heavily barred with iron rods. He sat down again, and drew his journal from his pocket. On the line where these words were written, \"21st December, Saturday, Liverpool,\" he added, \"80th day, <<11.40am|2a>>,\" and waited."
          ],
          [
            1,
            'Timestr [11:40]: twenty minutes before noon',
            'During the sessions at Ito he read the Lotus Sutra on mornings of play, and he now seemed to be bringing himself to order through silent meditation. Then, quickly, there came a rap of stone on board. It was <<twenty minutes before noon|10>>.'
          ],
          [
            1,
            'Timestr [11:41]: eleven forty-one',
            'Spagnola took a deep breath and started into the log again. "<<Eleven forty-one|9j>>: large dog craps in Dr. Yamata\'s Aston Martin. <<Twelve oh-three|9j>>: dog eats two, count \'em, two of Mrs. Wittingham\'s Siamese cats. She just lost her husband last week; this sort of put her over the edge. We had to call Dr. Yamata in off the putting green to give her a sedative. The personal-injury lawyer in the unit next to hers was home for lunch and he came over to help. He was talking class action then, and we didn\'t even know who owned the dog yet."'
          ],
          [
            1,
            'Timestr [11:42]: 11:42',
            '<<11:42|2>> I\'m doing fine. I\'m doing well. I\'ve got the Hoover on, I\'m cruising along nicely- What was that? What just went up the Hoover? Why is it making that grinding noise? Have I broken it?'
          ],
          [
            1,
            'Timestr [11:45]: quarter to twelve',
            'At <<10.15|9m>> Arlena departed from her rondezvous, a minute or two later Patrick Redfern came down and registered surprise, annoyance, etc. Christine\'s task was easy enough. Keeping her own watch concealed she asked Linda at <<twenty-five past eleven|10>> what time it was. Linda looked at her watch and replied that it was a <<quarter to twelve|10>>.'
          ],
          [
            1,
            'Timestr [11:45]: quarter to twelve',
            '"...I waited till a <<quarter to twelve|10>>, and found then that I was in All Souls\'. But I wasn\'t much frightened, for I thought it could be tomorrow as well."'
          ],
          [
            1,
            'Timestr [11:45]: quarter to twelve',
            '"I will tell you the time," said Septimus, very slowly, very drowsily, smiling mysteriously. As he sat smiling at the dead man in the grey suit the quarter struck, the <<quarter to twelve|10>>.'
          ],
          [
            1,
            'Timestr [11:45]: quarter to twelve',
            'As he sat smiling, the quarter struck - the <<quarter to twelve|10>>.'
          ],
          [
            1,
            'Timestr [11:45]: 11.45am',
            'I arrived at St. Gatien from Nice on Tuesday, the 14th of August. I was arrested at <<11.45am|2a>> on Thursday, the 16th by an agent de police and an inspector in plain clothes and taken to the Commissariat.'
          ],
          [
            1,
            'Timestr [11:45]: 11:45 A.M.',
            'She tucked the phone in the crook of her neck and thumbed hurriedly through her pink messages. .... Dr. Provetto, at <<11:45 A.M.|2a>>'
          ],
          [
            1,
            'Timestr [11:45]: quarter to twelve',
            'At <<10.15|9m>> Arlena departed from her rondezvous, a minute or two later Patrick Redfern came down and registered surprise, annoyance, etc. Christine\'s task was easy enough. Keeping her own watch concealed she asked Linda at <<twenty-five past eleven|10>> what time it was. Linda looked at her watch and replied that it was a <<quarter to twelve|10>>.'
          ],
          [
            1,
            'Timestr [11:47]: thirteen minutes to noon',
            'It was a vast plain with no one on it, neither living on the earth nor dead beneath it; and I walked a long time beneath a colourless sky, which didn\'t let me judge the time (my watch, set like all military watches to Berlin time, hadn\'t stood up to the swim and showed an eternal <<thirteen minutes to noon|10>>).'
          ],
          [
            1,
            'Timestr [11:50]: ten minutes before noon',
            'At <<11:38|2>>, she left her desk and walked to the side door of the auditorium, arriving <<ten minutes before noon|10>>.'
          ],
          [
            1,
            'Timestr [11:50]: ten minutes to twelve',
            'The man who gave them to him handed him a ten-shilling note and promised him another if it were delivered at exactly <<ten minutes to twelve|10>>.'
          ],
          [
            1,
            'Timestr [11:51]: nine minutes to twelve o\'clock',
            'The next day, at <<nine minutes to twelve o\'clock|10>> <<noon|13>>, the last clock ran down and stopped. It was then placed in the town museum, as a collector\'s item, or museum piece, with proper ceremonies, addresses, and the like.'
          ],
          [
            1,
            'Timestr [11:52]: eight minutes to twelve o\'clock',
            'At any rate, we whirled into the station with many more, just as the great clock pointed to <<eight minutes to twelve o\'clock|10>>. "Thank God! We are in time," said the young man, "and thank you, too, my friend, and your good horse..."'
          ],
          [
            1,
            'Timestr [11:54]: six minutes to twelve',
            'He swilled off the remains of [his beer] and looked at the clock. It was <<six minutes to twelve|10>>.'
          ],
          [
            1,
            'Timestr [11:55]: about five minutes to twelve',
            'He was tearing off on his bicycle to one of the jobs <<about five minutes to twelve|10>> to see if he could catch anyone leaving off for dinner before the proper time.'
          ],
          [
            1,
            'Timestr [11:55]: 11:55 a.m.',
            'It was <<11:55 a.m.|2a>> on April 30.'
          ],
          [
            1,
            'Timestr [11:55]: 11:55',
            'What time did you arrive at the site? It was <<11:55|9f>>. I remember since I happened to glance at my watch when we got there. We rode our bicycles to the bottom of the hill, as far as we could go, then climbed the rest of the way on foot.'
          ],
          [
            1,
            'Timestr [11:56]: around noon',
            "A few minutes' light <<around noon|13>> is all that you need to discover the error, and re-set the clock \x{2013} provide that you bother to go up and make the observation."
          ],
          [
            -1,
            'Timestr [11:56]: can\'t be far-off twelve',
            'I wondered what the time is?\' said the latter after a pause\'. \'I don\'t know exactly\', replied Easton, \'but it <<can\'t be far-off twelve|99>>.\''
          ],
          [
            -1,
            'Timestr [11:57]: can\'t be far-off twelve',
            'I wondered what the time is?\' said the latter after a pause\'. \'I don\'t know exactly\', replied Easton, \'but it <<can\'t be far-off twelve|99>>.\''
          ],
          [
            1,
            'Timestr [11:58]: 11.58',
            'And when you go down the steps, it\'s always <<11.58|5a:0>> on the morning of September ninth, 1958.'
          ],
          [
            1,
            'Timestr [11:58]: Two minutes before the clock struck noon',
            '<<Two minutes before the clock struck noon|11a>>, the savage baron was on the platform to inspect the preparation for the frightful ceremony of <<mid-day|13>>. The block was laid forth-the hideous minister of vengeance, masked and in black, with the flaming glaive in his hand, was ready. The baron tried the edge of the blade with his finger, and asked the dreadful swordsman if his hand was sure? A nod was the reply of the man of blood. The weeping garrison and domestics shuddered and shrank from him. There was not one there but loved and pitied the gentle lady.'
          ],
          [
            1,
            'Timestr [11:59]: near to twelve',
            'There is a big grandfather clock there, and as the hands drew <<near to twelve|11>> I don\'t mind confessing I was as nervous as a cat.'
          ],
          [
            1,
            'Timestr [12:00]: noonday',
            '\'It will soon be an hour and a half,\' said the girl who kept the records. The <<noonday|13>> siren blew. \'Exactly a minute,\' she said, looking at the stopwatch of which she was so proud.'
          ],
          [
            1,
            'Timestr [12:00]: twelve',
            '\'There\'s nobody here!\' I insisted. \'It was yourself, Mrs. Linton: you knew it a while since.\' \'Myself!\' she gasped, \'and the clock is striking <<twelve|11>>!'
          ],
          [
            1,
            'Timestr [12:00]: twelve',
            'A cheap little clock on the wall struck <<twelve|11>> hurriedly, and served to begin the conversation.'
          ],
          [
            1,
            'Timestr [12:00]: noon',
            'He had saved [the republic] and it was now in the present, alive now and everywhere in the present, and the hovering faces brightened and blurred about him, became the sound of a canal in the morning, the look of some roofs in the <<noon|13>> sun, and the fragrance of a certain evening flower. Here he was, home at last. Behind him were the mountains and the Sleeping Woman in the sky, and before him, like smoky flames in the sunset, the whole beautiful beloved city.'
          ],
          [
            1,
            'Timestr [12:00]: twelve o\'clock',
            'It was precisely <<twelve o\'clock|6>>; <<twelve|5g:1>> by Big Ben; whose stroke was wafted over the northern part of London; blent with that of other clocks, mixed in a thin ethereal way with the clouds and wisps of smoke and died up there among the seagulls, <<twelve o\'clock|6>> struck as Clarissa Dalloway laid her green dress on her bed and the Warren Smiths walked down Harley Street. Twelve was the hour of their appointment.'
          ],
          [
            1,
            'Timestr [12:00]: twelve o\'clock',
            'It was precisely <<twelve o\'clock|6>>; <<twelve|5g:1>> by Big Ben; whose stroke was wafted over the northern part of London; blent with that of other clocks, mixed in a thin ethereal way wth the clouds and wisps of smoke and died up there among the seagulls - <<twelve o\'clock|6>> struck as Clarissa Dalloway laid her green dress on the bed, and the Warren Smiths walked down Harley Street.'
          ],
          [
            1,
            "Timestr [12:00]: twelve o\x{2019}clock",
            "It was precisely <<twelve o\x{2019}clock|6>>; <<twelve|5g:1>> by Big Ben; whose stroke was wafted over the northern part of London; blent with that of other clocks, mixed in a thin ethereal way with the clouds and wisps of smoke and died up there among the seagulls\x{2014}<<twelve o\x{2019}clock|6>> struck as Clarissa Dalloway laid her green dress on her bed, and the Warren Smiths walked down Harley Street"
          ],
          [
            1,
            "Timestr [12:00]: twelve o\x{2019}clock",
            "It was precisely <<twelve o\x{2019}clock|6>>; <<twelve|5g:1>> by Big Ben; whose stroke was wafted over the northern part of London; blent with that of other clocks, mixed in a thin ethereal way with the clouds and wisps of smoke, and died up there among the seagulls."
          ],
          [
            1,
            'Timestr [12:00]: noon',
            '<<Noon|13>> found him momentarily alone, while the family prepared lunch in the kitchen. The cracks in the ceiling widened into gaps. The locked wheels of his bed sank into new fault lines opening in the oak floor beneath the rug. At any moment the floor was going to give.'
          ],
          [
            1,
            'Timestr [12:00]: noon',
            'On Friday <<noon|13>>, July the twentieth, 1714, the finest bridge in all Peru broke and precipitated five travellers into the gulf below.'
          ],
          [
            1,
            'Timestr [12:00]: noon',
            'Roaring <<noon|13>>. In a well-fanned Forty-second Street cellar I met Gatsby for lunch.'
          ],
          [
            1,
            'Timestr [12:00]: Noon',
            "The Birds begun at <<Four o'clock|6>> \x{2014} Their period for Dawn \x{2014} A Music numerous as space \x{2014} But neighboring as <<Noon|13>> \x{2014}"
          ],
          [
            1,
            'Timestr [12:00]: twelve of the clock',
            'The Oxen Christmas Eve, and <<twelve of the clock|6>>. "Now they are all on their knees," An elder said as we sat in a flock By the embers in hearthside ease. We pictured the meek mild creatures where They dwelt in their strawy pen, Nor did it occur to one of us there To doubt they were kneeling then. So fair a fancy few would weave In these years! Yet, I feel, If someone said on Christmas Eve, "Come; see the oxen kneel "In the lonely barton by yonder coomb Our childhood used to know," I should go with him in the gloom, Hoping it might be so.'
          ],
          [
            1,
            'Timestr [12:00]: noon',
            'Then came the stroke of <<noon|12>>, and all these working and professional people dispersed like a trampled anthill into all the streets and directions. The white bridge was swarming with nimble dots. And when you considered that each dot had a mouth with which it was now planning to eat lunch, you couldn\'t help bursting into laughter.'
          ],
          [
            1,
            'Timestr [12:01]: 12:01',
            "And on all sides there were the clocks. Conrad noticed them immediately, at every street corner, over every archway, three quarters of the way up the sides of buildings, covering every conceivable angle of approach. Most of them were too high off the ground to be reached by anything less than a fireman's ladder and still retained their hands. All registered the same time: <<12:01|2>>. Conrad looked at his wristwatch, noted that it was just <<2:45|2>>. \x{2018}\x{2018}They were driven by a master dock\x{2019}\x{2019} Stacey told him. \x{2018}\x{2018}When that stopped, they all ceased at the same moment. <<One minute after midnight|10>>, thirty-seven years ago.\x{2019}\x{2019}"
          ],
          [
            1,
            'Timestr [12:01]: 12:01',
            'It was the twelfth of December, the twelfth month. A was twelve. The electric clock/radio by his bedside table said <<12:01|2>>.'
          ],
          [
            1,
            'Timestr [12:01]: 12:01',
            'It was the twelfth of December, the twelfth month. A was twelve. The electric clock/radio by his bedside table said <<12:01|2>>. A was waiting for it to read <<12:12|2>>, he hoped there would be some sense of cosmic rightness when it did.'
          ],
          [
            1,
            'Timestr [12:02]: twelve o\'clock two minutes',
            'It had struck <<twelve o\'clock two minutes|14>> and a quarter. The Baron\'s footman hastily seized a large goblet, and gasped with terror as he filled it with hot, spiced wine. "Tis past the hour, \'tis past," he groaned in anguish, "and surely I shall now get the red hot poker the Baron hath so often promised me, oh! Woe is me! Would that I had prepared the Baron\'s lunch before!"'
          ],
          [
            1,
            'Timestr [12:03]: 12.03',
            'At <<12.03|9m>> the sun has already punched its ticket. Sinking, it stains the cobbles and stucco of the platz in a violin-coloured throb of light that you would have to be a stone not to find poignant.'
          ],
          [
            1,
            'Timestr [12:04]: 12.04pm',
            'Though by then it was by Tina\'s own desk clock <<12.04pm|2a>> I was always touched when, out of a morning\'s worth of repetition, secretaries continued to answer with good mornings for an hour or so into the afternoon, just as people often date things with the previous year well into February; sometimes they caught their mistake and went into a "This is not my day" or "Where is my head?" escape routine; but in a way they were right, since the true tone of afternoons does not take over in offices until <<nearly two|9c:1>>.'
          ],
          [
            1,
            'Timestr [12:05]: around noon',
            "A few minutes' light <<around noon|13>> is all that you need to discover the error, and re-set the clock \x{2013} provide that you bother to go up and make the observation."
          ],
          [
            1,
            'Timestr [12:06]: around noon',
            "A few minutes' light <<around noon|13>> is all that you need to discover the error, and re-set the clock \x{2013} provide that you bother to go up and make the observation."
          ],
          [
            1,
            'Timestr [12:07]: seven minutes after 12',
            'On a Monday Simon Hirsch was going to break his leg at <<seven minutes after 12|10>>, <<noon|13>>, and as soon as Satan told us the day before, Seppi went to betting with me that it would not happen, and soon they got excited and went to betting with me themselves.'
          ],
          [
            1,
            'Timestr [12:08]: 12:08',
            'When a clock struck <<noon|11>> in Washington, D.C., the time was <<12:08|2>> in Philadephia, <<12:12|2>> in new York, and <<12:24|2>> in Boston.'
          ],
          [
            1,
            'Timestr [12:00]: noon',
            'Madame Dumas arrived at <<noon|13>>, and ten minutes later Trause handed her his ATM card and instructed her to go to the neighborhood Citibank near Sheridan Square and transfer forty thousand dollars from his savings account to his checking account.'
          ],
          [
            1,
            'Timestr [12:10]: twelve-ten',
            "They paid for only one room and kept Einstein with them because they were not going to need privacy for lovemaking. Exhausted, Travis barely managed to kiss Nora before falling into a deep sleep. He dreamed of things with yellow eyes, misshapen heads, and crocodile mouths full of sharks\x{2019} teeth. He woke five hours later, at <<twelve-ten|3b>> Thursday afternoon."
          ],
          [
            1,
            'Timestr [12:11]: 12:11',
            "At <<12:11|2>> there was a knock on the door. It was Terry, A could tell. He hadn't known Terry long, but there was something calmer, more patient, that separated Terry's knocks from the rest of the staff. He knocked from genuine politeness, not formality. \"Come in,\" A said, although the lock was on the other side. Terry did. \"It's your mother,\" he said. \"There's no easy way to say this.\" Though he had just used the easiest, because A now knew the rest. A\x{2019}s face froze, as it tried to catch up, as it tried to register the news. Then it crumpled, and while he considered this fresh blow, the tears came."
          ],
          [
            1,
            'Timestr [12:12]: 12:12',
            'It was the twelfth of December, the twelfth month. A was twelve. The electric clock/radio by his bedside table said <<12:01|2>>. A was waiting for it to read <<12:12|2>>, he hoped there would be some sense of cosmic rightness when it did.'
          ],
          [
            1,
            'Timestr [12:14]: twelve-fourteen',
            'She left London on the <<twelve-fourteen|5a:0>> from Paddington, arriving at Bristol (where she had to change) at <<two-fifty|5b>>.'
          ],
          [
            1,
            'Timestr [12:15]: quarter past twelve',
            'Very well, dear,\' she said. \'I caught the <<10.20|5a:1>> to Eastnor, which isn\'t a bad train, if you ever want to go down there. I arrived at a <<quarter past twelve|10>>, and went straight up to the house--you\'ve never seen the house, of course? It\'s quite charming--and told the butler that I wanted to see Mr Ford on business. I had taken the precaution to find out that he was not there. He is at Droitwich.\''
          ],
          [
            1,
            'Timestr [12:15]: 12.15',
            'What shall I think of that\'s liberating and refreshing? I\'m in the mood when I open my window at night and look at the stars. Unfortunately it\'s <<12.15|3:0>> on a grey dull day, the aeroplanes are active'
          ],
          [
            1,
            'Timestr [12:17]: seventeen minutes after twelve',
            'Kava ordered two glasses of coffee for himself and his beloved and some cake. When the pair left, exactly <<seventeen minutes after twelve|10>>, the club began to buzz with excitement.'
          ],
          [
            1,
            'Timestr [12:20]: twelve-twenty in the afternoon',
            "By <<twelve-twenty in the afternoon|5>>, Vince was seated in a rattan chair with comfortable yellow and green cushions at a table by the windows in that same restaurant. He\x{2019}d spotted Haines on entering. The doctor was at another window table, three away from Vince, half-screened by a potted palm. Haines was eating shrimp and drinking margaritas with a stunning blonde. She was wearing white slacks and a gaily striped tube-top, and half the men in the place were staring at her."
          ],
          [
            1,
            'Timestr [12:20]: 12:20',
            "It is <<12:20|2>> in New York a Friday three days after Bastille day, yes it is <<1959|9c:0>> and I go get a shoeshine because I will get off the <<4:19|2>> in Easthampton at <<7:15|2>> and then go straight to dinner and I don\x{2019}t know the people who will feed me"
          ],
          [
            1,
            'Timestr [12:21]: twelve twenty-one',
            'Jake think of something. PLEASE! <<Twelve twenty-one|9j>>.'
          ],
          [
            1,
            'Timestr [12:22]: twenty-two minutes past twelve',
            'By <<twenty-two minutes past twelve|10>> we leave, much too soon for our desires, this delightful spot, where the pilgrims are in the habit of bathing who come to visit the Jordan.'
          ],
          [
            1,
            'Timestr [12:24]: 12:24',
            '<<12:24|2>> My legs are in total agony. I\'ve been kneeling on hard tiles, cleaning the bath, for what seems like hours. There are little ridges where the tiles have dug into my knees, and I\'m boiling hot and the cleaning chemicals are making me cough. All I want is a rest. But I can\'t stop for a moment. I am so behind ...'
          ],
          [
            1,
            'Timestr [12:25]: 12.25',
            'Boys, do it now. God\'s time is <<12.25|9c:0>>.'
          ],
          [
            -1,
            'Timestr [12:26]: 26',
            '<<12.25pm|2a>>. 26. 27. Every time Billy saved a shot he looked heartbroken'
          ],
          [
            -1,
            'Timestr [12:27]: 27',
            '<<12.25pm|2a>>. 26. 27. Every time Billy saved a shot he looked heartbroken'
          ],
          [
            1,
            'Timestr [12:28]: 12.28',
            'The DRINK CHEER-UP COFFEE wall clock read <<12.28|11>>.'
          ],
          [
            1,
            'Timestr [12:30]: half-past twelve',
            '"You\'ll never believe this but (in Spain) they are two hours late for ever meal - two hours Fanny - (can we lunch at <<half-past twelve|10>> today?)"'
          ],
          [
            1,
            'Timestr [12:30]: 12.30 p.m.',
            '<<12.30 p.m.|2a>> Lunch'
          ],
          [
            1,
            'Timestr [12:30]: half past twelve',
            "At <<half past twelve|10>>, when Catherine\x{2019}s anxious attention to the weather was over and she could no longer claim any merit from its amendment, the sky began voluntarily to clear. A gleam of sunshine took her quite by surprise; she looked round; the clouds were parting, and she instantly returned to the window to watch over and encourage the happy appearance. Ten minutes more made it certain that a bright afternoon would succeed, and justified the opinion of Mrs. Allen, who had \x{201c}always thought it would clear up.\x{201d}"
          ],
          [
            1,
            'Timestr [12:30]: 12.30pm',
            "Tuesday, <<12.30pm|2a>>\x{2026} Baker, California\x{2026} Into the Ballantine Ale now, zombie drunk and nervous. I recognize this feeling: three or four days of booze, drugs, sun, no sleep and burned out adrenalin reserves \x{2013} a giddy, quavering sort of high that means the crash is coming. But when? How much longer?"
          ],
          [
            1,
            'Timestr [12:32]: 12:32',
            '<<12:30|2>> What is wrong with this bleach bottle? Which way is the nozzle pointing, anyway? I\'m turning it round in confusion, peering at the arrows on the plastic ... Why won\'t anything come out? OK, I\'m going to squeeze it really, really hard- That nearly got my eye. <<12:32|2>> FUCK. What has it done to my HAIR?'
          ],
          [
            1,
            'Timestr [12:32]: twelve thirty-two',
            'A chutney-biting brigadier named Boyd-Boyd fixed an appointment on the \'phone with Oxted, at Hornborough Station, for the <<twelve thirty-two|5a:0>>. He was to deliver the goods.'
          ],
          [
            1,
            'Timestr [12:33]: 12.33',
            'It\'s <<12.33|9d>> now and I could do it, the station is just down that side road there.'
          ],
          [
            1,
            'Timestr [12:35]: twelve-thirty-five',
            'As surely as Apthorpe was marked for early promotion, Trimmer was marked for ignominy. That morning he had appeared at the precise time stated in orders. Everyone else had been waiting five minutes and Colour Sergeant Cork called out the marker just as Trimmer appeared. So it was <<twelve-thirty-five|3b>> when they were dismissed.'
          ],
          [
            1,
            'Timestr [12:39]: thirty-nine minutes past twelve',
            'Next, he remembered that the morrow of Christmas would be the twenty-seventh day of the moon, and that consequently high water would be at <<twenty-one minutes past three|10>>, the half-ebb at a <<quarter past seven|10>>, low water at <<thirty-three minutes past nine|10>>, and half flood at <<thirty-nine minutes past twelve|10>>.'
          ],
          [
            1,
            'Timestr [12:40]: twenty minutes to one',
            'A little ormolu clock in the outer corridor indicated <<twenty minutes to one|10>>. The car was due at <<one-fifteen|5d>>. Thirty-five minutes: oh, to escape for only that brief period!'
          ],
          [
            1,
            'Timestr [12:42]: eighteen minutes to one',
            'The butt had been growing warm in her fingers; now the glowing end stung her skin. She crushed the cigarette out and stood, brushing ash from her black skirt. It was <<eighteen minutes to one|10>>. She went to the house phone and called his room. The telephone rang and rang, but there was no answer.'
          ],
          [
            1,
            'Timestr [12:43]: twelve-forty-three',
            'Died five minutes ago, you say? he asked. His eye went to the watch on his wrist. <<Twelve-forty-three|9j>>, he wrote on the blotter.'
          ],
          [
            1,
            'Timestr [12:44]: around quarter to one',
            'It is <<around quarter to one|10>>. No sunlight comes into the room now through the windows at right. Outside the day is fine but increasingly sultry, with a faint haziness in the air which softens the glare of the sun.'
          ],
          [
            1,
            'Timestr [12:45]: 12:45',
            'The boy handed in a dispatch. The Professor closed the door again, and after looking at the direction, opened it and read aloud. "Look out for D. He has just now, <<12:45|2>>, come from Carfax hurriedly and hastened towards the South. He seems to be going the round and may want to see you: Mina"'
          ],
          [
            1,
            'Timestr [12:46]: around quarter to one',
            'It is <<around quarter to one|10>>. No sunlight comes into the room now through the windows at right. Outside the day is fine but increasingly sultry, with a faint haziness in the air which softens the glare of the sun.'
          ],
          [
            1,
            'Timestr [12:49]: 12:49 hours',
            'The first victim of the Krefeld raid died at <<12:49 hours|1>> Double British Summer Time at B Flight, but it wasn\'t due to carelessness.'
          ],
          [
            1,
            'Timestr [12:50]: ten minutes to one',
            'So presently Bert was sent up to the top of the house to look at a church clock which was visible therefrom, and when he came down he reported that it was <<ten minutes to one|10>>.'
          ],
          [
            1,
            'Timestr [12:52]: 12.52',
            'The nightclub stood on the junction, flamboyant, still. It was <<12.52|9f>>.'
          ],
          [
            1,
            'Timestr [12:53]: 12:53',
            'Aboot twelve miles. We ought tae pass her at Pinmore. She\'s due there at <<12:53|5d>>.'
          ],
          [
            1,
            'Timestr [12:54]: 12:54 pm',
            'I listen to the different boats\' horns, hoping to learn what kind of boat I\'m hearing and what the signal means: is the boat leaving or entering the harbor; is it the ferry, or a whale-watching boat, or a fishing boat? At <<5:33 pm|2a>> there is a blast of two deep, resonant notes a major third apart. On another day there is the same blast at <<12:54 pm|2a>>. On another, exactly <<8:00 am|2a>>.'
          ],
          [
            1,
            'Timestr [12:55]: five to one',
            'The inspector glanced at the clock. <<Five to one|10a:1>>. A busy morning.'
          ],
          [
            1,
            'Timestr [12:58]: 12.58pm',
            'The watch on my wrist showed <<12.58pm|2a>> I\'d have time to hit the morgue.'
          ],
          [
            1,
            'Timestr [12:59]: 12.59pm',
            'And I had been looking at my watch since the train had started at <<12.59pm|2a>>'
          ],
          [
            1,
            'Timestr [13:00]: one',
            '"I think," he said, with a triumphant smile, "that I may safely expect to find the person I seek in the dining-room, fair lady." "There may be more than one." "Whoever is there, as the clock strikes <<one|11>>, will be shadowed by one of my men; of these, one, or perhaps two, or even three, will leave for France to-morrow. One of these will be the `Scarlet Pimpernel.\'"'
          ],
          [
            1,
            'Timestr [13:00]: one o\'clock pee em',
            '"<<One o\'clock pee em|6>>! Hello, Insert Name Here!" Said by the Disorganizer'
          ],
          [
            1,
            'Timestr [13:00]: one o\'clock',
            "\x{201c}Czarina Catherine reported entering Galatz at <<one o'clock|6>> today.\x{201d}"
          ],
          [
            1,
            'Timestr [13:00]: 1.00 p.m.',
            '<<1.00 p.m.|2a>> First afternoon class'
          ],
          [
            1,
            'Timestr [13:02]: After 1 o\'clock',
            '<<After 1 o\'clock|6>> checks, Gretta always goes out for a smoke.'
          ],
          [
            1,
            'Timestr [13:00]: 1pm',
            'Gottfried Rembke arrived at <<1pm|5>> precisely. The moment he walked into the restaurant, handed his coat to the waiter, they knew it was him. The solid, stocky body, the gleaming pate, the open expression, the vigorous handshake: everything about him radiated ease and enthusiasm'
          ],
          [
            1,
            'Timestr [13:00]: one o\'clock',
            'I got to Schmidt\'s early, feeling horribly nervous. At <<one o\'clock|6>> sharp: Toni. She was looking at the menu she knew well - Schmorbraten? Schnitzel? - when he loomed over her. I had seen him come in. She looked up, through him, at me. \'Traitor.\' Jamie, hovering, looking very big, said her pet name, a German diminutive chosen by her. Toni addressed the air. \'If he does not leave at once I shall tell the waiter that I am not sharing my table with this gentleman.\' Jamie heard, said her name again, turned to go, I rose to go with him. Toni - with that concentration of will - said, \'YOU are lunching with me.\''
          ],
          [
            1,
            'Timestr [13:00]: thirteen',
            'It was a bright cold day in April, and the clocks were striking <<thirteen|11>>.'
          ],
          [
            1,
            'Timestr [13:00]: one o\'clock',
            'It was <<one o\'clock|6>>. I bought some apples and a small pork pie and drove across the bridge to the other side of the riverbank in the direction of Orford Ness.'
          ],
          [
            1,
            'Timestr [13:00]: one',
            "Many moons passed by. Did Baboon ever fly? Did he ever get to the sun? I\x{2019}ve just heard today That he\x{2019}s well on his way! He\x{2019}ll be passing through Acton at <<one|9c:0>>."
          ],
          [
            1,
            'Timestr [13:00]: one o\'clock',
            'That day it was <<one o\'clock|6>> before John and Roger rowed across and went up to Dixon\'s farm for the milk and a new supply of eggs and butter.'
          ],
          [
            1,
            'Timestr [13:00]: one o\'clock',
            'The day-room floor gets cleared of tables and at <<one o\'clock|6>> the doctor comes out of his office down the hall, nods once at the nurse as he goes past where he\'s watching out of her window, sits in his chair just to the left of the door.'
          ],
          [
            -1,
            'Timestr [13:01]: about one',
            'There\'s five fathoms out there, he said. It\'ll be swept up that way when the tide comes in <<about one|99>>. It\'s nine days today.'
          ],
          [
            1,
            'Timestr [13:02]: about one o\'clock',
            'At <<about one o\'clock|6>> the overseer arrived and told them he had no jobs for them'
          ],
          [
            1,
            'Timestr [13:03]: a little after one o\'clock',
            'It was <<a little after one o\'clock|6>> when I got there, time for lunch, so I had it. The food was awful. But it would go on the expense account, and after I\'d eaten I got out my notebook and put it down. Lunch $1.50. Taxi $1.00.'
          ],
          [
            1,
            'Timestr [13:04]: four minutes past one',
            '"Jesus Christ!" he gasped. "It\'s <<four minutes past one|10>>!" Linden frantically seized hold of a pair of steps and began wandering about the room with them.'
          ],
          [
            1,
            'Timestr [13:05]: five past one',
            "\x{201c}Samantha?\x{201d} I can hear Trish approaching. \x{201c}Um ... hold on!\x{201d} I hurry to the door, trying to block her view. \x{201c}It's already <<five past one|10>>,\x{201d} I can hear her saying a little sharply. \x{201c}And I did ask, most clearly for ...\x{201d} Her voice trails off into silence as she reaches the kitchen door, and her whole face sags in astonishment. I turn and follow her gaze as she surveys the endless plates of sandwiches. \x{201c}My goodness!\x{201d} At last Trish finds her voice. \x{201c}This is ... this is very impressive!\x{201d}"
          ],
          [
            1,
            'Timestr [13:05]: five past one',
            'At <<five past one|10>> Alleyn opened the outer door, knocked his pipe out on the edge of the stone step,and remained staring out on to the drive.'
          ],
          [
            1,
            'Timestr [13:06]: 13 hours and 6 minutes',
            'And then at precisely <<13 hours and 6 minutes|14>> - confusion broke out in the rectangle.'
          ],
          [
            1,
            'Timestr [13:09]: nine minutes past one',
            'At <<nine minutes past one|10>>, a pair of horses approached (not from the city, from which direction Krieger had expected her to come, but from the Desert, which lay, vast and largely uncharted, out to the West and South-West of the city.)'
          ],
          [
            1,
            'Timestr [13:10]: ten minutes past one',
            "\"It was <<ten minutes past one|10>>.\x{201d} \x{201c}You are sure of that?\""
          ],
          [
            1,
            'Timestr [13:11]: 1.11',
            'I pursued my inquiries at the other stations along the line an\' I found there was a gentleman wi\' a bicycle tuk the <<1.11|5a:1>> train at Girvan.'
          ],
          [
            1,
            'Timestr [13:13]: thirteen minutes past one',
            "\"There it is! There it is!\" shouted the Professor. \"Now for the centre of the globe!\" he added in Danish. I looked at Hans. \"For\x{fc}t!\" was his tranquil answer. \"Forward!\" replied my uncle. It was <<thirteen minutes past one|10>>."
          ],
          [
            1,
            'Timestr [13:15]: One hour and a quarter',
            "\x{2018}Monsieur has well slept this morning,\x{2019} he said, smiling. \x{2018}What o\x{2019}clock is it, Victor?\x{2019} asked Dorian Gray, sleepily. \x{2018}<<One hour and a quarter|14a:1>>, monsieur.\x{2019}"
          ],
          [
            1,
            'Timestr [13:15]: one-fifteen',
            '"Where are the ladies and Gentlemen?" asked Aleyn. "Sir, in the garding", said Bunce. "What time\'s lunch?" "<<One-fifteen|9j>>".'
          ],
          [
            1,
            'Timestr [13:15]: Quarter-past one',
            "The clock caught Miss LaFosse\x{b4}s eye. \x{b4}Good heavens!\x{b4} she gasped. \x{b4}Look at the time. <<Quarter-past one|10>>. You must be starved.' She turned impetuously to Miss Pettigrew."
          ],
          [
            1,
            'Timestr [13:16]: 1.16pm',
            'And the first stop had been at <<1.16pm|2a>> which was 17 minutes later.'
          ],
          [
            1,
            'Timestr [13:17]: one seventeen',
            "<<One seventeen|5a:0>> and four seconds. That shorter guy\x{2019}s really got it made, and gets on a scooter, and that taller one, he goes in. <<One seventeen|5a:0>> and forty seconds. That girl there, she\x{2019}s got a green ribbon in her hair. Too bad that bus just cut her from view."
          ],
          [
            1,
            'Timestr [13:18]: one eighteen',
            '<<One eighteen|9j>> exactly. Was she stupid enough to head inside? Or wasn\'t she? We\'ll know before long, When the dead are carried out.'
          ],
          [
            1,
            'Timestr [13:20]: 1320 hours',
            "Kamarov, signal to Purga: 'Diving at\x{2014},'\" he checked his watch, \"'\x{2014}<<1320 hours|1>>. Exercise OCTOBER FROST begins as scheduled. You are released to other assigned duties. We will return as scheduled.\" Kamarov worked the trigger on the blinker light to transmit the message. The Purga responded at once, and Ramius read the flashing signal unaided: \"IF THE WHALES DON'T EAT YOU. GOOD LUCK TO RED OCTOBER!\""
          ],
          [
            1,
            'Timestr [13:20]: twenty minutes past one',
            'The time is coming for action. Today this Vampire is limit to the powers of man, and till sunset he may not change. It will take him time to arrive here, see it is <<twenty minutes past one|10>>, and there are yet some times before he can hither come, be he never so quick.'
          ],
          [
            1,
            'Timestr [13:20]: twenty minutes past one',
            'Today this Vampire is limit to the powers of man, and till sunset he may not change. It will take him time to arrive here, see it is <<twenty minutes past one|10>>, and there are yet some times before he can hither come, be he never so quick.'
          ],
          [
            1,
            'Timestr [13:23]: 1.23pm',
            'And when we got to Swindon Mother had keys to the house and we went in and she said, "Hello?" but there was no one there because it was <<1.23pm|2a>>.'
          ],
          [
            1,
            'Timestr [13:23]: twenty-three minutes past one',
            "The clock marked <<twenty-three minutes past one|10>>. He was suddenly full of agitation, yet hopeful. She had come! Who could tell what she would say? She might offer the most natural explanation of her late arrival. F\x{e9}licie entered the room, her hair in disorder, her eyes shining, her cheeks white, her bruised lips a vivid red; she was tired, indifferent, mute, happy and lovely, seeming to guard beneath her cloak, which she held wrapped about her with both hands, some remnant of warmth and voluptuous pleasure."
          ],
          [
            1,
            'Timestr [13:24]: 1:24 p.m',
            'Littell checked his watch - <<1:24 p.m|2a>> - Littell grabbed the phone by the bed.'
          ],
          [
            1,
            'Timestr [13:25]: one-twenty-five',
            'I\'d really have liked to, I told her, if it weren\'t for the things I had in the drier. I cast an eye at my watch. <<One-twenty-five|9j>>. The drier had already stopped.'
          ],
          [
            1,
            'Timestr [13:26]: around one-thirty',
            'Raymond came back with Masson <<around one-thirty|5a:0>>. His arm was bandaged up and he had an adhesive plaster on the corner of his mouth. The doctor had told him it was nothing, but Raymond looked pretty grim. Masson tried to make him laugh. But he still wouldn\'t say anything.'
          ],
          [
            1,
            'Timestr [13:30]: half-past one',
            'Lupin not having come down, I went up again at <<half-past one|10>>, and said we dined at <<two|9c:0>>; he said he "would be there."'
          ],
          [
            1,
            'Timestr [13:30]: half past one',
            'She was a sticker. A clock away in the town struck <<half past one|10>>.'
          ],
          [
            1,
            'Timestr [13:30]: half-past one',
            'Shredding and slicing, dividing and subdividing, the clocks of Harley Street nibbled at the June day, counselled submission, upheld authority, and pointed out in chorus the supreme advantages of a sense of proportion, until the mound of time was so far diminished that a commercial clock, suspended above a shop in Oxford Street, announced, genially and fraternally, as if it were a pleasure to Messrs Rigby and Lowndes to give the information gratis, that it was <<half-past one|10>>.'
          ],
          [
            1,
            'Timestr [13:32]: one ... thirty-two',
            'At the third stroke it will be <<one ... thirty-two|5b>> ... and twenty seconds. \'Beep ... beep ... beep.\' Ford Prefect suppressed a little giggle of evil satisfaction, realized that he had no reason to suppress it, and laughed out loud, a wicked laugh.'
          ],
          [
            1,
            'Timestr [13:33]: one ... thirty-three',
            'He waited for the green light to show and then opened the door again on to the now empty cargo hold.\'... <<one ... thirty-three|5a:0>> ... and fifty seconds.\' Very nice.'
          ],
          [
            1,
            'Timestr [13:34]: one ... thirty-four',
            '\'At the third stroke it will be ...\' He tiptoed out and returned to the control cabin. \'... <<one ... thirty-four|5a:0>> and twenty seconds.\' The voice sounded as clear as if he was hearing it over a phone in London, which he wasn\'t, not by a long way.'
          ],
          [
            1,
            'Timestr [13:34]: one ... thirty ... four',
            'He then went and had a last thorough examination of the emergency suspended animation chamber, which was where he particularly wanted it to be heard. \'At the third stroke it will be <<one ... thirty ... four|5b>> ... precisely.\''
          ],
          [
            1,
            'Timestr [13:37]: 1.37pm',
            "He had not dared to sleep in his rented car\x{2014}you didn't sleep in your car when you worked for Jesus Castro\x{2014}and he was beginning to hallucinate. Still, he was on the job, and he scribbled in his notebook:\" <<1.37pm|2a>> Subject appears to be getting laid.\""
          ],
          [
            1,
            'Timestr [13:39]: 1.39pm',
            'And it was now <<1.39pm|2a>> which was 23 minutes after the stop, which mean that we would be at the sea if the train didn\'t go in a big curve. But I didn\'t know if it went in a big curve.'
          ],
          [
            1,
            'Timestr [13:42]: 1.42pm',
            'The last note was recorded at <<1.42pm|2a>>: G.M. on site at H-by; will take over the matter.'
          ],
          [
            1,
            'Timestr [13:44]: forty-four minutes past one',
            'By good luck, the next train was due at <<forty-four minutes past one|10>>, and arrived at Yateland (the next station) ten minutes afterward.'
          ],
          [
            1,
            'Timestr [13:45]: quarter to two',
            'That period which is always so dangerous, when the wicket is bad, the ten minutes before lunch, proved fatal to two more of the enemy. The last man had just gone to the wickets, with the score at a hundred and thirty-one, when a <<quarter to two|10>> arrived, and with it the luncheon interval.'
          ],
          [
            1,
            'Timestr [13:45]: one forty-five',
            'The blow fell at precisely <<one forty-five|5a:0>> (summer-time). Benson, my Aunt Agatha\'s butler, was offering me the fried potatoes at the moment, and such was my emotion that I lofted six of them on the sideboard with the spoon.'
          ],
          [
            1,
            'Timestr [13:47]: 1.47pm',
            'Poppy was sprawled on Brianne\'s bed, applying black mascara to her stubby lashes. Brianne was sitting at her desk, trying to complete an essay before the <<2pm|5>> deadline. It was <<1.47pm|2a>>.'
          ],
          [
            1,
            'Timestr [13:48]: twelve minutes to two in the afternoon',
            'It was <<twelve minutes to two in the afternoon|10>> when Claude Moreau and his most-trusted field officer, Jacques Bergeron, arrived at the Georges Cinq station of the Paris Metro. They walked, separately, to the rear of the platform, each carrying a handheld radio, the frequencies calibrated to each other.'
          ],
          [
            1,
            'Timestr [13:49]: 1.49',
            'The bookstall clerk had seen the passenger in grey pass the bookstall at <<1.49|9c:0>>, in the direction of the exit.'
          ],
          [
            1,
            'Timestr [13:50]: ten to two',
            'Rahel\'s toy wristwatch had the time painted on it. <<Ten to two|10a:1>>. One of her ambitions was to own a watch on which she could change the time whenever she wanted to (which according to her was what Time was meant for in the first place).'
          ],
          [
            1,
            'Timestr [13:50]: one-fifty',
            'The best train of the day was the <<one-fifty|5a:1>> from Paddington which reached Polgarwith <<just after seven o\'clock|10>>.'
          ],
          [
            1,
            'Timestr [13:55]: five minutes before two',
            'If I was punctual in quitting Mlle. Reuter\'s domicile, I was at least equally punctual in arriving there; I came the next day at <<five minutes before two|10>>, and on reaching the schoolroom door, before I opened it, I heard a rapid, gabbling sound, which warned me that the "priere du midi" was not yet concluded.'
          ],
          [
            1,
            'Timestr [13:57]: three minutes to two',
            'I looked for a clock. It was <<three minutes to two|10>>. "I hope you can catch him, then. Thank you. I really appreciate it."'
          ],
          [
            1,
            "Timestr [13:58]: almost two o\x{2019}clock",
            "It was <<almost two o\x{2019}clock|6>>, but nothing moved, Stari Teo\x{10d}ak was silent and so empty it seemed abandoned, and yet Tijmen constantly felt he was being observed by invisible eyes."
          ],
          [
            1,
            "Timestr [13:59]: One ... fifty-nine",
            "For twenty minutes he sat and watched as the gap between the ship and Epun closed, as the ship's computer teased and kneaded the numbers that would bring it into a loop around the little moon, and close the loop and keep it there, orbiting in perpetual obscurity. '<<One ... fifty-nine|5a:0>> \x{2026}'\""
          ],
          [
            1,
            'Timestr [14:00]: two o\'clock',
            '\'She could have fired the jig, and he could have kept on picking up his packages at the old time, <<two o\'clock|6>>. As it was, he had almost been arrested.\''
          ],
          [
            1,
            'Timestr [14:00]: two o\'clock',
            '"The old people\'s home is at Marengo, fifty miles from Algiers. I\'ll catch the <<two o\'clock|6>> bus and get there in the afternoon.".... "I caught the <<two o\'clock|6>> bus. It was very hot."'
          ],
          [
            1,
            'Timestr [14:00]: approximately 1400 hours',
            'At <<approximately 1400 hours|1>> a pair of enemy Skyhawks came flying in at deck level out of nowhere.'
          ],
          [
            1,
            'Timestr [14:00]: two o\'clock',
            'At <<two o\'clock|6>> Gatsby put on his bathing suit and left word with the butler that if any one phoned word was to be brought to him at the pool.'
          ],
          [
            1,
            'Timestr [14:00]: two',
            'At <<two|9e>>, the snowplows were in action in Lillestrom.'
          ],
          [
            1,
            'Timestr [14:00]: two o\'clock',
            "I caught the <<two o'clock|6>> bus. It was very hot. I ate at C\x{e9}leste's restaurant as usual. They all felt very sorry for me and C\x{e9}leste told me, 'There's no one like a mother'."
          ],
          [
            1,
            'Timestr [14:00]: two o\'clock',
            'The Home for Aged Persons is at Marengo, some fifty miles from Algiers. With the <<two o\'clock|6>> bus I should get there well before nightfall. Then I can spend the night there, keeping the usual vigil beside the body, and be back here by tomorrow evening.'
          ],
          [
            1,
            'Timestr [14:00]: 2.00',
            'When Salander woke up it was <<2.00|3b>> on Saturday afternoon and a doctor was poking at her.'
          ],
          [
            1,
            'Timestr [14:01]: about two o\' clock',
            'At <<about two o\' clock|6>> the owners young wife came, carrying a handleless cup and a pot with a quilted cover, to where I was still lying disconsolate'
          ],
          [
            1,
            'Timestr [14:01]: about two o\'clock',
            'The next day was Saturday and, now that Moon was done, I decided to bring the job to its end. So I sent word that I shouldn\'t be able to umpire for the team at Steeple Sinderby and, after working through the morning, came down <<about two o\'clock|6>>.'
          ],
          [
            1,
            'Timestr [14:02]: 14.02',
            '"I\'m not dead. How did that happen?" He was right. It was <<14.02|9d>> and twenty-six seconds. Destiny had not been fulfilled. We all looked at each other, confused.'
          ],
          [
            1,
            'Timestr [14:04]: 2.04pm',
            '<<2.04pm|2a>>. Once again, the Quartermaster-General\'s office came on the line asking for Colonel Finckh, and once again Finckh heard the quiet, unemotional, unfamiliar voice'
          ],
          [
            1,
            'Timestr [14:05]: five past two',
            '...and at <<five past two|10>> on 17 September of that same unforgettable year 1916, I was in the Muryovo hospital yard, standing on trampled withered grass, flattened by the September rain.'
          ],
          [
            1,
            'Timestr [14:06]: six minutes past two in the afternoon',
            'A man driving a tractor saw her, four hundred yards from her house, <<six minutes past two in the afternoon|10>>.'
          ],
          [
            1,
            'Timestr [14:10]: ten past two',
            'Mrs Eunice Harris pulls back the sleeve of her good coat and checks her good watch. "Indeed yes. Half twelve," and waves a hand at the Town Hall clock as if it was hers. "Always <<ten past two|10>>. Someone put a nail in the time years back."'
          ],
          [
            1,
            'Timestr [14:13]: two ... thirteen',
            'At the third stroke, it will be <<two ... thirteen|5b>> ... and fifty seconds.\''
          ],
          [
            1,
            'Timestr [14:15]: 2.15 P.M.',
            'I had a date with her next day at <<2.15 P.M.|2a>> In my own rooms, but it was less successful, she seemed to have grown less juvenile, more of a woman overnight.'
          ],
          [
            1,
            'Timestr [14:15]: 2.15 p.m.',
            '<<2.15 p.m.|2a>> Second afternoon class'
          ],
          [
            1,
            'Timestr [14:15]: 2.15pm',
            'I had a date with her next day at <<2.15pm|2a>> in my own rooms, but it was less successful, she seemed to have grown less juvenile, more of a woman overnight. A cold I caught from her led me to cancel a fourth assignment, nor was I sorry to break an emotional series that threatened to burden me with heart-rending fantasies and peter out in dull disappointment. So let her remain, sleek, slender Monique, as she was for a minute or two'
          ],
          [
            1,
            'Timestr [14:16]: 2.16',
            'Oh, good evening. I think you were on the barrier when I came in at <<2.16|3b>> this afternoon. Now, do you know that you let me get past without giving up my ticket? Yes, yes he-he! I really think you ought to be more careful'
          ],
          [
            1,
            'Timestr [14:19]: 2:19',
            '<<2:19|2>>: Duane Hinton walks out. He walks through the backyard. He lugs some clothes. He wore said clothes last night. He walks to the fence. He feeds the incinerator. He lights a match.'
          ],
          [
            1,
            'Timestr [14:20]: twenty minutes past two',
            'The having originated a precaution which was already in course of execution, was a great relief to Miss Pross. The necessity of composing her appearance so that it should attract no special notice in the streets, was another relief. She looked at her watch, and it was <<twenty minutes past two|10>>. She had no time to lose, but must get ready at once.'
          ],
          [
            1,
            'Timestr [14:20]: twenty past two',
            'Inevitable, implacable, the rainstorm wept itself out. She saw Tom look at his watch. \'What time is it?\' \'<<Twenty past two|10>>. Want to go back to the hotel for a while?\' \'All right.\' They walked out of the gardens and down the rue de Vaugirard. This holiday, unlike those holidays long ago, would not end with her sleeping at home. Two nights from now I will be high over the Atlantic Ocean and on Saturday I will be walking around in the Other Place. I am going to America. I am starting my life over again. But as she said these words to herself, she found it hard to imagine what the new life would be like. And, again, she was afraid.'
          ],
          [
            1,
            'Timestr [14:20]: twenty minutes past two',
            'She looked at her watch and it was <<twenty minutes past two|10>>. She had no time to lose but must get ready at once.'
          ],
          [
            1,
            'Timestr [14:20]: twenty minutes past two',
            'The watch found at the Weir was challenged by the jeweller as one he had wound and set for Edwin Drood, at <<twenty minutes past two|10>> on that same afternoon; and it had run down, before being cast into the water; and it was the jeweller\'s positive opinion that it had never been re-wound.'
          ],
          [
            1,
            'Timestr [14:22]: two-twenty-two',
            'Garth here. Sunday afternoon. Sorry to miss you, but I\'ll leave a brief message on your tape. <<Two-twenty-two|5a:0>> or there-aboutish. Great party.'
          ],
          [
            1,
            'Timestr [14:25]: 2:25',
            'Gary shut himself inside his office and flipped through the messages. Caroline had called at <<1:35|9f>>, <<1:40|2>>, <<1:50|2>>, <<1:55|2>>, and <<2:10|2>>; it was now <<2:25|2>>. He pumped his fist in triumph. Finally, finally, some evidence of desperation.'
          ],
          [
            1,
            'Timestr [14:28]: 28 minutes and 57 seconds after 2pm',
            'It happened to be the case that the sixty-based system coincided with our our current method of keeping time... Apparently they wanted us to know that that something might happen at <<28 minutes and 57 seconds after 2pm|10>> on a day yet to be specified.'
          ],
          [
            1,
            'Timestr [14:30]: 2:30',
            'Ach! It\'s <<2:30|9f>>. Look how the time is flying. And it\'s still so much to do today.. It\'s dishes to clean, dinner to defrost, and my pills I haven\'t yet counted. I don\'t get it... Why didn\'t the Jews at least try to resist? It wasn\'t so easy like you think. Everybody was so starving and frightened, and tired they couldn\'t believe even what\'s in front of their eyes.'
          ],
          [
            1,
            'Timestr [14:30]: 2.30pm',
            'At <<2.30pm|2a>> on the 13th inst. began to shadow Sir Bobadil the Ostrich, whom I suspect of being the criminal. Shadowing successful. Didn\'t lose sight of him once.'
          ],
          [
            1,
            'Timestr [14:30]: half past two',
            'At <<half past two|10>> the same afternoon the boy and the elderly man are standing in the room directly above the Inner Office and Waiting-Room.'
          ],
          [
            1,
            'Timestr [14:30]: half-past two in the afternoon',
            'It was <<half-past two in the afternoon|10>>. The sun hung in the faded blue sky like a burning mirror, and away beyond the paddocks the blue mountains quivered and leapt like sea. Sid wouldn\'t be back until <<half-past ten|10>>. He had ridden over to the township with four of the boys to help hunt down the young fellow who\'d murdered Mr. Williamson. Such a dreadful thing!'
          ],
          [
            1,
            'Timestr [14:30]: half-past two o\'clock',
            'It was <<half-past two o\'clock|10>> when the knock came. I took my courage a deux mains and waited. In a few minutes Mary opened the door, and announced "Dr. Van Helsing".'
          ],
          [
            1,
            'Timestr [14:30]: 1/2 past 2 o\'clock',
            'May 14th 1800. Wm and John set off into Yorkshire after dinner at <<1/2 past 2 o\'clock|10>>, cold pork in their pockets. I left them at the turning of the Low-wood bay under the trees. My heart was so full that I could barely speak to W. when I gave him a farewell kiss.'
          ],
          [
            1,
            'Timestr [14:32]: 2.32 p.m.',
            'Like <<2.32 p.m.|2a>>, Beecher and Avalon, L3 R2 (which meant left three blocks, right two) <<2:35 p.m.|2a>>, and you wondered how you could pick up one box, then drive 5 blocks in 3 minutes and be finished cleaning out another box.'
          ],
          [
            1,
            'Timestr [14:36]: two thirty-six',
            'I look at my watch. <<Two thirty-six|9j>>. All I\'ve got left today is take in the laundry and fix dinner.'
          ],
          [
            1,
            'Timestr [14:39]: 2.39',
            'Noo, there\'s a report come in fra\' the station-master at Pinwherry that there was a gentleman tuk the <<2.39|5a:0>> at Pinwherry.'
          ],
          [
            1,
            'Timestr [14:40]: two-forty',
            'If a girl looks swell when she meets you, who gives a damn when she\'s late? \'We better hurry\', I said. \'The show starts at <<two-forty|9g>>.\''
          ],
          [
            1,
            'Timestr [14:40]: twenty minutes to three',
            'Members of Big Side marked Michael and Alan as the two most promising three-quarters for Middle Side next year, and when the bell sounded at <<twenty minutes to three|10>>, the members of Big Side would walk with Michael and Alan towards the changing room and encourage them by flattery and genial ragging.'
          ],
          [
            1,
            'Timestr [14:41]: 2.41',
            'At <<2.41|9e>>, when the afternoon fast train to London was pulling out of Larborough prompt to the minute, Miss Pym sat under the cedar on the lawn wondering whether she was a fool, and not caring much anyhow.'
          ],
          [
            1,
            'Timestr [14:43]: 2.43pm',
            'Jacobson died at <<2.43pm|2a>> the next day after slashing his wrists with a razor blade in the second cubicle from the left in the men\'s washroom on the third floor.'
          ],
          [
            1,
            'Timestr [14:45]: quarter to three',
            'He never came down till a <<quarter to three|10>>.'
          ],
          [
            1,
            'Timestr [14:45]: two forty-five',
            'Pull the other one, and tell it to the marines, and don\'t make me laugh, and fuck off out of it, and all that, but the fact remained that it was still only <<two forty-five|5a:0>>\'.'
          ],
          [
            1,
            'Timestr [14:45]: quarter to three',
            'What time is it?\' \'Look for yourself,\' the old woman says to me. I look, and I see the clock has no hands. \'There are no hands,\' I say. The old woman looks at the clock face and says to me, \'It\'s a <<quarter to three|10>>\'.'
          ],
          [
            1,
            'Timestr [14:50]: ten to three',
            'Stands the Church clock at <<ten to three|10>>? And is there honey still for tea?'
          ],
          [
            1,
            'Timestr [14:54]: About 2.55',
            "In the end, it was the Sunday afternoons he couldn\x{2019}t cope with, and that terrible listlessness that starts to set in <<about 2.55|5a:1>>, when you know you\x{2019}ve had all the baths you can usefully have that day, that however hard you stare at any given paragraph in the newspaper you will never actually read it, or use the revolutionary new pruning technique it describes, and that as you stare at the clock the hands will move relentlessly on to <<four o\x{2019}clock|6>>, and you will enter the long dark teatime of the soul."
          ],
          [
            1,
            'Timestr [14:55]: five to three',
            'The superior, the very reverend John Conmee SJ reset his smooth watch in his interior pocket as he came down the presbytery steps. <<Five to three|10a:1>>. Just nice time to walk to Artane.'
          ],
          [
            1,
            'Timestr [14:56]: 2.56 P.M.',
            '<<2.56 P.M.|2a>> Helen is alone now. Her face is out of frame, and through the viewfinder I see only a segment of the pillow, an area of crumpled sheet and the upper section of her chest and shoulders.'
          ],
          [
            1,
            'Timestr [14:58]: two minutes to three',
            'From <<twenty minutes past nine|10>> until <<twenty-seven minutes past nine|10>>, from <<twenty-five minutes past eleven|10>> until <<twenty-eight minutes past eleven|10>>, from <<ten minutes to three|10>> until <<two minutes to three|10>> the heroes of the school met in a large familiarity whose Olympian laughter awed the fearful small boy that flitted uneasily past and chilled the slouching senior that rashly paused to examine the notices in assertion of an unearned right.'
          ],
          [
            1,
            'Timestr [14:58]: two minutes to three',
            'We betted that it would happen on the morrow; they took us up and gave us the odds of two to one; we betted that it would happen in the afternoon; we got odds of four to one on that; we betted that it would happen at <<two minutes to three|10>>; they willingly granted us the odds of ten to one on that.'
          ],
          [
            1,
            'Timestr [15:00]: three o\'clock',
            '\'I gotta get uptown by <<three o\'clock|6>>.\''
          ],
          [
            1,
            'Timestr [15:00]: three o\'clock',
            '"Remember," they shouted, "battle at <<three o\'clock|6>> sharp. There\'s no time to lose."'
          ],
          [
            1,
            'Timestr [15:00]: three',
            'And the sound of the bell flooded the room with its melancholy wave; which receded, and gathered itself together to fall once more, when she heard, distractedly, something fumbling, something scratching at the door. Who at this hour? <<Three|9i:1>>, good Heavens! Three already!'
          ],
          [
            1,
            'Timestr [15:00]: three o\'clock',
            'At <<three o\'clock|6>> on the afternoon of that same day, he called on her. She held out her two hands, smiling in her usual charming, friendly way; and for a few seconds they looked deep into each other\'s eyes.'
          ],
          [
            1,
            "Timestr [15:00]: three o\x{2019}clock",
            "At <<three o\x{2019}clock|6>> precisely I was at Baker Street, but Holmes had not yet returned."
          ],
          [
            1,
            'Timestr [15:00]: three',
            'At <<three|9m>> on the Wednesday afternoon, that bit of the painting was completed.'
          ],
          [
            1,
            'Timestr [15:00]: three in the afternoon',
            'Ditched by the woman I loved, I exalted my suffering into a sign of greatness (lying collapsed on a bed at <<three in the afternoon|9a>>), and hence protected myself from experiencing my grief as the outcome of what was at best a mundane romantic break-up. Chloe\'s departure may have killed me, but it had at least left me in glorious possession of the moral high ground. I was a martyr.'
          ],
          [
            1,
            'Timestr [15:00]: three o\'clock',
            'He walks into the Hospital for Broken Things at <<three o\'clock|6>> on Monday afternoon. That was the arrangement. If he came in <<after six o\'clock|6>>, he was to head straight for the house in Sunset Park.'
          ],
          [
            1,
            "Timestr [15:00]: three o\x{2019}clock",
            "I had a <<three o\x{2019}clock|6>> class in psychology, the first meeting of the semester, and I suspected I was going to miss it. I was right. Victoria made a real ritual of the whole thing, clothes coming off with the masturbatory dalliance of a strip show, the covers rolling back periodically to show this patch of flesh or that, strategically revealed."
          ],
          [
            1,
            'Timestr [15:00]: three o\'clock in the beautiful breezy autumn day',
            'It was <<three o\'clock in the beautiful breezy autumn day|6>> when Mr. Casaubon drove off to his Rectory at Lowick, only five miles from Tipton; and Dorothea, who had on her bonnet and shawl, hurried along the shrubbery and across the park that she might wander through the bordering wood with no other visible companionship than that of Monk, the Great St. Bernard dog, who always took care of the young ladies in their walks'
          ],
          [
            1,
            "Timestr [15:00]: three-o\x{2019}clock",
            "Ladies bathed before <<noon|13>>, after their <<three-o\x{2019}clock|6>> naps, and by nightfall were like soft teacakes with frostings of sweat and sweet talcum."
          ],
          [
            1,
            'Timestr [15:00]: three o\'clock',
            'M. Madeleine usually came at <<three o\'clock|6>>, and as punctuality was kindness, he was punctual.'
          ],
          [
            1,
            'Timestr [15:00]: three o\'clock',
            'On Wednesday at <<three o\'clock|6>>, Monsieur and Madame Bovary, seated in their dog-cart, set out for Vaubyessard, with a great trunk strapped on behind and a bonnet-box in front of the apron. Besides these Charles held a bandbox between his knees.'
          ],
          [
            1,
            'Timestr [03:00]: three in the morning',
            'The scent and smoke and sweat of a casino are nauseating at <<three in the morning|9a>>. Then the soul-erosion produced by high gambling - a compost of greed and fear and nervous tension - becomes unbearable and the senses awake and revolt from it.'
          ],
          [
            1,
            'Timestr [15:00]: three o\'clock',
            '<<Three o\'clock|6>> is always too late or too early for anything you want to do.'
          ],
          [
            1,
            'Timestr [15:00]: three o\'clock',
            '<<Three o\'clock|6>> is the perfect time in Cham, because anything is possible. You can still ski, but also respectably start drinking, the shops have just reopened, the sun is still up. <<Three o\'clock|6>> is never too late or too early.'
          ],
          [
            1,
            'Timestr [15:00]: three o\'clock',
            'Today was the day Alex had appointed for her \'punishment\'. I became increasingly nervous as the hour of <<three o\'clock|6>> approached. I was alone in the house, and paced restlessly from room to room, glancing at the clocks in each of them.'
          ],
          [
            1,
            'Timestr [15:01]: about three in the afternoon',
            'The sun was now setting. It was <<about three in the afternoon|9h>> when Alisande had begun to tell me who the cowboys were; so she had made pretty good progress with it - for her. She would arrive some time or other, no doubt, but she was not a person who could be hurried.'
          ],
          [
            1,
            'Timestr [15:03]: 3.03pm',
            'I check Shingi\'s mobile phone - it says it\'s <<3.03pm|2a>>. I get out of bed, open my suitcase to take clean socks out and the smell of Mother hit my nose and make me feel dizzy.'
          ],
          [
            -1,
            'Timestr [15:04]: 1504',
            'Woken at <<1504|99>> by Michelangelo hammering away with his chisel.'
          ],
          [
            1,
            'Timestr [15:05]: five minutes past three that afternoon',
            'Ultimately, at <<five minutes past three that afternoon|10>>, Smith admitted the falsity of the Fort Scott tale. "That was only something Dick told his family. So he could stay out overnight. Do some drinking."'
          ],
          [
            1,
            'Timestr [15:07]: seven minutes past three',
            'The next day was grey, threatening rain. He was there at <<seven minutes past three|10>>. The clock on the church over the way pointed to it. They had arranged to be there at <<three fifteen|5b>>. Therefore, if she had been there when he came, she would have been eight minutes before her time.'
          ],
          [
            1,
            'Timestr [15:08]: 3 hr 8 m p.m.',
            'A private wireless telegraph which would transmit by dot and dash system the result of a national equine handicap (flat or steeplechase) of 1 or more miles and furlongs won by an outsider at odds of 50 to 1 at <<3 hr 8 m p.m.|14>> at Ascot (Greenwich time), the message being received and available for betting purposes in Dublin at <<2.59 p.m.|2a>>'
          ],
          [
            1,
            'Timestr [15:09]: 3.09',
            'On the next day he boarded the London train which reaches Hull at <<3.09|9c:1>>. At Paragon Station he soon singled out Beamish from Merriman\'s description.'
          ],
          [
            1,
            'Timestr [15:10]: 3.10pm',
            'This time it was only the simple fact that the hands chanced to point to <<3.10pm|2a>>, the precise moment at which all the clocks of London had stopped.'
          ],
          [
            1,
            'Timestr [15:13]: thirteen minutes past three',
            'The lift moved. It was <<thirteen minutes past three|10>>. The bell gave out its ping. Two men stepped out of the lift, Alan Norman and another man. Tony Blair walked into the office.'
          ],
          [
            1,
            'Timestr [15:14]: 3.14',
            'A signal sounded. "There\'s the <<3.14|5a:0>> up," said Perks. "You lie low till she\'s through, and then we\'ll go up along to my place, and see if there\'s any of them strawberries ripe what I told you about."'
          ],
          [
            1,
            'Timestr [15:14]: three fourteen',
            'I shall be back at exactly <<THREE fourteen|5a:1>>, for our hour of revery together, real sweet revery darling'
          ],
          [
            1,
            'Timestr [15:15]: quarter past three',
            'Gordon was alone. He wandered back to the door. The strawberry-nosed man glanced over his shoulder, caught Gordon\'s eye, and moved off, foiled. He had been on the point of slipping Edgar Wallace into his pocket. The clock over the Prince of Wales struck a <<quarter past three|10>>.'
          ],
          [
            1,
            'Timestr [15:15]: 3:15',
            'I got out my old clothes. I put wool socks over my regular socks and took my time lacing up the boots. I made a couple of tuna sandwiches and some double-decker peanut-butter crackers. I filled my canteen and attached the hunting knife and the canteen to my belt. As I was going out the door, I decided to leave a note. So I wrote: "Feeling better and going to Birch Creek. Back soon. R. <<3:15|2>>." That was about four hours from now.'
          ],
          [
            1,
            'Timestr [15:15]: 3:15',
            'July 3: 5 3/4 hours. Little done today. Deepening lethargy, dragged myself over to the lab, nearly left the road twice. Concentrated enough to feed the zoo and get the log up to date. Read through the operating manuals Whitby left for the last time, decided on a delivery rate of 40 rontgens/min., target distance of 530 cm. Everything is ready now. Woke <<11:05|2>>. To sleep <<3:15|2>>.'
          ],
          [
            1,
            'Timestr [15:16]: 1516',
            'The Nimrod rendezvoused with the light aircraft at <<1516|1a>> GMT.'
          ],
          [
            1,
            'Timestr [15:20]: twenty minutes past three',
            "At <<twenty minutes past three|10>> on Monday, 26 January 1948, in Tokyo, and I am drinking and I am drinking and I am drinking and I am drinking and I am drinking and I am drinking and I am drinking and I am drinking and I am drinking \x{2026}"
          ],
          [
            1,
            'Timestr [15:23]: three twenty-three',
            '<<Three twenty-three|9j>>! Is that all? Doesn\'t time - no, I\'ve already said that, thought that. I sit and watch the seconds change on the watch. I used to have a limited edition Rolex worth the price of a new car but I lost it.'
          ],
          [
            1,
            'Timestr [15:23]: three twenty-three',
            '<<Three twenty-three|9j>>! Is that all? Doesn\'t time - no, I\'ve already said that, thought that. I sit and watch the seconds change on the watch. I used to have a limited edition Rolex worth the price of a new car but I lost it. It was present from...Christine? No, Inez. She got fed up with me always having to ask other people what the time was; embarrassed on my behalf.'
          ],
          [
            1,
            'Timestr [15:25]: 15.25',
            "\"Hmm, let's see. It's a three-line rail-fence, a, d, g...d-a-r-l...Got it: 'Darling Hepzibah'\x{2014}Hepzibah? What kind of name is that?\x{2014}'Will meet you Reading Sunday <<15.25|5a:1>> train Didcot-Reading.' Reading you all right, you idiots.\""
          ],
          [
            1,
            'Timestr [15:27]: 3.27pm',
            'And she rang the Reverend Peters and he came into school at <<3.27pm|2a>> and he said, \'So, young man, are we ready to roll?\''
          ],
          [
            1,
            'Timestr [15:29]: nearly half-past three',
            '"Good heavens!" she said, "it\'s <<nearly half-past three|10>>. I must fly. Don\'t forget about the funeral service," she added, as she put on her coat. "The tapers, the black coffin in the middle of the aisle, the nuns in their white-winged coifs, the gloomy chanting, and the poor cowering creature without any teeth, her face all caved in like an old woman\'s, wondering whether she wasn\'t really and in fact dead - wondering whether she wasn\'t already in hell. Goodbye."'
          ],
          [
            -1,
            'Timestr [15:30]: half-past thrrree',
            '"Before I am rrroasting the alarm-clock, I am setting it to go off, not at <<nine o\'clock|6>> the next morning, but at half-past thrrree the next afternoon. Vhich means <<half-past thrrree|99>> this afternoon. And that", she said, glancing at her wrist-watch, "is in prrree-cisely seven minutes\' time!"'
          ],
          [
            1,
            'Timestr [15:30]: 3.30 p.m.',
            '<<3.30 p.m.|2a>> Catch school bus home'
          ],
          [
            1,
            'Timestr [15:30]: half past three',
            'I must have completed my packing with time to spare, for when the knock came on my door at <<half past three|10>> precisely, I had been sitting in my chair waiting for a good while. I opened the door to a young Chinese man, perhaps not even twenty, dressed in a gown, his hat in his hand.'
          ],
          [
            1,
            'Timestr [15:32]: 3:32',
            'At <<3:32|2>> precisely, I noticed Kaitlyn striding confidently past the Wok House. She saw me the moment I raised my hand, flashed her very white and newly straightened teeth at me, and headed over.'
          ],
          [
            1,
            'Timestr [15:33]: three thirty-three',
            'I picked up my briefcase, glancing at my watch again as I did so. <<Three thirty-three|9j>>.'
          ],
          [
            1,
            'Timestr [15:35]: three-thirty-five',
            'By <<three-thirty-five|5b>> business really winds down. I have already sold my ladderback chairs and my Scottish cardigans. I\'m not even sure now why I\'ve sold all these things, except perhaps so as not to be left out of this giant insult to one\'s life that is a yard sale, this general project of getting rid quick.'
          ],
          [
            1,
            'Timestr [15:35]: 3:35 P.M.',
            "If Me flashed a little crazy after a restless night of smoking & prowling the darkened house with owl-eyes alert to suspicious noises outside & on the roof, it didn\x{2019}t inevitably mean she\x{2019}d still be in such a state when the schoolbus deposited Wolfie back home at <<3:35 P.M.|2a>>"
          ],
          [
            1,
            'Timestr [15:37]: 15.37',
            'The explosion was now officially designated an "Act of God". But, thought Dirk, what god? And why? What god would be hanging around Terminal Two of Heathrow Airport trying to catch the <<15.37|5a:0>> flight to Oslo?'
          ],
          [
            1,
            'Timestr [15:39]: three thirty-nine in the afternoon',
            'I lived two lives in late 1965 and early 1963, one in Dallas and one in Jodie. They came together at <<three thirty-nine in the afternoon|5>> of April 10.'
          ],
          [
            1,
            'Timestr [15:40]: three-forty',
            "At <<three-forty|9m>>, Cliff called to report that Dilworth and his lady friend were sitting on the deck of the Amazing Grace, eating fruit and sipping wine, reminiscing a lot, laughing a little. \x{201c}From what we can pick up with directional microphones and from what we can see, I\x{2019}d say they don\x{2019}t have any intention of going anywhere. Except maybe to bed. They sure do seem to be a randy old pair.\x{201d} \x{201c}Stay with them,\x{201d} Lem said. \x{201c}I don\x{2019}t trust him.\x{201d}"
          ],
          [
            1,
            'Timestr [15:41]: 15:41',
            'At <<15:41|1a>> GMT, the Cessna\'s engine began to cut out and the plane - presumably out of fuel - began to lose altitude'
          ],
          [
            1,
            'Timestr [15:44]: 3.44 p.m.',
            "The armed response team hastily assembled from Str\x{e4}ngn\x{e4}s arrived at Bjurman's summer cabin at <<3.44 p.m.|2a>>"
          ],
          [
            1,
            'Timestr [15:45]: 3.45pm',
            'I opened my notebook, flipped almost to the end before I found a blank page, and wrote "October 5th, <<3.45pm|2a>>, Dunning to Longview Cem, puts flowers on parents\' (?) graves. Rain." I had what I wanted.'
          ],
          [
            1,
            'Timestr [15:45]: 3:45',
            'One meal is enough now, topped up with a glucose shot. Sleep is still \'black\', completely unrefreshing. Last night I took a 16 mm. film of the first three hours, screened it this morning at the lab. The first true-horror movie. I looked like a half-animated corpse. Woke <<10:25|2>>. To sleep <<3:45|2>>.'
          ],
          [
            1,
            'Timestr [15:49]: 3.49 p.m.',
            '<<3.49 p.m.|2a>> Get off school bus at home'
          ],
          [
            1,
            'Timestr [15:49]: 3.49 pm',
            'But there were more bad things than good things. And one of them was that Mother didn\'t get back from work til <<5.30 pm|2a>> so I had to go to Father\'s house between <<3.49 pm|2a>> and <<5.30 pm|2a>> because I wasn\'t allowed to be on my own and Mother said I didn\'t have a choice so I pushed the bed against the door in case Father tried to come in.'
          ],
          [
            1,
            'Timestr [15:50]: 3.50 p.m.',
            '<<3.50 p.m.|2a>> Have juice and snack'
          ],
          [
            1,
            'Timestr [15:51]: fifty-one minutes after fifteen o\'clock',
            'Date of the telegram, Rome, November 24, <<ten minutes before twenty-three o\'clock|10>>. The telegram seems to say, "The Sovereigns and the Royal Children expect themselves at Rome tomorrow at <<fifty-one minutes after fifteen o\'clock|10>>."'
          ],
          [
            1,
            'Timestr [15:53]: seven minutes to four',
            'It was like the clouds lifting away from the sun. Jodie glanced at Reacher. He glanced at the clock. <<Seven minutes to four|10>>. Less than three hours to go.'
          ],
          [
            1,
            'Timestr [15:55]: 3.55 p.m.',
            '<<3.55 p.m.|2a>> Give Toby food and water'
          ],
          [
            1,
            'Timestr [15:56]: four minutes to four',
            '<<Four minutes to four|10>>. Newman sighed again, lost in thought.'
          ],
          [
            1,
            'Timestr [15:57]: close upon four',
            'It was <<close upon four|9:0>> before the door opened, and a drunken-looking groom, ill-kempt and side-whiskered with an inflamed face and disreputable clothes, walked into the room. Accustomed as I was to my friend\'s amazing powers in the use of disguises, I had to look three times before I was certain that it was indeed he.'
          ],
          [
            1,
            'Timestr [15:58]: Towards four o\'clock',
            '<<Towards four o\'clock|6>> the condition of the English army was serious. The Prince of Orange was in command of the centre, Hill of the right wing, Picton of the left wing. The Prince of Orange, desperate and intrepid, shouted to the Hollando-Belgians: "Nassau! Brunswick! Never retreat!"'
          ],
          [
            1,
            'Timestr [15:59]: nearly 4',
            'He looked at his watch: it was <<nearly 4|9f>>. He helped Delphine to her feet and led her down a passage to a rear door that gave on to the hospital garden.'
          ],
          [
            1,
            'Timestr [16:00]: four o\'clock',
            '... when they all sat down to table at <<four o\'clock|6>>, about three hours after his arrival, he had secured his lady, engaged her mother\'s consent, and was not only in the rapturous profession of the lover, but, in the reality of reason and truth, one of the happiest of men.'
          ],
          [
            1,
            'Timestr [16:00]: four',
            '"What else can I answer, When the lights come on at <<four|9f>>. At the end of another year"'
          ],
          [
            1,
            'Timestr [16:00]: 4.00 p.m.',
            '<<4.00 p.m.|2a>> Take Toby out of his cage'
          ],
          [
            1,
            'Timestr [16:00]: four o\'clock',
            'As he turned off towards the fishing village of Cellardyke, the familiar pips announced the <<four o\'clock|6>> news. The comforting voice of the newsreader began the bulletin. \'The convicted serial killer and former TV chat show host Jacko Vance has begun his appeal against conviction.'
          ],
          [
            1,
            'Timestr [16:00]: four',
            'Charmian woke at <<four|9b>> and sensed the emptiness of the house.'
          ],
          [
            1,
            "Timestr [16:00]: four o\x{2019}clock",
            "Djerzinski arrived punctually at <<four o\x{2019}clock|6>>. Desplechin had asked to see him. The case was intriguing. Certainly, it was common for a researcher to take a year\x{2019}s sabbatical to work in Norway or Japan, or one of those sinister countries where middle aged people committed suicide en masse."
          ],
          [
            1,
            'Timestr [16:00]: four o\'clock',
            '<<Four o\'clock|6>>: wedge-shaped gardens lie Under a cavernous, a wind-picked sky.'
          ],
          [
            1,
            'Timestr [16:00]: four o\'clock',
            '<<Four o\'clock|6>>: when time in the city quivers on its axis - the day not yet spent, the wheels of evening just beginning to turn. The handover hour, was how Marius liked to think of it.'
          ],
          [
            1,
            "Timestr [16:00]: Four o\x{2019}clock",
            "<<Four o\x{2019}clock|6>> has just struck. Good! Arrangement, revision, reading from <<four to five|10>>. Short snooze of restoration for myself, from <<five to six|10>>. Affair of agent and sealed letter from <<seven to eight|10>>. At <<eight|9e>>, en route."
          ],
          [
            1,
            "Timestr [16:00]: four o\x{2019}clock",
            "<<Four o\x{2019}clock|6>> has just struck. Good! Arrangement, revision, reading from <<four to five|10>>. Short snooze of restoration for myself, from <<five to six|10>>. Affair of agent and sealed letter from <<seven to eight|10>>. At <<eight|9e>>, en route."
          ],
          [
            1,
            'Timestr [16:00]: four o\'clock in the afternoon',
            'He played for twenty-two days, just as he said he would. Every day at <<four o\'clock in the afternoon|6>>, regardless of how much fighting was going on around him.'
          ],
          [
            1,
            "Timestr [16:00]: four o\x{2019}clock in the afternoon",
            "Her eyes caught the kryptonite glow of the digital clock on the front of the microwave. Honest and true, the numbers spelled out the time although she, for a moment, found its calculation to be somehow erroneous. It was <<four o\x{2019}clock in the afternoon|6>>."
          ],
          [
            1,
            'Timestr [16:00]: four o\'clock',
            'I doubt whether anyone was commissioned to send the news along the actual telegraph, and yet Mrs. Proudie knew it before <<four o\'clock|6>>. But she did not know it quite accurately.\'Bishop\', she said, standing at her husband\'s study door. \'They have committed that man to gaol. There was no help for them unless they had forsworn themselves.\''
          ],
          [
            1,
            "Timestr [16:00]: Four O\x{2019}clock",
            "I only found out much later that those flowers were called <<Four O\x{2019}clock|6>>, and were not magic at all. The magic was in the seed, waiting to be watered and cared for, the real magic was life."
          ],
          [
            1,
            "Timestr [16:00]: four o\x{2019}clock",
            "In the end, it was the Sunday afternoons he couldn\x{2019}t cope with, and that terrible listlessness that starts to set in <<about 2.55|5a:1>>, when you know you\x{2019}ve had all the baths you can usefully have that day, that however hard you stare at any given paragraph in the newspaper you will never actually read it, or use the revolutionary new pruning technique it describes, and that as you stare at the clock the hands will move relentlessly on to <<four o\x{2019}clock|6>>, and you will enter the long dark teatime of the soul."
          ],
          [
            1,
            'Timestr [16:00]: four',
            "In the four thousand rooms of the Centre the four thousand electric clocks simultaneously struck <<four|11>>. Discarnate voices called from the trumpet mouths. \"Main Day-shift off duty. Second Day-shift take over. Main Day-shift off \x{2026}\""
          ],
          [
            1,
            'Timestr [16:00]: 4 o\'clock',
            'It was my turn to cook the evening meal so I didn\'t linger in the common room. It was exactly <<4 o\'clock|6>> as I made my way out of the building, and doors opened behind and before me, discharging salvos of vocal babble and the noise of chair-legs scraping on wooden floors.'
          ],
          [
            1,
            'Timestr [16:00]: Four? O\'clock',
            "Miss Douce took Boylan's coin, struck boldly the cashregister. It clanged. Clock clacked. Fair one of Egypt teased and sorted in the till and hummed and handed coins in change. Look to the west. A clack. For me. \x{2014}What time is that? asked Blazes Boylan. <<Four? O'clock|6>>. Lenehan, small eyes ahunger on her humming, bust ahumming, tugged Blazes Boylan's elbowsleeve. \x{2014}Let's hear the time, he said."
          ],
          [
            1,
            'Timestr [16:00]: 1600h',
            'The horrifying R.N. wipes Gately\'s face off as best she can with her hand and says she\'ll try to fit him in for a sponge bath before she goes off shift at <<1600h|1>>., at which Gately goes rigid with dread.'
          ],
          [
            1,
            'Timestr [16:01]: 1601',
            'Light is coming in through the curtains. Suddenly the digits on the clock radio look like a year. <<1601|9l:1>>. I woke up a bit early, don\'t have to be born for another 400 years.'
          ],
          [
            1,
            'Timestr [16:02]: two minutes after four',
            'I\'d just looked up at the clock, to make sure time wasn\'t getting away from me, when I heard the shot. It was <<two minutes after four|10>>. I didn\'t know what to do.'
          ],
          [
            1,
            'Timestr [16:03]: 16.03',
            'She read the page carefully and then said, \'<<16.03|9j>> - cat goes to the toilet in front garden.\''
          ],
          [
            1,
            'Timestr [16:04]: A little after four o\'clock',
            '<<A little after four o\'clock|6>>, Pippa meandered over to Dot\'s house carrying a bottle of wine she had been keeping in reserve and wondering if she could possibly be pregnant in spite of the vestigial coil still lodged in her uterus like astronaut litter abandoned on the moon.'
          ],
          [
            1,
            'Timestr [16:05]: five past four',
            'I had met Irwin on the steps of the Widener Library. I was standing at the top of the long flight, overlooking the red brick buildings that walled the snow-filled quad and preparing to catch the trolley back to the asylum, when a tall young man with a rather ugly and bespectacled, but intelligent face, came up and said, \'Could you please tell me the time?\' I glanced at my watch. \'<<Five past four|10>>.\''
          ],
          [
            1,
            'Timestr [16:05]: five past four',
            'I was standing at the top of the long flight, overlooking the red brick buildings that walled the snow-filled quad and preparing to catch the trolley back to the asylum, when a tall young man with a rather ugly and bespectacled, but intelligent face, came up and said, \'Could you please tell me the time?\' I glanced at my watch. \'<<Five past four|10>>.\''
          ],
          [
            1,
            'Timestr [16:05]: five minutes past four',
            "IT was exactly <<five minutes past four|10>> as Mr. Robert Audley stepped out upon the platform at Shoreditch, and waited placidly \x{2026} it took a long while to make matters agreeable to all claimants, and even the barrister's seraphic indifference to mundane affairs nearly gave way."
          ],
          [
            1,
            'Timestr [16:06]: six minutes after four',
            'At <<six minutes after four|10>>, Benny\'s Cadillac pulled up in front of Mr. Botelia\'s store, and Benny\'s mother stepped out of the car with Penelope, who was gnawing on the tip of an ice cream cone.'
          ],
          [
            1,
            'Timestr [16:07]: seven minutes after four',
            'But he released him immediately because the ladder slipped from under his feet and for an instant he was suspended in air and then he realised that he had died without Communion, without time to repent of anything or to say goodbye to anyone, at <<seven minutes after four|10>> on Pentecost Sunday.'
          ],
          [
            1,
            'Timestr [16:08]: eight minutes after four',
            'It was <<eight minutes after four|10>>. I still don\'t have a plan. Maybe the guys in the Nova, maybe they had a plan.'
          ],
          [
            1,
            'Timestr [16:09]: nine minutes after four',
            'I have to hang up now, Rosemary said. "I just wanted to know if there was any improvement." "No, there isn\'t. It was nice of you to call." She hung up. It was <<nine minutes after four|10>>.'
          ],
          [
            1,
            'Timestr [16:10]: 1610h',
            '<<1610h|1>>. E.T.A Weight room. Freestyle circuits. The clank and click of various resistance systems.'
          ],
          [
            1,
            'Timestr [16:10]: ten-past four',
            'She looks at the clock. She\'s in the kitchen. A minute left. She waits. It\'s <<ten-past four|10>>. She picks up the eclair. She licks the cream out of it. She watches herself.It\'s fuckin\' stupid. But. She bites into the chocolate, and the pastry that\'s been softened by the cream. Jack\'s not home yet. Leannes\'s at work. Paula will be leaving, herself, in a bit. She\'s a year off the drink. Exactly a year. She looks at the clock. A year and a minute.'
          ],
          [
            1,
            'Timestr [16:11]: 4:11 P.M.',
            '<<4:11 P.M.|2a>> Thurs. A Huey helicopter flies east overhead as the last of the U.S. Marines make ready to leave the beach; a buzzard dangles in the thermals closer over the town.'
          ],
          [
            1,
            'Timestr [16:12]: twelve minutes after four',
            'At precisely <<twelve minutes after four|10>> a body of cavalry rode into the square, four abreast, clearing a way for the funeral cortege.'
          ],
          [
            1,
            'Timestr [16:13]: 4.13pm',
            'But at precisely <<4.13pm|2a>>, the fifty thousand spectators saw the totally unexpected happen, before their very eyes. From the most crowded section of the southern grandstand, an apparition suddenly emerged.'
          ],
          [
            1,
            'Timestr [16:14]: 4.14pm',
            'Then at <<4.14pm|2a>> on March 12 I moved behind zinc-zirconium-not-to-be-revealed-compounds protecting me in this hill, and God have mercy but the struggle is just exchanged for the next one, which is exhausting me further as I say, to separate the true from the false.'
          ],
          [
            1,
            'Timestr [16:15]: quarter past four',
            'I remember the dread with which I at <<quarter past four|10>>/ Let go with a bang behind me our house front door'
          ],
          [
            1,
            'Timestr [16:15]: quarter past four',
            'It is only a <<quarter past four|10>>, (shewing his watch) and you are not now in Bath. No theatre, no rooms to prepare for. Half an hour at Northanger must be enough.'
          ],
          [
            1,
            'Timestr [16:15]: 4:15',
            'Must have the phone disconnected. Some contractor keeps calling me up about payment for 50 bags of cement he claims I collected ten days ago. Says he helped me load them onto a truck himself. I did drive Whitby\'s pick-up into town but only to get some lead screening. What does he think I\'d do with all that cement? Just the sort of irritating thing you don\'t expect to hang over your final exit. (Moral: don\'t try too hard to forget Eniwetok.) Woke <<9:40|2>>. To sleep <<4:15|2>>.'
          ],
          [
            1,
            'Timestr [16:15]: quarter past four in the afternoon',
            'On the tenth day of October at <<quarter past four in the afternoon|10>> with a dry hot wind blowing through the passed Maria found herself in Baker. She had never meant to go as far as Baker, had started out that day as every day, her only destination the freeway. But she had driven out of San Bernadino and up the Barstow and instead of turning back at Barstow (she had been out that far before but never that late in the day, it was past time to navigate back, she was out too far too late, the rhythm was lost ) she kept driving.'
          ],
          [
            1,
            'Timestr [16:15]: 4.15',
            'The sun had begun to sink in the west, and the shadow of an oak branch had crept across my knees. My watch said it was <<4.15|9f>>.'
          ],
          [
            1,
            'Timestr [16:16]: 4.16pm',
            '<<4.16pm|2a>> The terrace outside the bar is packed, and Igor feels proud of his ability to plan things, because even though he\'s never been to Cannes before, he had foreseen precisely this situation and reserved a table.'
          ],
          [
            1,
            'Timestr [16:17]: four-seventeen',
            'Apparently the great Percy has no sense of humour, for at <<four-seventeen|5b>> he got tired of it, and hit Skinner crisply in the right eyeball, blacking the same as per illustration.'
          ],
          [
            1,
            'Timestr [16:17]: seventeen minutes after four',
            'In the next instant she was running toward her house, unmindful of the bags she had dropped, seeing only the police cars, knowing as she glanced down at her watch and saw that it was <<seventeen minutes after four|10>>, that for her time had stopped.'
          ],
          [
            1,
            'Timestr [16:18]: 4.18 p.m.',
            '<<4.18 p.m.|2a>> Put Toby into his cage'
          ],
          [
            1,
            'Timestr [16:19]: 4:19 PM',
            'Jessica [<<4:19 PM|2a>>] Don\'t tease me like that. I haven\'t been to a play in years. Charles [<<4:19 PM|2a>>] Then it\'ll be my treat. You and the hubby can have big fun on me.'
          ],
          [
            1,
            'Timestr [16:20]: 4.20 p.m.',
            '<<4.20 p.m.|2a>> Watch television or a video'
          ],
          [
            1,
            'Timestr [16:20]: twenty minutes past four',
            'At <<twenty minutes past four|10>> - or, to put it another, blunter way, an hour and twenty minutes past what seemed to be all reasonable hope - the unmarried bride, her head down, a parent stationed on either side of her, was helped out of the building...'
          ],
          [
            1,
            'Timestr [16:21]: 4.21pm',
            '<<4.21pm|2a>> As they started on, Doug picked up a twig and after rubbing it off, started to move one end of it inside his mouth. "What are you doing?" Bob asked. "Brushing my teeth, nature style," Doug answered. Bob grunted, smiling slightly. "I\'ll use my toothbrush," he said.'
          ],
          [
            1,
            'Timestr [16:22]: 4.22pm',
            'Monday, <<4.22pm|2a>> Washington, D.C. Paul Hood took his daily late-afternoon look at the list of names on his computer monitor.'
          ],
          [
            1,
            'Timestr [16:23]: 4.23',
            'They were hurrying west, trying to reach the river before sunset. The warming-related \'adjustments\' to Earth\'s orbit had shortened the winter days, so that now, in January, sunset was taking place at <<4.23|9c:0>>.'
          ],
          [
            1,
            'Timestr [16:24]: 4:24',
            'Mike winked at Ashley and continued with the remaining greetings and hugs and handshakes. The time was <<4:24|2>>. Six hours to go. The minutes seemed to just melt away.'
          ],
          [
            1,
            'Timestr [16:25]: twenty-five minutes past four',
            'As I dressed I glanced at my watch. It was no wonder that no one was stirring. It was <<twenty-five minutes past four|10>>. I had hardly finished when Holmes returned with the news that the boy was putting in the horse.'
          ],
          [
            1,
            'Timestr [16:26]: twenty-six minutes after four',
            "It seemed all wrong to have thought of such a thing. She thought, \"I don't know him. Nor does he know me. Nor ever shall we.\x{201d} She put her bare hand in the sun, where the wind would weather it. It was <<twenty-six minutes after four|10>>."
          ],
          [
            1,
            'Timestr [16:28]: 4.28pm',
            'Same day: <<4.28pm|2a>>- Right turn at the second bus stop after the gas station. I stopped the car at the first ward post office and inquired at the corner tobacconists. Mr. M\'s house was the one to the right of the post office, visible diagonally in front of me.'
          ],
          [
            1,
            'Timestr [16:29]: 4:29 pm',
            'October 21, 2007, <<4:29 pm|2a>>. The phone was red. And what William hated most about it, besides the fact that it was inconveniently mounted on a wall in a tight corner (and at a strange angle), was that when it rang it was so gratingly loud that you could actually see the cherry receiver quavering as you picked it up.'
          ],
          [
            1,
            'Timestr [16:30]: four-thirty that afternoon',
            'At <<four-thirty that afternoon|5>> in late January when I stepped into the parlour with Boo, my dog, Hutch was in his favourite armchair, scowling at the television, which he had muted.'
          ],
          [
            1,
            'Timestr [16:30]: four thirty',
            'I leave the office at <<four thirty|5b>>, head up to Xclusive where I work out on free weights for an hour, then taxi across the park to Gio\'s in the Pierre Room for a facial, a manicure and, if time permits, a pedicure.'
          ],
          [
            1,
            'Timestr [16:30]: four-thirty',
            "She hung up on me at first, then asked me whether I made a point of behaving like a 'small-time suburban punk' with women I had slept with. But after apologies, insults, laughter, and tears, Romeo and Juliet were to be seen together later that afternoon, mushily holding hands in the dark at a <<four-thirty|5f>> screening of L ove and Death at the National Film Theatre. Happy endings \x{2013} for now at least."
          ],
          [
            1,
            'Timestr [16:31]: 4:31 PM',
            "From: Renee Greene \x{2013} August 5, 2011 \x{2013} <<4:31 PM|2a>> To: Shelley Manning Subject: Re: All Access What should I be worried about, then? JUST KIDDING. You're right. Well, I gotta run, my groupie friend. I actually have REAL work to do. I'll talk to you tonight."
          ],
          [
            1,
            'Timestr [16:32]: 4.32pm',
            '<<4.32pm|2a>>. Now the eight Marines next to us leave their emplacement and file quickly past, the last saying, "Go! Go! Go!" They break into a run.'
          ],
          [
            1,
            'Timestr [16:33]: 4.33pm',
            'At <<4.33pm|2a>>, a short bald man puffing on a cigar arrived at the library. He approached a huge cabinet storing thousands of alphabetically arranged cards and slid a drawer out. The tips of his fingers were bandaged.'
          ],
          [
            1,
            'Timestr [16:34]: 4.34 p.m.',
            'A bedroom stocked with all the ordinary, usual things. There was a wardrobe in the corner. A bedside table with a collection of water glasses of varying ages and an alarm clock with red digital numbers- <<4.34 p.m.|2a>>'
          ],
          [
            1,
            'Timestr [16:35]: 4.35',
            'The Voice shut itself off with a click, and then reopened conversation by announcing the arrival at Platform 9 of the <<4.35|5a:0>> from Birmingham and Wolverhampton.'
          ],
          [
            1,
            'Timestr [16:37]: 1637',
            'She should have been home by now. <<1637|9l:0>>. Yes. It\'s as if I had the date of a year on my arm. Every day is a piece of world history.'
          ],
          [
            1,
            'Timestr [16:39]: 4:39 p.m.',
            'Harlem enjoys lazy Sabbath mornings, although the pace picks up again in the afternoon, after church. My watch read <<4:39 p.m.|2a>>, and I realized that I hadn\'t eaten all day. I bought two slices of pizza from a sidewalk vendor on 122nd and Lenox Avenue and washed it down with a grape Snapple.'
          ],
          [
            1,
            'Timestr [16:40]: four forty P.M.',
            '<<Four forty P.M.|5>> Besta sang another hymn. Everyone knew something was wrong. How long did they wait? The mayor was going crazy inside, as was the mayor\'s wife, as was their daughter. Seiji could barely contain his rage. He was turning as red as his red tuxedo.'
          ],
          [
            1,
            'Timestr [16:42]: 4:42pm',
            'I\'m always happy when I reach the finish line of a long-distance race, but this time it really struck me hard. I pumped my right fist into the air. The time was <<4:42pm|2a>>. Eleven hours and forty-two minutes since the start of the race.'
          ],
          [
            1,
            'Timestr [16:45]: four-forty-five',
            'At <<four-forty-five|9m>> Miss Haddon went to tea with the Principal, who explained why she desired all the pupils to learn the same duet. It was part of her new co-ordinative system.'
          ],
          [
            1,
            'Timestr [16:45]: fifteen minutes before five',
            'The next day Bill took only ten minutes of the twenty-minute break allotted for the afternoon and left at <<fifteen minutes before five|10>>. He parked the car in the lot just as Arlene hopped down from the bus.'
          ],
          [
            1,
            'Timestr [16:46]: 4:46',
            "At <<4:46|2>> an obese, middle-aged man shuffled in. Wearing a starched guayabera and dark green pants, Ure\x{f1}a asked for a book on confectionery, then took a seat at the end of the same reading room. Evelina and Leticia exchanged astonished glances. It definitely was one of those days."
          ],
          [
            1,
            'Timestr [16:47]: 4:47',
            'But maybe it was more than that, maybe Affenlight had erred badly somehow, because here it was <<4:49|2>> by his watch, <<4:47|2>> by the wall clock, and Owen had not yet come.'
          ],
          [
            1,
            'Timestr [04:48]: 4:48 a.m.',
            'Thinking about the card warms me to the idea of walking under the arched doorway of the Newtons\' home, but when I arrive at their house, the plan seems ridiculous. What am I doing? It\'s <<4:48 a.m.|2a>>, and I\'m parked outside their darkened house.'
          ],
          [
            1,
            'Timestr [16:49]: 4:49 p.m.',
            '<<4:49 p.m.|2a>>, a bald-headed man wearing khakis and ankle-high deck shoes came out through the front door of the purple house on 21st Avenue East. The detectives had nicknamed him the General.'
          ],
          [
            1,
            'Timestr [16:50]: 4.50',
            '"The train standing at Platform 3," the Voice told her, "is the <<4.50|5a:1>> for Brackhampton, Milchester, Waverton, Carvil Junction, Roxeter and stations to Chadmouth. Passengers for Brackhampton and Milchester travel at the rear of the train. Passengers for Vanequay change at Roxeter." The voice shut itself off with a click,'
          ],
          [
            1,
            'Timestr [16:50]: ten minutes to five',
            'They had all frozen at the same time, on a snowy night, seven years before, and after that it was always <<ten minutes to five|10>> in the castle.'
          ],
          [
            1,
            'Timestr [16:50]: ten minutes to five',
            'When the clock said <<ten minutes to five|10>>, she began to listen, and a few moments later, punctually as always, she heard the tires on the gravel outside, and the car door slamming, the footsteps passing the window, the key turning in the lock. She laid aside her sewing, stood up, and went forward to kiss him as he came in.'
          ],
          [
            1,
            'Timestr [16:51]: nine minutes to five',
            '<<Nine minutes to five|10>>. If this wasn\'t some new ordeal, intended to fray her nerves to shreds, if this important person really did exist, if he\'d actually set up this appointment, and if, moreover, he arrived on time, then there were nine minutes left.'
          ],
          [
            1,
            'Timestr [16:52]: eight minutes to five',
            'The corrida was to begin at <<five o\'clock|6>>. The five-footed beasts make a point of arriving at the latest at eight or seven minutes to: ritual again. At <<eight minutes to five|10>>, there they were. The urchins gave them a tap on the shoulder: another bit of ritual.'
          ],
          [
            1,
            'Timestr [16:53]: seven minutes before five',
            'It was so quiet in the post office that Trinidad could hear the soft tick of the clock\'s second hand every time it moved. It was now <<seven minutes before five|10>>.'
          ],
          [
            1,
            'Timestr [16:54]: six minutes before five o\'clock',
            'At <<six minutes before five o\'clock|10>>, Daisy Robinson, about to reach her own apartment door, paused to look and to listen. Something was out of order. Tess Rogan\'s door was standing wide open and, from within, Daisy could hear something being broken.'
          ],
          [
            1,
            'Timestr [16:54]: 1654',
            'It was <<1654|9d>> local time when the Red October broke the surface of the Atlantic Ocean for the first time, forty-seven miles southeast of Norfolk. There was no other ship in sight.'
          ],
          [
            1,
            'Timestr [16:55]: About five minutes to five',
            '<<About five minutes to five|10>>, just as they were all putting their things away for the night, Nimrod suddenly appeared in the house. He had come hoping to find some of them ready dressed to go home before the proper time.'
          ],
          [
            1,
            'Timestr [16:56]: 4:56 P.M.',
            'And when that final Friday came, when my packing was mostly done, she sat with my dad and me on the living-room couch at <<4:56 P.M.|2a>> and patiently awaited the arrival of the Good-bye to Miles Cavalry.'
          ],
          [
            1,
            'Timestr [16:57]: nearly five in the evening',
            'It was <<nearly five in the evening|9h>> when the cook came aboard. He did not have the cabbages.'
          ],
          [
            1,
            'Timestr [16:57]: three minutes to five',
            "Then at <<three minutes to five|10>> \x{2014} Pendel had somehow never doubted that Osnard would be punctual \x{2014} along comes a brown Ford hatchback with an Avis sticker on the back window and pulls into the space reserved for customers."
          ],
          [
            1,
            'Timestr [16:58]: A minute and twenty-one seconds to five',
            'I was told that in his vest pocket he kept a chronometer instead of a watch. If someone asked him what time it was, he would say, "<<A minute and twenty-one seconds to five|10>>."'
          ],
          [
            1,
            'Timestr [16:59]: around 5 p.m.',
            'The rain stopped <<around 5 p.m.|5>> and a few of those people who were out and about expressed mild surprise when the rainbow failed to fade.'
          ],
          [
            1,
            'Timestr [17:00]: 5.00 p.m.',
            '<<5.00 p.m.|2a>> Read a book'
          ],
          [
            1,
            'Timestr [17:00]: About five',
            '<<About five|9e>>, the Abbot, a young Manchester terrier, began chirruping. He stood on the body of his owner, Flora, with his forepaws on the sill of the balcony, stared through the green rattan blinds, and trembled. He could see the farmer in the field, and Edward asleep on the next balcony.'
          ],
          [
            1,
            'Timestr [17:00]: five o\'clock that afternoon',
            'At <<five o\'clock that afternoon|6>>, while Barbara waited in a taxi, Harold went into the convent in Auteuil and explained to the nun who sat in the concierge\'s glass cage that Mme. Straus-Muguet was expecting them. He assumed that men were not permitted any further, and that they would all three go out for tea.'
          ],
          [
            1,
            "Timestr [17:00]: five o\x{2019}clock",
            "At <<five o\x{2019}clock|6>> adieux were waved, and the ponderous liner edged away from the long pier, slowly turned its nose seaward, discarded its tug, and headed for the widening water spaces that led to old world wonders. By night the outer harbour was cleared, and late passengers watched the stars twinkling above an unpolluted ocean."
          ],
          [
            1,
            'Timestr [17:00]: five o\'clock in the afternoon',
            'But I took the mixture at <<five o\'clock in the afternoon|6>>. I run my tongue over my dry mouth. I feel dizzy. I know this dizziness: it\'s because I haven\'t had a cigarette for hours.'
          ],
          [
            1,
            'Timestr [17:00]: five o\'clock',
            'ERE THE HALF-HOUR ended, <<five o\'clock|6>> struck; school was dismissed, and all were gone into the refectory to tea. I now ventured to descend; it was deep dusk; I retired into a corner and sat down on the floor.'
          ],
          [
            1,
            'Timestr [17:00]: five o\'clock',
            'From <<five o\'clock|6>> to eight is on certain occasions a little eternity; but on such an occasion as this the interval could be only an eternity of pleasure.'
          ],
          [
            1,
            'Timestr [17:00]: five o\'clock',
            'He found it harder to concentrate on drills that afternoon and when he left the building at <<five o\'clock|6>>, he was still so worried that he walked straight into someone just outside the door.'
          ],
          [
            1,
            'Timestr [17:00]: five o\'clock',
            'She had not seen her yet, as Osmond had given her to understand that it was too soon to begin. She drove at <<five o\'clock|6>> to a high floor in a narrow street in the quarter of the Piazza Navona, and was admitted by the portress of the convent, a genial and obsequious person. Isabel had been at this institution before; she had come with Pansy to see the sisters.'
          ],
          [
            1,
            'Timestr [17:00]: five o\'clock',
            'Until <<five o\'clock|6>> there was no sign of life from the room. Then he rang for his servant and ordered a cold bath.'
          ],
          [
            1,
            'Timestr [17:00]: about five o\'clock',
            'We motored, I remember, leaving London in the morning in a heavy shower of rain, coming to Manderley <<about five o\'clock|6>>, in time for tea. I can see myself now, unsuitably dressed as usual, although a bride of seven weeks, in a tan-coloured stockinette frock, a small fur known as a stone marten round my neck, and over all a shapeless mackintosh, far too big for me and dragging to my ankles.'
          ],
          [
            1,
            'Timestr [17:01]: One minute after five',
            '<<One minute after five|10>>. The seated guests were told that the ceremony would begin shortly. A little more patience was required.'
          ],
          [
            1,
            'Timestr [17:02]: two minutes past five',
            'She stood up, shook her hair into place, smoothed her skirt and turned on the light. It was <<two minutes past five|10>>. She would have thought it <<midnight|13>> or <<five in the morning|5>>.'
          ],
          [
            1,
            'Timestr [17:03]: 5:03',
            '"Good evening, Mrs. Scheindlin," the man said before departing. "Good evening, Chris. Say hello to the wife for me." "I sure will. Thanks. Bye," he said, waving to Elliot, who returned the goodbye. It was <<5:03|2>> when Elliot rested the handset in its cradle.'
          ],
          [
            1,
            'Timestr [17:04]: 5:04 P.M.',
            'Frank Wamsley spotted his cousin Barbara and her husband and waved to them. Just ahead, he saw Marvin and his two friends. Suddenly the whole bridge convulsed. The time was <<5:04 P.M.|2a>> Steel screamed.'
          ],
          [
            1,
            'Timestr [17:05]: approximately 5:05 p.m.',
            'At <<approximately 5:05 p.m.|2a>> Joe became aware of a man standing close to the table, <<about two|9:0>> metres away, talking in Mandarin into a mobile phone. He was a middle-aged Han wearing cheap leather slip-on shoes, high-waisted black trousers and a white short-sleeved shirt.'
          ],
          [
            1,
            'Timestr [17:06]: around 5 p.m.',
            'The rain stopped <<around 5 p.m.|5>> and a few of those people who were out and about expressed mild surprise when the rainbow failed to fade.'
          ],
          [
            1,
            'Timestr [17:10]: five ten P.M.',
            '<<Five ten P.M.|5>> A ground-to-ground cruise missile, launched from a tractor installed in the backyard of Leonard Sudavico\'s former home by Rashan and a crew of technicians from Afghanistan, exploded onto the Paul Clay estate in the exact spot where the life-size mermaid had once swum in the waterfall.'
          ],
          [
            1,
            'Timestr [17:10]: ten minutes past five',
            'Hours later, at <<ten minutes past five|10>>, Saturday afternoon, Nora and Travis and Jim Keene crowded in front of the mattress on which Einstein lay. The dog had just taken a few more ounces of water. He looked at them with interest, too. Travis tried to decide if those large brown eyes still had the strange depth, uncanny alertness, and undoglike awareness that he had seen in them so many times before.'
          ],
          [
            1,
            'Timestr [17:12]: twelve minutes past five',
            '"Well, here we are," said Colonel Julyan, "and it\'s exactly <<twelve minutes past five|10>>. We shall catch them in the middle of their tea. Better wait for a bit" Maxim lit a cigarette, and then stretched out his hand to me. He did not speak.'
          ],
          [
            1,
            'Timestr [17:14]: fourteen minutes past five',
            '"Do you know what time it is, Atticus?" she said. "Exactly <<fourteen minutes past five|10>>. The alarm clock\'s set for <<five-thirty|5a:1>>. I want you to know that."'
          ],
          [
            1,
            'Timestr [17:15]: 17:15 hrs',
            'When August Bach emerged from the gloomy chill of the air-conditioned Divisional Fighter Control bunker it was <<17:15 hrs|1>> CET. The day had ripened into one of those mellow summer afternoons when the air is warm and sweet like soft toffee'
          ],
          [
            1,
            'Timestr [17:18]: eighteen minutes past five',
            'Lupin rose, without breaking his contemptuous silence, and took the sheet of paper. I remembered soon after that, at this moment, I happened to look at the clock. It was <<eighteen minutes past five|10>>.'
          ],
          [
            1,
            'Timestr [17:19]: 5.19 p.m.',
            'The call came at <<5.19 p.m.|2a>> The line was surprisingly clear. A man introduced himself as Major Liepa from the Riga police. Wallander made notes as he listened, occasionally answering a question.'
          ],
          [
            1,
            'Timestr [17:20]: around 1720',
            'The Meeting was listed as starting at <<1730|9g>>, and it was only <<around 1720|9c:0>>, and Hal thought the voices might signify some sort of pre-Meeting orientation for people who\'ve come for the first time, sort of tentatively, just to scout the whole enterprise out, so he doesn\'t knock.'
          ],
          [
            1,
            'Timestr [17:21]: around 1720',
            'The Meeting was listed as starting at <<1730|9g>>, and it was only <<around 1720|9c:0>>, and Hal thought the voices might signify some sort of pre-Meeting orientation for people who\'ve come for the first time, sort of tentatively, just to scout the whole enterprise out, so he doesn\'t knock.'
          ],
          [
            1,
            'Timestr [17:23]: five twenty-three',
            '"I was wondering if we could meet for a drink." "What for?" "Just for a chat. Do you know the Royal batsman, near Central Station? We could meet tomorrow at <<five|9g>>?" "<<Five twenty-three|9j>>," I said, to exert some control over the situation.'
          ],
          [
            1,
            'Timestr [17:25]: five-twenty-five',
            'It was <<five-twenty-five|3b>> when I pulled up in front of the library. Still early for our date, so I got out of the car and took a stroll down the misty streets. In a coffee shop, watched a golf match on television, then I went to an entertainment center and played a video game. The object of the game was to wipe out tanks invading from across the river. I was winning at first, but as the game went on, the enemy tanks bred like lemmings, crushing me by sheer number and destroying my base. An on-screen nuclear blast took care of everything, followed by the message game over insert coin.'
          ],
          [
            1,
            'Timestr [17:25]: twenty-five minutes past five',
            'Now said Handsley, when Angela had poured out the last cup, "it\'s <<twenty-five minutes past five|10>>, At half-past the Murder game is on"'
          ],
          [
            1,
            'Timestr [17:30]: half-past five',
            "He went up to his coachman, who was dozing on the box in the shadow, already lengthening, of a thick lime-tree; he admired the shifting clouds of midges circling over the hot horses, and, waking the coachman, he jumped into the carriage, and told him to drive to Bryansky\x{2019}s. It was only after driving nearly five miles that he had sufficiently recovered himself to look at his watch, and realise that it was <<half-past five|10>>, and he was late."
          ],
          [
            1,
            'Timestr [17:30]: half-past five',
            'It was <<half-past five|10>> before Holmes returned. He was bright, eager, and in excellent spirits, a mood which in his case alternated with fits of the blackest depression.'
          ],
          [
            1,
            'Timestr [17:33]: 5:33 p.m.',
            'At <<5:33 p.m.|2a>> there is a blast of two deep, resonant notes a major third apart. On another day there is the same blast at <<12:54 p.m.|2a>> On another, exactly <<8:00 a.m.|2a>>'
          ],
          [
            1,
            'Timestr [17:37]: 5:37',
            'Look, Lucille, said Joe when Lucille strolled into the office at <<5:37|2>>. "I don\'t know what you said to this gal, but it seems to have had exactly the opposite of the desired effect. She\'s got some bee in her bonnet about Harvard Law School."'
          ],
          [
            1,
            'Timestr [17:40]: 5:40',
            'Hey, young man, what time is it? \'What?\' I said, is it <<5:30|2>> yet? \'Er, <<5:40|2>>.\' Heavens, they\'ll be starving. But then that\'s a good thing. Let them.\''
          ],
          [
            1,
            'Timestr [17:40]: five-forty',
            'It\'s <<five-forty|9j>> now. The party\'s at <<six|9c:0>>. By about ten past, the eleventh floor should be clearing. Arnold is a very popular partner; no one\'s going to miss his farewell speech if they can help it. Plus, at Carter Spink parties, the speeches always happen early on, so people can get back to work if they need to. And while everyone\'s listening I\'ll slip down to Arnold\'s office. It should work. It has to work. As I stare at my own bizarre reflection, I feel a grim resolve hardening inside me. He\'s not going to get away with everyone thinking he\'s a cheery, harmless old teddy bear. He\'s not going to get away with it.'
          ],
          [
            1,
            'Timestr [17:42]: around 5.45',
            'Janice is not waiting for him in the lounge or beside the pool when at last <<around 5.45|3:0>> they come home from playing the par-5 eighteenth. Instead one of the girls in their green and white uniforms comes over and tells him that his wife wants him to call home.'
          ],
          [
            1,
            'Timestr [17:45]: around 5.45',
            'Janice is not waiting for him in the lounge or beside the pool when at last <<around 5.45|3:0>> they come home from playing the par-5 eighteenth. Instead one of the girls in their green and white uniforms comes over and tells him that his wife wants him to call home.'
          ],
          [
            1,
            'Timestr [17:46]: fourteen minutes to six',
            'Through the curtained windows of the furnished apartment which Mrs. Horace Hignett had rented for her stay in New York rays of golden sunlight peeped in like the foremost spies of some advancing army. It was a fine summer morning. The hands of the Dutch clock in the hall pointed to <<thirteen minutes past nine|10>>; those of the ormolu clock in the sitting-room to <<eleven minutes past ten|10>>; those of the carriage clock on the bookshelf to <<fourteen minutes to six|10>>. In other words, it was exactly <<eight|9f>>; and Mrs. Hignett acknowledged the fact by moving her head on the pillow, opening her eyes, and sitting up in bed. She always woke at <<eight|9b>> precisely.'
          ],
          [
            1,
            'Timestr [17:48]: 5:48 p.m.',
            'Father came home at <<5:48 p.m.|2a>> I heard him come through the front door. Then he came into the living room. He was wearing a lime green and sky blue check shirt and there was a double knot on one of his shoes but not on the other.'
          ],
          [
            1,
            'Timestr [17:50]: ten to six',
            '"What time is it Jack?" "<<Ten to six|10a:1>>""Ten more minutes then." I shuffle the cards. "Time for a quick game of rummy?"'
          ],
          [
            1,
            'Timestr [17:53]: seven minutes to six',
            '"That boy will be spoiled, as sure as I go on springs; he\'s made such a lot of. Have you been regulated?" "I should think I have!" exclaimed I, in indignant recollection of my education. "All right; keep your temper. What time are you?" "<<Seven minutes to six|10>>."'
          ],
          [
            1,
            'Timestr [17:54]: 5:54 pm',
            'It was <<5:54 pm|2a>> when Father came back into the living room. He said, \'What is this?" but he said it very quietly and I didn\'t realise that he was angry because he wasn\'t shouting.'
          ],
          [
            1,
            'Timestr [17:55]: five minutes to six',
            'The wind moaned and sang dismally, catching the ears and lifting the shabby coat-tails of Mr Mortimer Jenkyn, \'Photographic Artist\', as he stood outside and put the shutters up with this own cold hands in despair of further trade. It was <<five minutes to six|10>>.'
          ],
          [
            1,
            'Timestr [17:57]: nearly six o\'clock',
            'When he arrived it was <<nearly six o\'clock|6>>, and the sun was setting full and warm, and the red light streamed in through the window and gave more colour to the pale cheeks.'
          ],
          [
            1,
            'Timestr [17:58]: nearly six o\'clock in the evening',
            'It was <<nearly six o\'clock in the evening|6>>, and the absurd bell in the six-foot tin steeple of the church went clank-clank, clank- clank! as old Mattu pulled the rope within.\''
          ],
          [
            1,
            'Timestr [17:59]: nearly six o\'clock',
            'When he arrived it was <<nearly six o\'clock|6>>, and the sun was setting full and warm, and the red light streamed in through the window and gave more colour to the pale cheeks.'
          ],
          [
            1,
            'Timestr [18:00]: 6.00 p.m.',
            '<<6.00 p.m.|2a>> Have tea'
          ],
          [
            1,
            'Timestr [18:00]: six o\'clock',
            'Although it was only <<six o\'clock|6>>, the night was already dark. The fog, made thicker by its proximity to the Seine, blurred every detail with its ragged veils, punctured at various distances by the reddish glow of lanterns and bars of light escaping from illuminated windows.'
          ],
          [
            1,
            'Timestr [18:00]: six o\'clock',
            'Did you go down to the farm while I was away?\' \'No,\' I said \'but I saw Ted.\' \'Did he have a message for me ?\' she asked. \'He said today was no good as he was going to Norwich. But Friday at <<six o\'clock|6>>, same as usual.\' \'Are you sure he said <<six o\'clock|6>>?\' she asked, puzzled. \'Quite sure.\''
          ],
          [
            1,
            'Timestr [18:00]: six o\'clock',
            'King Richard: What is o\'clock? Catesby: It is <<six o\'clock|6>>, full supper time. King Richard: I will not sup tonight. Give me some ink and paper.'
          ],
          [
            1,
            'Timestr [18:00]: six o\'clock',
            'Leon waited all day for <<six o\'clock|6>> to arrive; when he got to the inn, he found no one there but Monsieur Binet, already at the table.'
          ],
          [
            1,
            'Timestr [18:00]: six o\'clock',
            'Oh oh oh. <<Six o\'clock|6>> and the master not home yet.'
          ],
          [
            1,
            'Timestr [18:00]: six o\'clock',
            'The newspaper snaked through the door and there was suddenly a <<six o\'clock|6>> feeling in the house'
          ],
          [
            1,
            'Timestr [18:00]: six o\'clock',
            'The winter evening settles down With smell of steaks in passageways. <<Six o\'clock|6>>.'
          ],
          [
            1,
            'Timestr [18:00]: six',
            'When the bells of Calvary Church struck <<six|11>>, she saw Mr and Mrs Biggs hurrying down the front stoop, rushing off to the shops before they closed.'
          ],
          [
            1,
            'Timestr [18:03]: three minutes past six',
            'Above it all rose the Houses of Parliament, with the hands of the clock stopped at <<three minutes past six|10>>. It was difficult to believe that all that meant nothing any more, that now it was just a pretentious confection that could decay in peace.'
          ],
          [
            1,
            'Timestr [18:04]: Four minutes after six, in the evening',
            "\"We will make record of it, my Rosannah; every year, as this dear hour chimes from the clock, we will celebrate it with thanksgivings, all the years of our life.\" \"We will, we will, Alonzo!\" \"<<Four minutes after six, in the evening|10>>, my Rosannah...\x{201d}"
          ],
          [
            1,
            'Timestr [18:05]: about five past six',
            'At <<about five past six|10>> Piers came in carrying an evening paper and a few books.'
          ],
          [
            1,
            'Timestr [18:08]: 6:08 p.m.',
            '<<6:08 p.m.|2a>> The code-word "Valkyrie" reached von Seydlitz Gabler\'s headquarters'
          ],
          [
            1,
            'Timestr [18:10]: six ten',
            '\'Let me see now. You had a drink at the Continental at <<six ten|5b>>.\' \'Yes.\' \'And at <<six forty-five|5b>> you were talking to another journalist at the door of the Majestic?\' \'Yes, Wilkins. I told you all this, Vigot, before. That night.\''
          ],
          [
            1,
            'Timestr [18:15]: quarter past six',
            '\'<<Quarter past six|10>>,\' said Tony. \'He\'s bound to have told her by now.\''
          ],
          [
            1,
            'Timestr [18:15]: quarter past six',
            'At a <<quarter past six|10>> he was through with them.'
          ],
          [
            1,
            'Timestr [18:15]: 6.15 pm',
            'I checked the time on the corner of my screen. <<6.15 pm|2a>>. I was never going to finisah my essay in forty-five minutes'
          ],
          [
            1,
            'Timestr [18:20]: twenty past six',
            'By the time Elliot\'s mother arrived at <<twenty past six|10>>, Mrs Sen always made sure all evidence of her chopping was disposed of.'
          ],
          [
            1,
            'Timestr [18:21]: 6.21pm',
            '<<5.20pm|2a>> - <<6.21pm|2a>>: Miss Pettigrew found herself wafted into the passage. She was past remonstrance now, past bewilderment, surprise, expostulation. Her eyes shone. Her face glowed. Her spirits soared. Everything was happening too quickly. She couldn\'t keep up with things, but, by golly, she could enjoy them.'
          ],
          [
            1,
            'Timestr [18:22]: twenty-two minutes past six',
            'Clock overturned when he fell forward. That\'ll give us the time of the crime. <<Twenty-two minutes past six|10>>.'
          ],
          [
            1,
            'Timestr [18:25]: twenty-five past six',
            'At <<twenty-five past six|10>> I go into the bathroom and have a wash, then while the Old Lady\'s busy in the kitchen helping Chris with the washing up I get my coat and nip out down the stairs.'
          ],
          [
            1,
            'Timestr [18:25]: 6.25',
            'I have this moment, while writing, had a wire from Jonathan saying that he leaves by the <<6.25|3b>> tonight from Launceston and will be here at <<10.18|3c>>, so that I shall have no fear tonight.'
          ],
          [
            1,
            'Timestr [18:26]: around half past six in the evening',
            'It is <<around half past six in the evening|10>>. Dusk is gathering in the living room, an early dusk due to the fog which has rolled in from the Sound and is like a white curtain drawn down outside the windows.'
          ],
          [
            1,
            'Timestr [18:30]: six-thirty',
            'At <<six-thirty|9m>> I left the bar and walked outside. It was getting dark and the big Avenida looked cool and graceful. On the other side were homes that once looked out on the beach. Now they looked out on hotels and most of them had retreated behind tall hedges and walls that cut them off from the street.'
          ],
          [
            1,
            'Timestr [18:30]: 6.30 p.m.',
            '<<6.30 p.m.|2a>> Watch television or a video'
          ],
          [
            1,
            'Timestr [18:30]: half-past six',
            'As I was turning away, grieved to be parting from him, a thought started up in me and I turned back. \'Shall I take one more message for you?\' \'That\'s good of you\' he said, \'but do you want to?\' \'Yes, just this once.\' It could do no harm, I thought; and I should be far away when the message takes effect, and I wanted to say something to show we were friends. \'Well,\' he said, once more across the gap, \'say tomorrow\'s no good, I\'m going to Norwich, but Friday at <<half-past six|10>>, same as usual.\''
          ],
          [
            1,
            'Timestr [18:30]: half past six',
            'At <<five o\'clock|6>> the two ladies retired to dress, and at <<half past six|10>> Elizabeth was summoned to dinner.'
          ],
          [
            1,
            'Timestr [18:30]: six thirty',
            'It is <<six thirty|9f>>. Now the dark night and the deafening racket of the crickets again engulf the garden and the veranda, all around the house'
          ],
          [
            1,
            'Timestr [18:30]: half-past six',
            'To a casual visitor it might have seemed that Mr Penicuik, who owned the house, had fallen upon evil days; but two of the three gentlemen assembled in the Saloon at <<half-past six|10>> on a wintry evening of late February were in no danger of falling into this error.'
          ],
          [
            1,
            'Timestr [18:31]: a little after half past six',
            'I had been delayed at a case and it was <<a little after half past six|10>> when I found myself at Baker Street once more'
          ],
          [
            1,
            'Timestr [18:32]: around half past six in the evening',
            'It is <<around half past six in the evening|10>>. Dusk is gathering in the living room, an early dusk due to the fog which has rolled in from the Sound and is like a white curtain drawn down outside the windows.'
          ],
          [
            1,
            'Timestr [18:33]: 6.33pm',
            "Every evening, Michel took the train home, changed at Esbly and usually arrived in Cr\x{e9}cy on the <<6.33pm|2a>> train where Annabelle would be waiting at the station."
          ],
          [
            1,
            'Timestr [18:34]: around half past six in the evening',
            'It is <<around half past six in the evening|10>>. Dusk is gathering in the living room, an early dusk due to the fog which has rolled in from the Sound and is like a white curtain drawn down outside the windows.'
          ],
          [
            1,
            'Timestr [18:35]: 6.35 pm',
            'And then it was <<6.35 pm|2a>> and I heard Father come home in his van and I moved the bed up against the door so he couldn\'t get in and he came into the house and he and Mother shouted at each other.'
          ],
          [
            1,
            'Timestr [18:36]: 6:36',
            'Kaldren pursues me like luminescent shadow. He has chalked up on the gateway \'96,688,365,498,702\'. Should confuse the mail man. Woke <<9:05|2>>. To sleep <<6:36|2>>.'
          ],
          [
            1,
            'Timestr [18:39]: Nearly twenty to seven',
            'Amy: What\'s that? I thought I saw someone pass the window. What time is it? Charles: <<Nearly twenty to seven|10>>.'
          ],
          [
            1,
            'Timestr [18:40]: twenty minutes to seven',
            "Having to change 'buses, I allowed plenty of time \x{2014} in fact, too much; for we arrived at <<twenty minutes to seven|10>>, and Franching, so the servant said, had only just gone up to dress."
          ],
          [
            1,
            'Timestr [18:41]: six forty-one',
            'He made it to Grand Central well in advance. Stillman\'s train was not due to arrive until <<six forty-one|9f>>, but Quinn wanted time to study the geography of the place, to make sure that Stillman would not be able to slip away from him.'
          ],
          [
            1,
            'Timestr [18:45]: six forty-five',
            '\'Let me see now. You had a drink at the Continental at <<six ten|5b>>.\' \'Yes.\' \'And at <<six forty-five|5b>> you were talking to another journalist at the door of the Majestic?\' \'Yes, Wilkins. I told you all this, Vigot, before. That night.\''
          ],
          [
            1,
            'Timestr [18:45]: six forty-five',
            '"<<Six forty-five|9j>>," called Louie. "Did you hear, Ming," he asked, "did you hear?" "Yes, Taddy, I heard." "What is it?\' asked Tommy. "The new baby, listen, the new baby."'
          ],
          [
            1,
            'Timestr [18:45]: quarter to seven',
            'It was a <<quarter to seven|10>> when I let myself into the office and clicked the light on and picked a piece of paper off the floor. It was a notice from the Green Feather Messenger Service ...'
          ],
          [
            1,
            'Timestr [18:49]: 6:49 p.m.',
            '<<6:49 p.m.|2a>> Lieutenant-General Tanz escorted by a motorized unit, drove to Corps headquarters'
          ],
          [
            1,
            'Timestr [18:50]: ten minutes to seven',
            'At <<ten minutes to seven|10>> Dulcie was ready. She looked at herself in the wrinkly mirror. The reflection was satisfactory. The dark blue dress, fitting without a wrinkle, the hat with its jaunty black feather, the but-slightly-soiled gloves--all representing self- denial, even of food itself--were vastly becoming. Dulcie forgot everything else for a moment except that she was beautiful, and that life was about to lift a corner of its mysterious veil for her to observe its wonders. No gentleman had ever asked her out before. Now she was going for a brief moment into the glitter and exalted show.'
          ],
          [
            1,
            'Timestr [18:50]: ten minutes before seven o\'clock',
            'It was time to go see the Lady. When we arrived at her house at <<ten minutes before seven o\'clock|10>>, Damaronde answered the door.'
          ],
          [
            1,
            'Timestr [18:50]: ten minutes before seven o\'clock',
            'It was time to go see the Lady. When we arrived at her house at <<ten minutes before seven o\'clock|10>>, Damaronde answered the door.'
          ],
          [
            1,
            'Timestr [18:51]: 6:51',
            'The square of light in the kitchen doorway had faded to thin purple; his watch said <<6:51|2>>.'
          ],
          [
            1,
            'Timestr [18:53]: near on seven o\'clock',
            'It was <<near on seven o\'clock|6>> when I got to Mr. and Mrs. Fleming\'s house on 6th Street, where I was renting a room. It was late September, and though there was some sun left, I didn\'t want to visit a dead man\'s place with night coming on.'
          ],
          [
            1,
            'Timestr [18:55]: five to seven',
            '... You had no reason to think the times important. Indeed how suspicious it would be if you had been completely accurate. \'\'Haven\'t I been?\'\' Not quite. It was <<five to seven|10>> that you talked to Wilkins. \'\'Another ten minutes."'
          ],
          [
            1,
            'Timestr [18:55]: 6:55',
            'The play was set to begin at <<seven o\'clock|6>> and finish before sunset. It was <<6:55|9f>>. Beyond the flats we could hear the hockey field filling up. the low rumble got steadily louder - voices, footsteps, the creaking of bleachers, the slamming of car doors in the parking lot.'
          ],
          [
            1,
            'Timestr [18:56]: 6.56',
            'Then it was <<6.56|9f>>. A black Rover - a Rover 90, registration PYX 520 - turned into the street that ran down the left-hand side of The Bunker. It parked. The door on the driver\'s side opened. A man got out.'
          ],
          [
            1,
            'Timestr [18:57]: a few minutes before seven',
            '"I feel a little awkward," Kay Randall said on the phone, "asking a man to do these errands ... but that\'s my problem, not yours. Just bring the supplies and try to be at the church meeting room <<a few minutes before seven|10>>."'
          ],
          [
            -1,
            'Timestr [18:57]: three minutes to the hour; which was seven',
            "Folded in this triple melody, the audience sat gazing; and beheld gently and approvingly without interrogation, for it seemed inevitable, a box tree in a green tub take the place of the ladies\x{2019} dressing-room; while on what seemed to be a wall, was hung a great clock face; the hands pointing to <<three minutes to the hour; which was seven|99>>.'"
          ],
          [
            1,
            'Timestr [18:58]: two minutes to seven',
            "\"Walk fast,\" says Perry, \"it's <<two minutes to seven|10>>, and I got to be home by\x{2014}' \"Oh, shut up,\" says I. \"I had an appointment as chief performer at an inquest at <<seven|9c:0>>, and I'm not kicking about not keeping it.\""
          ],
          [
            1,
            "Timestr [18:59]: About seven o\x{2019}clock in the evening",
            "<<About seven o\x{2019}clock in the evening|6>> she had died, and her frantic husband had made a frightful scene in his efforts to kill West, whom he wildly blamed for not saving her life. Friends had held him when he drew a stiletto, but West departed amidst his inhuman shrieks, curses, and oaths of vengeance."
          ],
          [
            1,
            'Timestr [19:00]: seven o\'clock at night',
            "\x{2026} in a word, seen always at the same evening hour, isolated from all its possible surroundings, detached and solitary against its shadowy background, the bare minimum of scenery necessary .. to the drama of my undressing, as though all Combray had consisted of but two floors joined by a slender staircase, and as though there had been no time there but <<seven o'clock at night|6>>."
          ],
          [
            1,
            'Timestr [19:00]: seven',
            'The town clock struck <<seven|11>>. The echoes of the great chime wandered in the unlit halls of the library. An autumn leaf, very crisp, fell somewhere in the dark. But it was only the page of a book, turning.'
          ],
          [
            1,
            'Timestr [19:00]: 7.00 p.m.',
            '<<7.00 p.m.|2a>> Do maths practice'
          ],
          [
            1,
            'Timestr [19:00]: seven o\'clock',
            'By <<seven o\'clock|6>> the orchestra has arrived--no thin five-piece affair but a whole pitful of oboes and trombones and saxophones and viols and cornets and piccolos and low and high drums.'
          ],
          [
            1,
            'Timestr [19:00]: seven',
            'Edward had been allowed to see me only from <<seven|9c:0>> till <<nine-thirty pm|5>>, always inside the confines of my home and under the supervision of my dad\'s unfailingly crabby glare.'
          ],
          [
            1,
            'Timestr [19:00]: seven o\'clock',
            'It was <<seven o\'clock|6>> and by this time she was not very far from Raveloe, but she was not familiar enough with those monotonous lanes to know how near she was to her journey\'s end. She needed comfort, and she knew but one comforter - the familiar demon in her bosom; but she hesitated a moment, after drawing out the black remnant, before she raised it to her lips.'
          ],
          [
            1,
            'Timestr [19:00]: seven o\'clock',
            "It was <<seven o'clock|6>> when we got into the coup\x{e9} with him and started for Long Island. [...] So we drove on toward death through the cooling twilight."
          ],
          [
            1,
            'Timestr [19:01]: around seven',
            'He waited until <<nearly eight|9f>>, because <<around seven|9:0>> there were always more people coming in and out of the house than at other times.'
          ],
          [
            1,
            'Timestr [19:02]: about seven o\'clock at night',
            'Twas <<about seven o\'clock at night|6>>, And the wind it blew with all its might, And the rain came pouring down, And the dark clouds seem\'d to frown,'
          ],
          [
            1,
            'Timestr [19:08]: eight minutes past seven',
            'It was <<eight minutes past seven|10>> and still no girl. I waited impatiently. I watched another crowd surge through the barriers and move quickly down the steps. My eyes were alert for the faintest recognition.'
          ],
          [
            -1,
            'Timestr [19:10]: in five minutes it would be a quarter past seven',
            "He had already got to the point where, by rocking more strongly, he maintained his equilibrium with difficulty, and very soon he would finally have to make a final decision, for <<in five minutes it would be a quarter past seven|99>>. Then there was a ring at the door of the apartment. \x{201c}That\x{2019}s someone from the office,\x{201d} he told himself, and he almost froze, while his small limbs only danced around all the faster. For one moment everything remained still. \x{201c}They aren\x{2019}t opening,\x{201d} Gregor said to himself, caught up in some absurd hope."
          ],
          [
            1,
            'Timestr [19:10]: seven-ten',
            'The party was to begin at <<seven|9f>>. The invitations gave the hour as <<six-thirty|5a:1>> because the family knew everyone would come a little late, so as not to be the first to arrive. At <<seven-ten|9m>> not a soul had come; somewhat acrimoniously, the family discussed the advantages and disadvantages of tardiness'
          ],
          [
            1,
            'Timestr [19:11]: 19:11',
            'Good, you said. Run, or you won\'t get a seat. See you soon. Your voice was reassuring. <<19:11|2>>:00, the clock said. I put the phone back on its hook and I ran. The seat I got, almost the last one in the carriage, was opposite a girl who started coughing as soon as there weren\'t any other free seats I could move to. She looked pale and the cough rattled deep in her chest as she punched numbers into her mobile. Hi, she said (cough). I\'m on the train. No, I\'ve got a cold. A cold (cough). Yeah, really bad. Yeah, awful actually. Hello? (cough) Hello?'
          ],
          [
            1,
            'Timestr [19:12]: 7:12',
            'He taught me that if I had to meet someone for an appointment, I must refuse to follow the \'stupid human habit\' of arbitrarily choosing a time based on fifteen-minute intervals. "Never meet people at <<7:45|2>> or <<6:30|2>>, Jasper, but pick times like <<7:12|2>> and <<8:03|2>>!"'
          ],
          [
            1,
            'Timestr [19:14]: 7:14',
            'If he\'d lived in New York and worked in an office, he might have thrived as the typical, over-martini\'d, cheating husband, leaving every night on the <<7:14|2>> to White Plains, a smudge of lipstick high on his neck, and a tide of lies to see him through to the next day.'
          ],
          [
            1,
            'Timestr [19:15]: 7:15',
            'Cell count down to 400,000. Woke <<8:10|2>>. To sleep <<7:15|2>>. (Appear to have lost my watch without realising it, had to drive into town to buy another.)'
          ],
          [
            1,
            'Timestr [19:15]: seven fifteen',
            'Nick had a large wild plan of his own for the night, but for now he let Leo take charge: they were going to go back to Notting Hill and catch the <<seven fifteen|5a:0>> screening of Scarface at the Gate.'
          ],
          [
            1,
            'Timestr [19:15]: seven-fifteen',
            'The party was to begin at <<seven|9f>>. The invitations gave the hour as <<six-thirty|5a:1>> because the famly knew everyone would come a little late, so as not to be the first to arrive. .. By <<seven-fifteen|5b>> not another soul could squeeze into the house.'
          ],
          [
            1,
            'Timestr [19:16]: sixteen past seven PM',
            "\x{201c}<<Sixteen past seven PM|10>>? That's when he came into the store or when he left after the fact?\x{201d}"
          ],
          [
            1,
            'Timestr [19:17]: 7.17 p.m.',
            'Colonel Putnis knocked on his door at <<7.17 p.m.|2a>> The car was waiting in front of the hotel, and they drove through the dark streets to police headquarters. It had grown much colder during the evening, and the city was almost deserted.'
          ],
          [
            1,
            'Timestr [19:19]: seven-nineteen',
            'And it was me who spent about three hours this afternoon arguing one single contract. The term was best endeavors. The other side wanted to use reasonable efforts. In the end we won the point- but I can\'t feel my usual triumph. All I know is, it\'s <<seven-nineteen|9f>>, and in eleven minutes I\'m supposed to be halfway across town, sitting down to dinner at Maxim\'s with my mother and brother Daniel. I\'ll have to cancel. My own birthday dinner.'
          ],
          [
            1,
            'Timestr [19:20]: seven-twenty',
            'The clock read <<seven-twenty|11>>, but I felt no hunger. You\'d think I might have wanted to eat something after the day I\'d had, but I cringed at the very thought of food. I was short of sleep, my gut was slashed, and my apartment was gutted. There was no room for appetite.'
          ],
          [
            1,
            'Timestr [19:20]: 7:20',
            'The pause, we finally concluded, was to allow the other important people to catch up, those who had arrived at <<7:10|2>> waiting for those who had arrived at <<7:20|2>>.'
          ],
          [
            1,
            'Timestr [19:21]: 7:21',
            'Gripping her gym bag in her right hand, Aomame, like Buzzcut, was waiting for something to happen. The clock display changed to <<7:21|2>>, then <<7:22|2>>, then <<7:23|2>>.'
          ],
          [
            1,
            'Timestr [19:22]: 7:22',
            'Gripping her gym bag in her right hand, Aomame, like Buzzcut, was waiting for something to happen. The clock display changed to <<7:21|2>>, then <<7:22|2>>, then <<7:23|2>>.'
          ],
          [
            1,
            'Timestr [19:23]: 7:23',
            'Gripping her gym bag in her right hand, Aomame, like Buzzcut, was waiting for something to happen. The clock display changed to <<7:21|2>>, then <<7:22|2>>, then <<7:23|2>>.'
          ],
          [
            1,
            'Timestr [19:24]: almost twenty-five after seven',
            'He picked up his hat and coat and Clarice said hello to him and he said hello and looked at the clock and it was <<almost twenty-five after seven|10>>.'
          ],
          [
            1,
            'Timestr [19:25]: almost twenty-five after seven',
            'He picked up his hat and coat and Clarice said hello to him and he said hello and looked at the clock and it was <<almost twenty-five after seven|10>>.'
          ],
          [
            1,
            'Timestr [19:30]: half-past seven',
            "But now he was close - here was the house, here were the gates. Somewhere a clock beat a single chime. 'What, is it really <<half-past seven|10>>? That's impossible, it must be fast!\x{2019}"
          ],
          [
            1,
            'Timestr [19:30]: 7:30 that same evening',
            'On July 25th, <<8:30 a.m.|2a>> the bitch Novaya dies whelping. At <<10 o\'clock|6>> she is lowered into her cool grave, at <<7:30 that same evening|2a>> we see our first floes and greet them wishing they were the last.'
          ],
          [
            1,
            'Timestr [19:30]: half-past seven',
            'The clock showed <<half-past seven|10>>. This was the twilight time. He would be there now. I pictured him in his old navy-blue sweater and peaked cap, walking soft-footed up the track towards the wood. He told me he wore the sweater because navy-blue barely showed up in the dark, black was even better, he said. The peaked cap was important too, he explained, because the peak casts a shadow over one\'s face.'
          ],
          [
            1,
            'Timestr [19:30]: 7.30',
            'The telephone call came at <<7.30|3b>> on the evening of March 18th, a Saturday, the eve of the noisy, colourful festival that the town held in honour of Saint Joseph the carpenter -'
          ],
          [
            1,
            'Timestr [19:35]: 7.35',
            '<<7.35|9j>>-40. Yseut arrives at \'M. and S.\', puts through phone call.'
          ],
          [
            1,
            'Timestr [19:40]: 7.40',
            'She arrives at <<7.40|9f>>, ten minutes late, but the children, Jimmy and Bitsy, are still eating supper and their parents are not ready to go yet. From other rooms come the sound of a baby screaming, water running, a television musical (no words: probably a dance number - patterns of gliding figures come to mind).'
          ],
          [
            1,
            'Timestr [19:42]: seven forty-two',
            'I glance at my watch as we speed along the Strand. <<Seven forty-two|9j>>. I\'m starting to feel quite excited. The street outside is still bright and warm and tourists are walking along in T-shirts and shorts, pointing at the High Court. It must have been a gorgeous summer\'s day. Inside the air-conditioned Carter Spink building you have no idea what the weather in the real world is doing.'
          ],
          [
            1,
            'Timestr [19:45]: 7:45',
            'He taught me that if I had to meet someone for an appointment, I must refuse to follow the \'stupid human habit\' of arbitrarily choosing a time based on fifteen-minute intervals. "Never meet people at <<7:45|2>> or <<6:30|2>>, Jasper, but pick times like <<7:12|2>> and <<8:03|2>>!"'
          ],
          [
            1,
            'Timestr [19:45]: 19.45',
            'He tells his old friend the train times and they settle on the <<19.45|3c>> arriving at <<23.27|9c:1>>. \'I\'ll book us into the ultra-luxurious Francis Drake Lodge. Running water in several rooms. Have you got a mobile?"'
          ],
          [
            1,
            'Timestr [19:49]: eleven minutes to eight',
            'There\'s a big, old-fashioned clock in the surgery. Just as Dr. Wellesley went out I heard the Moot Hall clock chime <<half-past seven|10>>, and then the chimes of St. Hathelswide\'s Church. I noticed that our clock was a couple of minutes slow, and I put it right." When did you next see Dr. Wellesley?" "At just <<eleven minutes to eight|10>>." "Where?" "In the surgery." "He came back there?" "Yes." "How do you fix that precise time--<<eleven minutes to eight|10>>?" "Because he\'d arranged to see a patient in Meadow Gate at <<ten minutes to eight|10>>. I glanced at the clock as he came in, saw what time it was, and reminded him of the appointment."'
          ],
          [
            1,
            'Timestr [19:50]: ten to eight',
            'At <<ten to eight|10>>, he strolled downstairs, to make sure that Signora Buffi was not pottering around in the hall and that her door was not open, and to make sure there really was no one in Freddie\'s car'
          ],
          [
            1,
            'Timestr [19:52]: nearly eight',
            'He waited until <<nearly eight|9f>>, because <<around seven|9:0>> there were always more people coming in and out of the house than at other times. At <<ten to eight|10>>, he strolled downstairs, to make sure that Signora Buffi was not pottering around in the hall and that her door was not open, and to make sure there really was no one in Freddie\'s car, though he had gone down in the middle of the afternoon to look at the car and see if it was Freddie\'s.'
          ],
          [
            1,
            'Timestr [19:53]: 7.53 p.m.',
            'Wednesday, 11 th December 1963. <<7.53 p.m.|2a>> "Help me. You\'ve got to help me." The woman\'s voice quavered on the edge of tears. The duty constable who had picked up the phone heard a hiccuping gulp, as if the caller was struggling to speak.'
          ],
          [
            1,
            'Timestr [19:54]: six minutes to eight',
            'The body was found at <<six minutes to eight|10>>. Doctor Young arrived some thirty minutes later. Just let me get that clear - I\'ve a filthy memory.'
          ],
          [
            1,
            'Timestr [19:55]: five to eight',
            'Flora drew her coat round her, and looked up into the darkening vault of the sky. Then she glanced at her watch. It was <<five to eight|10>>.'
          ],
          [
            1,
            'Timestr [19:56]: four minutes to eight',
            'I remember the cigarette in his hard face, against the now limitless storm cloud. Bernardo cried to him unexpectedly: \'What time is it, Ireno?\' Without consulting the sky, without stopping, he replied: \'It\'s <<four minutes to eight|10>>, young Bernardo Juan Franciso.\' His voice was shrill, mocking.'
          ],
          [
            1,
            'Timestr [19:57]: three minutes till eight',
            'At <<three minutes till eight|10>>, Laszlo and His Yankee Hussars set up onstage. While the band played their Sousa medley, Carter thoroughly checked his kit, stuffing his pockets with scarves, examining the seals on decks of cards. He glanced toward his levitation device. "Good luck, Carter." The voice was quiet.'
          ],
          [
            1,
            'Timestr [19:58]: 7.58pm',
            'Robert Langdon stole an anxious glance at his wristwatch: <<7.58pm|2a>>. The smiling face of Mickey Mouse did little to cheer him up.'
          ],
          [
            1,
            'Timestr [19:59]: just before eight o\' clock',
            'Kuniang made her appearance in my study <<just before eight o\' clock|10>>, arrayed in what had once ben a "party frock".'
          ],
          [
            1,
            'Timestr [19:59]: A minute to eight',
            'Quickly, quickly. <<A minute to eight|10>>. My hot water bottle was ready, and I filled a glass with water from the tap. Time was of the essence.'
          ],
          [
            1,
            'Timestr [20:00]: eight o\'clock',
            '\'TIS <<eight o\'clock|6>>,--a clear March night, The moon is up,--the sky is blue, The owlet, in the moonlight air, Shouts from nobody knows where; He lengthens out his lonely shout, Halloo! halloo! a long halloo!'
          ],
          [
            1,
            'Timestr [20:00]: eight',
            '"I trace the words, I\'ll arrive to collect you for drinks at <<eight|9a>> on Saturday."'
          ],
          [
            1,
            'Timestr [20:00]: 8.00 p.m.',
            '<<8.00 p.m.|2a>> Have a bath'
          ],
          [
            1,
            'Timestr [20:00]: eight o\'clock',
            'Arthur thought he could even bear to listen to the album of bagpipe music he had won. It was <<eight o\'clock|6>> and he decided he would make himself, force himself, to listen to the whole record before he phoned her.'
          ],
          [
            1,
            'Timestr [20:00]: eight o\'clock that evening',
            'At <<eight o\'clock that evening|6>>, a Saturday, Pamela Chamcha stood with Jumpy Joshi - who had refused to let her go unaccompanied - next to the Photo-Me machine in a corner of the main concourse of Euston station, feeling ridiculously conspiratorial.'
          ],
          [
            1,
            'Timestr [20:00]: eight',
            'Freud had me knock on Jung\'s door, to no avail. They waited until <<eight|9f>>, then set off for Brill\'s without him.'
          ],
          [
            1,
            'Timestr [20:01]: after eight o\'clock',
            'I have been drunk just twice in my life, and the second time was that afternoon; so everything that happened has a dim, hazy cast over it. although until <<after eight o\'clock|6>> the apartment was full of cheerful sun.'
          ],
          [
            1,
            'Timestr [20:00]: eight o\'clock in the evening',
            'It\'s the twenty-third of June nineteen seventy-five, and it is <<eight o\'clock in the evening|6>>, seated at his jigsaw puzzle, Bartlebooth has just died.'
          ],
          [
            1,
            'Timestr [20:00]: eight o\'clock',
            'She looked at her watch- it was <<eight o\'clock|6>>'
          ],
          [
            1,
            'Timestr [20:00]: eight in the evening',
            'That day he forgot to go to dinner; he noticed the fact at <<eight in the evening|9a>>, and as it was too late to go to the Rue St Jaques, he ate a lump of bread.'
          ],
          [
            1,
            'Timestr [20:00]: eight',
            'The clock struck <<eight|11>>. Had it been ten, Elinor would have been convinced that at that moment she heard a carriage driving up to the house; and so strong was the persuasion that she did, in spite of the almost impossibility of their being already come, that she moved into the adjoining dressing-closet and opened a window-shutter, to be satisfied of the truth. She instantly saw that her ears had not deceived her.'
          ],
          [
            1,
            'Timestr [20:01]: a little after eight o\'clock',
            'It was only <<a little after eight o\'clock|6>>, so all the shows were about silliness or murder.'
          ],
          [
            1,
            'Timestr [20:02]: two minutes past eight',
            '"Yes, I must go to the railway station, and if he\'s not there, then go there and catch him." Anna looked at the railway timetable in the newspapers. An evening train went at <<two minutes past eight|10>>. "Yes, I shall be in time."'
          ],
          [
            1,
            'Timestr [20:03]: 8:03',
            'He taught me that if I had to meet someone for an appointment, I must refuse to follow the \'stupid human habit\' of arbitrarily choosing a time based on fifteen-minute intervals. \'Never meet people at <<7:45|2>> or <<6:30|2>>, Jasper, but pick times like <<7:12|2>> and <<8:03|2>>!\''
          ],
          [
            1,
            'Timestr [20:04]: 8.04',
            'The earth seems to cast its darkness upward into the air. The farm country is somber at night. He is grateful when the lights of Lankaster merge with his dim beams. He stops at a diner who\'s clock says <<8.04|11>>.'
          ],
          [
            1,
            'Timestr [20:05]: 8.05 pm',
            'December 23rd At <<8.05 pm|2a>> Prof. Preobrazhensky commenced the first operation of its kind to be performed in Europe: removal under anaesthesia of a dog\'s testicles and their replacement by implanted human testes, with appendages and seminal ducts, taken from a 28-year-old human male'
          ],
          [
            1,
            'Timestr [20:05]: five minutes past eight',
            'Ransom took out his watch, which he had adapted, on purpose, several hours before, to Boston time, and saw that the minutes had sped with increasing velocity during this interview, and that it now marked <<five minutes past eight|10>>.'
          ],
          [
            1,
            "Timestr [20:06]: after eight o\x{2019}clock",
            "I have been drunk just twice in my life, and the second time was that afternoon; so everything that happened has a dim, hazy cast over it, although until <<after eight o\x{2019}clock|6>> the apartment was full of cheerful sun."
          ],
          [
            1,
            'Timestr [20:07]: 8:07 pm',
            'And I could hear that there were fewer people in the little station when the train wasn\'t there, so I opened my eyes and I looked at my watch and it said <<8:07 pm|2a>> and I had been sitting on the bench for approximately 5 hours but it hadn\'t seemed like approximately 5 hours, except that my bottom hurt and I was hungry and thirsty.'
          ],
          [
            1,
            'Timestr [20:07]: 8:07',
            'Bennie pulled the transcripts for that night. The first call had come in at <<8:07|2>>, with a positive ID.'
          ],
          [
            1,
            'Timestr [20:10]: 2010h',
            'At <<2010h|1>>. on 1 April Y.D.A.U., the medical attache is still watching the unlabelled entertainment cartridge.'
          ],
          [
            1,
            "Timestr [20:14]: fourteen minutes past eight o\x{2019}clock",
            "When a call came through to Dilworth\x{2019}s home number at <<fourteen minutes past eight o\x{2019}clock|10>>, Olbier and Jones reacted with far more excitement than the situation warranted because they were desperate for action."
          ],
          [
            1,
            'Timestr [20:15]: 8:15 p.m.',
            '<<8:15 p.m.|2a>> Cannot locate operating instructions (for video)'
          ],
          [
            1,
            'Timestr [20:15]: 8.15 p.m.',
            '<<8.15 p.m.|2a>> Get changed into pyjamas'
          ],
          [
            1,
            'Timestr [20:15]: quarter past eight',
            'Natsha: I was looking to see if there wasn\'t a fire. It\'s Shrovetide, and the servant is simply beside herself; I must look out that something doesn\'t happen. When I came through the dining-room yesterday <<midnight|13>>, there was a candle burning. I couldn\'t get her to tell me who had lighted it. [Puts down her candle] What\'s the time? Andrey: [Looks at his watch] A <<quarter past eight|10>>. Natasha: And Olga and Irina aren\'t in yet. The poor things are still at work. Olga at the teachers\' council, Irina at the telegraph office...[sighs] I said to your sister this morning, "Irina, darling, you must take care of yourself." But she pays no attention. Did you say it was a <<quarter past eight|10>>?'
          ],
          [
            1,
            'Timestr [20:16]: sixteen minutes past eight',
            'He kissed her hand and after a while went to get two more drinks. When he got back, it was <<sixteen minutes past eight|10>>, and Lois was humming softly along with the jukebox'
          ],
          [
            1,
            'Timestr [20:17]: 20.17',
            '<<20.17|5a:0>> A red warning light failed to go on in the Drive Room, beginning a chain of events which would lead, in a further twenty-three minutes, to the total annihilation of the entire crew of Red Dwarf.'
          ],
          [
            1,
            'Timestr [20:18]: 2018 hrs',
            '<<2018 hrs|1>> Katya has arrived at the Odessa Hotel. Barley and Katya are talking in the canteen. Wicklow and one irregular observing. More.'
          ],
          [
            1,
            'Timestr [20:20]: 8.20 p.m.',
            '<<8.20 p.m.|2a>> Play computer games'
          ],
          [
            1,
            'Timestr [20:20]: 20.20',
            'At <<20.20|9m>> all ships had completed oiling. Hove to, they had had the utmost difficulty in keeping position in that great wind; but they were infinitely safer than in the open sea'
          ],
          [
            1,
            'Timestr [20:20]: twenty minutes past eight',
            'Knowing that the dinner was only for us six, we never dreamed it would be a full dress affair. I had no appetite. It was quite <<twenty minutes past eight|10>> before we sat down to dinner.'
          ],
          [
            1,
            'Timestr [20:21]: 8.21',
            'At <<8.21|9e>>, after a knock at the door, a constable said a military police vehicle had just driven into the courtyard, the driver asking for "Mr." Murray.'
          ],
          [
            1,
            'Timestr [20:23]: 20.23',
            '<<20.23|9j>>. In a few minutes she would go down.She could have borrowed some mascara from her daughter Sally, but it was too late. She could have rung her mother in Northam, but it was too late. Seven minutes of solitude she had, and then she would descend.'
          ],
          [
            1,
            'Timestr [20:24]: 8.24',
            'Peach checked his watch. <<8.24|9j>>. If he wasn\'t in a taxi in twenty minutes he\'d be done for.'
          ],
          [
            1,
            'Timestr [20:25]: five and twenty past eight',
            'She sat down in her usual seat and smiled at her husband as he sank into his own chair opposite her. She was saved. It was only <<five and twenty past eight|10>>.'
          ],
          [
            1,
            'Timestr [20:27]: seven-and-twenty minutes past eight',
            'At <<seven-and-twenty minutes past eight|10>> Mrs Lofthouse was seated at Aurora\'s piano, in the first agonies of a prelude in six flats; a prelude which demanded such extraordinary uses of the left hand across the right, and the right over the left, and such exercise of the thumbs in all positions'
          ],
          [
            1,
            'Timestr [20:29]: Twenty-nine and a half minutes past eight',
            '"<<Twenty-nine and a half minutes past eight|10>>, sir." And then, from habit, he glanced at the clock in the tower, and made further oration. "By George! that clock\'s half an hour fast! First time in ten years I\'ve known it to be off. This watch of mine never varies a--" But the citizen was talking to vacancy. He turned and saw his hearer, a fast receding black shadow, flying in the direction of a house with three lighted upper windows.'
          ],
          [
            1,
            'Timestr [20:30]: half-past eight',
            'Alix took up a piece of needlework and began to stitch. Gerald read a few pages of his book. Then he glanced up at the clock and tossed the book away. "<<Half-past eight|10>>. Time to go down to the cellar and start work."'
          ],
          [
            1,
            'Timestr [20:30]: half-past eight',
            'The bicycles go by in twos and threes - there\'s a dance on in Billy Brennan\'s barn tonight, and there\'s the half-talk code of mysteries and the wink-and-elbow language of delight. <<Half-past eight|10>> and there is not a spot upon a mile of road, no shadow thrown that might turn out a man or woman,'
          ],
          [
            1,
            'Timestr [20:32]: eight thirty-two',
            'At the station he captured Miss Lantry out of the gadding mob at <<eight thirty-two|5b>>. "We mustn\'t keep mamma and the others waiting," said she. "To Wallack\'s Theatre as fast as you can drive!"'
          ],
          [
            1,
            'Timestr [20:33]: 20.33',
            '<<20.33|5a:0>> Navigation officer Henri DuBois knocked his black cona coffee with four sugars over his computer console keyboard. As he mopped up the coffee, he noticed three red warning blips on his monitor screen, which he wrongly assumed were the result of his spillage.'
          ],
          [
            1,
            'Timestr [20:35]: 8:35pm',
            '<<8:35pm|2a>>. Found operating instructions under Hello.'
          ],
          [
            1,
            'Timestr [20:35]: 8.35 p.m.',
            'Left Munich at <<8.35 p.m.|2a>> on 1st May, arriving at Vienna early the next morning'
          ],
          [
            1,
            'Timestr [20:35]: five and twenty to nine',
            'She paused reflectively. He was keenly interested now, not a doubt of it. The murderer is bound to have an interest in murder. She had gambled on that, and succeeded. She stole a glance at the clock. It was <<five and twenty to nine|10>>.'
          ],
          [
            1,
            'Timestr [20:36]: 20.36',
            '<<20.36|5a:0>> Rimmer stood in the main wash-room on the stasis deck and combed his hair.'
          ],
          [
            1,
            'Timestr [20:40]: twenty minutes to nine',
            'It was when I stood before her, avoiding her eyes, that I took note of the surrounding objects in detail, and saw that her watch had stopped at <<twenty minutes to nine|10>>, and that a clock in the room had stopped at <<twenty minutes to nine|10>>.'
          ],
          [
            1,
            'Timestr [20:40]: twenty minutes to nine',
            'The letter had been brought in at <<twenty minutes to nine|10>>.'
          ],
          [
            1,
            'Timestr [20:42]: 8.42',
            'The hand at this moment pointed to <<8.42|5a:1>>. The players took up their cards, but their eyes were constantly on the clock. One may safely say that, however secure they might feel, never had minutes seemed so long to them.'
          ],
          [
            1,
            'Timestr [20:43]: 8.43',
            '\'<<8.43|9j>>,\' said Thomas Flanagan, as he cut the cards placed before him by Gauthier Ralph. There was a moment\'s pause, during which the spacious room was perfectly silent.'
          ],
          [
            1,
            'Timestr [20:44]: 8.44',
            'The clock\'s pendulum beat every second with mathematical regularity, and each player could count every sixtieth of a minute as it struck his ear."<<8.44|9j>>!" said John Sullivan, in a voice that betrayed his emotion.Only one minute more and the wager would be won.'
          ],
          [
            1,
            'Timestr [20:45]: 8.45',
            '\'It\'s not impossible,\' Phileas said quietly.\'I bet you 20,000 pounds I could do it. If I leave this evening on the <<8.45|3c>> train to Dover, I can be back here at the Reform Club by <<8.45|3b>> on Saturday 21 December. I\'ll get my passport stamped at every place i stop to prove I\'ve been around the world.\''
          ],
          [
            1,
            'Timestr [20:45]: quarter to nine',
            'Beaver arrived at <<quarter to nine|10>> in a state of high self-approval; he had refused two invitations for dinner while dressing that evening; he had cashed a cheque for ten pounds at his club; he had booked a Divan table at Espinosa\'s.'
          ],
          [
            1,
            'Timestr [20:46]: eight forty six',
            'At the tone, the time will be <<eight forty six|5b>>, exactly. One cubic mile of seawater contains about 50 pounds of gold.'
          ],
          [
            1,
            'Timestr [20:49]: 8.49',
            '<<8.49|9j>>. I took the phone, cleared my throat, and dialled the keep, the packs stronghold on the outskirts of Atlanta. Just keep it professional. Less pathetic that way.'
          ],
          [
            1,
            'Timestr [20:50]: 8.50pm',
            '<<8.50pm|2a>>. Ah Diagram "Buttons for IMC functions". But what are IMC functions?'
          ],
          [
            1,
            'Timestr [20:50]: ten minutes before nine',
            'all the clocks in London were striking <<ten minutes before nine|10>>.'
          ],
          [
            1,
            'Timestr [20:50]: ten minutes to nine',
            'He glanced at the bracket-clock on the mantelpiece, but as this had stopped, drew out his watch. \'It is already too late,\' he said. \'It wants only <<ten minutes to nine|10>>.\' \'Good God!\' she exclaimed, turning quite pale. \'What am I to do?\''
          ],
          [
            -1,
            'Timestr [20:50]: 2050',
            'He was, yes, always home from work by <<2050|99>> on Thursdays.'
          ],
          [
            1,
            'Timestr [20:50]: ten minutes to nine',
            'What did it mean by beginning to tick so loudly all of a sudden? Its face indicated <<ten minutes to nine|10>>. Mrs Verloc cared nothing for time, and the ticking went on.'
          ],
          [
            1,
            'Timestr [20:53]: eight fifty-three',
            'Only <<eight fifty-three|9j>>. The partners\' decision meeting starts in seven minutes. I\'m not sure I can bear this.'
          ],
          [
            1,
            'Timestr [20:55]: 8:55pm',
            'And the past. The clock on the dash said <<8:55pm|2a>>. And the last pink shard of the sun was reaching up into the night sky, desperately trying to hold on for just one more minute.'
          ],
          [
            1,
            'Timestr [20:56]: four minutes to nine',
            "\x{201c}No. 7 berth\x{2014}a second-class. The gentleman has not yet come, and it is <<four minutes to nine|10>>.\""
          ],
          [
            1,
            'Timestr [20:57]: three minutes to nine',
            '"Wait," he said solemnly, "till the clock strikes. I have wealth and power and knowledge above most men, but when the clock strikes I am afraid. Stay by me until then. This woman shall be yours. You have the word of the hereditary Prince of Valleluna. On the day of your marriage I will give you $100,000 and a palace on the Hudson. But there must be no clocks in that palace--they measure our follies and limit our pleasures. Do you agree to that?" "Of course," said the young man, cheerfully, "they\'re a nuisance, anyway--always ticking and striking and getting you late for dinner." He glanced again at the clock in the tower. The hands stood at <<three minutes to nine|10>>.'
          ],
          [
            1,
            'Timestr [20:58]: two minutes to nine',
            '"What time is it?" she asked, quiet, definite, hopeless. "<<Two minutes to nine|10>>," he replied, telling the truth with a struggle.'
          ],
          [
            1,
            'Timestr [21:00]: 9.00 p.m.',
            '<<9.00 p.m.|2a>> Watch television or a video'
          ],
          [
            1,
            'Timestr [21:00]: 2100 at night',
            'At <<2100 at night|9m>> it\'s cold out.'
          ],
          [
            1,
            'Timestr [21:00]: nine o\'clock at night',
            "It was <<nine o'clock at night|6>> upon the second of August\x{2014}the most terrible August in the history of the world. One might have thought already that God's curse hung heavy over a degenerate world, for there was an awesome hush and a feeling of vague expectancy in the sultry and stagnant air"
          ],
          [
            1,
            'Timestr [21:00]: about nine o\'clock',
            'On the evening before K.\'s thirty-first birthday - it was <<about nine o\'clock|6>>, when there is a lull in the streets - two gentlemen came to his apartment.'
          ],
          [
            1,
            "Timestr [21:00]: nine o\x{2019}clock",
            "On the stroke of <<nine o\x{2019}clock|6>> Mr. and Mrs. De Voted took their places on either side of the drawing-room fire, in attitudes of gracefully combined hospitality and unconcern, Vivian De Voted wearing a black beard and black velvet jacket buttoned over his Bohemian bosom, his lady in a flowing purple gown embroidered in divers appropriate places with pomegranates and their leaves."
          ],
          [
            1,
            'Timestr [21:01]: Shortly after nine o\'clock that evening',
            '<<Shortly after nine o\'clock that evening|6>>, Weyrother drove with his plans to Kutuzov\'s quarters where the council of war was to be held. All the commanders of columns were summoned to the commander in chief\'s and with the exception of Prince Bagration, who declined to come, were all there at the appointed time.'
          ],
          [
            1,
            'Timestr [21:00]: nine o\'clock',
            'Standing in the chrome-and-tile desolation of the Polar-Shtern Kafeteria at <<nine o\'clock|6>> on a Friday night, in a snowstorm, he\'s the loneliest Jew in the Sitka District.'
          ],
          [
            1,
            'Timestr [21:00]: nine',
            'That night at <<nine|9b>> the President addressed the nation.'
          ],
          [
            1,
            'Timestr [21:00]: nine o\'clock',
            'Then he put on a grey jacket and left the flat to make his way to Praca da Alegria. It was already <<nine o\'clock|6>>, Pereira maintains.'
          ],
          [
            1,
            'Timestr [21:00]: nine o\'clock at night',
            'This time, the putting on of her best hat at <<nine o\'clock at night|6>> with the idea of sallying forth from the castle, down the long drive and then northwards along the acacia avenue, had been enough to send her to her own doorway as though she suspected someone might be there, someone who was listening to her thoughts.'
          ],
          [
            1,
            'Timestr [21:01]: about nine o\'clock',
            'On the evening before K.\'s thirty-first birthday - it was <<about nine o\'clock|6>>, when there is a lull in the streets - two gentlemen came to his apartment.'
          ],
          [
            -1,
            'Timestr [21:02]: after nine',
            'The good Brants did not allow the boys to play out <<after nine|99>> in summer evenings; they were sent to bed at that hour; Eddie honorably remained, but Georgie usually slipped out of the window toward ten, and enjoyed himself until <<midnight|13>>.'
          ],
          [
            1,
            "Timestr [21:03]: about nine o\x{2019}clock in the evening",
            "Billy Weaver had travelled down from London on the slow afternoon train, with a change at Swindon on the way, and by the time he got to Bath it was <<about nine o\x{2019}clock in the evening|6>> and the moon was coming up out of a clear starry sky over the houses opposite the station entrance. But the air was deadly cold and the wind was like a flat blade of ice on his cheeks."
          ],
          [
            1,
            'Timestr [21:04]: 9.04pm',
            'At <<9.04pm|2a>> trilobites swim onto the scene, followed more or less immediately by the shapely creatures of the Burgess Shale.'
          ],
          [
            1,
            'Timestr [21:05]: nine-five',
            '<<Nine-five|9j>>. A voice spoke from the study ceiling: "Mrs. McClellan, which poem would you like this evening?". The house was silent. The voice said at last, "Since you express no preference, I shall select a poem at random."'
          ],
          [
            1,
            'Timestr [21:09]: 9.09',
            '<<9.09|9j>>. Too late to turn around and go back. Too late, too dangerous.'
          ],
          [
            1,
            'Timestr [21:11]: 9.11',
            'Every few seconds the house changed character, at one time menacing and sinister, and again the innocent abode of law-abiding citizens about to be attacked by my private army. The luminous watch said <<9.11|11>>.'
          ],
          [
            1,
            'Timestr [21:12]: 21.12',
            'The crime was reported to us (with almost indecent alacrity, Rog) at <<21.12|9c:1>>, by Susan Trott - of Black Grouse Cottage - who had been, I quote: \'out looking for hedgehogs when I was horrified to notice the postbox door had fallen off and was just lying there, on the ground\'.'
          ],
          [
            1,
            'Timestr [21:15]: 9.15',
            '<<9.15|9j>>. Did Roberts pay you yet?'
          ],
          [
            1,
            'Timestr [21:15]: nine-fifteen',
            'What are we going to do? Should we try to walk to Clapham High Street? But it\'s bloody miles away. I glance at my watch and am shocked to see that it\'s <<nine-fifteen|9f>>. We\'ve spent over an hour faffing about and we haven\'t even had a drink. And it\'s all my fault. I can\'t even organize one simple evening without its going catastrophically wrong.'
          ],
          [
            1,
            'Timestr [21:17]: 21:17',
            '<<21:17|2>>, Sunday Evening, Angbyplan. A man is observed outside the hair salon. He presses his face and hands against the glass, and appears extremely intoxicated.'
          ],
          [
            1,
            'Timestr [21:18]: eighteen minutes after nine',
            'The same thing would hold true if there were someone in her apartment. In that case he would just say that he had been passing by, recognized her charming house, and thought to drop in. It was <<eighteen minutes after nine|10>> when Mr. Martin turned into Twelfth Street.'
          ],
          [
            1,
            'Timestr [21:20]: 9.20 p.m.',
            '<<9.20 p.m.|2a>> Have juice and a snack'
          ],
          [
            1,
            'Timestr [21:22]: 21.22 hrs',
            'Fifteen minutes later (<<21.22 hrs|1>>), Miss Squire arrives in Skipton where she is booked into a local B&B. This B&B is located directly across the road from Mhairi Callaghan\'s Feathercuts.'
          ],
          [
            1,
            'Timestr [21:23]: 9.23pm',
            'My father met me at the station, the dog jumped up to meet me, missed, and nearly fell in front of the <<9.23pm|2a>> Birmingham express.'
          ],
          [
            1,
            'Timestr [21:25]: 9:25 p.m.',
            '<<9:25 p.m.|2a>> Aargh. Suddenly main menu is on TV saying Press 6. Realize was using telly remote control by mistake. Now News has come on'
          ],
          [
            1,
            'Timestr [21:28]: 9:28 in the evening',
            'From that moment on--<<9:28 in the evening|2a>>, June 18, 1941--everything was different.'
          ],
          [
            1,
            'Timestr [21:30]: 9.30 p.m.',
            '<<9.30 p.m.|2a>> Go to bed'
          ],
          [
            1,
            'Timestr [21:30]: nine thirty',
            'Forty-eight years old, profoundly asleep at <<nine thirty|5b>> on a Friday night - this is modern professional life.'
          ],
          [
            1,
            'Timestr [21:30]: 9:30 p.m.',
            'It\'s <<9:30 p.m.|2a>> already. I\'ve gotta head uptown for my appointment with Pavel. Pavel is my shrink. He sees patients at night. He\'s a Czech Jew, a survivor of Terezin and Auswitz. I see him once a week.'
          ],
          [
            1,
            'Timestr [21:30]: nine-thirty',
            'The light in Mr. Green\'s kitchen snapped off at <<nine-thirty|5b>>, followed by the light in his bedroom at his usual <<ten o\'clock|6>>. His house was the first on the street to go dark.'
          ],
          [
            1,
            'Timestr [21:31]: 9:31',
            'I took some juice out of the refrigerator and sat down at the kitchen table with it. On the table was a note from my girlfriend: "Gone out to eat. Back by <<9:30|2>>." The digital clock on the table read <<9:30|2>>. I watched it flip over to <<9:31|2>>, then to <<9:32|2>>.'
          ],
          [
            1,
            'Timestr [21:32]: 9:32',
            'I took some juice out of the refrigerator and sat down at the kitchen table with it. On the table was a note from my girlfriend: "Gone out to eat. Back by <<9:30|2>>." The digital clock on the table read <<9:30|2>>. I watched it flip over to <<9:31|2>>, then to <<9:32|2>>.'
          ],
          [
            1,
            'Timestr [21:34]: 9.34 p.m.',
            'Thanks; expect me <<9.34 p.m.|2a>> 26th\'; which produced, three hours later, a reply: \'Delighted; please bring a No. 3 Rippingille stove\' - a perplexing and ominous direction, which somehow chilled me in spite of its subject matter.'
          ],
          [
            1,
            'Timestr [21:35]: 9.35 p.m.',
            'The Sergeant jotted it down on a piece of paper. \'That checks up with his own story: <<9.35 p.m.|2a>> Budd leaves; the North dame arrives.\''
          ],
          [
            1,
            'Timestr [21:36]: 9:36',
            'My backpack was already packed, and I\'d already gotten the other supplies together, like the altimeter and the granola bars and the Swiss army knife I\'d dug up in Central Park, so there was nothing else to do. Mom tucked me in at <<9:36|2>>.'
          ],
          [
            1,
            'Timestr [21:38]: nine thirty-eight',
            'At <<nine thirty-eight|9m>> the waiter came back and offered us a second helping of cheese,salami and sardines, and Mr Yoshogi who had been converting sterling into yen looked extremely puzzled and said he had no idea that British Honduras had so large an export trade'
          ],
          [
            1,
            'Timestr [21:42]: 9:42 P.M.',
            'Langdon looked at his Mickey Mouse watch. <<9:42 P.M.|2a>>'
          ],
          [
            1,
            'Timestr [21:45]: 9:45 PM',
            'But for some unfathomable reason-birth, death, the end of the universe and all things available to man-Cody Menhoff\'s was closed at <<9:45 PM|2a>> on a Thursday...'
          ],
          [
            1,
            'Timestr [21:47]: thirteen minutes to ten',
            'For Hunter, who was trained to note times exactly, the final emergency started at <<thirteen minutes to ten|10>>.'
          ],
          [
            1,
            'Timestr [21:50]: ten minutes to ten',
            'I passed out on to the road and saw by the lighted dial of a clock that it was <<ten minutes to ten|10>>. In front of me was a large building which displayed the magical name.'
          ],
          [
            1,
            'Timestr [21:57]: 21:57',
            'Second to last, the inset clock blinks from <<21:57|2>> to <<21:58|2>>. Napier\'s eyes sink, newborn sunshine slants through ancient oaks and on a lost river. Look, Joe, herons'
          ],
          [
            1,
            'Timestr [21:57]: three minutes to ten',
            'The waiting man pulled out a handsome watch, the lids of it set with small diamonds. "<<Three minutes to ten|10>>," he announced.'
          ],
          [
            1,
            'Timestr [21:58]: 21:58',
            'Second to last, the inset clock blinks from <<21:57|2>> to <<21:58|2>>. Napier\'s eyes sink, newborn sunshine slants through ancient oaks and on a lost river. Look, Joe, herons'
          ],
          [
            1,
            'Timestr [21:59]: About 10',
            'The first night, as soon as the corporal had conducted my uncle Toby upstairs, which was <<about 10|9e>> - Mrs. Wadman threw herself into her arm chair'
          ],
          [
            1,
            'Timestr [22:00]: ten',
            'By <<ten|9e>>, Quoyle was drunk. The crowd was enormous, crushed together so densely that Nutbeem could not force his way down the hall or to the door and urinated on the remaining potato chips in the blue barrel, setting a popular example.'
          ],
          [
            1,
            'Timestr [22:00]: ten o\'clock',
            'Her body asserted itself with a restless movement of the knee, and she stood up. \'<<Ten o\'clock|6>>,\' she remarked, apparently finding the time on the ceiling. \'Time for this good girl to go to bed.\''
          ],
          [
            1,
            'Timestr [22:00]: ten',
            'I could not doubt that this was the BLACK SPOT; and taking it up, I found written on the other side, in a very good, clear hand, this short message: "You have till <<ten|9a>> tonight."'
          ],
          [
            1,
            'Timestr [22:00]: ten o\'clock',
            'I went back into the library, limp and exhausted. In a few minutes the telephone began ringing again. I did not do anything. I let it ring. I went and sat down at Maxim\'s feet. It went on ringing. I did not move. Presently it stopped, as though cut suddenly in exasperation. The clock on the mantelpiece struck <<ten o\'clock|6>>. Maxim put his arms round me and lifted me against him. We began to kiss one another, feverishly, desperately, like guilty lovers who have not kissed before.'
          ],
          [
            1,
            'Timestr [22:00]: ten o\'clock',
            'No one wanted to go to bed when at <<ten o\'clock|6>> Mrs. March put by the last finished job, and said, "Come girls." Beth went to the piano and played the father\'s favorite hymn.'
          ],
          [
            1,
            'Timestr [22:00]: ten',
            'The grandfather clock in the State Room strikes <<ten|11>> times.'
          ],
          [
            1,
            'Timestr [22:00]: ten o\'clock',
            'The light in Mr. Green\'s kitchen snapped off at <<nine-thirty|5b>>, followed by the light in his bedroom at his usual <<ten o\'clock|6>>. His house was the first on the street to go dark.'
          ],
          [
            1,
            'Timestr [22:00]: ten o\'clock',
            'They were alone then, and theoretically free to do whatever they wanted, but they went on eating the dinner they had no appetite for. Florence set down her knife and reached for Edward\'s hand and squeezed. From downstairs they heard the wireless, the chimes of Big Ben at the start of the <<ten o\'clock|6>> news.'
          ],
          [
            1,
            'Timestr [22:00]: ten o\'clock',
            'We let our upstairs room to a certain Mr. Goudsmit, a divorced man in his thirties, who appeared to have nothing to do on this particular evening; we simply could not get rid of him without being rude; he hung about until <<ten o\'clock|6>>.'
          ],
          [
            1,
            'Timestr [22:02]: 10.02pm',
            'It was now <<10.02pm|2a>>. He has less than two hours.'
          ],
          [
            1,
            'Timestr [22:05]: 10:05 p.m.',
            'The A-B elevator was our elevator, the elevator on which the paramedics came up at <<9:20 p.m.|2a>>, the elevator on which they took John (and me) downstairs to the ambulance at <<10:05 p.m.|2a>>'
          ],
          [
            1,
            'Timestr [22:06]: long after ten o\'clock',
            'Of course, they had good reason to be fussy on such a night. And then it was <<long after ten o\'clock|6>> and yet there was no sign of Gabriel and his wife. Besides they were dreadfully afraid that Freddy Malins might turn up screwed.'
          ],
          [
            1,
            'Timestr [22:08]: ten eight',
            '"My watch is always a little fast," I said. "What time do you make it now?" "<<Ten eight|9j>>." "<<Ten eighteen|5a:1>> by mine. You see."'
          ],
          [
            1,
            'Timestr [22:10]: 10.10pm',
            '<<10.10pm|2a>>. When you turn your recorder on you must adjust clock and the calendar.......Press red and nothing happens. Press numbers and nothing happens. Wish stupid video had never been invented.'
          ],
          [
            1,
            'Timestr [22:10]: ten minutes past ten',
            'That was the past, and now I had just died on the narrow couch of a Paris lodging house, and my wife was crouching on the floor, crying bitterly. The white light before my left eye was growing dim, but I remembered the room perfectly. On the left there was a chest of drawers, on the right a mantelpiece surmounted by a damaged clock without a pendulum, the hands of which marked <<ten minutes past ten|10>>. The window overlooked the Rue Dauphine, a long, dark street. All Paris seemed to pass below, and the noise was so great that the window shook.'
          ],
          [
            1,
            'Timestr [22:11]: eleven minutes past ten in the evening',
            'Therefore a sergeant called Trifonov had been on post all day or all week and then he had left at <<eleven minutes past ten in the evening|10>>.'
          ],
          [
            1,
            'Timestr [22:12]: 2212',
            'The Chinese women scuttled at an amazing rate, given their size and the bags\' size. It was c. <<2212|1a>>:30-40h., smack in the middle of the former Interval of Issues Resolution.'
          ],
          [
            1,
            'Timestr [22:14]: 2214',
            'The shopping bags looked heavy and impressive, their weight making the Chinese women lean in slightly towards each other. Call it <<2214|1a>>:10h.'
          ],
          [
            1,
            'Timestr [22:15]: 10:15 p.m.',
            '<<10:15 p.m.|2a>> Aargh Newsnight on in 15 minutes'
          ],
          [
            1,
            'Timestr [22:17]: 10:17 p. m.',
            '<<10:17 p. m.|2a>> Casette will not go in'
          ],
          [
            1,
            'Timestr [22:18]: ten eighteen',
            '"My watch is always a little fast," I said. "What time do you make it now?" "<<Ten eight|9j>>." "<<Ten eighteen|5a:1>> by mine. You see."'
          ],
          [
            1,
            'Timestr [22:18]: 10:18pm',
            '<<10:18pm|2a>>. Ah. Thelma and Louise is in there'
          ],
          [
            1,
            'Timestr [22:20]: 10:20',
            'At <<10:20|2>> she returned with a shopping bag from the supermarket. In the bag were three scrub brushes, one box of paperclips and a well-chilled six-pack of canned beer. So I had another beer. "It was about sheep," I said. "Didn\'t I tell you?" she said.'
          ],
          [
            1,
            'Timestr [22:21]: 10:21pm',
            '<<10:21pm|2a>>. Frenziedly press all buttons. Cassette comes out and goes back in again'
          ],
          [
            1,
            'Timestr [22:21]: 10:21pm',
            '<<10:21pm|2a>>. Thelma and Louise will not come out'
          ],
          [
            1,
            'Timestr [22:21]: 2221h',
            'On a Saturday c. <<2221h|1>>., Lenz found a miniature bird that had fallen out of some nest and was sitting bald and pencil-necked on the lawn of Unit #3 flapping ineffectually, and went in with Green and ducked Green and went back outside to # 3\'s lawn and put the thing in a pocket and went in and put it down the garbage disposal in the kitchen sink of the kitchen, but still felt largely impotent and unresolved.'
          ],
          [
            1,
            'Timestr [22:21]: 2221h',
            'On a Saturday c. <<2221h|1>>., Lenz found a miniature bird that had fallen out of some nest and was sitting bald and pencil-necked on the lawn of Unit #3 flapping ineffectually...'
          ],
          [
            1,
            'Timestr [22:24]: 10:24',
            'Thanks to ten minutes or so of balmy weather, by <<10:24|2>> the Earth is covered in the great carboniferous forests whose residues give us all our coal, and the first winged insects are evident.'
          ],
          [
            1,
            'Timestr [22:25]: 10:25pm',
            '<<10:25pm|2a>>. Got new cassette in now. Right. Turn to "Recording.................. Aargh Newsnight is starting'
          ],
          [
            1,
            'Timestr [22:26]: ten-twenty-six',
            'As always, consciousness returned to me progressively from the edges of my field of vision. The first things to claim recognition were the bathroom door emerging from the far right and a lamp from the far left, from which my awareness gradually drifted inward like ice flowing together toward the middle of a lake. In the exact center of my visual field was the alarm clock, hands pointing to <<ten-twenty-six|11>>.'
          ],
          [
            1,
            'Timestr [22:27]: twenty-seven minutes past 10',
            'Mr Harcourt woke up with mysterious suddenness at <<twenty-seven minutes past 10|10>>, and, by a curious coincidence, it was at that very instant that the butler came in with two footmen laden with trays of whisky, brandy, syphons, glasses and biscuits.'
          ],
          [
            1,
            'Timestr [22:30]: ten thirty',
            'She looked at the clock; it was <<ten thirty|9f>>. If she could get there quickly on the subway, then she could be at his house in less than an hour, maybe a bit longer if the late trains did not come so often.'
          ],
          [
            1,
            'Timestr [22:30]: ten-thirty',
            'The time was <<ten-thirty|5b>> but it could have been <<three in the morning|5>>, because along its borders, West Berlin goes to bed with the dark'
          ],
          [
            1,
            'Timestr [22:31]: 10.31pm',
            '<<10.31pm|2a>>. Ok OK. Calm. Penny Husbands-Bosworth, so asbestos leukaemia item is not on yet.'
          ],
          [
            1,
            'Timestr [22:31]: 10.31 pm',
            'And, later on, at <<10.31 pm|2a>>, I went out onto the balcony to find out whether I could see any stars, but there weren\'t any because of all the clouds and what is called Light Pollution which is light from streetlights and car headlights and floodlights and lights in buildings reflecting off tiny particles in the atmosphere and getting in the way of light from the stars. So I went back inside.'
          ],
          [
            1,
            'Timestr [22:33]: 10:33 p.m.',
            '<<10:33 p.m.|2a>> Yessss, yessss. RECORDING CURRENT PROGRAMME. Have done it. Aargh. All going mad. Cassette has started rewinding and now stopped and ejected. Why? Shit. Shit. Realize in excitement have sat on remote control.'
          ],
          [
            1,
            'Timestr [22:33]: 10:33pm',
            '<<10:33pm|2a>>. Yessss, yessss. RECORDING CURRENT PROGRAMME. Have done it. Aargh. All going mad. Cassette has started rewinding and now stopped and ejected. Why? Shit. Shit. Realize in excitement have sat on remote control.'
          ],
          [
            1,
            'Timestr [22:35]: 10:35 p.m.',
            '<<10:35 p.m.|2a>> Frantic now. Have rung Sahzzer, Rebecca, Simon, Magda. Nobody knows how to programme their videos. Only person I know who knows how to do it is Daniel.'
          ],
          [
            1,
            'Timestr [22:40]: twenty to eleven',
            'The station clock told him the time: <<twenty to eleven|10a:1>>. He went to the booking office and asked the clerk in a polite tone when was the next train to Paris. \'In twelve minutes.\''
          ],
          [
            1,
            'Timestr [22:41]: 10:41',
            'He climbed into the front seat and started the car. It started with a merry powerful hum, ready to go. "There, the bastards", said Julian, and smashed the clock with the bottom of the bottle, to give them an approximate time. It was <<10:41|2>>'
          ],
          [
            1,
            'Timestr [22:44]: About a quarter to eleven',
            'Alec pricked up his ears. "When was that?" "Oh, yesterday evening." "What time?" "<<About a quarter to eleven|10>>. I was playing bridge."'
          ],
          [
            1,
            'Timestr [22:45]: 10.45pm',
            '<<10.45pm|2a>>. Oh God Daniel fell about laughing when I said I could not programme video. Said he would do it for me. Still at least I have done best for Mum. It is exciting and historic when one\'s friends are on TV.'
          ],
          [
            1,
            'Timestr [22:45]: fifteen minutes before eleven o\'clock',
            'So the Lackadaisical Broadcasting Co. bids you farewell with the message that if you aren\'t grateful to be living in a world where so many things to be grateful for are yours as a matter of course. Why it is now five seconds until <<fifteen minutes before eleven o\'clock|10>> and you are just an old Trojan Horse.'
          ],
          [
            1,
            'Timestr [22:46]: 10.46 p.m.',
            'The \'night train\' tallied to perfection, for high tide in the creek would be, as Davies estimated, between <<10.30|5a:1>> and <<11.00 p.m.|2a>>on the night of the 25th; and the time-table showed that the only night train arriving at Norden was one from the south at <<10.46 p.m.|2a>>'
          ],
          [
            1,
            'Timestr [22:48]: 10.48',
            '"Oh! I don\'t know about that," said Mr. Satterthwaite, warming to his subject. "I was down there for a bit last summer. I found it quite convenient for town. Of course the trains only go every hour. 48 minutes past the hour from Waterloo-up to <<10.48|5a:1>>."'
          ],
          [
            1,
            'Timestr [22:50]: 10.50 P. M.',
            '<<10.50 P. M.|2a>> This diary-keeping of mine is, I fancy, the outcome of that scientific habit of mind about which I wrote this morning. I like to register impressions while they are fresh.'
          ],
          [
            1,
            'Timestr [22:50]: ten to eleven',
            "Saturday night. And I said, 'It's a hundred this year, ain't anybody noticed?'\"Jack said, 'What's a hundred?' I said, 'Pub is. Coach is. Look at the clock.' Jack said, \x{2018}It's <<ten to eleven|10a:1>>\x{2019}."
          ],
          [
            1,
            'Timestr [22:50]: 22.50',
            'So think yourself lucky while you\'re awake and remember a happy crew. Think of Hamburg on the Magic Night. <<22.50|5a:0>> and they went out neatly, just as they should - you couldn\'t fault Parks, he was always on his route.'
          ],
          [
            1,
            'Timestr [22:51]: well after 2245h',
            'It\'s <<well after 2245h|1>>. The dog\'s leash slides hissing to the end of the Day-Glo line and stops the dog a couple of paces from the inside of the gate, where Lenz is standing, inclined in the slight forward way of somebody who\'s talking baby-talk to a dog.'
          ],
          [
            -1,
            'Timestr [22:55]: Eleven o\'clock, all but five minutes',
            '"It is <<eleven o\'clock|6>>! <<Eleven o\'clock, all but five minutes|99>>!" "But which <<eleven o\'clock|6>>?" "The <<eleven o\'clock|6>> that is to decide life or death!...He told me so just before he went....He is terrible....He is quite mad: he tore off his mask and his yellow eyes shot flames!..."'
          ],
          [
            1,
            "Timestr [22:58]: just about eleven o\x{2019}clock",
            "Then it grew dark; she would have had them to bed, but they begged sadly to be allowed to stay up; and, <<just about eleven o\x{2019}clock|6>>, the door-latch was raised quietly, and in stepped the master."
          ],
          [
            1,
            'Timestr [22:59]: one minute to eleven',
            'They parked the car outside Lowther\'s at precisely <<one minute to eleven|10>>. People were leaving, not all of them happy at having their evening curtailed. But the grumbling was muted, and even then it only started once they were safely on the street.'
          ],
          [
            1,
            'Timestr [23:00]: eleven',
            '\'He will be here at <<eleven|9b>> exactly, sir.\' At the bar, naked couples had begun dancing.'
          ],
          [
            1,
            'Timestr [23:00]: eleven o\'clock that night',
            'At <<eleven o\'clock that night|6>>, having secured a bed at one of the hotels and telegraphed his address to his father immediately on his arrival, he walked out into the streets of Sandbourne.'
          ],
          [
            1,
            'Timestr [23:00]: eleven o\'clock',
            'At <<eleven o\'clock|6>>, I rang the bell for Betteredge, and told Mr. Blake that he might at last prepare himself for bed.'
          ],
          [
            1,
            'Timestr [23:00]: eleven o\'clock',
            'He says, "They\'ve killed Jan. Clear out." "The suitcase?" I ask. "Take it away again. We want nothing to do with it now. Catch the <<eleven o\'clock|6>> express." "But it doesn\'t stop here...." "It will. Go to track six. Opposite the freight station. You have three minutes." "But..." "Move, or I\'ll have to arrest you."'
          ],
          [
            1,
            'Timestr [23:00]: eleven',
            'The clock struck <<eleven|11>>. I looked at Adele, whose head leant against my shoulder; her eyes were waxing heavy, so I took her up in my arms and carried her off to bed. It was <<near one|9c:1>> before the gentlemen and ladies sought their chambers.'
          ],
          [
            1,
            'Timestr [23:00]: eleven',
            'The clock struck <<eleven|11>>. I looked at Adele, whose head leant against my shoulder; her eyes were waxing heavy, so I took her up in my arms and carried her off to bed. It was <<near one|9c:1>> before the gentlemen and ladies sought their chambers.'
          ],
          [
            1,
            'Timestr [23:00]: eleven that night',
            'The train arrived in New York at <<eleven that night|9a>>.'
          ],
          [
            1,
            'Timestr [23:00]: 2300h',
            'They didn\'t even sit down to eat until <<2300h|1>>.'
          ],
          [
            1,
            'Timestr [23:00]: eleven o\'clock',
            'When they reached the top of the Astronomy Tower at <<eleven o\'clock|6>>, they found a perfect night for stargazing, cloudless and still.'
          ],
          [
            1,
            'Timestr [23:03]: Eleven oh-three',
            '"What makes you think it\'s for real?" "Just a hunch, really. He sounded for real. Sometimes you can just tell about people"-he smiled-"even if you\'re a dull old WASP." "I think it\'s a setup." "Why?" "I just do. Why would someone from the government want to help you?" "Good question. Guess I\'ll find out." She went back into the kitchen."What time are you meeting him?" she called out. "<<Eleven oh-three|9j>>," he said. "That made me think he\'s for real. Military and intelligence types set precise appointment times to eliminate confusion and ambiguity. Nothing ambiguous <<about eleven oh-three|5a:1>>."'
          ],
          [
            1,
            'Timestr [23:05]: 11.05',
            'It was <<11.05|9f>>, five minutes later than my habitual bedtime. I felt. I felt guilty at being still up, but the past kept pricking at me and I knew that all the events of those nineteen days in July were astir within me, like the loosening phlegm in an attack of bronchitis'
          ],
          [
            1,
            'Timestr [23:05]: five minutes past eleven',
            'It was <<five minutes past eleven|10>> when I made my last entry. I remember winding up my watch and noting the time. So I have wasted some five hours of the little span still left to us. Who would have believed it possible? But I feel very much fresher, and ready for my fate--or try to persuade myself that I am. And yet, the fitter a man is, and the higher his tide of life, the more must he shrink from death. How wise and how merciful is that provision of nature by which his earthly anchor is usually loosened by many little imperceptible tugs, until his consciousness has drifted out of its untenable earthly harbor into the great sea beyond!'
          ],
          [
            1,
            'Timestr [23:05]: 11:05',
            'My watch says <<11:05|2>>. But whether AM or PM I don\'t know.'
          ],
          [
            1,
            'Timestr [23:07]: 11.07 pm',
            'At <<11.07 pm|2a>>, Samuel "Gunner" Wilson was moving at 645 miles per hour over the Mojave Desert. Up ahead in the moonlinght, he saw the twin lead jets, their afterburners glowing angrily in the night sky.'
          ],
          [
            1,
            'Timestr [23:10]: ten past eleven',
            'Another Christmas day is nearly over. It\'s <<ten past eleven|10>>. Richard declined with thanks my offer to make up a bed for him here in my study, and has driven off back to Cambridge, so I am able to make some notes on the day before going to bed myself.'
          ],
          [
            1,
            'Timestr [23:10]: ten minutes past eleven',
            'He had not the strength to help himself, and at <<ten minutes past eleven|10>> no one could have helped him, no one in the world'
          ],
          [
            1,
            'Timestr [23:11]: 11:11 p.m.',
            'Life changes fast Life changes in an instant You sit down to dinner and life as you know it ends. The Question of self-pity. Those were the first words I wrote after it happened. The computer dating on the Microsoft Word file ("Notes on change.doc") reads "May 20, 2004, <<11:11 p.m.|2a>>," but that would have been a case of my opening the file and reflexively pressing save when I closed it. I had made no changes to that file since I wrote the words, in January 2004, a day or two after the fact. For a long time I wrote nothing else. Life changes in the instant. The ordinary instant.'
          ],
          [
            1,
            'Timestr [23:12]: 23:12 hours',
            'There was a confirmatory identification done by undercover officer 6475 at <<23:12 hours|1>> at the corner of 147th and Amsterdam.'
          ],
          [
            1,
            'Timestr [23:15]: 11.15pm',
            '<<11.15pm|2a>>. Humph. Mum just rang "Sorry, darling. It isn\'t Newsnight, it\'s Breakfast News tomorrow. Could you set it for <<seven o\'clock|6>> tomorrow morning, BBC1?"'
          ],
          [
            1,
            'Timestr [23:15]: quarter-past eleven',
            'On arriving home at a <<quarter-past eleven|10>>, we found a hansom cab, which had been waiting for me for two hours with a letter. Sarah said she did not know what to do, as we had not left the address where we had gone.'
          ],
          [
            1,
            'Timestr [23:16]: 11.16 pm',
            'But I couldn\'t get out of the house straight away because he would see me, so I would have to wait until he was asleep. The time was <<11.16 pm|2a>>. I tried doubling 2s again, but I couldn\'t get past 2(15) which was 32,768. So I groaned to make the time pass quicker and not think.'
          ],
          [
            1,
            'Timestr [23:18]: 11.18',
            'It is <<11.18|9f>>. A row of bungalows in a round with a clump of larch tree in the middle.'
          ],
          [
            1,
            'Timestr [23:19]: 11:19',
            'A whistle cut sharply across his words. Peter got onto his knees to look out the window, and Miss Fuller glared at him. Polly looked down at her watch: <<11:19|2>>. The train. But the stationmaster had said it was always late.'
          ],
          [
            1,
            'Timestr [23:20]: eleven-twenty',
            'From Balboa Island, he drove south to Laguna Beach. At <<eleven-twenty|9m>>, he parked his van across the street from the Hudston house.'
          ],
          [
            1,
            'Timestr [23:20]: twenty past eleven',
            'Harvey looked at the clock, which marked <<twenty past eleven|10>>. "Then I\'ll sleep here till <<three|9c:1>> and catch the <<four o\'clock|6>> freight. They let us men from the Fleet ride free as a rule."'
          ],
          [
            1,
            'Timestr [23:22]: 11.22',
            'At <<11.22|9m>> he handed his ticket to a yawning guard and walked down a long flight of wooden steps to the car-park. A breeze lifted and dropped the leaves of a tree, and he thought of the girl with the blonde hair. His bicycle lay where he had left it.'
          ],
          [
            1,
            'Timestr [23:25]: 11.25 p.m.',
            '"OK, Estelle, I willl be at Nice Airport at <<11.25 p.m.|2a>> on Saturday, BA: Could you send the driver?"'
          ],
          [
            1,
            'Timestr [23:25]: eleven o\'clock and twenty-five minutes',
            "To test the intensity of the light whose nature and cause he could not determine, he took out his watch to see if he could make out the figures on the dial. They were plainly visible, and the hands indicated the hour of <<eleven o'clock and twenty-five minutes|14>>. At that moment the mysterious illumination suddenly flared to an intense, an almost blinding splendor\x{2026}"
          ],
          [
            1,
            'Timestr [23:26]: 11:26 p.m.',
            'Los Angeles. <<11:26 p.m.|2a>> In a dark red room- the color of the walls is close to that of raw liver- is a tall woman dressed cartoonishly in too-tight silk shorts, her breasts pulled up and pressed forward by the yellow blouse tied beneath them.'
          ],
          [
            1,
            'Timestr [23:27]: 23.27',
            'He tells his old friend the train times and they settle on the <<19.45|3c>> arriving at <<23.27|9c:1>>. "I\'ll book us into the ultra-luxurious Francis Drake Lodge. Running water in several rooms. Have you got a mobile?"'
          ],
          [
            -1,
            'Timestr [23:30]: 2330',
            'He loaded the player and turned on the viewer, his knees popping again as he squatted to set the cue to <<2330|99>>.'
          ],
          [
            1,
            'Timestr [23:30]: half past eleven',
            'He would catch the night bus for Casablanca, the one that left the beach at <<half past eleven|10>>.'
          ],
          [
            1,
            'Timestr [23:30]: half-past eleven',
            'The Picton boat was due to leave at <<half-past eleven|10>>. It was a beautiful night, mild, starry, only when they got out of the cab and started to walk down the Old Wharf that jutted out into the harbour, a faint wind blowing off the water ruffled under Fenella\'s hat, and she put up her hand to keep it on.'
          ],
          [
            1,
            'Timestr [23:30]: half past eleven',
            'The ship\'s clock in the bar says <<half past eleven|10>>. <<Half past eleven|10>> is opening time. The hands of the clock have stayed still at <<half past eleven|10>> for fifty years.'
          ],
          [
            1,
            'Timestr [23:31]: twenty-nine minutes to midnight',
            'It is <<twenty-nine minutes to midnight|10>>. Dr Narlikar\'s Nursing Home is running on a skeleton staff; there are many absentees, many employees who have preferred to celebrate the imminent birth of the nation, and will not assist tonight at the births of children.'
          ],
          [
            -1,
            'Timestr [23:32]: In about twenty-eight minutes it will be midnight',
            "\"This is the evening. This is the night. It is New Year\x{b4}s Eve. In about twenty-eight minutes it will be <<midnight|13>>. I still have twenty-eight minutes left. I have to recollect my thoughts. At <<twelve o\x{b4}clock|6>>, I should be done thinking.\" He looked at his father. \"Help those that are depressed and consider themselves lost in this world,\" he thought. \"Old fart.\""
          ],
          [
            1,
            'Timestr [23:32]: 11.32 pm',
            'And then it started to rain and I got wet and I started shivering because I was cold. And then it was <<11.32 pm|2a>> and I heard voices of people walking along the street. And a voice said, \'I don\'t care whether you thought it was funny or not,\' and it was a lady\'s voice.'
          ],
          [
            1,
            'Timestr [23:33]: twenty-seven minutes to midnight',
            'We are on Colaba Causeway now, just for a moment, to reveal that at <<twenty-seven minutes to midnight|10>>, the police are hunting for a dangerous criminal. His name: Joseph D\'Costa. The orderly is absent, has been absent for several days, from his work at the Nursing Home, from his room near the slaughterhouse, and from the life of a distraught virginal Mary'
          ],
          [
            1,
            'Timestr [23:34]: eleven thirty-four',
            '<<Eleven thirty-four|9j>>. We stand on the sidewalk in front of Jean\'s apartment on the Upper East Side. Her doorman eyes us warily and fills me with a nameless dread, his gaze piercing me from the lobby. A curtain of stars, miles of them, are scattered, glowing, across the sky and their multitude humbles me, which I have a hard time tolerating. She shrugs and nods after I say something about forms of anxiety. It\'s as if her mind is having a hard time communicating with her mouth, as if she is searching for a rational analysis of who I am, which is, of course, an impossibility: there ... is ... no ... key.'
          ],
          [
            1,
            'Timestr [23:34]: eleven thirty-four',
            'Reacher retrieved his G36 from under the saloon bar window at <<eleven thirty-four|5b>> precisely and set out to walk back on the road, which he figured would make the return trip faster.'
          ],
          [
            1,
            'Timestr [23:35]: eleven thirty-five',
            'Then at <<eleven thirty-five|5b>> the door at the rear of the hall opened and a police sergeant and three constables entered, ushered by Bagot.'
          ],
          [
            1,
            'Timestr [23:36]: 2336',
            'Then Green knocks at the front door at <<2336|5d>> - Gately has to Log the exact time and then it\'s his call whether to unlock the door.'
          ],
          [
            1,
            'Timestr [23:39]: 11.39',
            'There\'s a whisper down the line at <<11.39|3b>> When the Night Mail\'s ready to depart, Saying "Skimble where is Skimble has he gone to hunt the thimble? We must find him or the train can\'t start."'
          ],
          [
            1,
            'Timestr [23:40]: 11:40',
            'We all have the maps and appliances of various kinds that can be had. Professor Van Helsing and I are to leave by the <<11:40|2>> train tonight for Veresti, where we are to get a carriage to drive to the Borgo Pass. We are bringing a good deal of ready money, as we are to buy a carriage and horses.'
          ],
          [
            1,
            'Timestr [23:41]: 11:41',
            'In a little while his mind cleared, but his head ached, arms ached, body ached. The phosphorescent figures on his watch attracted his attention. He peered at them. The time was <<11:41|2>>. I remember...what do I remember?'
          ],
          [
            1,
            'Timestr [23:42]: 11.42',
            'At <<11.42|9m>> then the signal\'s nearly due And the passengers are frantic to a man- Then Skimble will appear and he\'ll saunter to the rear:'
          ],
          [
            1,
            'Timestr [23:43]: eleven forty-three',
            'The clock told him it was <<eleven forty-three|9f>> and in that moment, in a flash of illumination, Mungo understood what the numbers at the end of Moscow Centre\'s messages were'
          ],
          [
            1,
            'Timestr [23:44]: eleven forty-four',
            "'At <<eleven forty-four|9e>> last night somebody stabbed this girl in the neck with a kitchen knife and immediately thereafter plunged the same knife through her skull, where it remained.\x{2019}"
          ],
          [
            1,
            'Timestr [23:45]: three quarters past eleven',
            'The church clocks chimed <<three quarters past eleven|10>>, as two figures emerged on London Bridge. <<One|9i:0>>, which advanced with a swift and rapid step, was that of a woman who looked eagerly about her as though in quest of some expected object; the other figure was that of a man...'
          ],
          [
            1,
            'Timestr [23:45]: quarter to twelve',
            'We struck the tow-path at length, and that made us happy because prior to this we had not been sure whether we were walking towards the river or away from it, and when you are tired and want to go to bed, uncertainties like that worry you. We passed Shiplake as the clock was striking the <<quarter to twelve|10>> and then George said thoughtfully: \'You don\'t happen to remember which of the islands it was, do you?\''
          ],
          [
            1,
            'Timestr [23:46]: 11:46 p.m.',
            'In the Kismet Lounge, Mr. Early sees suddenly to his horror it\'s <<11:46 p.m.|2a>> He\'s been in this place far longer than he\'d planned, and he\'s had more to drink than he\'d planned. Shame! What if, back at the E-Z, his little girl is crying piteously for him?'
          ],
          [
            1,
            'Timestr [23:47]: thirteen minutes to midnight',
            'If he had glanced at his watch, he would have seen that it was <<thirteen minutes to midnight|10>>. And if he had been interested in what was going on, he would have heard the voices and bawling of terrified men.'
          ],
          [
            1,
            'Timestr [23:48]: 11.48pm',
            'Littell arranged a private charter.He told the pilot to fly balls-to-the-wall.The little two-seater rattled and shook-Kemper couldn\'t believe it. It was <<11.48pm|2a>>. They were thirty-six hours short of GO.'
          ],
          [
            1,
            'Timestr [23:49]: eleven minutes to midnight',
            'Tom shrugged. He pushed his pinkish ruffled sleeve back, and saw that it was <<eleven minutes to midnight|10>>. Tom finished his coffee.'
          ],
          [
            1,
            'Timestr [23:50]: 11.50pm',
            'At <<11.50pm|2a>>, I got up extremely quietly, took my things from under the bed, and opened the door one millimeter at a time, so it wouldn\'t make any noise.'
          ],
          [
            1,
            'Timestr [23:51]: eleven-fifty-one',
            '"Due at Waterloo at <<eleven-fifty-one|5d>>," panted Smith."That gives us thirty-nine minutes to get to the other side of the river and reach his hotel."'
          ],
          [
            1,
            'Timestr [23:52]: eight minutes to midnight',
            'It was <<eight minutes to midnight|10>>. Just nice time, I said to myself. Indoors, everything was quiet and in darkness. Splendid. I went to the bar and fetched a tumbler, a siphon of soda and a bottle of Glen Grant, took a weak drink and a pill, and settled down in the public dining-room to wait the remaining two minutes.'
          ],
          [
            1,
            'Timestr [23:53]: 7 minutes to midnight',
            'It was <<7 minutes to midnight|10>>. The dog was lying on the grass in the middle of the lawn in front of Mrs. Shears\' house.'
          ],
          [
            1,
            'Timestr [23:54]: 11.54pm',
            'His watch read <<11.54pm|2a>> Eastern Standard Time. Already it was <<nearly 6.00am|2a>> in Rome. He had left a city frozen by a harsh January storm, after a bleak, wet Christmas season.'
          ],
          [
            1,
            'Timestr [23:55]: five minutes to midnight',
            '"I am going to lock you in. It is-" he consulted his watch, "<<five minutes to midnight|10>>. Miss Granger, three turns should do it. Good luck."'
          ],
          [
            1,
            'Timestr [23:55]: five minutes to twelve',
            'I looked at my watch. It wanted <<five minutes to twelve|10>>, when the premonitory symptoms of the working of the laudanum first showed themselves to me. At this time, no unpractised eyes would have detected any change in him. But, as the minutes of the new morning wore away, the swiftly-subtle progress of the influence began to show itself more plainly. The sublime intoxication of opium gleamed in his eyes; the dew of a stealthy perspiration began to glisten on his face. In five minutes more, the talk which he still kept up with me, failed in coherence.'
          ],
          [
            1,
            'Timestr [23:56]: four minutes to midnight',
            'The human race is at the end of the line, the doomsday clock ticks on. It\'s stopped for a decade at <<four minutes to midnight|10>>, but there the hands still stand. Any minute now they\'ll begin to move again.'
          ],
          [
            1,
            'Timestr [23:57]: eleven fifty-seven',
            'Wells looked out at the street. "What time is it?" he said. Chigurh raised his wrist and looked at his watch. "<<Eleven fifty-seven|9j>>" he said. Wells nodded. By the old woman\'s calendar I\'ve got three more minutes.'
          ],
          [
            1,
            'Timestr [23:58]: one minute and seventeen seconds before midnight',
            'Humans emerge <<one minute and seventeen seconds before midnight|10>>. The whole of our recorded history, on this scale, would be no more than a few seconds, a single human lifetime barely an instant.'
          ],
          [
            1,
            'Timestr [23:59]: A minute to midnight',
            'At <<a minute to midnight|10>>, Roquenton was holding his wife\'s hand and giving her some last words of advice. On the stroke of <<midnight|12>>, she felt her companion\'s hand melt away inside her own.'
          ],
          [
            -1,
            'Timestr [23:59]: new day was still a minute away',
            'Chigurgh rose and picked up the empty casing off the rug and blew into it and put it in his pocket and looked at his watch. The <<new day was still a minute away|99>>.'
          ]
        ];
}
