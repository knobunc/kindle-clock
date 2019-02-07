package TimeMatch;

use Modern::Perl '2017';

use utf8;

use Exporter::Easy (
  EXPORT => [ qw( do_match strip_match extract_times shorten_book DEBUG_MSG ) ],
);

use Carp;
use Data::Dumper;
use Lingua::EN::Words2Nums;
use Time::HiRes qw( gettimeofday tv_interval );

# Punctuation
my $ellips         = qr{ … | ((\x{a0}|\x{200b})[.]){3} | [.]{3,6} }xin;      # Ellipsis
my $phrase_punc    = qr{ [.;:?!,] | $ellips   }xin;                          # Phrase delimiter
my $phrase_punc_nc = qr{ [.;:?!]  | $ellips   }xin;                          # Same, but with no comma
my $sq             = qr{ ['‘’´]               }xin;                          # Single quote
my $aq             = qr{ ['"‘’“”]             }xin;                          # All quotes
my $hy             = qr{ \p{Format}* \p{Dash_Punctuation} \p{Format}* }xin;  # Hyphens

# Times of day
my $morn_re    = qr{ ( (late | early) \s+)?
                     ( morn(ing)? | mornin $sq? | after($hy|\s)?noon | eve(ning)? )
                   }xin;
my $timeday_re = qr{ ( $morn_re | day | night )
                     (?! \s+ ( dress | clothes ) )
                   }xin;

# Special named times
my $noon_re     = qr{ ( ( twelve | 12 | high ) \s+ )? noon ($hy? (day | time | tide) )?
                    | mid($hy|\s)*day
                    }xin;
my $midnight_re = qr{ ( (twelve | 12 ) \s+ )? midnight (?! \s+ oil ) }xin;
my $ecclesiastical_re =
    qr{ # Ecclesiastical times -- https://en.wikipedia.org/wiki/Liturgy_of_the_Hours
        # Prime and Nones are handled specially
        matins  | lauds    | terce    | sext
      | vespers | evensong | compline | vigils     | nocturns
      | night \s+ office
      | ( dawn | early \s+ morning | mid $hy morning | mid $hy? day
        | mid $hy afternoon | evening | night
        )
        \s+ prayer
      }xin;
my $meal_times = qr{ ( second \s+ )? breakfast
                   | luncheon | lunch
                   | ( ( afternoon | high ) \s+ )? tea
                   | dinner
                   | supper
                   | elevenses
                   }xin;
my $all_named_times = qr{ $ecclesiastical_re | prime | nones
                        | $meal_times
                        }xin;
my $midnight_noon_re = qr{ $noon_re | $midnight_re | $ecclesiastical_re | elevenses }xin;

# Numbers 1-9 as words
my $low_num_re   = qr{ one | two | three | four | five | six | seven | eight | nine }xi;
my $z_low_num_re = qr{ $low_num_re | zero | oh | niner }xin;

# The hours 1-12 as words
my $hour12_word_re = qr{ $low_num_re | ten | eleven | twelve | $midnight_noon_re }xi;
my $hour_word_re   = $hour12_word_re;

# The hours 13-24 as words
my $hour_h_word_re = qr{ thirteen | fourteen | fifteen
                       | sixteen | seventeen | eighteen | nineteen
                       | twenty ( $hy ( one | two | three | four ) )?
                       }xin;
my $hour24_word_re = qr{ $hour_word_re | $hour_h_word_re }xin;

my $fraction_re = qr{ quarter | 1/4
                    | third   | 1/3
                    | half    | 1/2
                    | third ($hy | \s)+ quarter | three ($hy | \s)+ quarters | 3/4
                    }xin;

my $before_re = qr{ before | to | of | till | $sq til | short \s+ of }xin;
my $after_re  = qr{ after | past }xin;
my $till_re   = qr{ $before_re | $after_re }xin;

# TODO Add 'only', 'just' to twas_re?
my $twas_re = qr{ ( it | time | which ) \s+ ( is ( \s+ now )? | was | will \s+ be )
                | $sq? ( twas | tis ( \s+ now )? | till | twill \s+ be )
                | it $sq s ( \s+ now )?
                }xin;

my $today_re = qr{ to $hy? ( night | day | morrow ) }xin;

my $clock_re  = qr{ ( clock | bell | watch | hands | alarm ) s? }xin;
my $strike_re = qr{ struck  | strikes | striking | strike | striketh
                  | chimed  | chimes  | chiming
                  | rung    | rings   | ringing
                  | beat    | beats   | beating
                  }xin;
my $points_re = qr{ said    | says    | showed | shows
                  | read    | reads   | reading
                  | drew
                  | ( point s? | pointed | pointing ) \s+ to
                  }xin;



# The minutes
my $min_word_re =
    qr{ # 1-9
        ( oh ($hy | \s) | \b )? $low_num_re
        | # 10-19
        ( ten | eleven | twelve | thirteen | fourteen | fifteen |
            sixteen | seventeen | eighteen | nineteen )
        | # 20-59
        ( twenty | thirty | forty | fifty ) ( ( $hy | \s+ | \s* $ellips \s* ) $low_num_re )?
      }xin;
my $sec_word_re = $min_word_re;

# Hour digits
my $hour_dig_re     = qr{ [01]?\d | 2[0-4] }xin;       # 0 or 00-24
my $hour0_dig_re    = qr{ [01]\d  | 2[0-4] }xin;       # 00-24
my $hour12_dig_re   = qr{ [1-9] | 1[0-2] }xin;         # 1-12
my $hour24nz_dig_re = qr{ 0?[1-9] | 1\d | 2[0-4] }xin; # 1 or 01-24
my $hour_h_dig_re   = qr{ 1[3-9] | 2[0-4] }xin;        # 13-24
my $hour24_dig_re   = $hour_dig_re;

# Min / sec digits
my $minsec_dig_re  = qr{ [0-5]?\d | 60 }xin;
my $minsec0_dig_re = qr{ [0-5]\d | 60 }xin;

# The minutes / seconds as words or numbers
my $min_re = qr{ $minsec_dig_re | $min_word_re }xin;
my $min0_re = qr{ $minsec0_dig_re | $min_word_re }xin;
my $sec_re = $min_re;

# The hours as words or numbers
my $hour_re   = qr{ $hour24_dig_re | $hour12_word_re }xin;
my $hour12_re = qr{ $hour12_dig_re | $hour12_word_re }xin;
my $hour24_re = qr{ $hour24_dig_re | $hour24_word_re }xin;
my $hour_h_re = qr{ $hour_h_dig_re | $hour_h_word_re }xin; # The high hours 13-24

# The am / pm permutations
my $am_re = qr{ am \b | a[.] \s* m[.]? | ayem       }xin;
my $pm_re = qr{ pm \b | p[.] \s* m[.]? | pee \s+ em }xin;
my $ampm_only_re = qr{ $am_re | $pm_re }xin;
my $in_the_re = qr{ ( ( in \s+ the \s+ ( (?! same) \w+ \s+ ){0,4}?
                      | ( this | that ) \s+ ( \w+ \s+ ){0,2}?
                      | $hy \s* (?!day|night)                         # Don't match five-day
                      )
                      $timeday_re
                    | ( in  \s+ the \s+
                      | ( this | that ) \s+
                      )
                      $ampm_only_re                                  # in the am
                    | of \s+ the \s+ (afternoon | morning )          # of the afternoon
                    | at \s+ ( dawn | dusk | night | sunset | sunrise )
                    )
                  }xin;
my $ampm_re = qr{ $ampm_only_re | $in_the_re }xin;
my $ampm_ph_re = qr{ [:,]? \s* $ampm_re }xin;

# Oclocks
my $oclock_re = qr{ o( $sq \s* | f \s+ the \s+ | $hy )? clock s? }xin;

# Boundary before and after
my $bb_re = qr{ (?<=     [—"'(‘’“”\s[] ) | \A }xin;
my $ba_re = qr{ \b | (?= [—/"'‘’“”\s…,:;?.] ) | \z }xin;

# Match stuff from the start of the string to here.
# This must be matched and included in the results
my $not_in_match    = qr{ [—…,:;?/""''‘’“”\s([]+                                        (*SKIP)
                        | \A      (\p{Format}* \p{Dash_Punctuation} \p{Format}* | [.])* (*SKIP)
                        | [^\d\w] (\p{Format}* \p{Dash_Punctuation} \p{Format}* | [.])+ (*SKIP)
                        }xin;

# Relative words
my $far_re          = qr{ well    | long                }xin;
my $short_re        = qr{ shortly | just | a \s+ little }xin;

my $far_before_re   = qr{   $far_re   \s+    before
                        |   far ($hy|\s)+ ( from | off )
                        }xin;
my $short_before_re = qr{   $short_re \s+    before
                        |   nearly
                        |   near ( \s+ on )?
                        |   towards?
                        |   lacks \s+ of
                        |   almost ( \s ( gone | at | to ) )?
                        |   just \s+ ($sq|a)bout
                        |   can $sq t \s+ be \s+ $far_before_re
                        }xin;
my $around_re       = qr{ ( near \s+ )? ($sq|a)bout
                        | ($sq|ap)proximately
                        | ($sq|a)?round
                        }xin;
my $on_or_after_re  = qr{ ( $short_re \s+ )? gone }xin;
my $far_after_re    = qr{   $far_re   \s+    after      }xin;
my $short_after_re  = qr{ ( $short_re \s+ )? ( after | past )
                        | can $sq t \s+ be \s+ $far_after_re
                        }xin;

# my $rel_words       = qr{ $far_before_re | $short_before_re
#                        | $around_re
#                        | $on_or_after_re
#                        | $far_after_re  | $short_after_re
#                        }xin;

# This is equivalent to the above but needs to be done this way to optimize it for speed
my $rel_words       = qr{ ( well | long) \s+ ( before | after )
                        | far ($hy|\s)+ ( from | off )

                        | ( shortly | just | a \s+ little ) \s+ ( before | gone | after | past )
                        | gone | after | past

                        | can $sq t \s+ be \s+ ( $far_before_re | $far_after_re )

                        | nearly
                        | near ( \s+ on )?
                        | towards?
                        | lacks \s+ of
                        | almost ( \s ( gone | at | to ) )?
                        | just \s+ ($sq|a)bout

                        | ( near \s+ )? ($sq|a)bout
                        | ($sq|ap)proximately
                        | ($sq|a)?round

                        }xin;

my $at_words        = qr{ until | at }xin;
my $rel_at_words    = qr{ $at_words | $rel_words | before }xin;

# Weekdays
my $weekday_re = qr{ monday | tuesday | wednesday | thursday | friday | saturday | sunday }xin;

# Bible books
my $bible_book_re = qr{ Acts | Amos | Baruch | [12] \s+ Chronicles | Colossians
                      | [12] \s+ Corinthians | Daniel | Deuteroronomy | Ecclesiastes
                      | Ephesians | Esther | Exodus | Ezekiel | Ezra | Galatians
                      | Genesis | Habakkuk | Haggai | Hebrews | Hosea | Isaiah
                      | James | Jeremiah | Job | Joel | John | [123] \s+ John
                      | Jonah | Joshua | Jude | Judges | Judith | [12] \s+ Kings
                      | Lamentations | Leviticus | Luke | [12] \s+ Maccabees
                      | Malachi | Mark | Matthew | Micah | Nahum | Numbers | Obadiah
                      | [12] \s+ Peter | Philemon | Philippians | Proverbs | Psalms
                      | Revelation | Romans | Ruth | [12] \s+ Samuel | Sirach
                      | Solomon | [12] \s+ Thessalonians | [12] \s+ Timothy
                      | Titus | Tobit | Wisdom | Zechariah | Zephaniah
                      | ( Gen  | Ge   | Gn
                        | Ex   | Exod
                        | Lev  | Le   | Lv
                        | Num  | Nu   | Nm | Nb
                        | Deut | De   | Dt
                        | Josh | Jos  | Jsh
                        | Judg | Jdg  | Jg | Jdgs
                        | Ruth | Rth  | Ru
                        | [12] \s* (Sam | Sm  | Sa | S)
                        | [12] \s* (Kgs | Kin | Ki)
                        | [12] \s* (Chr | Ch  | Chron)
                        | Ezra | Ezr  | Ez
                        | Neh  | Ne
                        | Tob
                        | Jdt
                        | Esth | Est | Es
                        | [12] \s* Macc
                        | Job  | Jb
                        | Ps   | Psalm | Pslm | Psa | Psm
                        | Prov | Pro   | Prv  | Pr
                        | Ecc1 | Eccles | Eccle | Ecc | Ec
                        | Song
                        | Cant
                        | Wis
                        | Sir
                        | Isa  | Is
                        | Jer  | Je    | Jr
                        | Lam  | La
                        | Bar
                        | Ezek | Eze   | Ezk
                        | Dan  | Da    | Dn
                        | Hos  | Ho
                        | Joel | Jl
                        | Am
                        | Jon  | Jnh
                        | Mic  | Mc
                        | Nah  | Na
                        | Hab
                        | Zeph | Zep  | Zp
                        | Hag  | Hg
                        | Zech | Zec  | Zc
                        | Mal  | Ml
                        | Mt   | Matt
                        | Mk   | Mrk
                        | Lk   | Luk
                        | Jn   | Jhn
                        | Acts
                        | Rom  | Ro   | Rm
                        | [12] \s* (Cor | Co)
                        | Gal  | Ga
                        | Eph  | Ephes
                        | Phil | Php  | Pp
                        | Col
                        | [12] \s* (Thess | Thes | Th)
                        | [12] \s* (Tim | Ti)
                        | Tit    | Ti
                        | Philem | Phm | Pm
                        | Heb
                        | Jas    | Jm
                        | [12] \s* (Pet | Pe | Pt | P)
                        | [123] \s* (Jn | Jhn | J)
                        | Jud    | Jd
                        | Rev
                        | Apoc
                        ) \.
                      }xin;

# The states, short and long
my $state_re = qr{
                   Alabama            | AL
                 | Alaska             | AK
                 | Arizona            | AZ
                 | Arkansas           | AR
                 | California         | CA
                 | Colorado           | CO
                 | Connecticut        | CT
                 | Delaware           | DE
                 | Florida            | FL
                 | Georgia            | GA
                 | Hawaii             | HI
                 | Idaho              | ID
                 | Illinois           | IL
                 | Indiana            | IN
                 | Iowa               | IA
                 | Kansas             | KS
                 | Kentucky           | KY
                 | Louisiana          | LA
                 | Maine              | ME
                 | Maryland           | MD
                 | Massachusetts      | MA
                 | Michigan           | MI
                 | Minnesota          | MN
                 | Mississippi        | MS
                 | Missouri           | MO
                 | Montana            | MT
                 | Nebraska           | NE
                 | Nevada             | NV
                 | New \s+ Hampshire  | NH | N\. \s* H\.
                 | New \s+ Jersey     | NJ | N\. \s* J\.
                 | New \s+ Mexico     | NM | N\. \s* M\.
                 | New \s+ York       | NY | N\. \s* Y\.
                 | North \s+ Carolina | NC | N\. \s* C\.
                 | North \s+ Dakota   | ND | N\. \s* D\.
                 | Ohio               | OH
                 | Oklahoma           | OK
                 | Oregon             | OR
                 | Pennsylvania       | PA
                 | Rhode \s+ Island   | RI | R\. \s* I\.
                 | South \s+ Carolina | SC | S\. \s* C\.
                 | South \s+ Dakota   | SD | S\. \s* D\.
                 | Tennessee          | TN
                 | Texas              | TX
                 | Utah               | UT
                 | Vermont            | VT
                 | Virginia           | VA
                 | Washington         | WA
                 | West \s+ Virginia  | WV | W\. \s* V\.
                 | Wisconsin          | WI
                 | Wyoming            | WY
                   # Commonwealth and Territories
                 | American \s+ Samoa                         | AS | A\. \s* S\.
                 | District \s+ of \s+ Columbia               | DC | D\. \s* C\.
                 | Federated \s+ States \s+ of \s+ Micronesia | FM
                 | Guam                                       | GU
                 | Marshall \s+ Islands                       | MH | M. \s* I\.
                 | Northern \s+ Mariana \s+ Islands           | MP
                 | Palau                                      | PW
                 | Puerto \s+ Rico                            | PR | P\. \s* R\.
                 | Virgin \s+ Islands                         | VI | V\. \s* I\.
}xin;

# Parts of speech
my $pronoun_re = qr{ me | my | your | their | his | her | our }xin;

# The months
my $month_re = qr{ January | February | March | April | May | June
                 | July | August | September | October | November | December
                 | (Jan | Feb | Mar | Apr | May | Jun | Jul | Aug | Sep | Sept | Oct | Nov | Dec ) \.?
                 }xin;
my $special_day_re = qr{ Christmas | Easter | New \s+ Year s? }xin;

# Time periods
my $some_time_periods_re = qr{ ( year | month | week | hour | half | minute ) s? }xin;
my $time_periods_re      = qr{ ( day | night | second ) s? | $some_time_periods_re}xin;

# Things that never follow times
my $never_follow_times_exp_re =
    qr{ ( ( or \s+ $min_re
          | to \s+ the
          ) \s+
        )?
        ( $min_re $hy )?                                    # Things like six-inch
        ( $hy   \d+   )?                                    # 400-600F
        ( \s+ (and|or|to) \s+ \d+ )?                        # 400 or 500 miles

        ( and \s+ a \s+ (half | quarter | third) \s+ (to \s+ $low_num_re \s+)?
        | \d+ / \d+ \s+
        )?   # Two and a half centuries, 9 1/2 inches
        ( # SI prefixes
          ( milli | centi | kilo | mega | giga ) $hy?
        )?

        ( point | time | moment | instant | end | stage | who
        | heartbeat | generation | color
        | since
        | degrees | [°º] [FCK]?
        | per\s*cent | %
        | cm | meter | km | klick | mm | acre
        | metre | watt | sol | au
        | mph | \Qm.p.h.\E | kmh | k?m/s | millisecond | ms | volt | v | amp | decibel | hertz | carat
        | gauss | gev | electron \s+ volts | ev | joule | parsec
        | inch | inches | foot | feet | ft | yard | yd
        | ( ( English | American | nautical | imperial | terrestrial | mortal) \s+)? mile
        | mi | knot | kt | block
        | pound | lb | kg | kilo | ton | tonne | gram | ounce | oz
        | cup | pint | quart | gallon
        | tablespoon | tbsp | teaspoon | tsp
        | gravities | gravity | g $sq? s | gee
        | cubic | square
        | ( hundred | thousand | million | billion ) (th)?
        | dozen | score | gross | grand
        | ( \w+ \s+)? ( $some_time_periods_re | days ) | (full | a) \s+ day
        | (light (\s+|$hy))? $time_periods_re
        | final | false | true
        | (cosmological \s+)? (century | centuries | decade | millenium | millenia)
        | third | half | halve | quarter | fourth | fifth | sixth | seventh | eighth | nineth | tenth
        | dollar | buck | cent | pound | quid | bob
        | $(\d+,)*\d+(\.\d+)
        | shilling | guinea | penny | pennies | yuan | galleon | crown
        | and \s+ sixpence
        | kid | children | man | men | woman | women | girl | boy | male | female
        | family | families | person | people
        | round | turn   | line
        | book  | volume | plate | illustration | page | chapter | verse | psalm | word
        | shell | bullet | odd
        | side  | edge   | corner | face
        | Minister
        | possibilities | against | vote | machine | box | part | piece
        | on \s+ the \s+ field
        | ( tb | gb | mb | kb ) (p)? | baud
        | odds | more
        | AD | CE | BC | BCE | A\.D\. | C\.E\. | B\.C\. | B\.C\.E\. | B \s+ C | A \s+ D
        | giant | tiny | large | small | layer
        | of \s+ them
        | step | pace | place
        )
        s?
      | [.,] \d
      }xin;
my $never_follow_times_re = qr{ ($hy|\s)* $never_follow_times_exp_re $ba_re }xin;

my $screen_times_re = qr{ \b ( $hour24_re
                             | $all_named_times \b
                             | ( new | next ) \s+ (?<hr> day) \s+
                             ) }xin;

# Set the variables used in the regexes
my $branch      = "x";
my $is_timey    = 0;
my $is_racing   = 0;
my $is_trainy   = 0;
my $is_pricey   = 0;
my $is_agey     = 0;
my $last_masked = 0;
my $last_timey  = 0;
my $author      = undef;
my $book        = undef;
my @parts;

sub do_match {
    (my ($line, $raw), $author, $book, my $timing) = @_;
    $author //= '';
    $book   //= '';

    ## Shortcircuit if it just has a number in the line
    # e.g "Twenty-one" since these are probably chapters
    if ($line =~ m{ \A [\n\s]* $min_word_re ( ($hy|\s)+ $low_num_re )? [\n\s]* \z }xin) {
        return $line;
    }

    ## Shortcircuit unless it has something that might be part of a time in it
    if ($line !~ $screen_times_re) {
    return $line;
    }

    ## Does this look like a "timey" paragraph
    $is_timey = 0;
    $is_timey = 1
        if $line =~
            m{ \b ( struck   | strikes | striking | striketh
                  | ( hour   | minute
                    | clock | watch
                    | train
                    ) s?
                  | $midnight_noon_re
                  | ( $twas_re | at | what ) \s+ time
                  | ( there | here ) \s+ from
#                  | ( return | returned | back ) \s* $rel_at_words
                  | reported | reports
                  | station ($hy master)?
                  | (starts | starting | begins | commences) \s+ at
                  ) \b
             }xin;

    ## Does this look like a "racing" paragraph?  If so, then times of the form "ten to one"
    # are probably not times
    $is_racing = 0;
    $is_racing = 1
        if $line =~
            m{ \b ( colts? | filly | fillies | stallions?
                  | odds \s+ (at | of) | betting
                  | interest | ratio | advantage | superiority | proportion | outnumbered
                  | back \s+ (him | her | it)
                  | give \s+ (you | odds)
                  | (good | bad | the) \s+ odds
                  | on \s+ the \s+ field
                  | come \s+ in \s+ (\w+ \s+)? at
                  ) \b
             }xin;

    ## Does this look like a train paragraph?  If so, then times of the form 'eleven-five'
    # are okay
    $is_trainy = 0;
    $is_trainy = 1
        if $line =~
            m{ \b ( train | station | night \s+ mail
                  | Waterloo
                  ) \b
             }xin;

    ## Does this look like a price paragraph?
    $is_pricey = 0;
    $is_pricey = 0 # XXX
        if $line =~
            m{ \b ( cost | price | cheap | amount ) \b
             }xin;

    ## Does this look like an age paragraph
    $is_agey = 0;
    $is_agey = 1
        if $line =~
            m{ \b (young | small) \s+ (girl | boy | child | teen) \b
             | \b so \s+ (young | small) \b
             }xin;

    ## Mask out some patterns and apply them first
    my ($masks) = get_masks();

    ## Get the matches and apply them
    my ($matches) = get_matches();

    # The masked regex
    my $masked_re = qr{<< ( [^|>]+ ) [|] [yx] \d+\w?  (:TIMEY)? >>}xi;
    my $timey_re  = qr{<< ( [^|>]+ ) [|]     (\d+ \w?) :TIMEY   >>}xi;

    # Apply the matches and separate them into parts if they match
    @parts = ([0, $line]);
    foreach my $r (@$masks, @$matches) {
        my $r_name = $timing ? get_re_name($r) : undef;

        my @new;
        foreach my $p (@parts) {
            my ($matched, $part, $part_masked, $part_timey) = @$p;
            if (not $matched) {
                while ($part ne '') {
                    # Work out if we are following on from a masked >>
                    $last_masked = 0;
                    $last_timey  = 0;
                    if (@new) {
                        # We have a previous item and it had >>s
                        $last_masked = $new[-1][2] ? 1 : 0;
                        $last_timey  = $new[-1][3] ? 1 : 0;
                    }

                    # Start the timing if desired
                    my $re_start = $timing ? [ gettimeofday() ] : undef;

                    # Do the match
                    if ($part =~ m{$r}p and $branch ne 'xx') {
                        ## We matched

                        # Update the timing
                        if ($timing) {
                            my $re_time = tv_interval($re_start);
                            $timing->{$r_name}{count}++;
                            $timing->{$r_name}{time} += $re_time;
                            $timing->{$r_name}{hits} += 1;
                        }

                        # Handle the match
                        my $match =
                                sprintf("%s<<%s%s|%s>>%s",
                                    map { defined ? $_ : "" }
                                    $+{pr}, $+{t1}, $+{t2}, $branch, $+{po});
                        my ($leadin, $leadout) = map { defined ? $_ : "" } ($+{li}, $+{lo});

                        my $pre = ${^PREMATCH} . $leadin;
                        $part = $leadout . ${^POSTMATCH};

                        # See if this match was timey or masked
                        my $was_timey  = $match =~ $timey_re  ? 1 : 0;
                        my $was_masked = $match =~ $masked_re ? 1 : 0;

                        push @new, [0, $pre, 0, 0],
                                   [1, $match, $was_masked, $was_timey];
                    }
                    else {
                        ## We did not match

                        # Update the timing
                        if ($timing) {
                            my $re_time = tv_interval($re_start);
                            $timing->{$r_name}{count}++;
                            $timing->{$r_name}{time} += $re_time;
                        }

                        # Handle the miss
                        push @new, [0, $part, 0, 0];
                        $part = '';
                    }
                }
            }
            else {
                # We have a <<>> in this part, no need to re-match
                push @new, $p;
            }
        }
        @parts = @new;
    }

    # Put all the parts back together
    $line = join '', map { $_->[1] } @parts;

    ## Fixups
    # Change TIMEY to $is_timey's value
    $line =~ s{$timey_re}{<<$1|$2:$is_timey>>}xg;

    # Get absolute words out
    $line =~ s{<< ( ( at | by | until ) \s+ )}{$1<<}xgi;

    # Undo the masks (unmask)
    $line =~ s{$masked_re}{$1}g
        unless $raw;

    ## Relative matches
    # These are relative to other time strings
    $line =~ s{\b (?<pr> ( from | between | at ) \s+ )
                  (?<t1> $hour_re ( \s+ $min_re )? )
                  (?<po> \s+ ( or | and | until ) \s+
                         << ([^|>]+) [|] \d+ \w? (?<timey> (:\d)? ) >>
                  )
              }{$+{pr}<<$+{t1}|90$+{timey}>>$+{po}}xing;

    $line =~ s{ (?<pr> << ([^|>]+) [|] \d+ \w? (?<timey> (:\d)? ) >>
                       \s+ ( or | and ) \s+
                )
                (?<t1> $hour_re ( ($hy | \s)+ $min_re )?
                  (?! $never_follow_times_re | \s+ to )
                )
                (?<po> $ba_re )
              }{$+{pr}<<$+{t1}|91$+{timey}>>$+{po}}xing;

    return $line;
}

sub get_re_name {
    my ($re) = @_;

    state %re_name;

    return $re_name{$re} if $re_name{$re};

    if ($re =~ m{\$branch \s* = \s* " (?<branch> [^"]+) ";}xin) {
        $re_name{$re} = $+{branch};
        return $re_name{$re};
    }

    die "Unable to extract branch from re: $re";
}

sub get_masks {
    state @r;
    return(\@r)
        if @r;

    # Take out compound numbers, times never look like:
    # 12,000
    # 14.000
    push @r,qr{ $bb_re
                (?<t1> ( \d{1,3} ( [,] \d{3} )+
                       | \d{1,3} ( [.] \d{3} )+
                       )
                )
                $ba_re
                (?{ $branch = "x1"; })
              }xin;

    # odds of five to one
    # the three of one
    # add 1 to 19
    push @r,qr{ $bb_re
                (?<pr>
                 ( ( odds | betting | bets? | ratio ) ( \s+ ( of | being | at ) )? ( \s+ $rel_words )?
                 | got | get | numbers? ( \s+ from )?
                 | the | offered | add | subract | multiply | divide | change
                 ) \s+
                )
                (?<t1> $min_re \s+ ( to | of ) \s+ $min_re )
                (?! $ampm_ph_re)
                \b
                (?{ $branch = "x2"; $is_racing = 1; })
              }xin;

    # five to one against
    push @r,qr{ $bb_re
                (?<t1> $min_re ($hy|\s)+ ( to | of ) ($hy|\s)+ $min_re )
                (?<po>
                 \s+ ( against | on \s+ the \s+ field )
                )
                \b
                (?{ $branch = "x02"; $is_racing = 1; })
              }xin;

    # one's, the only one
    push @r,qr{ \b
                (?<t1>
                  one $sq s
                | the \s+ ( only | last | first | final | ultimate ) \s+ one
                | saw \s+ one
                | fallen \s+ one
                | ( was | were | are | will \s+ be ) \s+ ( at | as ) \s+ one
                | one ($hy|\s)+ to ($hy|\s)+ one
                | one \s+ other
                | from \s+ one \s+ and \s+ (sometimes \s+)? from \s+ another
                | one \s+ and \s+ the \s+ same
                | ( no | this ) \s+ one (?! $ampm_ph_re | \s+ $oclock_re )
                | ( an \s+ hour | a \s+ (second|minute) ) \s+ or \s+ two
                | $min_re \s+ to \s+ the \s+ (\w | $hy)+ \s+ power
                )
                \b
                (?{ $branch = "x3"; })
              }xin;

    # I was one of twenty
    # two by two
    # I, for one, am sick of it.
    # nine-to-five
    # ten-four
    # nineteen and six (old British currency)
    push @r,qr{ (?<pr> $bb_re )
                (?<t1> one \s+ of \s+ $min_re
                |      $min_re ,? \s+ by \s+ $min_re
                |      I ,? \s+ for \s+ one ,? \s+ am
                |      nine ($hy|\s)+ to ($hy|\s)+ five
                |      ten $hy four
                |      $min_word_re ($hy|\s)+ and ($hy|\s)+ six
                )
                (?! [:,]? \s* $ampm_only_re
                |   \s* $oclock_re
                )
                \b
                (?{ $branch = "x4"; })
              }xin;

    # Bible quotes
    push @r,qr{ (?<pr> \b (?<bb> $bible_book_re ) ,? \s+ )
                (?<t1>
                     \d+ : \d+ ( $hy \d+ ( : \d+ )? )?
                | \( \d+ : \d+ ( $hy \d+ ( : \d+ )? )? \)
                | \[ \d+ : \d+ ( $hy \d+ ( : \d+ )? )? \]
                | (?<wb> $min_word_re ($hy|\s)+ $min_word_re )
                | [cxvli]+ \.? \s+ \d+ (\. \d+)?
                | \d+ (\. \d+)?
                )
                (?{ $branch = "x5";
                    my ($bb, $wb) = ($+{bb}, $+{wb});
                    if ($bb !~ m{^([12] \s+)? [A-Z]}xin or
                        ($bb =~ m{^\w+ \. }xin and $wb))
                    {
                        # Bible books must start with a capital letter
                        # Or if they have spelled out verses, must not be abbreviated
                        $branch = "xx";
                    }
                  })
              }xin;

    # age of twenty-four, aged twenty-four
    push @r,qr{ (?<pr> \s+ ( age \s+ of | aged | (he | she | I) \s+ (was | am) ) \s+ )
                (?<t1>
                  $min_word_re ( ($hy|\s)+ $low_num_re )?
                  ( \s+ ( or | to ) \s
                   $min_word_re ( ($hy|\s)+ $low_num_re )?
                  )?
                )
                \b
                (?{ $branch = "x6"; })
              }xin;

    # months or special days followed by years, dates
    push @r,qr{ \b
                (?<t1> \d+ ( \. \d+ ){2,}+
                | \d+ \s+ $month_re ( \s+ \d+ ((\s* $hy \s* | , \s+) \d+)? )? (?! ($hy | [:.]) \d )
                | $month_re \s+ \d+           ((\s* $hy \s* | , \s+) \d+)?    (?! ($hy | [:.]) \d )
                )
                $ba_re
                (?{ $branch = "x7a"; })
              }xin;
    push @r,qr{ (?<pr> ( $month_re | $special_day_re )[,]? \s+ )
                (?<t1> \d{4} )
                (?! $ampm_ph_re)
                \b
                (?{ $branch = "x7"; })
              }xin;

    # Dates that are of the form 12-12-32
    push @r,qr{ (?<pr> $bb_re )
                (?<t1> \d{1,2} $hy \d{1,2} $hy \d{2,4} )
                (?! $ampm_ph_re)
                $ba_re
                (?{ $branch = "x7b"; })
              }xin;

    # AD or BC or BCE
    my $bcad_re = qr{ BC | BCE | B\.C\. | AD | A\.D\. }xin;
    push @r,qr{ (?<t1>
                  ( \b $bcad_re \s* \d+
                  | \b \d+ \s* $bcad_re
                  )
                )
                $ba_re
                (?{ $branch = "x8"; })
              }xin;

    # Addresses
    push @r,qr{ (?<t1>
                  \b
                  ( ( \d+ \s* )+                    # Street numbers
                    ( \w | \# \d+ )? \s+            # Apartment number / letter
                  | ( $min_word_re ($hy|\s)+ )+   # Street words
                    ( ( \w | \# \d+ ) \s+ )?        # Apartment number / letter
                  )
                  ( \w+ \s+ ){0,2}?                 # Filler words
                  ( road | rd | rue | via
                  | street | st
                  | avenue | ave
                  | crescent
                  | boulevard | blvd | bvd
                  | north | south | east | west
                  | lane | cottages?
                  | place | pl | plaza
                  | headquarters | hq
                  | meadows
                  )
                )
                $ba_re
                (?{ $branch = "x9"; })
              }xin;

    # Zip codes
    push @r,qr{ (?<t1>
                  \b $state_re [.,\s]+
                  \d{5}
                )
                $ba_re
                (?{ $branch = "x10"; })
              }xin;

    # XXX Lat / Long?
    # "dropped into south Indian Ocean at 350 E., 600 S.,"

    # Things that look like times but have high hours
    # Eighteen to twenty
    push @r,qr{ (?<li> $not_in_match )
                (?<t1> $min_word_re \s+ to \s+ $hour_h_re )
                $ba_re
                (?! \s+ to )
                (?{ $branch = "x11"; })
              }xin;

    # Numbers, page number
    # number 9, pp 9
    push @r,qr{ (?<li> $not_in_match )
                (?<t1>
                  ( pp?s?\.
                  | nos?\.?
                  | number
                  | chapter | line | paragraph | page | issue | volume | figure
                  | exercise | illustration | example | act | scene | question
                  | version
                  ) s? \s+
                  ( \d+ (\. \d+)* | $min_word_re )
                  ( (, \s+ and | ,) \s* \d+ (\. \d+)* )*
                )
                $ba_re
                (?{ $branch = "x12"; })
              }xin;

    # Numbers after punctuation at the end of a line with no trailing punctuation
    # These seem to be footnotes or page numbers mis-scanned
    push @r,qr{ (?<li> [.?!] \s+ )
                (?<t1>
                  \d+
                )
                (?<lo> \s* )
                \z
                (?{ $branch = "x13"; })
              }xin;

    # Prices
    push @r,qr{ (?<li> [\$£€] \s+ )
                (?<t1>
                  \d+ ( \. \d+ )?
                )
                $ba_re
                (?{ $branch = "x14"; })
              }xin;

    # 135 over 90
    push @r,qr{ \b
                (?<t1> ( \d+ | $min_re ) \s+ over \s+ (\d+ | $min_re ) )
                $ba_re
                (?{ $branch = "x15"; })
              }xin;


    # Phone number things
    push @r,qr{ $bb_re
                (?<t1> (?-i)
                  ( ( \( \d{3} \) | \d{3} ) ($hy|[/\s])* )?
                  \d{3} ($hy|[/\s])* [\dA-Z]{4}
                )
                $ba_re
                (?{ $branch = "x16"; })
              }xin;

    # URLs
    push @r,qr{ $bb_re
                (?<t1>
                  http:// \S+
                )
                $ba_re
                (?{ $branch = "x17"; })
              }xin;

    # Time periods
    push @r,qr{ $bb_re
                (?<t1>
                  $min_re \s+ days?    ,? \s+ ( and \s+ )?
                  $min_re \s+ hours?   ,? \s+ ( and \s+ )?
                  $min_re \s+ minutes?
                )
                $ba_re
                (?{ $branch = "x18"; })
              }xin;

    # height five-eleven
    # weight one-thirty
    push @r,qr{ (?<pr> (height | weight | length | width | depth) [:,]? \s+
                       ( (of | at) \s+ )?
                       ( $rel_words \s+ )?
                )
                (?<t1> $min_word_re ($hy|\s)+ $min_word_re )
                (?{ $branch = "x19"; })
              }xin;

    # Lists of forbidden things
    my $n_r = qr{ \d+ (\. \d+)+  }xin;
    push @r,qr{ (?<t1> $n_r ( (, | ,? \s+ and ) \s+ $n_r )+ \s+
                       $never_follow_times_re
                )
                (?{ $branch = "x20"; })
              }xin;

    # in 1.6 hours
    push @r,qr{ (?<pr> \b
                       ( along \s+ in | within | every ) \s+
                       ( $rel_words \s+ )?
                )
                (?<t1> \d+ ($hy|[.:])? \d+ )
                (?<po> \s* ( hrs | hours ) )
                (?{ $branch = "x21"; })
              }xin;

    # Version strings v1.0.3
    push @r,qr{ $bb_re
                (?<t1> v \d+ (\. \d+)* )
                $ba_re
                (?{ $branch = "x22"; })
              }xin;

    # in nineteen twenty-two
    # spring of nineteen twenty-two
    push @r,qr{ $bb_re
                (?<t1>
                  ( in
                  | (spring | summer | fall | autumn | winter) \s+ of
                  )
                  ( \s+ $hour24_word_re \s+ $min_word_re
                  | \s+ \d{3,4}
                  )
                )
                $ba_re
                (?{ $branch = "x23"; })
              }xin;

    return(\@r);
}

sub get_matches {
    state @r;
    return(\@r)
        if @r;

    # Capture names:
    # li - Lead-in: Stuff before the match that we don't mask out
    # pr - Preamble: Stuff that is part of the match phrase but not the time
    # t1 - Time 1: The time phrase
    # t2 - Time 2: More of the time phrase (if needed)
    # po - Postamble: Part of the match phrase but not the time
    # lo - Lead-out: Stuff after the match that we don't mask out

    # Times to/from hour
    # ten minutes past noon
    # three minutes till eight
    my $nf_re = qr{(?! $never_follow_times_re
                     | :\d
                     | $hy ( $min_re | and )
                     | \s+ of
                     )
                  }xin;
    push @r,qr{ (?<li> $not_in_match )
                (?<t1>
                  ( ( $rel_words \s+
                    | between \s+ $min_word_re \s+ and \s+
                    | ( $min_word_re | a ) \s+ (minute s? \s+)? or \s+
                    )?
                    ( $min_re | a | a \s+ few ) ( \s+ | $hy )
                    ( minute s? ,? \s+ )? ( good ,? \s+ )?
                    ( and ( \s+ | $hy )
                            ( a \s+ half | 1/2 | a \s+ quarter | 1/4 | twenty
                            | $sec_re \s+ second s?
                            )? \s+
                    | ( after | before ) \s+ ( the \s+ )? $fraction_re ( \s* | $hy )
                    )?
                    ( minute s? \s+ )?
                  | ( $rel_words \s+ ( a \s+ )? )? $fraction_re ( \s* | $hy )
                    (of \s+)? (an? \s+ hours? \s+)?
                  | ( $hour24_re | an ) \s+ hours? \s+
                  | ( just | nearly ) \s+
                  | in \s+ ( $rel_words \s+ )? $min_re \s+ ( minute s? \s+ )?
                    it \s+ (would | will) \s+ be \s+ (a \s+)?
                    $fraction_re ( \s* | $hy )
                  )
                  $till_re ( $hy | \s )+
                  ( the \s+ hour [,;]? \s+ which \s+ ( is | was ) \s+ )?
                  $hour24_re
                  ( \s+ $oclock_re ( $ampm_ph_re )?
                  |                  $ampm_ph_re
                  | $nf_re
                  )
                )
                $ba_re
                (?{ # This is a bit tricky
                    # Basically we are deciding if the match is of the form 'five to ten' and
                    # if so, we change the branch
                    $branch = "10";

                    my $t1 = $+{t1};
                    my $pre = ${^PREMATCH} . $+{li};
                    my $post = ${^POSTMATCH};

                    if ($t1 =~ m{\A ( $min_re \s+ or \s+ )?
                                    $min_re ($hy|\s)+ to ($hy|\s)+ $hour24_re \z}xin
                       )
                    {
                        $branch = "10a:TIMEY";
                        if ($is_racing or $pre =~ m{ \s of \s+ \z}xin) {
                            $branch = "y10";
                        }
                        elsif ($pre =~ m{ (\A | \s ) ( $twas_re | at ) \s+ \z }xin)
                        {
                            $branch = "10";
                        }
                        elsif ($t1 =~ m{\A 0 \s+ to \s+ 1 \z}xin) {
                            $branch = "y10";
                        }
                    }
                    elsif ($t1 =~ m{\A $minsec_dig_re \s+ of \s+ $hour24_word_re \z}xin or
                           $t1 =~ m{\A $min_word_re   \s+ of \s+ $hour24_dig_re  \z}xin)
                    {
                          # Mismatched
                          $branch = "10b:TIMEY";
                    }
                  })
              }xinp;

    # Ones with a phrase before to fix it better as a time
    push @r,qr{ \b (?<pr> ( meet  | meeting  | meets
                      |  start | starting | starts
                     ) \s+
                     ( ( $today_re | $weekday_re | this ) \s+
                      ( $morn_re \s+ )?
                     )?
                     at \s+
                   )
                   (?<t1> ( $rel_words \s+ )?
                     (?<hm> $hour24_re ( ($hy|[.:\s])* $min0_re )? )
                     (?! $never_follow_times_re )
                     ( ($hy|\s)+ $oclock_re )?
                     (?<ap> $ampm_ph_re )?
                   )
                   $ba_re
                (?{ $branch = "9g";
                    if (not $+{ap} and is_yearish($+{hm})) {
                        # If we didn't get an ampm and it looks like a year loosen it
                        $branch = "9g:TIMEY";
                    }
                  })
              }xin;

    # after eleven the next day
    push @r,qr{ \b (?<t1> ( $rel_words | (?<! turned \s) ( close \s+ )? upon ) \s+
                     $hour_word_re
                   )
                   ( (?<t2> \s+ $in_the_re ) \b
                   | (?<t2> $ampm_ph_re )
                   | (?<po>
                       \s+ the  \s+ ( next | following ) \s+ $timeday_re
                     | \s+ for  \s+ $meal_times
                     | \s+ on   \s+ ( the \s+ )? $weekday_re
                     | \s+ that \s+ $timeday_re
                     | \s+ $today_re
                     )
                   )
                   $ba_re
                 (?{ $branch = "9h"; })
              }xin;

    # Due ... at eleven-fifty-one
    # Knocks ... at 2336
    push @r,qr{ $bb_re
                (?<pr> ( due | knocks? | expected ) \s+ (\w+ \s+){0,5}? at \s+ )
                (?<t1> $hour24_re ($hy|[\s.:])* $min_re ( $ampm_ph_re )?)
                $ba_re
                (?{ $branch = "5d"; })
              }xin;

    # on the 1237
    push @r,qr{ (?<li> $not_in_match )
                (?<pr> ( on \s+ the
                       | here \s+ at
                       ) \s+
                )
                (?<t1> ( $hour12_dig_re [.]? | $hour24_dig_re [.] )
                       $minsec0_dig_re
                       $ampm_ph_re?
                )
                (?! ($hy | [.]) | $never_follow_times_re )
                $ba_re
                (?{ $branch = "3c";
                    my ($t1) = @+{qw( t1 )};
                    if ($t1 =~ m{\A \d\d\d \z}xin) {
                        # Three digit numbers are too loose, let it fall through
                        $branch = "xx";
                    }
                  })
              }xin;

    # 13 hours and 6 minutes
    # 13 hours, 6 minutes, and 10 seconds
    push @r,qr{ $bb_re
                (?<t1>
                        $hour24_re \s+ ( hour | $oclock_re | h | hr ) s? ,? ( \s+ and )?
                    \s+ $min_re    \s+ ( minute | min | m )           s?
                    ( $ampm_ph_re )?
                )
                (?<po>
                  ,? ( \s+ and )?
                  ( \s+ $sec_re    \s+ ( seconds | sec | s)           s?
                   | ( \s+ a )? \s+ $fraction_re
                  )?
                  (?! $never_follow_times_re
                  |   \s+ ( before | after )
                  )
                )
                $ba_re
                (?{ $branch = "14"; })
               }xin;

    # O'Clocks
    # 1 o'clock, 1 oclock, 1 of the clock
    push @r,qr{ (?<li> $not_in_match )
                (?<t1>
                  ( $rel_words \s+ )?
                  $hour24_re [?]? ( ($hy|[.:]) $min_re )?
                  ($hy|\s)+ $oclock_re
                  ( $ampm_ph_re )?
                  ( ,? \s+ all \s+ but \s+ $min_re (\s+ minutes?)? )?
                )
                $ba_re
                (?{ $branch = "6"; })
              }xin;

    # Simple times
    # 2300h, 23.00h, 2300 hrs
    push @r,qr{ $bb_re
                (?<t1> ( $rel_words \s+ )?
                  ( $hour_dig_re [.:] $minsec_dig_re
                    ( [.:] $minsec_dig_re ( $hy $minsec_dig_re )? )?
                  | $hour_dig_re $minsec0_dig_re
                    ( ( [.:] $minsec_dig_re | $minsec0_dig_re ) ( $hy $minsec_dig_re )? )?
                  | ( $z_low_num_re \s+ ){3} $z_low_num_re
                  )
                  ( h | \s* ( hrs | hours ) )
                )
                $ba_re
                (?{ $branch = "1"; })
              }xin;

    # Separators are mandatory, and it needs am/pm
    # 5.06 a.m.
    push @r,qr{ (?<li> $not_in_match )
                (?<t1>
                  ( $rel_words \s+ )?
                  $hour12_dig_re [.:] $minsec_dig_re
                )
                ( (?<t2> $ampm_ph_re )
                | (?<po> ( [.:] $minsec_dig_re )? $ampm_ph_re )
                )
                (?{ $branch = "2a"; })
              }xin;

    # 2300 GMT, 2300z, 1131 local time
    # Sounded out digits
    #  zero eight zero zero
    #  oh eight oh oh
    push @r,qr{ $bb_re
                (?<t1> ( $rel_words \s+ )?
                 ( ( $hour0_dig_re | $hour_dig_re )
                   [.:]?
                   $minsec0_dig_re )
                )
                (?<po>
                  ( [.:]? $minsec_dig_re ( $hy $minsec_dig_re )? )?
                  ( z
                  | \s* ( gmt | zulu
                        | (?-i: [A-Z]\w* \s+){1,2} time
                        | ( local | ship | $pronoun_re ) \s+ time
                        )
                  )
                )
                $ba_re
                (?{ $branch = "1a"; })
              }xin;
    # Leading GMT
    push @r,qr{ $bb_re
                (?<pr> ( gmt | zulu ) \s* )
                (?<t1> ( $rel_words \s+ )?
                 ( ( $hour0_dig_re | $hour_dig_re )
                   [.:]?
                   $minsec0_dig_re )
                )
                (?<po>
                  ( [.:]? $minsec_dig_re ( $hy $minsec_dig_re )? )?
                )
                $ba_re
                (?{ $branch = "1c"; })
              }xin;
    # 11h20
    push @r,qr{ $bb_re
                (?<t1>
                 ( $rel_words \s+ )?
                  $hour_dig_re h $minsec0_dig_re m?
                )
                $ba_re
                (?{ $branch = "1b"; })
              }xin;

    # : Means it's a time
    # 12:37
    push @r,qr{ (?<li> $not_in_match )
                (?<t1>
                 ( $rel_words \s+ )?
                 $hour_dig_re : $minsec0_dig_re
                )
                ( (?<t2> $ampm_ph_re )
                | (?<po> ( : $minsec_dig_re )?
                  $ampm_ph_re )
                )?
                $ba_re
                (?{ $branch = "2"; })
              }xin;

    # one hour and a quarter
    push @r,qr{ $bb_re
                (?<t1> $hour24_re \s+ hour s? ,? \s+ and \s+
                  a \s+ $fraction_re
                )
                (?! $never_follow_times_re )
                $ba_re
                (?{ $branch = "14a:TIMEY"; })
               }xin;

    # Word times (other word times come later)
    # eleven fifty-six am
    # three in the morning
    # 1 pm, one p.m.
    push @r,qr{ (?<li> $not_in_match )
                (?<t1> ( $rel_words \s+ )?
                  $hour_re
                  ( ( \s+ | $hy | [./] ) $min_word_re )?
                  ( ( \s+ | $hy | [./] ) $sec_word_re )?
                  $ampm_ph_re
                )
                (?! $never_follow_times_re )
                $ba_re
                (?{ $branch = "5"; })
              }xin;

    # at 1237 when
    # by 8.45 on saturday
    push @r,qr{ (?<li> $not_in_match )
                ( (?<pr> ( at | $twas_re | by | by \s+ the | since
                         | between \s+ ( $min_re | $hour_re )  \s+ and
                         ) \s+
                  )
                | (?<t1> $rel_words \s+ )
                )
                (?<t2> $hour_re [?]? ( ($hy | [.\s]) $min_re | $minsec0_dig_re )? )
                (?<po>
                 \s+ ( ( ( on (\s a)? | in ) \s+ )? (\w+ \s+){0,2} $weekday_re
                     | when
                     | $today_re
                     | ( this | that | one | on \s+ (the | that | an | a) ) \s+
                       $timeday_re
                     | by \s+ the
                     | $min_word_re s? \s+ ( day | week | month | year ) s?
                     | for  \s+ $meal_times
                     )
                )
                $ba_re
                (?{ $branch = "3b";
                    my ($t2, $po) = @+{qw( t2 po )};
                    if (not $is_trainy and $po =~ m{\A \s+ when }xin) {
                        if (is_yearish($t2) and
                            $t2 !~ m{\A 2[123]\d\d \z}xin     # Allow yearish things that are big
                           )
                        {
                            $branch = "3b:0";
                        }
                    }
                  })
              }xin;

    # Hour\? ... Three
    push @r,qr{ (?<pr> \b hour \? \s+ )
                (?<t1> $hour_word_re )
                $ba_re
                (?{ $branch = "9i:TIMEY"; })
              }xin;

    # The only time in a sentence
    # See also 9l, 9p, and 9k
    push @r,qr{ (?<pr>
                  ( \A | $aq | $phrase_punc \s+ | \s+ $hy+ \s+ )
                  ( ( only | just | it $sq s | it \s+ is | the ) \s+ )?
                )
                (?<t1>
                  ( $rel_words \s+ )?
                  (?<hh> $hour_word_re) ( \s+ | $hy ) (?<mm> $min_word_re) (?<ap> $ampm_ph_re)?
                )
                (?<po>
                  ( $hy $minsec_dig_re )?
                  ( \s+ ( now | precisely | exactly ) )?
                  ( \z | $phrase_punc? $aq | $phrase_punc ( \s+ | \z ) | \s+ $hy+ \s+) )
                  (?{ $branch = "9j";
                    # This needs more indication that it is timey
                    my ($hh, $mm, $ap) = @+{qw( hh mm ap )};
                    if (not $ap and $hh =~ m{\A one \z}xin and $mm =~ m{\A (one | two) \z}xin) {
                        $branch = "9j:0";
                    }
                  })
              }xin;
    # Handle the 6.15 differently so the - doesn't require spaces around it
    # And so that the leading puctuation can be adjacent
    push @r,qr{ (?<pr>
                  ( \A | $aq | $phrase_punc \s* | \s* $hy+ \s* )
                  ( ( only | just | it $sq s | it \s+ is | the ) \s+ )?
                )
                (?<t1>
                  ( $rel_words \s+ )?
                  $hour_dig_re [.:] $minsec0_dig_re ( [.:] $minsec0_dig_re )?
                  ( $hy $minsec0_dig_re )?
                )
                (?<po>
                  ( $hy $minsec_dig_re )?
                  ( \s+ ( now | precisely | exactly ) )?
                  ( \z | $phrase_punc? $aq | $phrase_punc ( \s+ | \z ) | \s* $hy+ \s*) )
                (?{ $branch = "9p"; })
              }xin;

    # In 5 minutes it would be 11
    # Three quarters of an hour before twelve
    push @r,qr{ (?<li> $not_in_match )
                (?<t1>
                  in \s+ ( $rel_words \s+ )? $min_re \s+ ( minute s? \s+ )?
                  it \s+ (would | will) \s+ be \s+ (a \s+)?
                  $fraction_re \s+
                  ( $rel_words \s+ )?
                  $hour_re
                  ( $ampm_ph_re )?
                )
                $ba_re
                (?{ $branch = "21"; })
              }xin;

    # Struck / strikes
    push @r,qr{ \b
                (?<t1>
                  $min_re \s+ minutes \s+ ( before | after ) \s+ the \s+
                  ( $clock_re | it | now ) \s+
                  ( $strike_re | $points_re ) \s+
                  $hour24_re ( ($hy|[.\s])+ $min0_re )?
                )
                $ba_re
                (?{ $branch = "11a"; })
              }xin;
    push @r,qr{ \b
                (?<pr>
                  (?<cl> $clock_re | ( it (\s is)? | $sq? tis ) ( \s+ now )? ) \s+
                  ( \w+ \s+ )*?
                  ( $strike_re | $points_re ) \s+
                )
                (?<t1>
                  ( ( a | $min_re ) \s+ minute s? \s+
                    ( before | after | short \s+ of | near \s+ to ) \s+
                  | near \s+ to \s+
                  )?
                  $hour24_re ( ($hy|[.\s])+ $min0_re )?
                )
                (?! \s+ ( faces | another ) )
                $ba_re
                (?{ $branch = "11";
                    if ($+{cl} =~ m{\A it \z}xin and not $is_timey) {
                        $branch = "11b:TIMEY";
                    }
                  })
              }xin;
    push @r,qr{ \b
                (?<pr> stroke \s+ of \s+ )
                (?<t1> $hour24_re ( ($hy|[.\s])+ $min0_re )? )
                $ba_re
                (?{ $branch = "12"; })
              }xin;

    # In about twenty-eight minutes it will be midnight.
    push @r,qr{ (?<li> $not_in_match )
                (?<t1>
                  in \s+ ( $rel_words \s+ )? $min_re \s+ ( minutes? \s+ )?
                  it \s+ (would | will) \s+ be \s+ (a \s+)?
                  $hour24_word_re ( ( \s+ | \s* $ellips \s* | $hy ) $min_word_re )?
                  ( \s* $ellips \s* $low_num_re )?
                  ( $ampm_ph_re )?
                  ( \s+ $oclock_re )?
                )
                (?! $never_follow_times_re )
                $ba_re
                (?{ $branch = "5h"; })
              }xin;

    # Noon / midnight
    push @r,qr{ (?<li> $not_in_match )
                (?<t1>
                  ( ( $rel_words | before ) \s+ ) ?
                  $midnight_noon_re
                )
                (?! $never_follow_times_re )
                $ba_re
                (?{ $branch = "13"; })
              }xin;

    # A little after two on a boiling hot afternoon
    push @r,qr{ (?<li> $bb_re )
                (?<t1> $rel_words \s+ $hour_re )
                (?<po>
                  ( \s+ or \s+ $hour_re )?
                  \s+ ( on | in | the ) \s+ (\w+ \s+){0,3} $timeday_re s?
                )
                $ba_re
                (?{ $branch = "3i"; })
              }xin;

    # at two the previous afternoon
    push @r,qr{ (?<li> $bb_re
                  ( to \s+ (*SKIP)(*FAIL) )?

                  (?<bw>
                    at | $till_re | until | by | from
                  | $twas_re (\s+ already)?
                  ) \s+
                )
                (?<t1> (?<rl> $rel_words \s+)?
                  (?<hm> ( $fraction_re ($hy | \s)+ $till_re \s+ )?
                    $hour_re
                  )
                )
                (?<po> \s+
                  (?<aw>
                    the
                  | on \s+ ( (a | the) \s+ )? (\w+ \s+){0,2}
                                              ( $timeday_re s?
                                              | $weekday_re s?
                                              )
                  )
                )
                $ba_re
                (?{ $branch = "3j";
                    my ($bw, $rl, $hm, $aw) = @+{qw( bw rl hm aw )};
                    if ($hm =~ m{\A ( one ) \z}xin and
                        not $rl and
                        $aw =~ m{\A ( the ) \z}xin and
                        $bw !~ m{\A ( at  ) \z}xin
                       )
                    {
                       # We don't want hours of 'one' that are followed by the unless preceeded by at
                       # e.g. 'at one the' is fine, 'of one the' is not
                       # Unless there's a relative word since that seems to make it legit
                       $branch = "xx";
                    }
                  })
              }xin;

    # Three in the morning
    push @r,qr{ (?<li> $not_in_match
                  ( (in | the | that| another | have) \s+ (*SKIP)(*FAIL) )?
                )
                (?<t1> ( $rel_words \s+ )? (?<hm> $hour_re (:$min_re)? ) )
                (?<po> \s+
                  ( the \s+ ( next | previous | following | preceeding ) \s+ $timeday_re
                  | in  \s+
                    ( (de | the| that ) \s+ (\w+ \s+){0,2} )?
                    ( $weekday_re \s+)?
                    $timeday_re
                  )
                )
                $ba_re
                (?{ $branch = "3d";
                    my ($po, $hm) = @+{qw( po hm )};
                    if ($po =~ m{\A \s+ in \s+ ( a | $pronoun_re ) \s+ $timeday_re \z}xin) {
                        $branch = "xx";
                    }
                    elsif ($hm =~ m{\A (one) \z}xin) {
                        $branch = "3d:TIMEY";
                    }
                  })
              }xin;

    # Strong word times
    # at eleven fifty-seven
    push @r,qr{ (?<li> $not_in_match )
                (?<pr> ( $twas_re (\s+ (\w+ly|already))? # Adverb
                       | at | by | $points_re ) \s+
                       )
                (?<t1>
                  $hour_word_re ( \s+ | \s* $ellips \s* | $hy ) $min_word_re
                  (             ( \s+ | \s* $ellips \s* | $hy ) $z_low_num_re )?
                  ( $ampm_ph_re )?
                )
                (?! $never_follow_times_re | $hy $z_low_num_re )
                $ba_re
                (?{ # If they look like five-three-zero then they aren't usually times
                    $branch = "5b";
                    my ($t1) = @+{qw( t1 )};
                    if ($t1 =~ m{\A $z_low_num_re $hy $z_low_num_re $hy $z_low_num_re \z}xin and
                        $t1 !~ m{\A $z_low_num_re $hy oh $hy $z_low_num_re \z}xin)
                    {
                        $branch = "x5b";
                    }
              })
              }xin;

    # Other weird cases
    # here at nine ...
    push @r,qr{ (?<pr> \b
                  ( here | there
                  | $today_re
                  | ( through \s+ the | following | that | at ) \s+ ( night | day )
                  | gets \s+ up | woke | rose | waking
                  | happened \s+ at
                  | news
                  | ( earlier | later ) \s+ than
                  ) \s+
                )
                (?<t1> $rel_at_words \s+
                  $hour_word_re
                  ( ( \s+ | $hy ) $min_word_re )?
                )
                (?! \s+ $time_periods_re | $never_follow_times_re | \s+ of )
                $ba_re
                (?{ $branch = "9b"; })
               }xin;

    # at a four-thirty screening
    push @r,qr{ (?<li> $not_in_match )
                (?<pr> ( at \s+ a | on \s+ the | with \s+ the | by \s+ the ) \s+ )
                (?<t1>
                  $hour24_word_re ( \s+ | ($hy|[.]) ) $min_word_re ( $ampm_ph_re )?
                | ( $hour12_dig_re [.]? | $hour24_dig_re ($hy|[.])? ) $minsec0_dig_re
                )
                (?<po> \s+
                  ( screening | viewing | performance | departure | arrival
                  | game | play | movie | flight | train | ship | express
                  )
                )
                $ba_re
                (?{ $branch = "5f"; })
              }xin;

    # Times at the end of a phrase
    # These are guaranteed times:
    #   waited until eight, ...
    # XXX Needs work
    push @r,qr{ $bb_re
                (?<pr>
                  ( waited | arrive s? | called | expired
                  | $twas_re
                  | begin | end
                  | ( (?<ba> make ) \s+)? it ( \s+ will \s+ be )?
                  | ( come | turn ) \s+ on
#                  | still
                  ) \s+
                  ( ( exactly | precisely | only | already | actually | virtually ) \s+ )?
                  ( ( at | upon | till | until ) \s+ )?
                )
                (?<t1> ( $rel_words \s+ )?
                  $hour12_word_re ( ( $hy | [:.] | \s+ )? $min_word_re )?
                )
                (?! $never_follow_times_re )
                (?<po>
                  (\s+ ( here | there | now | soon ) )?
                  ( \z | $phrase_punc? $aq | $phrase_punc ( \s+ | \z ) | \s+ $hy+ \s+)
                | \s+ ( and | $hy+ ) \s+
                )
                (?{ $branch = "9f";
                    my ($ba) = @+{qw( ba )};
                    if ($ba) {
                        $branch = "9q:TIMEY";
                    }
                  })
              }xin;

    # More at the end of a phrase
    # ... tomorrow at one.
    # ... to-morrow, at ten.
    # ... monday, at twelve.
    push @r,qr{ $bb_re
                (?<pr>
                  ( $today_re | $weekday_re | comes ) ,? \s+
                  ( in | at ) \s+
                )
                (?<t1>
                  ( $rel_words \s+ )?
                  ( near \s+ ( on \s+ )? )?
                  $hour_re ( ( $hy | [:.] | \s+ )? $min0_re )?
                )
                (?! $sq s | $never_follow_times_re )
                (?<po>
                  ( \s+ or \s+ so )?
                  ( $aq
                   | $phrase_punc ( $aq | \s | \z )
                   | \s+ ( and | till | before | $hy+ ) \s+
                  )
                )
                (?{ $branch = "9o"; })
              }xin;

    # The only time, but as digits with no separators... only if it says "looks like a year"
    # or something like that elsewhere in the phrase
    push @r,qr{ (?<pr>
                  ( \A | $aq | $phrase_punc \s+ | \s+ $hy+ \s+ )
                  ( ( only | just | it $sq s | it \s+ is | the ) \s+ )?
                )
                (?<t1>
                  (?<rl> $rel_words \s+ )?
                  (?<hr> $hour_dig_re ) $minsec0_dig_re ( $minsec0_dig_re )?
                )
                (?<po>
                  ( $hy $minsec_dig_re )?
                  ( \s+ ( now | precisely | exactly ) )?
                  ( \z | $phrase_punc? $aq | $phrase_punc ( \s+ | \z ) | \s+ $hy+ \s+) )
                (?{ $branch = "x9l";
                    my ($pre, $post, $rl, $hr) = (${^PREMATCH}, ${^POSTMATCH}, $+{rl}, $+{hr});
                    if ("$pre <<>> $post" =~
                            m{ ( look | seem) ( | s | ed ) \s+
                               like \s+ a \s+ (year | date)
                             | ( have | had ) \s+ the \s+ ( date | year )
                             }xin or
                        $hr =~ /\A 0\d /x
                       )
                    {
                        $branch = "9l";
                    }
                    elsif ($rl) {
                        # Let something else have a shot
                        $branch = "xx";
                    }
                  })
              }xinp;


    # Times at the start of a sentence
    # At ten, ...
    push @r,qr{ (?<pr>
                  ( \A | $aq | $phrase_punc \s+ )
                  ( ( $twas_re | and ) \s+ )?
                )
                (?<t1>
                  (?<rl> $rel_at_words | ( close \s+ )? upon | till | by ) \s+
                  (?<xx> $hour_re ( [.\s]+ $min0_re )? )
                  (?= \s+ ( last | yesterday | $weekday_re | he | she ) \b |  \s* $hy+ \s+ | , \s+ )
                )
                $ba_re
                (?{ $branch = "9e";
                    my ($xx, $rl) = @+{qw( xx rl )};
                    if ($xx =~ m{\A one \z}xin) {
                        $branch = "9e:TIMEY";
                    }
                    elsif ($is_agey and
                           $rl =~ m{\A $around_re \z}xin and
                           $xx =~ m{\A $hour_re \z}xin)
                    {
                        $branch = "9e:TIMEY";
                    }
                  })
              }xin if 0;
    push @r,qr{ (?<pr>
                  ( \A | $aq | $phrase_punc \s+ )
                  $twas_re \s+
                )
                (?<t1>
                  $hour_word_re (?<sep> $hy | [:.] \s* | \s+ )? (?<mn> $min_word_re)
                | $low_num_re \s* (*SKIP)(*FAIL)
                | $hour_word_re
                )
                (?!
                  $never_follow_times_re
                | \. \d+
                | \s+ (above | below)  # Temperatures
                | (\s+ \w+)? \s+ ( seconds )
                | $hy
                )
                (?= \s* (?<tr> (\w+ \s+){0,3} time
                        | now
                        )
                )?
                $ba_re
                (?{ $branch = "9d:1";
                    if (not $+{tr}) {
                        # No strong time indicator
                        if (is_yearish($+{t1}) and not $+{tr}) {
                            $branch = "9d:0";
                        }
                        elsif (not $+{sep} and $+{mn}) {
                           # If we have minutes but no separator that's not great
                           $branch = "9d:TIMEY";
                        }
                     }
                     if ($+{t1} eq '0') {
                         $branch = "x9d";
                     }
                  })
              }xin;
    push @r,qr{ (?<pr>
                  ( \A | $aq | $phrase_punc_nc \s+ ) # No comma
                  ( at ) \s+
                )
                (?<t1> (?<hh> $hour_re)
                       ( (?<sep> $hy | [:.] | \s+ )? (?<mm> $min0_re) )?
                       (?<ap> $ampm_ph_re )?
                )
                (?! $never_follow_times_re | \s+ of )
                (?<po> (?<tr> ,? \s+ (?<bw> last | yesterday | $weekday_re | he | she | they ) \b
                       | \s* $hy+ \s+
                       | , \s+
                       )?
                )
                $ba_re
                (?{ $branch = "9m:TIMEY";
                    my ($hh, $mm, $sep, $pr, $ap, $bw, $tr) = @+{qw( hh mm sep pr ap bw tr )};
                    if ($bw) {
                        $branch = "9e";
                    }
                    elsif ($tr) {
                        $branch = "9v";
                    }
                    elsif ($hh =~ m{\A $hour_word_re \z}xin) {
                        # If we have words then we want this to be stronger
                        $branch = "9t";

                        if (not $mm and
                            ( $pr =~ m{\A from \b }xin or $hh =~ m{\A $low_num_re \z}xin ))
                        {
                            $branch = "9t:TIMEY";
                        }
                    }
                    elsif ($sep or $ap) {
                        # If we have a separator or ampm then this is stronger
                        $branch = "9m";
                    }
                    elsif (defined $mm and is_yearish($hh.$mm)) {
                        # Weaken it if it looks like a year
                        $branch = "9m:0";
                    }
                  })
              }xin;

    push @r,qr{ (?<pr>
                  ( \A | $aq | $phrase_punc \s+ )
                  (?<was> ( $twas_re | only | because | and | maybe ) \s+)?
                  (?<mod> ( already | nightly | daily ) ,? \s+ )?
                )
                (?<t1>
                  (?<rl> $rel_at_words | close \s+ upon | till | by ) \s+
                  ( (?<xx> $hour24_re (?<sep> $hy | [:.] | \s+ )? $min0_re )
                  | (?<hh> $hour_re )
                  )
                )
                (?! $never_follow_times_re
                | : \d
                )
                (?<po> (?<tr>
                         ,? \s+ (?<bw> last | yesterday | $weekday_re
                                 | he | she | they | we
                                 | nobody
                                 | (?-i: \p{Uppercase}\p{Lowercase}\w* )
                                 ) \b
                       | \s* $hy+ \s+
                       | , \s+ (?! [^.]+ ( years | months ) )
                       )?
                )?
                $ba_re
                (?{ $branch = "9:TIMEY";
                    my ($was, $mod, $xx, $sep, $rl, $hh, $bw, $of, $tr) =
                        @+{qw( was mod xx sep rl hh bw of tr )};

                    if (is_yearish($xx) and (not $rl or $rl =~ m{\A (until) \z}xin)) {
                        $branch = "9n:0";
                    }
                    elsif ($sep and $xx !~ /[a-z]/i) {
                        # We had a separator and digits (12.30)
                        $branch = "9:1";
                    }
                    elsif ($mod) {
                        $branch = "9s";
                    }
                    elsif ($bw) {
                        $branch = "9u";
                        if ($xx and $xx =~ m{\A $hour_h_word_re ( $hy $min0_re )? \z}xin) {
                            $branch = "9u:TIMEY";
                        }
                    }
                    elsif ($was and $rl and
                           (not $hh or "$was $rl" !~ m{\A and \s+ at \z}xin) )
                    {
                        $branch = "9w";
                    }
                    elsif ($rl and $hh and $tr and
                           $hh =~ $hour_word_re and $rl =~ m{\A about \z}xin)
                    {
                        $branch = "9x";
                    }
                    elsif ($hh and $hh =~ m{\A one \z}xin) {
                        $branch = "xx";
                    }
                    elsif ($is_agey and
                           defined $hh and
                           $rl =~ m{\A $around_re \z}xin and
                           $hh =~ m{\A $hour_re \z}xin)
                    {
                        $branch = "9r:0";
                    }
                  })
              }xin;

    # More at the end of a phrase
    # These are not always, so look for timey:
    #   ... through Acton at one.
    #   ... starts opening at eight and ...
    push @r,qr{ $bb_re
                (?<pr>
                  ( $at_words | before | upon | till | from
                   | $twas_re
                  ) \s+
                  ( only \s+ )?  # Generalize?
                )
                (?<t1>
                  (?<rl> $rel_words \s+ )?
                  ( near \s+ ( on \s+ )? )?
                  (?<hh> $hour_re) ( (?<sep> $hy | [:.] | \s+ )? (?<mm> $min0_re) )?
                )
                (?!
                  $sq s
                | $never_follow_times_re
                | \s+ and \s+ a \s+ (half | quarter | third)
                )
                (?<po>
                  ( \s+ or \s+ so )?
                  ( $aq
                  | $phrase_punc ( $aq | \s | \z )
                  | \s+ ( and | till | before | $hy+ ) \s+
                  )
                )
                (?{ $branch = "9c:TIMEY";
                    my ($hh, $mm, $sep, $pr, $po, $rl) = @+{qw( hh mm sep pr po rl )};
                    if ($hh =~ m{\A $hour_word_re \z}xin) {
                        # If we have words then we want this to be stronger
                        $branch = "9c:1";

                        if (not $mm and $pr =~ m{\A from \b }xin and $po !~ /\w/) {
                            $branch = "9c:TIMEY";
                        }
                    }
                    elsif ($sep) {
                        # If we have a separator then this is stronger
                        $branch = "9c:1";
                    }
                    elsif (defined $mm and is_yearish($hh.$mm)) {
                        if ($rl or not $is_trainy or $pr =~ m{^ until }xin) {
                            # Weaken it if it looks like a year
                            $branch = "9c:0";
                        }
                    }
                    elsif (not defined $mm and $hh =~ /^00?$/) {
                        # Just 0s don't work as bare hours
                        $branch = "xx";
                    }
                  })
              }xin;

    # The only time, but as a single hour (these are less reliable)
    push @r,qr{ (?<pr>
                  ( \A | $aq | $phrase_punc_nc \s+ | \s+ $hy+ \s+ ) # No comma
                  ( ( $twas_re | only | just | the | probably ) \s+ )?
                )
                (?<t1>
                  ( $rel_words \s+ )?
                  $hour24_word_re ( ( \s+ | $hy ) $min_word_re ( $ampm_ph_re )? )?
                )
                (?<po>
                  ( $hy $minsec_dig_re )?
                  ( \s+ ( now | precisely | exactly ) )?
                  ( \z | $phrase_punc? $aq | $phrase_punc ( \s+ | \z ) | \s+ $hy+ \s+)
                )
                    (?{ $branch = "9k:0";
                        my ($pr, $po, $t1) = @+{qw( pr po t1 )};
                        if ( ( $po // '' ) =~ /now/i or
                             ( $pr // '' ) =~ /now/i )
                        {
                            $branch = "9q";
                        }
                        elsif ($t1 =~ /$rel_words/i) {
                            $branch = "9k:TIMEY";
                        }
                        elsif ($is_timey) {
                            $branch = "9k:0";
                        }
                        else {
                            $branch = "x9k";
                        }
                   })
              }xin;

    # Untrustworthy times... need an indication that it is a time, not just some number
    # Hours 1-12 only
    #  at 1237, is 1237, was 1237, by 1237
    push @r,qr{ (?<li> $not_in_match )
                (?<pr>
                  ( (?<prw> \w+) \s+)?
                  ( $at_words | before | by
                  | $twas_re
                  ) \s+
                )
                (?<t1>
                  ( $rel_words \s+ )?
                  (?<tt>
                    ( $hour12_dig_re (?<sep> [.])? | $hour24_dig_re (?<sep> [.]) )
                    $minsec0_dig_re
                  )
                )
                (?! ([.] \d+)? $never_follow_times_re
                | [.] \d{3,}
                )
                $ba_re
                (?{ $branch = "3:TIMEY";
                    my ($sep, $tt, $prw) = @+{qw( sep tt prw )};
                    if ($sep or $is_trainy) {
                        $branch = "3:1";
                    }
                    elsif ($prw and $prw =~ m{\A (lived | lives | known
                                                 | building    | house | appartment
                                                 | multiply    | divide | less
                                                 | multiplying | dividing
                                                 | multiplied  | divided
                                                 | oven | cook | fry | bake
                                                 | \d+
                                                 ) \z}xin) {
                        $branch = "xx";
                    }
                    elsif ($tt =~ m{\A \d\d\d \z}xin) {
                        # Three digit numbers seem never to be times
                        $branch = "3:0";
                    }
                  })
              }xin;

    # Untrustworthy times... need an indication that it is a time, not just some number
    # All 24 hours
    #  by 2037 on ...
    push @r,qr{ (?<li> $not_in_match )
                (?<pr>
                  ( $at_words | before | by
                  | $twas_re
                  ) \s+
                )
                (?<t1>
                  ( $rel_words \s+ )?
                  $hour_dig_re
                  $minsec0_dig_re
                )
                (?<po> \s+ on \s+ )
                (?{ $branch = "3a:TIMEY"; })
              }xin;

    # Bare hour (1-12) numbers or words but with a strong time indication
    # ... at nine ...
    my $def_re = qr{ he | she | they | we
                   | exactly | precisely | punctually
                   | $weekday_re
                   }xin;
    push @r,qr{ (?<li> $not_in_match
                       ( (?<tm> morning | afternoon | evening | night
                         | awoke | woke | arose | rose | dressed | dined
                         | $weekday_re
                         | exactly | precisely | punctually
                         ) \s+
                         ( \w+ly \s+ )?  # An adverb
                       )?
                )
                (?<pr> $at_words \s+ ) # XXX Should we allow by or before?
                (?<t1>
                  (?<rel> $rel_words \s+ )?
                  (?<hh> $hour12_re )
                )
                (?! $never_follow_times_re )
                (?<po> \s+ (?<sub> $def_re | (?-i: \p{Uppercase}\p{Lowercase}\w*) ) \s+ )
                (?{ $branch = "3e:TIMEY";
                    my ($hh, $sub, $tm, $rel) = @+{qw( hh sub tm rel )};
                    if ($sub =~ m{\A $def_re \z}xin) {
                        # XXX these can be ages :-(
                        # e.g. "In fact at <<twelve|3f>> she was already a BP."
                        $branch = "3f";
                    }
                    elsif ($tm) {
                        $branch = "3g";
                    }
                    elsif ($rel) {
                        $branch = "3h";
                    }
                    elsif ($hh  =~ m{\A \p{Uppercase}\p{Lowercase}\w* \z}xn or
                           $sub =~ m{\A ( $month_re | $special_day_re ) \z}xn)
                    {
                        # Upper case hours seem to mean counts often
                        # And we don't want counts of months to show
                        $branch = "xx";
                    }
                  })
              }xin;

    # Between, as I was saying, the hours of twelve and twelve five
    # hour of twelve
    push @r,qr{ (?<li> $not_in_match )
                (?<pr> hours? \s+ of \s+ )
                (?<t1>
                  ( $rel_words \s+ )?
                  $hour_re
                  ( ($hy|\s)+ $min_re )?
                )
                (?! $never_follow_times_re
                |   \s+ ( another ) \b
                )
                $ba_re
                (?{$branch = "20"; })
              }xin;
    # ^ and twelve five
    push @r,qr{ \A
                (?<pr> ,? \s+ (or | and) \s+ )
                (?<t1>
                  ( $rel_words \s+ )?
                  $hour_re
                  ( ($hy|[.:\s])+ $min_re )?
                )
                (?! $never_follow_times_re )
                $ba_re
                (?{ $branch  = "20a";
                    $branch  = "x20a" if $last_masked;
                    $branch .= ":TIMEY" if $last_timey;
                  })
              }xin;

    # eleven fifty-six
    push @r,qr{ (?<li> $not_in_match )
                (?<t1>
                  (?<rl> $rel_words \s+ )?
                  (?<hr> $hour24_word_re (       \s+ | \s* $ellips \s* )
                  |      $hour_word_re   ( $hy | \s+ | \s* $ellips \s* )
                  )
                  (?<mn> $min_word_re )
                  $ampm_ph_re?
                )
                (?! $never_follow_times_re
                |  $hy+
                )
                $ba_re
                (?{ $branch = $is_pricey ? "5k:TIMEY" : "5k:1";
                    my ($rl, $hr, $mn) = ($+{rl}, $+{hr}, $+{mn});
                    if ($mn =~ m{\A $low_num_re \z}xin) {
                        if ($is_trainy) {
                            $branch = "5l:TIMEY";
                        }
                        else {
                            $branch = "x5l";
                        }
                    }
                    if ($hr =~ m{\A ( sixteen | seventeen | eighteen | nineteen ) \z}xin) {
                        # Yearish
                        $branch = "5k:TIMEY";
                    }
                  })
              }xin;

    # when at last around 5.45
    push @r,qr{ (?<li>
                  $not_in_match
                  when \s+
                  ( at \s+ (last \s+)? )?
                )
                (?<t1>
                  $rel_words \s+
                  ( $hour24nz_dig_re | 00 ) ($hy|[.]) $minsec0_dig_re
                  ( $ampm_ph_re )? )
                (?! $never_follow_times_re
                |  $hy+
                )
                $ba_re
                (?{ $branch = "5m"; })
              }xin;

    # 20.36 Rimmer stood...
    push @r,qr{ (?<li> (\A \s* | $bb_re \w+ \. \s+ ) )
                (?<t1>
                  ( $rel_words \s+ )?
                  ( $hour24nz_dig_re | 00 ) [.] $minsec0_dig_re
                  ( $ampm_ph_re )?
                )
                (?! $never_follow_times_re
                |  $hy+
                )
                (?<po> \s+
                  ( (?<bad>
                      ( photograph | reprinted ) \s+
                    | (\w+,? \s+){0,4} ©
                    )
                  | (?-i: \p{Uppercase}\p{Lowercase}\w* )
                  )
                 )
                $ba_re
                (?{ $branch = "4";
                    if ($+{bad}) {
                        # If the match is bad, can it so nothing else matches this
                        $branch = "y4";
                    }
                    elsif ( ($author =~ m{\bBrooks\b}   and $book =~ m{\QMythical Man Month\E  }) or
                            ($author =~ m{\bPeterson\b} and $book =~ m{\QPlaying at the World\E})
                          )
                    {
                        # Skip books that use this form for sections and are not delimited any way
                        $branch = "y4";
                    }
                  })
              }xin;


    # 3.00
    push @r,qr{ (?<li> $not_in_match
                  (?<ci> \(? ($month_re|spring|summer|autumn|fall|winter) \s+ \d{4} \)? \, \s+ )?
                  (?<pl> \w+ s \s+)?
                )
                (?<t1>
                  ( $rel_words \s+ )?
                  ( $hour24nz_dig_re | 00 ) (?<sep> $hy | [.]) $minsec0_dig_re
                  ( $ampm_ph_re )?
                )
                (?! $never_follow_times_re
                |  $hy+
                )
                $ba_re
                (?{ $branch = "5a:TIMEY";
                    my ($ci, $pl, $sep) = @+{qw( ci pl sep )};
                    my ($pre, $post) = (${^PREMATCH}, ${^POSTMATCH});
                    if ($ci) {
                        # We have a citation
                        $branch = "y5a";
                    }
                    elsif ($pl and $sep =~ $hy) {
                        # These are ranges of nouns... probably not a time
                        $branch = "5a:0";
                    }
                    elsif ($is_trainy and $sep eq '.') {
                        $branch = "5a:1";
                    }
                    elsif (@parts == 1 and
                           $sep   =~ $hy and
                           $pre   =~ m{^ \s*            $}mxin and
                           $post  =~ m{^ [\s\p{Punct}]* $}mxin)
                    {
                        # Skip hyphenated ranges that are the only thing on a line
                        $branch = "y5a";
                    }
                  })
              }xinp;

    # Hours by, at start of phrase
    # ; eleven by big ben ...
    push @r,qr{ (?<pr> ( \A | $aq | $phrase_punc \s+ ) )
                (?<t1> $hour24_re ( [.\s]+ $min0_re )? )
                (?<po>
                  (\s+ \w+)?
                  \s+ ( by | of ) \s+
                  ( big \s+ ben
                  | the \s+ ( clock | bell )
                  )
                )
                $ba_re
                (?{ $branch = "5g:TIMEY"; })
              }xin;

    # Other ecclesiastical times that conflict
    push @r,qr{ \b
                ( (?<pr> ( when | during ) \s+ )
                | (?<t1> $rel_words \s+ )
                )
                (?<t2> prime | nones )
                $ba_re
                (?{ $branch = "16"; })
              }xin;

    # Nearer to one than half past
    push @r,qr{ \b
                (?<t1> nearer \s+ to \s+
                       $hour_re \s+
                       ( $oclock_re \s+ )? than \s+
                       $fraction_re ($hy|\s)+ past
                )
                $ba_re
                (?{ $branch = "17"; })
              }xin;

    # I tried to pull her off about 0230, and there ...
    push @r,qr{ (?<li> $not_in_match )
                (?<t1>
                  ( ( $rel_at_words \s+ )? 0\d           $minsec0_dig_re
                  |   $rel_at_words \s+    $hour0_dig_re $minsec0_dig_re
                  )
                  ( $ampm_ph_re )? )
                (?! $never_follow_times_re
                |  $hy+
                )
                $ba_re
                (?{ $branch = "18:TIMEY"; })
              }xin;

    # The new day was still a minute away
    # If you change this you need to change the screen above and the match below
    push @r,qr{ (?<li> $not_in_match )
                (?<pr> the \s+ )
                (?<t1>
                  ( new | next ) \s+ day \s+
                  was \s+ ( ( still | just | $rel_words ) \s+ )?
                  ( ( a | $min_re ) \s+ )?
                  ( ( minute | hour | second ) s? \s+)? away
                )
                $ba_re
                (?{ $branch = "19"; })
              }xin;

    # TODO: Military times?
    #   Thirteen hundred hours; Zero five twenty-three; sixteen thirteen

    return(\@r);
}

sub extract_times {
    my ($string, $permute, $adj, $abs) = @_;

    my @times;
  MATCH_LOOP:
    while ($string =~ m{<< ([^|>]+) [|] \d+ \w? (:\d)? >>}gx) {
        my $str = $1;
        my $branch;

        if ($str =~
            m{\A
              ( # one ... thirty ... four
                ( (?<rl> $rel_at_words ) \s+ )?
                                  (?<hr> $hour24_word_re )
                  \s* $ellips \s* (?<mn> $min_word_re )
                ( \s* $ellips \s* (?<m3> $z_low_num_re ) )?
                ( \s+ $oclock_re )?
                ( [:,]? \s+ (?<am> $ampm_re ) )?
                (?{ $branch = "9"; })

              | # one-three-zero (should we support one-one-three-zero?)
                ( (?<rl> $rel_at_words ) \s+ )?
                        (?<hr> $hour24_word_re )
                  $hy (?<mn> $z_low_num_re )
                  $hy (?<m3> $z_low_num_re )
                ( \s+ $oclock_re )?
                ( [:,]? \s+ (?<am> $ampm_re ) )?
                (?{ $branch = "14"; })

              | # Exact time
                ( (?<rl> $rel_at_words ) \s+
                  ( ( at | to ) \s+ )?
                | in \s+ ( (?<rl> $rel_at_words ) \s+ )?
                  (?<n1> $min_re ) \s+ ( minutes? \s+ )?
                  it \s+ (would | will) \s+ be \s+ (a \s+)?
                | (?<rl> close \s+ upon | till ) \s+
                )?
                (                                (?<hr>  $hour24_re | $all_named_times     ) \?? \s*
                  ( ( $hy | [\s.:/] | $ellips )+ (?<mn>  $min_re ( (?<rl> $hy ) $min_re )? ) \s* )?
                  ( ( $hy | [\s.:/] | $ellips )+ (?<sec> $sec_re ( (?<rl> $hy ) $min_re )? ) \s* )?
                |   (?<hr>  $hour24_dig_re  )
                  ( (?<mn>  $minsec0_dig_re ) )?
                  ( (?<sec> $minsec0_dig_re ) )?
                | (?<hr>  $hour24_word_re ) \s*
                  (?<mn>  $min_word_re | hundred ) \s*
                )
                ( \s+ $oclock_re )?
                ( [:,]? \s* (?<am> $ampm_re   ) )?
                ( ,? \s+ all \s+ but \s+ (?<n1> $min_re ) (\s+ minutes?)? )?
                (?{ $branch = "1"; })

              | # 0000h
                ( (?<rl> $rel_at_words ) \s+ )?
                  (?<hr> $hour_dig_re
                  | $z_low_num_re ( \s+ $z_low_num_re )?
                  ) ( $hy | [\s.:] )*
                ( (?<mn> $minsec0_dig_re
                  | $z_low_num_re \s+ $z_low_num_re
                  ) \s*
                )?
                (?<sec> [:.] $minsec_dig_re ( ( $hy | [.] ) $minsec_dig_re )?
                |            $minsec0_dig_re
                )? \s*
                (?<am> h | hrs | hours )
                (?{ $branch = "2"; })

              | # 11h20m, 11h20, 3 hr 8 m p.m.
                ( (?<rl> $rel_at_words ) \s+ )?
                  (?<hr> $hour_dig_re   | $hour24_re ) \s* ( h | hrs?  | hours?   ) \s*
                ( ,? \s+ ( and \s+ )? )?
                  (?<mn> $minsec_dig_re | $min_re    ) \s* ( m | mins? | minutes? )?
                ( [:,]? \s+ (?<am> $ampm_re ) )?
                (?{ $branch = "3"; })

              | # twenty minutes past eight
                ( (?<rl> $rel_at_words | a \s+ few | just ) \s+
                | (?<rl> ( $rel_at_words \s+ )? (a | $min_re) \s+ (minutes? \s+)? or ) \s+
                )?
                ( (?<mn> $min_re | a ) ($hy | \s)+ )?
                ( and ( \s+ | $hy )
                  ( a \s+ half | 1/2 | a \s+ quarter | 1/4 ) \s+
                )?
                  ( minutes? ,? \s+ )? ( good ,? \s+ )?
                ( and ( \s+ | $hy ) (?<sec> $sec_re ) \s+ seconds? \s+ )?
                  (?<dir> $till_re ) ( $hy | \s )+
                  ( the \s+ hour [,;]? \s+ which \s+ was \s+ )?
                  (?<hr> $hour24_re )
                ( ( $hy | \s )+ (?<m3> $min_re ) )?
                ( \s+ $oclock_re )?
                ( [:,]? \s* (?<am> $ampm_re ) )?
                (?{ $branch = "4"; })

              | # seven-and-twenty minutes past eight
                ( (?<rl> $rel_at_words | between ) \s+ )?
                  (?<mn> $min_re ($hy | \s)+ and ($hy | \s)+ $min_re ) \s+
                  ( and ( \s+ | $hy )
                    (?<sec> a \s+ half | 1/2 | a \s+ quarter | 1/4 | twenty
                    | (?<sec> $sec_re ) \s+ second s?
                    ) \s+
                  )?
                  ( minutes? \s+ )?
                  (?<dir> $till_re ) \s+
                  (?<hr> $hour_re )
                ( \s+ $oclock_re )?
                ( [:,]? \s* (?<am> $ampm_re ) )?
                (?{ $branch = "5j"; })

              | # three quarters past eleven
                ( in \s+ ( (?<rl> $rel_at_words ) \s+ )?
                  (?<n1> $min_re ) \s+ ( minutes? \s+ )?
                  it \s+ (would | will) \s+ be \s+ (a \s+)?
                )?
                ( ( (?<rl2>
                      ( $min_re | a (\s+ few)? | just (\s+ a)? ) \s+ ( minute s? \s+ )?
                      ( or \s+ $min_re \s+ )?
                      (before | after)
                    ) \s+
                  | (?<rl> $rel_at_words ) \s+ ( a \s+ )?
                  )?
                  ( the \s+ )?
                )?
                  (?<mn> $fraction_re ) ($hy | \s)* (of \s+)? (an? \s+ hours? \s+)?
                  (?<dir> $till_re ) ($hy | \s)+
                  (?<hr> $hour24_re )
                ( \s+ $oclock_re )?
                ( [:,]? \s+ (?<am> $ampm_re ) )?
                (?{ $branch = "6"; })

              | # three o'clock
                ( (?<rl> $rel_at_words ) \s+ )?
                  (?<hr> $hour24_re ) \??
                  ($hy | \s)+ $oclock_re
                ( \s+ ( and \s+ )?
                  (?<mn> $min_re | $fraction_re ) \s*
                  minutes?
                )?
                ( [:,]? \s+ (?<am> $ampm_re ) )?
                (?{ $branch = "7"; })

              | # One hour and a quarter
                ( (?<rl> $rel_at_words ) \s+ )?
                  (?<hr> $hour24_re ) \s+ hours? \s+ and \s+ (a \s+)?
                  (?<mn> $fraction_re )
                ( [:,]? \s+ (?<am> $ampm_re ) )?
                (?{ $branch = "8"; })

              | # Two minutes before the clock struck noon
                  (?<mn> $min_word_re ) \s+ minutes? \s+
                  (?<dir> $till_re ) \s+
                ( the \s+ (\w+ \s+){0,2} ( clock | bell ) s? \s+ ( rang | struck ) \s+ )?
                  (?<hr> $hour24_re )
                ( \s+ $oclock_re )?
                ( [:,]? \s+ (?<am> $ampm_re ) )?
                (?{ $branch = "10"; })

              | # 4.15 o'clock
                ( (?<rl> $rel_at_words ) \s+ )?
                  (?<hr> $hour24_re ) [.:\s]+
                  (?<mn> $min_re )
                  (?<dir> $till_re ) \s+
                ( the \s+ ( clock | bell ) \s+ ( rang | struck ) \s+ )?
                ( \s+ $oclock_re )?
                ( [:,]? \s+ (?<am> $ampm_re ) )?
                (?{ $branch = "11"; })

              | # nearer to one than half past
                  (?<rl> nearer \s+ to ) \s+
                  (?<hr> $hour24_re ) \s+
                  ( $oclock_re \s+ )? than \s+
                  (?<mn> $fraction_re ) ($hy | \s)+ past
                ( [:,]? \s+ (?<am> $ampm_re ) )?
                (?{ $branch = "12"; })

              | # next day was just a minute away
                  ( new | next ) \s+ (?<hr> day) \s+
                  was \s+ ( ( still | just | $rel_words ) \s+ )?
                  ( (?<n1> a | $min_re ) \s+ )?
                  ( (?<un> minute | hour | second ) s? \s+)? away
                (?{ $branch = "13"; })

              | # One hour after noon
                ( (?<rl> $rel_at_words ) \s+ )?
                  (?<h2> $hour24_re | an? ) \s+ hours? \s+
                  ( and \s+ (a \s+)? (?<mn> $fraction_re ) \s+
                  | and \s+ (?<mn> $min_re) \s+ minutes? \s+
                  )?
                  (?<dir> $till_re ) \s+
                  (?<hr> $hour24_re )
                ( \s+ $oclock_re )?
                ( [:,]? \s+ (?<am> $ampm_re ) )?
                (?{ $branch = "14"; })

              )
              \z}xin)
        {
            # Save the captured values
            my @k = qw{ rl hr h2 mn m2 rl2 m3 n1 sec dir am branch };
            my %c; @c{@k} = @+{@k};
            $c{branch} = $branch;

            my $min  = $c{mn}  // 0;             # The base minutes
            my $m2   = $c{m2}  // 0;             # Additional minutes elsewhere in the string
            my $m3   = $c{m3}  // 0;             # Further minutes elsewhere in the string
            my $n3   = $c{n1}  // 0;             # Negative value in the string
            my $un   = $c{un}  // 'minutes';     # The units of the negative value
            my $sec  = defined $c{sec} ? 1 : 0;  # Seconds present?
            my $hour = $c{hr}  // 0;             # The base hour
            my $hr2  = $c{h2}  // 0;             # A relative hour
            my $rel  = $c{rl}  // '';            # The relative phrase
            my $rel2 = $c{rl2} // '';            # A second relative phrase (or two)
            my $ampm = $c{am};                   # AM or PM?
            my $dir  = $c{dir} // '';            # Whether the time is before or after the base hour

            my $abs_hour = 0;

            # Turn the hours into numbers
            if ($hour !~ /^\d+$/) {
                if ($hour =~ $all_named_times) {
                    # Transform the hour into something we can look up
                    my $h = lc($hour);
                    $h =~ s{$hy}{};
                    $h =~ s{\s+}{ };

                    # Translate the prayer times
                    if ($h =~ s{ prayer}{}) {
                        my %pts = (
                            'dawn'          => 'lauds',
                            'early morning' => 'prime',
                            'midmorning'    => 'terce',
                            'midday'        => 'sext',
                            'midafternoon'  => 'nones',
                            'evening'       => 'vespers',
                            'night'         => 'compline',
                            );
                        $h = $pts{$h};
                    }

                    # Handle special named times
                    my %time_strs =
                        (
                         # Ecclesiastical times
                         #  Per Eco in "The Name of the Rose"
                         #  See also: https://en.wikipedia.org/wiki/Liturgy_of_the_Hours
                         'matins'       => ["02:30 AM",       "03:00 AM", 30], # Between 2:30 & 3:00 AM
                         'vigils'       => ["02:30 AM",       "03:00 AM", 30], # Between 2:30 & 3:00 AM
                         'nocturns'     => ["02:30 AM",       "03:00 AM", 30], # Between 2:30 & 3:00 AM
                         'night office' => ["02:30 AM",       "03:00 AM", 30], # Between 2:30 & 3:00 AM
                         'lauds'        => ["05:00 AM",       "06:00 AM", 00], # Between 5:00 & 6:00 AM
                         'prime'        => ["around 7:30 AM", undef,      00],
                         'terce'        => ["around 9:00 AM", undef,      00],
                         'sext'         => ["noon",           undef,      00],
                         'nones'        => ["02:00 PM",       "03:00 PM", 60], # Between 2:00 & 3:00 PM
                         'vespers'      => ["around 4:30 PM", undef,      00],
                         'evensong'     => ["around 4:30 PM", undef,      00],
                         'compline'     => ["around 6:00 PM", undef,      00],
                         #
                         # Other times
                         'elevenses'    => ["around 11:00 AM", undef,     00],
                        );
                    my $tr = $time_strs{$h}
                      or die "Unable to work out a time for '$hour' ($h)";

                    # Handle times relative to this. i.e. just before matins
                    my ($start_str, $end_str, $adj) = @$tr;
                    $end_str //= $start_str;
                    my ($rs, $ts, $as) = ('', $start_str, $adj);

                    if ($rel ne '') {
                        if ($rel =~ m{\A ( $far_before_re
                                         | $short_before_re
                                         | close ( \s+ upon )?
                                         | before
                                         ) \z}xin
                            )
                        {
                            ($rs, $ts, $as) = ($rel, $start_str, 0);
                        }
                        elsif ($rel =~ m{\A $around_re \z}xin) {
                            if (not $as) {
                                ($rs, $ts, $as) = ($rel, $start_str, 0);
                            }
                        }
                        elsif ($rel =~ m{\A ( $short_after_re | $far_after_re ) \z}xin) {
                            ($rs, $ts, $as) = ($rel, $end_str, 0);
                        }
                        else {
                            confess "Can't parse '$rel'";
                        }

                        $rs .= " " if $rs ne '';
                        $ts =~ s{\A around \s }{}xin;
                    }

                    my $abs = 0;
                    if ($dir) {
                        $min  = min2num($min) + min2num($m2) + min2num($hr2) * 60;
                        if ($dir =~ $before_re) {
                            $min = - $min;
                            $min -= 1 if $sec;
                        }
                        $min += min2num($m3);

                        $abs = $min;
                    }

                    push @times, extract_times("<<$rs$ts|88>>", $permute, $as, $abs);
                    next MATCH_LOOP;
                }

                # Handle normal times
                if ($hour =~ $noon_re) {
                    $hour = 12;
                    $abs_hour = 1;
                }
                elsif ($hour =~ $midnight_re or $hour =~ /day/i) {
                    $hour = 00;
                    $abs_hour = 1;
                }
                else {
                    $hour = min2num($hour);
                }
            }

            # Turn the minutes into numbers
            if ($min !~ /^\d+$/) {
                if ($rel eq 'between') {
                    $min =~ s{ \A (.*?) \s+ and \s+ .* \z }{$1}xi;
                }
                elsif ($rel =~ /$hy/) {
                    $min =~ s{ \A (.*) $hy .* \z }{$1}xi;
                    $dir = 'after';
                }
                elsif ($min =~ m{\A hundred \z}xin) {
                    $min = 0;
                    $abs_hour = 1;
                }
                $min = min2num($min);

                $min -= 30 if $rel =~ m{\A nearer \s+ to \z}xin and $min == 30;
            }
            $min += min2num($m2);
            $min += min2num($hr2) * 60;

            # If we got am or pm we can set the hour absolutely
            if (defined $ampm) {
                $abs_hour = 1;
                my $pm = undef;

                if ($ampm =~ m{\A $in_the_re \z}xin) {
                    # Work out the time
                    if ($ampm =~ m{ morn(ing)? | mornin $sq? | dawn | sunrise | $am_re }xi) {
                        $pm = 0;
                    } elsif ($ampm =~ m{ after($hy|\s)?noon | evening | eve | dusk | sunset | $pm_re }xi) {
                        $pm = 1;
                    }
                    elsif ($ampm =~ m{ day }xi) {
                        # Day means 6AM to 6PM
                        $hour += 12 if $hour <= 5;
                    }
                    elsif ($ampm =~ m{ night }xi) {
                        # Night means 0-6AM and 6-12PM
                        $hour += 12 if $hour >= 5 and $hour <= 12;
                    }
                    else {
                        confess "Can't parse ampm '$ampm'";
                    }
                }
                elsif ($ampm =~ m{\A $ampm_only_re \z}xin) {
                    $pm = $ampm =~ /^p/i ? 1 : 0;
                }
                elsif ($ampm =~ m{\A (h | hrs | hours) \z}xin) {
                    # Military times
                }
                else {
                    confess "Can't parse ampm '$ampm'";
                }

                if (defined $pm) {
                    if ($hour == 12 and $min == 00) {
                        # 12:00 am/pm is ambiguous let it be both
                        $hour = 0;
                        $abs_hour = 0;
                    }
                    elsif ($pm) {
                        # PM
                        $hour += 12
                            if $hour != 12;
                    } else {
                        # AM
                        if ($hour == 12) {
                            $hour = 0;
                        }
                    }
                }
            }
            elsif (not $abs_hour) {
                if ($hour > 12 or $hour == 0) {
                    # Otherwise, depending on the hour, there can only be one choice
                    $abs_hour = 1;
                }
                elsif ($hour == 12) {
                    # 12:20 could be either am or pm, so set it low so we get both
                    $hour = 0;
                }
            }

            # Look at the direction and see if we need to subtract the minutes rather than add
            if ($dir =~ $before_re) {
                $min = - $min;
                $min -= 1 if $sec;
            }

            # Always add in the m3, it's never negative
            $min += min2num($m3);

            # Always subtract the n1, it's always negative
            if ($un =~ /hour/i) {
                $hour -= min2num($n3);
            }
            elsif ($un =~ /second/i) {
                $min -= 1;
            }
            else {
                $min -= min2num($n3);
            }

            # Handle the rel2 phrase "a minute or two before"
            if ($rel2 =~ m{\A (?<a> $min_re | a (\s+ few)? | just (\s+ a)? ) \s+ ( minute s? \s+ )?
                              ( or \s+ (?<b> $min_re) \s+ )?
                              (?<r> before | after )
                           \z}xin)
            {
                my $a = min2num($+{a});
                my $b = min2num($+{b} // 0);
                my $r = $+{r};
                if ($r =~ $before_re) {
                    $min -= $a;
                }
                else {
                    $min += $a;
                }
            }

            # If we are in the afternoon then we are absolute
            $abs_hour = 1 if $hour > 12;

            # Add in the minutes for a recursive call
            $min += ( $abs // 0);

            my @hours = $hour;
            my @mins  = $min;
            my ($low, $high, $exp) =
                get_spread(make_c_str(\%c, \@k), $rel, $dir, $c{mn}, $c{m2}, $c{rl2});

            $high += ( $adj || 0 );
            if ($permute) {
                # If we are permuting, we don't need the relative expression
                $exp = '';

                # Handle the 12 hour clock ambiguity
                push @hours, $hour+12
                    unless $abs_hour;

                # Handle relative times by spreading the range
                @mins = ();
                for my $d ($low .. $high) {
                    push @mins, $min + $d;
                }
            }
            else {
                if (not $abs_hour) {
                    $exp = $exp eq '' ? 'ap' : "ap $exp";
                }
            }

            foreach my $h (@hours) {
                foreach my $m (@mins) {
                    my ($hour, $min) = fix_time($h, $m);
                    my $t = sprintf("%02d:%02d", $hour, $min);

                    $exp = $exp . ' '
                        if $exp ne '';

                    my $time = "$exp$t: " . make_c_str(\%c, \@k);

                    push @times, $time;
                }
            }
        }
    }

    return @times;
}

sub is_yearish {
    my ($str) = @_;

    if (defined $str and $str =~ m{\A \d{3,4} \z}xi and $str !~ m{\A 0\d{3} \z}xi) {
        # It looks like a year
        return 1;
    }

    return 0;
}

sub make_c_str {
    my ($c, $k) = @_;
    return join(" ",  map { defined $c->{$_} ? "$_<$c->{$_}>" : () } @$k );
}

sub fix_time {
    my ($h, $m) = @_;

    while ($m < 0) {
        $h -= 1;
        $m += 60;
    }

    while ($m > 59) {
        $h += 1;
        $m -= 60;
    }

    $h %= 24;

    return ($h, $m);
}

sub min2num {
    my ($min) = @_;
    confess "Missing arg min"
        unless defined $min;

    # Digits
    return $min if $min =~ m{\A \d+ \z}xin;

    # Fixed numbers
    return 0  if $min =~ m{\A ( oh \s* )+ \z}xin;
    return 1  if $min =~ m{\A ( a | an ) \z}xin;
    return 9  if $min =~ m{\A ( niner \s* )+ \z}xin;

    # Approximate times
    return 3  if $min =~ m{\A ( a \s+ few ) \z}xin;
    return 1  if $min =~ m{\A ( just (\s+ a)? ) \z}xin;

    # Fractions
    return 15 if $min =~ m{\A ( quarter | 1/4 ) \z}xin;
    return 20 if $min =~ m{\A ( third   | 1/3 ) \z}xin;
    return 30 if $min =~ m{\A ( half    | 1/2 ) \z}xin;
    return 45 if $min =~ m{\A ( three ($hy|\s)+ quarters
                              | third \s+ quarter
                              | 3/4
                               ) \z}xin;

    # Lose the leading oh-
    $min =~ s{\A ( oh ($hy|\s)+ ) }{}xin;

    # Strip out ellipses
    $min =~ s{$ellips}{ }g;

    $min = words2nums($min)
        // confess "Can't parse minute '$min'";

    return $min;
}

sub get_spread {
    my ($c, $rel, $dir, $min, $m2, $rl2) = @_;

    if ($rel eq '' and defined $dir and $dir ne '' and not defined $min) {
        return (-9, -1, '<')  if $dir =~ $before_re;
        return ( 1,  9, '>')  if $dir =~ $after_re;
    }

    if (not $rl2) {
        return (  0,  0, ''  )  if $rel eq '';
        return (-15, -5, '<<')  if $rel =~ m{\A $far_before_re   \z}xin;
        return ( -9, -1, '<' )  if $rel =~ m{\A ( $short_before_re
                                                | close ( \s+ upon )?
                                                ) \z}xin;
        return ( -6,  6, '~' )  if $rel =~ m{\A $around_re       \z}xin;
        return (  0,  6, '~' )  if $rel =~ m{\A $on_or_after_re  \z}xin;
        return (  1,  9, '>' )  if $rel =~ m{\A $short_after_re  \z}xin;
        return (  5, 15, '>>')  if $rel =~ m{\A $far_after_re    \z}xin;
    }

    if (defined $dir and $dir ne '') {
        if ($rel =~ m{\A ( (?<m> $min_re | a) \s+ (minutes? \s+)? or
                     | (?<r> a \s+ few | just (\s+ a)? )
                     )
                     \z}xin)
        {
            my $r    = $+{r};
            my $rmin = defined $+{m} ? min2num($+{m}) : 5;
            if (defined $min and $min ne '') {
                # We already used the min to set the time, so take that away from the spread
                $rmin -= min2num($min);
            }

            my $m = '-';
            $m = $dir =~ $before_re ? '<' : '>'
                if defined $r;

            $rmin = -$rmin if $dir =~ $before_re;
            return $rmin < 0 ? ($rmin, 0, $m) : (0, $rmin, $m);
        }
        elsif ($rel =~ m{\A ( between | $hy ) \z}xin and
               $min =~ m{\A (?<a> $min_re)
                            ( \s+ ( and | or ) \s+
                            | $hy
                            )
                            (?<b> $min_re) \z
                        }xin)
        {
            # Since we've already consumed the first number as minutes, we need to adjust by that
            my $rmin = min2num($+{b}) - min2num($+{a});

            $rmin = -$rmin if $dir =~ $before_re;
            return $rmin < 0 ? ($rmin, 0, '-') : (0, $rmin, '-');
        }
        elsif ($rl2 and
               $rl2 =~ m{\A (?<a> $min_re | a (\s+ few)? | just (\s+ a)? ) \s+ ( minute s? \s+ )?
                            ( or \s+ (?<b> $min_re) \s+ )?
                            (?<r> before | after )
                         \z}xin)
        {
            my ($a, $b, $r) = @+{qw{ a b r }};
            if ($a =~ m{\A a \s+ few \z}xin or $a =~ m{\A just \z}xin) {
                my $t = $a =~ m{\A just \z}xin ? 2 : 4;
                return $r =~ $before_re ? (-$t, 0, '<') : (0, $t, '>');
            }
            elsif ($a =~ m{\A just \s+ a \z}xin or not defined $b) {
                return (0, 0, '');
            }

            # Since we've already consumed the first number as minutes, we need to adjust by that
            my $rmin = min2num($b) - min2num($a);

            $rmin = -$rmin if $dir =~ $before_re;
            return $rmin < 0 ? ($rmin, 0, '-') : (0, $rmin, '-');
        }
    }
    else {
        return ( 0,  0, '' )  if $rel =~ m{\A ( until | at | till ) \z}xin;
        return (-5, -1, '<')  if $rel =~ m{\A ( before ) \z}xin;

        return ( 1, 15, '+') if "$rel $min" =~ m{\A nearer \s+ to \s+ half \z}xin;
    }

    confess "Can't parse rel '$rel'";
}

sub shorten_book {
    my ($book) = @_;

    if ($book !~ m{\A ( \QBridget Jones\E
                      | \QElric\E
                      | \QHow to Read Literature Like a Professor\E
                      | \QLuna\E
                      | \QPacific\E
                      | \QThe Conan Chronicles\E
                      | \QThe Lord God Made Them All\E
                      ) _
                   }xin)
    {
        $book =~ s{_ .*}{};
    }

    return $book;
}

sub strip_match {
    my ($string) = @_;

    while ($string =~ s{<< ([^|>]+) [|] \d+ \w? (:\d)? >>}{$1}gx) { }
    $string =~ s{<<(.*?)>>}{$1}g;

    return $string;
}

sub DEBUG_MSG {
    my @dump = @_;

    my ($package, $filename, $line) = caller;

    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Sortkeys = 1;
    print STDERR "Debug at $filename:$line:\n", Dumper(@dump);

    return;
}

1;
