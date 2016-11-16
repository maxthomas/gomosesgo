Notes on processing pipeline for 1.8

Pre/post processing pipeline now looks like this:

1. remove-non-printing-char.perl  - removes Unicode nonbreaking spaces, RTL/LTR markers, etc
2. pretag-twitter-zone.perl - XML marks-up URLS, Handles, and sets translation boundaries on the contents of hashtags
3. moses_mada_proc_zone.perl - applies MADA morph. processing to portions of sentence not explicitly tagged - converts Arabic to Buckwalter representation
4. Decode with Moses2
5. deescape-special-chars.perl - converts characters reserved by moses from their escaped to original form (e.g. &amp; -> & )
6. debuckwalter_oov.perl - converts any remaining Buckwalter-encoded Arabic out-of-vocabulary words back to Arabic script (lossy conversion!)
7. remove-oov-tags.perl - removes <OOV> and </OOV> tags surrounding unknown words.
8. detokenizer.perl - reverses tokenization

PERL5LIB should be set as follows in the container:

PERL5LIB=/home/moses/bin/MADA-3.2:/home/moses/bin

