package MADAWord;

#######################################################################
# MADAWord.pm
# Copyright (c) 2007-2012 Columbia University in 
#               the City of New York
#
# Please do not distribute to anyone else without written permission
# from authors.  If you know someone who can use this software, please 
# direct them to http://www1.ccls.columbia.edu/~cadim/MADA, where they
# may freely obtain the software.  Doing this helps us to understand how
# our software is being used, and to make future improvements tailored to
# the needs of users.
#
# MADA, TOKAN and ALMOR are distributed in the hope that they will be 
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
#
#
# For more information, bug reports, fixes, contact:
#    Nizar Habash, Owen Rambow and Ryan Roth
#    Center for Computational Learning Systems
#    Columbia University
#    New York, NY 10115
#    USA
#    habash@cs.columbia.edu
#    ryanr@ccls.columbia.edu
#
#######################################################################


use strict;
use warnings;
use MADA::MADATools;


=head1 NAME

    MADAWord -- Class for reading and viewing analysis information in MADA

=head1 SYNOPSIS

    use MADAWord;
    my $mword = MADAWord->new();         # Creates an empty MADAWord object
    open(FH, '<', "madafile.ma");
    while( $mword->readMADAWord(*FH) ) {
      # Loads the next word's worth of information from the FH madafile
      ...
      ( process word )
      ...
    }

=head1 DESCRIPTION

    This is a data structure class to hold all information relating to a particular Arabic word and
    its morphological analyses.

    Object Structure:

    $self->{word}        = The surface form of the word (ie, as it appears in the ;;WORD line)

    $self->{normword}    = As above, but normalized digits, alefs, trailing Ys and no diacritics.
                             If the word consists of nothing but diacritics, its normalized form
                             will equal to its surface form (that is, no change will be made).

    $self->{numanalyses} = The number of analyses the word has.

    $self->{starlabels}  = Reference to Array of in which each element is either "*", "^", "_" or "".
                             A "*" indicates the best possible analysis (as determined by annotation or
                             scoring). A "^" indicates an analysis that nearly tied with the "*" analysis
                             when scored; a "_" indicates an analysis which scored less than the "*"
                             analysis. A "" indicates that the analysis has not been scored and that,
                             if annotated, the analysis was not considered the best one available.

    $self->{scores}      = Reference to Array of scores for each analysis (if present).

    $self->{feats}       = Reference to Array of feature hash references, such that the keys are the set of 
                             principle features. The values are the values for that feature for that 
                             analysis. (i.e., $featureHash{"pos"} = "noun", $featureHash{"gen"} = "m", etc.) 
                             The default value for principal features is "na" for most, "noun" for pos.

    $self->{origanalyses} = Reference to an Array of the original analysis lines produced by the morphological
                             analyzer.

    $self->{noanalysis}  = 1 only if the word was marked as having no analysis

    $self->{sbreak}      = 1 if a SENTENCE BREAK was encountered. In this case, the rest of
                             the MADAWord object will be empty.

    $self->{pass}        = 1 only if the word was marked with a ;;PASS line; this is typically done
                             for foreign words or ones beginning with '@@', and means that this
                             word is not supposed to have analyses or be processed. This variable
                             can also be set in order to force scripts to not process a particular
                             word, even if it has valid analyses.

    $self->{blankline}   = 1 only if the readMADAWord or readMADAStars functions found a ;;; BLANK_LINE
                             comment in the .ma/.mada file, indicating that the input had a line with
                             no text or only whitespace.

    $self->{comments}    = Reference to Array of strings, which hold additional information about this
                             word, or any extra ";;" lines encountered when reading the .ma file.


    The starlabels, lexes, diacs, feats, and glosses arrays will always have the same number of elements. The
    scores array will either be empty or have the same number of elements (that is, if one analysis has a
    score, they all must have scores). 


=cut


#  Class 'constant' array & hash of main features: Older versions (pre MADA-3.0)
#my @oldfeatures = qw( art aspect case clitic conj def diac gen gloss idafa lexeme mood num part per pos voice );
#my %oldfeatures = ( "art"   => 1,  "aspect" => 1, "case"   => 1, "clitic" => 1,
#		 "conj"  => 1,  "def"    => 1, "diac"   => 1, "gen"    => 1, 
#		 "gloss" => 1,  "idafa"  => 1, "lexeme" => 1, "mood"   => 1,
#		 "num"   => 1,  "part"   => 1, "per"    => 1, "pos"    => 1,
#		 "voice" => 1 );
#my @oldtotalfeatures = qw( art aspect case clitic conj def diac gen gloss idafa lexeme mood num part per pos score
#		      starlabel voice );


# Class 'constant' array and hash of main features (MADA 3.0 and above)
##  Probably replace with dynamic Map later
#my @features = qw( asp bw cas diac enc0 enc1 enc2 gen gloss lex mod num per pos prc0 prc1 
#                   prc2 prc3 rat stt vox );

# Features with list of possible values; "open" means any value is allowed
#my %features = ( "diac"  => {"open"=>1},   
#		 "lex"   => {"open"=>1},  
#		 "bw"    => {"open"=>1},   
#		 "gloss" => {"open"=>1}, 
#		 "pos"  => {"noun"=>1, "noun_num"=>1, "noun_quant"=>1, "noun_prop"=>1, "adj"=>1, "adj_comp"=>1,
#		            "adj_num"=>1, "adv"=>1, "adv_interrog"=>1, "adv_rel"=>1, "pron"=>1, "pron_dem"=>1,
#		            "pron_exclam"=>1, "pron_interrog"=>1, "pron_rel"=>1, "verb"=>1, "verb_pseudo"=>1,
#		            "part"=>1, "part_det"=>1, "part_focus"=>1, "part_fut"=>1, "part_interrog"=>1,
#		            "part_neg"=>1, "part_restrict"=>1, "part_verb"=>1, "part_voc"=>1, "prep"=>1,
#		            "abbrev"=>1, "punc"=>1, "conj"=>1, "conj_sub"=>1, "interj"=>1, "digit"=>1,
#		            "latin"=>1 },    
#		 "prc0" => {"0"=>1, "na"=>1, "Al"=>1, "lA_neg"=>1, "mA_neg"=>1, "mA_rel"=>1, "mA_part"=>1 }, 
#                "prc1" => {"0"=>1, "na"=>1, "bi_part"=>1, "bi_prep"=>1, "ka_prep"=>1, "la_emph"=>1, "la_prep"=>1, 
#		            "la_rc"=>1, "li_jus"=>1, "li_prep"=>1, "sa_fut"=>1, "ta_prep"=>1, "wa_part"=>1,
#                            "wa_prep"=>1, "fy_prep"=>1, "lA_neg"=>1, "mA_neg"=>1, "yA"=>1, "wA"=>1, "hA"=>1 },
#		 "prc2" => {"0"=>1, "na"=>1, "fa_conj"=>1, "fa_conn"=>1, "fa_rc"=>1, "fa_sub"=>1, "wa_conj"=>1,
#                            "wa_part"=>1, "wa_sub"=>1 }, 
#		 "prc3" => {"0"=>1, "na"=>1, "A"=>1 }, 
#		 "per"  => {"1"=>1, "2"=>1, "3"=>1, "na"=>1 },   
#		 "asp"  => {"c"=>1, "i"=>1, "p"=>1, "na"=>1 }, 
#		 "vox"  => {"a"=>1, "p"=>1, "na"=>1, "u"=>1 }, 
#                "mod"  => {"i"=>1, "j"=>1, "s"=>1, "na"=>1, "u"=>1 },  
#		 "gen"  => {"f"=>1, "m"=>1, "na"=>1 },  
#		 "num"  => {"s"=>1, "d"=>1, "p"=>1, "na"=>1, "u"=>1 },  
#		 "stt"  => {"i"=>1, "d"=>1, "c"=>1, "na"=>1, "u"=>1 },   
#		 "cas"  => {"n"=>1, "a"=>1, "g"=>1, "na"=>1, "u"=>1 }, 
#		 "enc0" => {"0"=>1, "na"=>1, "1p"=>1, "1s"=>1, "2d"=>1, "2fp"=>1, "2fs"=>1, "2mp"=>1, "2ms"=>1,
#                            "3d"=>1, "3fp"=>1, "3fs"=>1, "3mp"=>1, "3ms"=>1, "Ah"=>1, "ma_interrog"=>1, 
#		            "mA_interrog"=>1, "man_interrog"=>1, "man_rel"=>1, "ma_rel"=>1, "mA_rel"=>1, 
#			    "ma_sub"=>1, "mA_sub"=>1, "lA_neg"=>1}, 
#		 "enc1" => {"0"=>1, "na"=>1 }, 
#		 "enc2" => {"0"=>1, "na"=>1 }, 
#		 "rat"  => {"n"=>1, "y"=>1, "na"=>1 } );

#my @totalfeatures = qw( asp bw cas diac enc0 enc1 enc2 gen gloss lex mod num per pos prc0 
#                        prc1 prc2 prc3 rat score starlabel stt vox );



=head2 Features

    These are the principal features defined within MADA to describe words and morphological
    analyses of words. Each of the principal features has a limited range of possible values. 
    Note that not all of these are used to classify analyses; this is noted when needed below.

    The features and their potential values are:
  
    Aspect: [c]ommand [i]mperfective [p]erfective [na]=not applicable
            asp    c i p na

    Buckwalter: (open class)
            bw     (open)
            Not used to classify analyses

    Case:  [n]ominative [a]ccusative [g]enitive [na]=not applicable [u]ndefined
            case   n a g na u

    Diacritization: (open class)
            diac   (open)

    Enclitics:   
            enc0   0 na 1p 1s 2d 2fp 2fs 2mp 2ms 3d 3fp 3fs 3mp 3ms Ah ma_interrog
                   mA_interrog man_interrog man_rel ma_rel mA_rel ma_sub mA_sub lA_neg
            enc1   0 na
                   Placeholder; Currently not used by MADA
            enc2   0 na
                   Placeholder; Currently not used by MADA
   
    Gender: [f]eminine [m]asculine [na]=not applicable
            gen    f m na

    Gloss:  (open class)
            gloss  (open)
            Not used to classify analyses

    Lexeme/Lemma:  (open class)
            lex    (open)

    Mood: [i]ndicative [j]ussive [s]ubjunctive [na]=not applicable [u]ndefined
            mod     i j s na u

    Number:  [s]ingular [d]ual [p]lural [na]=not applicable [u]ndefined
            num     s d p na u

    Person:  [1]st [2]nd [3]rd [na]=not applicable
            per     1 2 3 na

    Part of Speech (POS):
            pos     noun | noun_num | noun_quant | noun_prop | adj | adj_comp | adj_num
                    adv | adv_interrog | adv_rel | pron | pron_dem | pron_exclam 
                    pron_interrog | pron_rel | verb | verb_pseudo | part | part_det | part_focus 
                    part_fut | part_interrog | part_neg | part_restrict | part_verb | part_voc
                    prep | abbrev | punc | conj | conj_sub | interj | digit | latin

    Proclitics:
            prc0    0 na Al lA_neg mA_neg mA_rel mA_part
            prc1    0 na bi_part bi_prep ka_prep la_emph la_prep la_rc li_jus li_prep sa_fut ta_prep
                    wa_part wa_prep fy_prep lA_neg  mA_neg yA wA hA na
            prc2    0 na fa_conj fa_conn fa_rc fa_sub wa_conj wa_part wa_sub
            prc3    0 na A

    Rationality: [n]o [y]es [na]=not applicable
            rat     n y na
            Placeholder; currently not used by MADA and should not be considered reliable.

    State/Determination:  [i]ndefinite [d]efinite [c]construct/poss/idafa [na]=not applicable [u]ndefined
            stt     i d c na u

    Voice:  [a]ctive [p]assive [na]=not applicable [u]ndefined
            vox     a p na u



    Finally, there are two additional elements which are not features of the language itself,
    but are used within the library to mark properties. These are score and starlabel. 

    Score is a numerical value applied to an analysis to quantify its predicted correctness 
    relative to other analysis. Starlabel is a single character which is used simply to flag 
    analyses which are predicted to be the best or worst out of a set. Starlabel is one of 
    ("*", "^", "_" or "").

    The set of the principal features "main" feature set in this documentation. The set of these 
    plus score and starlabel is referred to as "total" feature set.


=cut


=head2 Methods

=head3 new

    MADAWord::new()
 
    my $mword = MADAWord->new();

    Constructor.  Creates an empty MADAWord object

=cut

sub new {
    my $class = shift;
    my $self = {};

    # Create blank entries for the MADAWord elements
    $self->{word}        = "";
    $self->{normword}    = "";
    $self->{noanalysis}  = 0;
    $self->{sbreak}      = 0;
    $self->{pass}        = 0;
    $self->{numanalyses} = 0;
    $self->{blankline}   = 0;

    $self->{starlabels}   = [];
    $self->{scores}       = [];
    $self->{feats}        = [];
    $self->{comments}     = [];
    $self->{origanalyses} = [];
    #$self->{stemorthnorm} = {};

    bless $self, $class;
    
    return $self;
}

=head3 Get Methods
    
    These methods retrieve data from the MADAWord object, or generate
    data from it, without changing anything in the object itself.

=head4 getWord

    MADAWord::getWord()
 
    my $word = $mword->getWord();

    Returns the surface form of the word represented by this MADAWord.
    If the MADAWord object is empty, a "" value will be returned.

=cut

sub getWord {
    my $self = shift;
    return $self->{word};
}

##################################################################################

=head4 getNormWord

    MADAWord::getNormWord()

    my $normword = $mword->getNormWord();
 
    Return the normalized form of the surface word. The normalizations currently
    used include:  
       digits -> '8'
       all 'Y' characters -> 'y'
       Alef normalization ( alefs -> 'A' )
       Diacritic stripping ( [uiao~FKN\`] -> '' )

    None of the above steps are taken if the surface form of the word begins with
    "@@"; in this case, getNormWord() and getWord() return the same value.

    If the MADAWord object is empty, a "" value will be returned.

=cut

sub getNormWord {
    my $self = shift;
    return $self->{normword};
}

##################################################################################


=head4 isNoAnalysis

    MADAWord::isNoAnalysis()  
    
    if( $mword->isNoAnalysis() ) { ... }
    else { ... }

    Returns 1 if this set was marked as NO-ANALYSIS; returns 0 otherwise.
    Returns 0 if the MADAWord is empty.

=cut

sub isNoAnalysis {
    my $self = shift;
    my $val = 0;
    if( $self->{noanalysis} == 1 ) { $val = 1; }
    return $val;    
}

##################################################################################


=head4 isPass

    MADAWord::isPass()
    
    if( $mword->isPass() ) { ... }
    else { ... }

    Returns 1 if this word is marked as PASS (that is, a word that has no analyses 
    and should not be processed, such as a foreign word).
    Returns 0 if this word is not a PASS word, or if the MADAWord is empty.

=cut

sub isPass {
    my $self = shift;
    my $val = 0;
    if( $self->{pass} == 1 ) { $val = 1; }
    return $val;
}

##################################################################################


=head4 isSentenceBreak

    MADAWord::isSentenceBreak()

    if( $mword->isSentenceBreak() ) { ... }

    Returns 1 if the MADAWord represents a SENTENCE BREAK; in this case, the rest of 
    the MADAWord elements will be empty.

    Returns 0 if the MADAWord is empty.

=cut

sub isSentenceBreak {
    my $self = shift;
    my $val = 0;
    if( $self->{sbreak} == 1 ) { $val = 1; }
    return $val;
}

##################################################################################


=head4 isBlankLine

    MADAWord::isBlankLine()

    if( $mword->isBlankLine() ) { ... }

    Returns 1 if the MADAWord represents a line that was either empty or
    contained only whitespace.  In this case, the rest of 
    the MADAWord elements will be empty.

    Returns 0 if the MADAWord is empty.

=cut

sub isBlankLine {
    my $self = shift;
    return $self->{blankline};
}

##################################################################################


=head4 getNumAnalyses

    MADAWord::getNumAnalyses()

    my $numanalyses = $mword->getNumAnalyses();

    Returns total number of analyses found in this MADAWord object; returns 0
    if the MADAWord is empty.

=cut

sub getNumAnalyses {
    my $self = shift;
    return $self->{numanalyses};
}

##################################################################################


=head4 hasScores

    MADAWord::hasScores()

    if( $mword->hasScores() ) { ... }

    Returns 1 if the analyses have been given scores; returns 0 otherwise.

=cut

sub hasScores {
    my $self = shift;
    my $val = 0;
    if( scalar( @{ $self->{scores} } ) > 0 ) { $val = 1; }
    return $val;
}

##################################################################################


=head4 getScore

    MADAWord::getScore($index)

    my $score = $mword->getScore(2);  # Returns the score of the 3rd analysis in this MADAWord

    Returns the score indicated by the specified index number; returns "" if 
    the index is out-of-bounds for this word, if the MADAWord is empty, or if no
    score is attached to this analysis.
    
    Index numbers start at index 0.

=cut

sub getScore {
    my $self = shift;
    my $index = shift;
    my $l = "";
    if( $index >= 0 && $index < scalar( @{ $self->{scores} } ) ) {
	$l = $self->{scores}->[$index];
    }
    return $l;
}

##################################################################################


=head4 getScores

    MADAWord::getScores()  
    
    my @scores = @{ $mword->getScores() };

    Returns a reference to an array of scores in this MADAWord object; this array 
    is a copy of the scores array, so changes to it will not be translated into the 
    MADAWord object. The array will be empty if the MADAWord is empty. The order of 
    elements in the array will be identical to the original order of analyses. If 
    no scores have been given to the analyses, this function will return an empty 
    array.

=cut

sub getScores {
    my $self = shift;
    my @a = @{ $self->{scores} };
    return \@a;
}

##################################################################################



=head4 getOrigAnalysis

    MADAWord::getOrigAnalysis($index)

    my $a = $mword->getOrigAnalysis(2);  # Returns the 3rd original input analysis 
                                         #   in this MADAWord

    Returns the original analysis, as read by readMADAWord() and indicated by 
    the specified index number; returns "" if the index is out-of-bounds for this 
    word or if the MADAWord is empty.
    
    Index numbers start at index 0.

=cut

sub getOrigAnalysis {
    my $self = shift;
    my $index = shift;
    my $l = "";
    if( $index >= 0 && $index < scalar( @{ $self->{origanalyses} } ) ) {
	$l = $self->{origanalyses}->[$index];
    }
    return $l;
}

##################################################################################


=head4 getOrigAnalyses

    MADAWord::getOrigAnalyses()  
    
    my @Oanalyses = @{ $mword->getOrigAnalyses() };

    Returns a reference to an array of original analyses in this MADAWord object; this array 
    is a copy of the array, so changes to it will not be translated into the 
    MADAWord object. The array will be empty if the MADAWord is empty. The order of 
    elements in the array will be identical to the original order of analyses.

=cut

sub getOrigAnalyses {
    my $self = shift;
    my @a = @{ $self->{origanalyses} };
    return \@a;
}

##################################################################################




=head4 getLex

    MADAWord::getLex($index)

    my $lex = $mword->getLex(2);  # Returns the lexeme of the 3rd analysis in this MADAWord

    Returns the lexeme indicated by the specified index number; returns "" if 
    the index is out-of-bounds for this word, if the MADAWord is empty, or if
    the lex feature was not determined for the given analysis.
    
    Index numbers start at index 0.

=cut

sub getLex {
    my $self = shift;
    my $index = shift;
    my $l = "";
    if( $index >= 0 && $index < scalar( @{ $self->{feats} } ) ) {
	if( exists $self->{feats}->[$index]->{lex} ) {
	    $l = $self->{feats}->[$index]->{lex};
	}
    }
    return $l;
}

##################################################################################


=head4 getLexes

    MADAWord::getLexes()

    my @lexes = @{ $mword->getLexes() };

    Returns a reference to an array of lexemes in this MADAWord object. Returned array 
    will be empty if the MADAWord is empty. The order of the array returned will be 
    identical to the original order of analyses.

    If the lex feature was not determined for this word, the returned array will
    be filled with "" elements.

=cut

sub getLexes {
    my $self = shift;
    return $self->getFeatureArray('lex');
}

##################################################################################


=head4 getNormLex

    MADAWord::getNormLex($index)

    my $lex = $mword->getNormLex(2);  
    # Returns the normalized lexeme of the 3rd analysis in this MADAWord

    Returns the normalized lexeme (the lexeme with its trainling _\d+ stripped 
    off) indicated by the specified index number; returns "" if the index is 
    out-of-bounds for this word or if the MADAWord is empty.
    
    Index numbers start at index 0.

=cut

sub getNormLex {
    my $self = shift;
    my $index = shift;
    return &MADATools::normalizeLex( $self->getLex($index) );
}

##################################################################################


=head4 getNormLexes

    MADAWord::getNormLexes()

    my @normlexes = @{ $mword->getNormLexes() };
 
    Returns a reference to an array of the lexemes of this MADAWord object with their 
    trailing _\d+ stripped off. Returned array will be empty if the MADAWord is 
    empty. The order of the array returned will be identical to the original order 
    of analyses.

    If the lex feature was not determined for this word, the returned array will
    be filled with "" elements.

=cut

sub getNormLexes {
    my $self = shift;
    my @nlex = ();
    foreach( @{ $self->getFeatureArray('lex') } ) {
	push @nlex,  &MADATools::normalizeLex( $_ );
    }
    return \@nlex;
}

##################################################################################


=head4 getDiac

    MADAWord::getDiac($index)

    my $diac = $mword->getDiac(2);  
    # Returns the diacritic form of the 3rd analysis in this MADAWord

    Returns the diacritic form indicated by the specified index number; returns "" if 
    the index is out-of-bounds for this word, if the MADAWord is empty, or if 
    the diac feature was not determined for this analysis.
    
    Index numbers start at index 0.

=cut

sub getDiac {
    my $self = shift;
    my $index = shift;
    my $l = "";
    if( $index >= 0 && $index < scalar( @{ $self->{feats} } ) ) {
	if( exists $self->{feats}->[$index]->{diac} ) {
	    $l = $self->{feats}->[$index]->{diac};
	}
    }
    return $l;
}

##################################################################################


=head4 getDiacs

    MADAWord::getDiacs()

    my @diacs = @{ $mword->getDiacs() };

    Return a reference to an array of diacritic forms in this MADAWord object. 
    The array will be empty if the MADAWord is empty. The order of the array 
    returned will be identical to the original order of analyses.

    If the diac feature was not determined for this word, the returned array will
    be filled with "" elements.

=cut

sub getDiacs {
    my $self = shift;
    return $self->getFeatureArray('diac');
}



##################################################################################

=head4 getFeatHash

    MADAWord::getFeatHash($index)

    my %feats = %{ $mword->getFeatHash(2) };  
    # Returns a reference to a hash of feature values for the 3rd analysis

    Returns a feature hash reference (where the features are keys and their values 
    are the hash values) for the analysis indicated by the specified index number; 
    returns an empty hash if the index is not valid for this word or if the MADAWord 
    is empty.

    The keys of the returned hash are the elements of the main feature set, plus
    normlex (normalized version of lexeme).
 
    Index numbers start at index 0.

=cut

sub getFeatHash {
    my $self = shift;
    my $index = shift;
    my %feats = ();
    if( $index >= 0 && $index < scalar( @{ $self->{feats} } ) ) {
	%feats = %{ $self->{feats}->[$index] };
    }
    ## Add normlex too:
    $feats{normlex} = $self->getNormLex($index);

    #print STDERR "------\n";
    #foreach( keys %feats ) { print STDERR "$_ = $feats{$_}\n"; }
    return \%feats;
}

##################################################################################


=head4 getFeatLine

    MADAWord::getFeatLine($index)

    my $featline = $mword->getFeatLine(2);  
    # Returns the feat line of the 3rd analysis in this MADAWord

    Returns a feat line (in "feature-value feature-value ..." format) 
    indicated by the specified index number; returns "" if the index is 
    not valid for this word or if the MADAWord is empty.

    The keys of the returned hash are the elements of the main feature set.
 
    Index numbers start at index 0.

=cut

sub getFeatLine {
    my $self = shift;
    my $index = shift;
    my $l = "";

    my ($f,$v);
    if( $index >= 0 && $index < scalar( @{ $self->{feats} } ) ) {
	foreach $f ( sort keys %{ $self->{feats}->[$index] } ) {
	    $v = $self->{feats}->[$index]->{$f};
	    if( $v ne "" ) {
		$l .= "$f\:$v ";
	    }
	}
    }
    $l =~ s/\s$//;
    return $l;
}

##################################################################################


=head4 getFeatLines

    MADAWord::getFeats()

    my @feats = @{ $mword->getFeatLines() };

    Return a reference to an array of features in this MADAWord object in 
    "feature-value feature-value ..." format. Returned array will be empty if the 
    MADAWord is empty. The order of the array returned will be identical to the 
    original order of analyses.

=cut

sub getFeatLines {
    my $self = shift;
    my @arr = ();
    my $i;
    for( $i = 0; $i< scalar( @{ $self->{feats} } ); $i++ ) {
	push @arr, $self->getFeatLine($i);
    }
    return \@arr;
}

##################################################################################


=head4 getFeature

    MADAWord::getFeature($feat,$index)

    my $pos = $mword->getFeature("pos",2);   # The POS of the 3rd analysis
    my $gen = $mword->getFeature("gen",0);   # The GEN of the 1st analysis
    my $case = $mword->getFeature("cas",4); # The CAS of the 5th analysis
   
    Returns the feature value of a specific feature for a specified analysis. 
    For example, getFeature("pos",0) returns the POS of first analysis in
    this MADAWord analysis set (such as "N" or "PX").

    The specified feature can be any one of the "total" feature set
    elements.

    Returns "" if the index given is out-of-range for this word, if the MADAWord 
    is empty, or if the feature specified is invalid.

=cut

sub getFeature {
    my $self = shift;
    my ($feat, $index) = @_;
    my $val = "";
    
    $feat = lc( $feat ); 
  
    if( $feat =~ /^starlabel$/ ) {
	$val = $self->getStarLabel($index);
    }
    elsif( $feat =~ /^score$/ ) {
	$val = $self->getScore($index);
    }
    elsif( $feat =~ /^normlex(eme)?$/ ) {
	$val = $self->getNormLex($index);
    }
    elsif( $index >= 0 && $index < scalar( @{ $self->{feats} } ) ) {
	if( exists $self->{feats}->[$index]->{$feat} ) {
	    $val = $self->{feats}->[$index]->{$feat};
	}
    }
    return $val;
}

##################################################################################


=head4 getFeatureArray

    MADAWord::getFeatureArray($feat)

    my @pos  = @{ $mword->getFeatureArray("pos")  };
    my @gen  = @{ $mword->getFeatureArray("gen")  };
    my @cas  = @{ $mword->getFeatureArray("cas") };

    Returns a reference to an array of the feature values of a specific feature. 
    For example, getFeatureArray("pos") returns a referenct to a new array of all 
    the POS values found in this MADAWord analysis set (in order).  

    The specified feature can be any one of the "total" feature set
    elements.

    Specifying the feature to be "score", or "starlabel", does the equivalent of 
    calling getScores() or getStarLabels(), respectively.

    Returned array  will be empty if the MADAWord is empty, or if the given feature 
    is not a valid one. The order of the array returned will be identical to the 
    original order of analyses.

=cut

sub getFeatureArray {
    my $self = shift;
    my $feat = shift;
    my @arr = ();
    my $i;
    $feat = lc( $feat ); 
   
    
    if( $feat =~ /^starlabel$/ ) {
	return $self->getStarLabels();
    }
    elsif( $feat =~ /^score$/ ) {
	return $self->getScores();
    }
    else {
	for( $i = 0; $i< scalar( @{ $self->{feats} } ); $i++ ) {
	    push @arr, $self->getFeature($feat,$i);
	}
    }

    return \@arr;
}

##################################################################################


=head4 getGloss

    MADAWord::getGloss($index)

    my $gloss = $mword->getGloss(2);  
    # Returns the gloss of the 3rd analysis in this MADAWord

    Returns the gloss indicated by the specified index number; returns "" if 
    the index is out-of-bounds for this word, if the MADAWord is empty, or if
    the feature gloss is not determined for this analysis.
    
    Index numbers start at index 0.

=cut

sub getGloss {
    my $self = shift;
    my $index = shift;
    my $l = "";
    if( $index >= 0 && $index < scalar( @{ $self->{feats} } ) ) {
	if( exists $self->{feats}->[$index]->{gloss} ) {
	    $l = $self->{feats}->[$index]->{gloss};
	}	
    }
    return $l;
}

##################################################################################

=head4 getGlosses

    MADAWord::getGlosses()

    my @glosses = @{ $mword->getGlosses() };

    Return the array of glosses in this MADAWord object. Returned array will be 
    empty if the MADAWord is empty. The order of the array returned will be identical 
    to the original order of analyses.

    If the gloss feature was not determined for this word, the returned array will
    be filled with "" elements.

=cut

sub getGlosses {
    my $self = shift;
    return $self->getFeatureArray('gloss');
}

##################################################################################


=head4 isStar

    MADAWord::isStar($index)

    my $ret = $mword->isStar(2);  # Is the 3rd analysis a starred analysis?

    Returns 1 if the analysis specified by the given index is a starred analysis.
    Returns 0 if the analysis is not.
    Returns -1 if the specified index is out-of-bounds.


=cut

sub isStar {
    my $self = shift;
    my $index = shift;
    my $ret = -1;
    if( $index >= 0 && $index < scalar( @{ $self->{starlabels} } ) ) {
	if( $self->{starlabels}->[$index] eq "*" ) {
	    $ret = 1;
	}
	else { $ret = 0; }
    }
    return $ret;
}

##################################################################################


=head4 getStarIndices

    MADAWord::getStarIndices()

    my @starindices = @{ $mword->getStarIndices() };

    Returns a reference to an array of the indices of all the analyses in this 
    MADAWord that have been flagged with a "*" (that is, marked as correct in the 
    annotation). Returns an empty list if no analysis is marked with a star or if 
    the MADAWord is empty.

=cut

sub getStarIndices {
    my $self = shift;
    my @arr = ();
    my $i;
    for($i = 0; $i< scalar( @{ $self->{starlabels} } ); $i++ ) {
	if( $self->{starlabels}->[$i] eq "*" ) {
	    push @arr, $i;
	}
    }
    return \@arr;
}

##################################################################################


=head4 getStarLabel

    MADAWord::getStarLabel($index)

    my $label = $mword->getStarLabel(2); # Return the label of the 3rd analysis

    Returns the star label (that is, "*", "^", "_" or "") for the specified
    analysis. Returns "" if the index is out-of-bounds for this word or if 
    the MADAWord is empty.
    
    Index numbers start at index 0.

=cut

sub getStarLabel {
    my $self = shift;
    my $index = shift;
    my $l = "";
    if( $index >= 0 && $index < scalar( @{ $self->{starlabels} } ) ) {
	$l = $self->{starlabels}->[$index];
    }
    return $l;
}

##################################################################################

=head4 getStarLabels

    MADAWord::getStarLabels()

    my @labels = @{ $mword->getStarLabels() };

    Return the array of star labels (that is, "*", "^", "_" or ""), one for each 
    analysis in this MADAWord object. The returned array will be empty if the 
    MADAWord is empty. The order of the array returned will be identical to the 
    original order of analyses.

=cut

sub getStarLabels {
    my $self = shift;
    my @a = @{ $self->{starlabels} };
    return \@a;
}

##################################################################################

=head4 getComment

    MADAWord::getComment($commentname)

    my $comment = $mword->getComment("SENTENCE"); 
    # grabs the comment line beginning with ";;SENTENCE" if it exists

    Returns a particular comment line associated with this MADAWord object.

    The argument is the first word that appears after the ";;" in the comment line.
    Whitespace can be placed between the ";;" and the word. There can also be 2 or 
    more ";" characters (that is, a comment starting with ";;;  SENTENCE" could be
    returned by the above command).

    If more than one of the MADAWord comment lines matches the query, this function
    will return the last one entered into its list. If none match, or if the MADAWord 
    is empty, the returned string will be "".


=cut

sub getComment {
    my $self = shift;
    my $query = shift;
    my $comment = "";

    foreach( @{ $self->{comments} } ) {
	if( $_ =~ /^;;+\s*$query\s+/ ) {
	    $comment =  $_;
	}
    }

    return $comment;
}


##################################################################################

=head4 getComments

    MADAWord::getComments()

    my @comments = @{ $mword->getComments() };

    Returns a reference to an array of comment strings associated with this MADAWord 
    object.

    The returned array will be empty if the MADAWord is empty or if no extra comment
    lines were encountered or added.


=cut

sub getComments {
    my $self = shift;
    my @a = @{ $self->{comments} };
    return \@a;
}


##################################################################################

=head4 getFeatureCounts

    MADAWord::getFeatureCounts($feat)

    my %list = %{ $mword->getFeatureCounts("pos") }; 
               # Returns a hash of all the possible POS values 
 
    %list = %{ $mword->getFeatureCounts("case") };   
               # Returns a hash of all the possible case values

    %list = %{ $mword->getFeatureCounts("lex") }; 
               # Returns a hash of all the possible lexeme values

    Returns a reference to a hash of all the potential values of the given feature, 
    as specified by these analyses. The keys of the hash are the possible values of 
    this feature; the values are number of analyses that used this particular value 
    for this feature.

    The specified feature can be any one of the "total" feature set elements, plus 
    "normlexeme". If "normlexeme" is chosen, the lexemes will be normalized prior to
    building the feature count hash.

    Returns an empty hash if the MADAWord is empty or the specified feature is 
    not in the above feature set.

=cut

sub getFeatureCounts {
    my $self = shift;
    my $feat = shift;
    
    my %list = ();
    my $val;

    my $a;
    if( $feat =~ /^normlex(eme)?$/i  ) {
	$a = $self->getNormLexes();
    }
    else {
	$a = $self->getFeatureArray($feat);
    }

    foreach $val ( @{$a} ) {	
	if( exists $list{$val} ) { $list{$val} += 1; }
	else { $list{$val} = 1; }
    }	

    return \%list;
}


##################################################################################

=head4 getStemOrthNorm

    MADAWord::getStemOrthNorm($index)

    my $bw = $mword->getStemOrthNorm(2);  
    # Returns the orthnorm stem of the 3rd analysis

    Returns the ortho-normalized stem of the given analysis, if known. 
    If the word did not have a orthnorm stem entry, the return value
    will be an empty string.

    Index numbers start at index 0.

=cut

sub getStemOrthNorm {
    my $self = shift;
    my $index = shift;
    my $stem = "";
    if( $index >= 0 && $index < scalar( @{ $self->{feats} } ) ) {
	if( exists $self->{feats}->[$index]->{'orthnorm'}) {
	    $stem = $self->{feats}->[$index]->{'orthnorm'};
	}
    }
    return $stem;

}

##################################################################################

=head4 getStemOrthNorms

    MADAWord::getStemorthnorms()

    my %bw = %{ $mword->getStemOrthNorms() };  
    # Returns an reference to an array of orthnorm stems of these analyses

    Returns a reference to an hash of the ortho-normalized stems of the analyses in 
    this MADAWord, if known. 


    Index numbers start at index 0.

=cut

sub getStemOrthNorms {
    my $self = shift;
    return $self->getFeatureArray('orthnorm');
}


##################################################################################

=head4 getBWA

    MADAWord::getBWA($index)

    my $bw = $mword->getBWA(2);  
    # Returns the Buckwalter Analysis portion of the 3rd analysis

    Returns the Buckwalter analysis portion of the specified analysis, if it was
    present when the MADAWord was read. Returns "" if the BW was absent, if
    the index is out-of-bounds for this word, if the MADAWord is empty, or if
    the bw feature was not determined for this analysis.
    
    Index numbers start at index 0.

=cut

sub getBWA {
    my $self = shift;
    my $index = shift;
    my $bw = "";
    if( $index >= 0 && $index < scalar( @{ $self->{feats} } ) ) {
	if( exists $self->{feats}->[$index]->{'bw'} ) {
	    $bw = $self->{feats}->[$index]->{'bw'};
	}
    }
    return $bw;
}

##################################################################################

=head4 getBWAs

    MADAWord::getBWAs()

    my @bw = @{ $mword->getBWAs() };  
    # Returns an array of the Buckwalter Analysis portions of these analyses

    Return the array of Buckwalter analyses in this MADAWord object. Returned array will be 
    empty if the MADAWord is empty. The order of the array returned will be identical 
    to the original order of analyses.

    If the gloss feature was not determined for this word, the returned array will
    be filled with "" elements.

=cut

sub getBWAs {
    my $self = shift;
    return $self->getFeatureArray('bw');

#    my $i;
#    my @bw = ();
#    my $b;
#    my $empty = 1;
#    for( $i = 0; $i< scalar( @{ $self->{feats} } ); $i++ ) {
#	$b = $self->{feats}->[$i]->{'bw'};
#	if( $b ne "" ) { $empty = 0; }
#	push @bw, $b;
#    }

#    if( $empty ) { @bw = (); }
#    return \@bw;
}

##################################################################################

=head4 getSortedAnalysisIndices

    MADAWord::getSortedAnalysisIndices()

    my @sorted = @{ $mword->getSortedAnalysisIndices() }; 

    Returns a reference to an array which lists the indices of the
    analyses of this MADAWord, sorted in descending order according to
    score.

    If the word has no scores, the returned array keeps the
    indices in their original order.


=cut

sub getSortedAnalysisIndices {
    my $self = shift;
    my @arr = ();
    my $i;
    
    my $n = $self->getNumAnalyses();

   if( $self->hasScores() ) {
	my %s = ();
	for( $i=0; $i<$n; $i++) {
	    $s{$i} = $self->getScore($i);
	}
	foreach $i ( sort {$s{$b} <=> $s{$a}} keys %s ) {
	    push @arr, $i;
	}
    }
    else {	
	for( $i=0; $i<$n; $i++) {
	    $arr[$i] = $i;
	}
    }


    return \@arr;
}


##################################################################################

=head3 Utility Methods

    These methods perform operations on the data within the MADAWord object, adding
    to it or modifying it in some way.

=head4 readMADAWord

    MADAWord::readMADAWord($filehandle)

    my $mword = &MADAWord->new();         # Creates an empty MADAWord object
    open(FH, '<', "madafile.ma");
    while( $mword->readMADAWord(*FH) ) {
        ...
        { process MADAWord information }
        ...     
    }
    close(FH);

    Reads information about one word from Mada file (one word block); fills MADAWord 
    with that information. Existing information in MADAWord is overwritten. Assumes 
    provided filehandle is already open. Does not close filehandle.

    Any additional ';;' (that are not ;;WORD or ;;PASS) are placed in the comment 
    list of this word.

    A word block that is read with a single call to this function can consist of:
        1) A regular word and its associated analyses,
        2) a SENTENCE BREAK,
        3) a word marked as having NO-ANALYSIS,
    or  4) a word that has a ;;PASS line, such as a foreign word or one beginning 
             with '@@'

    Case 2 is identified by the isSentenceBreak() function.
    Case 3 is identified by the isNoAnalysis() function. 
    Case 4 is identified by the isPass() function. In this case, readMADAWord will 
      also set the $self->{noanalysis} variable.

    Returns 1 if the set was read without problems; 0 if the EOF was reached, and 
    -1 if a problem was encountered.


=cut

sub readMADAWord {
    my $self = shift;
    my $filehandle = shift;
    my $result = 0;

    if( ! -r $filehandle ) { 
	print STDERR "MADAWord::readMADAWord : Unable to read from filehandle $filehandle\n";
	return -1; 
    } # Fail if the file can't be read

    # Clean out old MADAWord data
    $self->{word}       = "";    $self->{normword}    = "";
    $self->{noanalysis} = 0;     $self->{sbreak}      = 0;
    $self->{pass}       = 0;     $self->{numanalyses} = 0;
    $self->{blankline}  = 0;

    $self->{starlabels}   = [];  $self->{scores}       = [];
    $self->{feats}        = [];  $self->{comments}     = [];
    $self->{origanalyses} = [];
    #$self->{stemorthnorm} = {};

    my $line = "";
    my $word = "";
    my @analyses = ();
    my $blankline = 0;

    while( $line = <$filehandle> ) {

	chomp $line;
	#print "LINE = $line\n";
	if( $line =~/^-------------*$/){ 

	    if( $word ne "" || $blankline ) {
		$result = 1;
		$blankline = 0;
		last;
	    }
	    # If $word eq "", then this is probably an extraneous line,
	    #  so we keep going.

	}
	elsif( $line =~/^;;; BLANK-LINE/ ) {
	    $blankline = 1;
	    $self->{blankline} = 1;
	    push @{ $self->{comments} }, $line;
	}
	elsif($line=~/^;;WORD (\S+)/){ 
	    $word = $1;
	    $self->{word} = $word;
	    $self->{normword} = &MADATools::normalizeWord($word);
	}
	elsif($line=~/^SENTENCE BREAK$/){
	    $self->{sbreak} = 1;
	    $line = <$filehandle>;  ## Remove following dashed line
	    $result = 1;
	    last;
	}
	elsif($line=~/^;;PASS /){ 
	    $self->{pass} = 1;
	    $self->{noanalysis} = 1;	   
	}
	elsif($line =~ /^NO-ANALYSIS/ ) {
	    $self->{noanalysis} = 1;
	    push @analyses,  $line;
	}
	elsif( $line =~ /^;;/ ) {
	    push @{ $self->{comments} }, $line;
	}
	elsif(  $line!~/^;;/ && $line !~ /^\s*$/  ) {
	    push @analyses,  $line;   ## Assume any non-comment, non-blank line is an analysis
	}

    }

    $self->addAnalyses( \@analyses );	    

    # $result is 1 now if a Word was read or a SENTENCE BREAK encountered; if
    #  it is still 0, the EOF was reached.
    
    return $result;

}


##################################################################################

=head4 readMADAStars

    MADAWord::readMADAStars($filehandle)

    my $mword = &MADAWord->new();         # Creates an empty MADAWord object
    open(FH, '<', "madafile.ma");
    while( $mword->readMADAStars(*FH) ) { # Only read the analyses which are flagged with *
        ...
        { process MADAWord information }
        ...     
    }
    close(FH);


    This function operates in the same way as readMADAWord, except that it will only
    read in analyses which are labeled with "*". If none of the analyses is starred,
    the resulting word will have no analyses, but the word and normalized word
    will still be filled.

    readMADAStars handles PASS, NO-ANALYSIS, and SENTENCE BREAKS in the same way as
    readMADAWord.

    This function will also add the following comment to the word:
      
       ";;TOTAL_NUMBER_OF_ANALYSES = X"
    
    where X is the total number of analyses encountered when this word was read 
    (starred and unstarred).		

    Returns 1 if the set was read without problems; 0 if the EOF was reached, and 
    -1 if a problem was encountered.


=cut

sub readMADAStars {
    my $self = shift;
    my $filehandle = shift;
    my $result = 0;

    if( ! -r $filehandle ) { 
	print STDERR "MADAWord::readMADAStars : Unable to read from filehandle $filehandle\n";
	return -1; 
    } # Fail if the file can't be read

    # Clean out old MADAWord data
    $self->{word}       = "";    $self->{normword}    = "";
    $self->{noanalysis} = 0;     $self->{sbreak}      = 0;
    $self->{pass}       = 0;     $self->{numanalyses} = 0;
    $self->{blankline}  = 0;


    $self->{starlabels}   = [];  $self->{scores}       = [];
    $self->{feats}        = [];  $self->{comments}     = [];
    $self->{origanalyses} = [];
    #$self->{stemorthnorm} = {};

    my $line = "";
    my $word = "";
    my $num = 0;
    my @analyses = ();
    my $blankline = 0;

    while( $line = <$filehandle> ) {

	chomp $line;
	#print "LINE = $line\n";
	if( $line =~/^-------------*$/){ 

	    if( $word ne "" || $blankline ) {
		$result = 1;
		$blankline = 0;
		last;
	    }
	    # If $word eq "", then this is probably an extraneous line,
	    #  so we keep going.

	}
	elsif( $line =~/^;;; BLANK-LINE/ ) {
	    $blankline = 1;
	    $self->{blankline} = 1;
	    push @{ $self->{comments} }, $line;	
	}
	elsif($line=~/^;;WORD (\S+)/){ 
	    $word = $1;
	    $self->{word} = $word;
	    $self->{normword} = &MADATools::normalizeWord($word);
	}
	elsif($line=~/^SENTENCE BREAK$/){
	    $self->{sbreak} = 1;
	    $line = <$filehandle>;
	    $result = 1;
	    last;
	}
	elsif($line=~/^;;PASS /){ 
	    $self->{pass} = 1;
	    $self->{noanalysis} = 1;	   
	}
	elsif($line =~ /^NO-ANALYSIS/ ) {
	    $self->{noanalysis} = 1;
	    push @analyses,  $line; 
	}
	elsif( $line =~ /^;;/ ) {
	    push @{ $self->{comments} }, $line;
	}
	elsif( $line!~/^;;/ && $line !~ /^\s*$/ ) {
	    if( $line =~ /^\*/ ) {
		#print STDERR "$line\n";
		push @analyses, $line;   ## Record starred analyses only
	    }
	    $num++;
	}

    }
    
    $self->addAnalyses( \@analyses );

    # Add a comment line to indicate the total number of analyses this word had,
    #   in case that information is useful later
    my $l = ";;TOTAL_NUMBER_OF_ANALYSES = $num";
    push @{ $self->{comments} }, $l;

    # $result is 1 now if a Word was read or a SENTENCE BREAK encountered; if
    #  it is still 0, the EOF was reached.
    
    return $result;

}


##################################################################################


=head4 addAnalyses

    MADAWord::addAnalyses(\@analysesToAdd,$newword)

    my $mword = &MADAWord->new();       # Creates an empty MADAWord object
    my @extraAnalyses = ("...","...","...");

    my $n = $mword->addAnalyses(\@extraAnalyses, "myWord");  
            # adds extra Analyses and sets the word to 'myWord'
    $n = $mword->addAnalyses(\@otherAnalyses);            
            # adds some more analyses
    
    Takes an array of analysis lines and appends those analyses to the existing 
    MADAWord set. If a second argument is provided and the MADAWord is empty, 
    the second argument will be used as the MADAWord surface word.

    Before adding each extra analysis, the analysis is compared to each analysis 
    already stored in the MADAWord object; duplicate analyses are not added to 
    the MADAWord.

    Returns the number of analyses that were added.

=cut

sub addAnalyses {
    my $self = shift;
    my ($aref, $aword) = @_;

    # Set word if given AND if word not set already
    if( ! defined $aword ) { $aword = ""; }
    elsif( $self->{word} eq "" ) {
	$self->{word} = $aword;
	$self->{normword} = &MADATools::normalizeWord($aword);
    }
    
    my $line;
    my $useScores = 1; # Assume scores are present
    my $n = 0;
    my $prevNum = $self->{numanalyses};

    $self->{numanalyses} += scalar( @{ $aref} );

    foreach $line ( @{ $aref } ) {

	push @{ $self->{origanalyses} }, $line;

	if( $line =~ /^NO-ANALYSIS/ ) {
	    $self->{noanalysis} = 1;
	}
	else {

	    $n++;
	    
	    # First, remove any orthonorm tags that might be present
	    #if( $line =~ s/orthnorm\:(\S+)// ) {
		#my $key = $n + $prevNum - 1;
		#$self->{orthnorm}->{$key} = $1;
	    #}

	    # Second, strip off star label and score if present
	    my $label = "";
	    my $score = "";
	    if( $line =~ s/^([\*\^\_])(\-?\d+\.\d+) // ) {
		$label = $1;
		$score = $2;
	    }
	    elsif( $line =~ s/^([\*\^\_]) // ) {
		$label = $1;
	    }
	    elsif( $line =~ s/^(\-?\d+\.\d+) // ) {
		$score = $1;
	    }

	    push @{ $self->{starlabels} }, $label;


	    if($useScores == 1 && $score ne "" ) {
		push @{ $self->{scores} }, $score;		
	    }
	    elsif( $useScores == 1 && $score eq "" ) {
		# If you are adding an analysis without a score,
		#  any scores already in the MADAWord are invalid, so blank them out.
		$useScores = 0;
		$self->{scores} = [];
	    }


	    # Third, fill the feature hash using the remainder of the analysis line
	    # $feats is a reference to a hash.
	    my $feats = &_readFeatures($line);

	    # Load the analysis into the MADAWord structure
	    push @{ $self->{feats} }, $feats;


	}

    }

    return $n;

}


##################################################################################


=head4 printMADAWord

    MADAWord::printMADAWord(\%options)

    $mword->printMADAWord();  # Print this word's information to STDOUT

    my %options = ( filehandle => *FH, nosort=>1 );
    $mword->printMADAWord(\%options);  #Print this word's information to the 
                                       # file handle FH, but use the options 
                                       # indicated

    This method prints the information contained in the MADAWord to a file. The 
    format of printing will be the same as a .ma file, but will include scores if 
    they are present.

    Possible options (with examples) are:

        nosort => 1         : Do not sort the analyses; if not set, the function 
                              will try to sort the analyses by score (if scores 
                              are present). If no scores are present, sort will 
                              be done on star labels only.

        filehandle => *FH   : Causes the output to be written to FH; default 
                              filehandle is STDOUT

        featureguesses => "EdnAn pos:noun_prop prc3:0 prc2:0 prc1:0 prc0:0 per:na 
                                 asp:na vox:na mod:na gen:m num:s stt:i cas:u enc0:0"

                            : A feature line produced by feature classifiers for 
                              this word. If given, it is printed in a ";;SVM_PREDICTIONS " 
                              line comment. 

        reducedprint => <number> | stars | all
                            : tells whether to print all the analyses, just the
                              star analyses, or up to a set number of unique scoring
                              analyses from the top of the list (e.g., the analyses
                              which have the 3 top scores, which could be more than 3
                              if some of them are tied).

 
    Returns -1 if there is a problem with writing; otherwise returns 1.

=cut

sub printMADAWord {
    my $self = shift;
    my $oref = shift;

    my $filehandle = *STDOUT;
    if( defined $oref->{filehandle} ) { $filehandle = $oref->{filehandle}; }

    if ( ! -w $filehandle ) {
	print STDERR "MADAWord::printMADAWord : Unable to write to filehandle $filehandle\n";
	return -1;
    }

    my $featline = "";
    if( defined $oref->{featureguesses} ) { $featline = $oref->{featureguesses}; }
 
    my $sort = 1;
    if( defined $oref->{nosort} ) { if( $oref->{nosort} == 1 ) { $sort = 0; } }

    my $reduced = "all";
    if( defined $oref->{reducedprint} ) { 
	$reduced = $oref->{reducedprint};
	if( $reduced !~ /^(\d+|stars|all)$/i ) {
	    $reduced = "all";
	}
    }

    my $word = $self->{word};    

    # Print out any comment lines this MADAWord has first, in order
    my @postwordcomments = ();
    my $com;
    foreach $com ( @{ $self->{comments} } ) {
	if( $com =~ /^;;(MADA|PASS|NO-ANALYSIS|PATB|\#)/ ) {
	    push @postwordcomments, $com;
	}
	else {
	    print $filehandle "$com\n";
	    if( $com =~ /^;;; BLANK-LINE/ ) {	
		print $filehandle "--------------\n";
		return 1;	
	    }
	}
    }

    if( $self->{sbreak} == 1 ) {               ## Print Sentence Breaks
	print $filehandle "SENTENCE BREAK\n";
    }
    elsif( $self->{noanalysis} == 1 ) {        ## Print No Analysis cases
	
	print $filehandle ";;WORD $word\n";
	print $filehandle ";;NO-ANALYSIS\n";
	my $madalinecomment = 0;
	foreach( @postwordcomments ) {
	    if( ! /^;;NO-ANALYSIS/ ) {
		print $filehandle $_, "\n";
	    }
	    if (/^;;(MADA|SVM_PREDICTIONS):/) { $madalinecomment = 1; }
	}
	if( $madalinecomment == 0 && $featline ne "" ) {
	    print $filehandle ";;SVM_PREDICTIONS: $featline\n";
	}

	if( $self->{pass} == 1 ) {
	    print $filehandle ";;PASS $word\n";
	}
	else {
	    print $filehandle "NO-ANALYSIS [$word]\n";
	}
	
    }
    else {
	print $filehandle ";;WORD $word\n";
	my $madalinecomment = 0;
	foreach( @postwordcomments ) {
	    print $filehandle $_, "\n";
	    if (/^;;(MADA|SVM_PREDICTIONS):/) { $madalinecomment = 1; }
	}
	if( $madalinecomment == 0 && $featline ne "" ) {
	    print $filehandle ";;SVM_PREDICTIONS: $featline\n";
	}

	if( $self->{pass} == 1 ) {
	    print $filehandle ";;PASS $word\n";
	}
	else {

	    my @originals = @{ $self->{origanalyses}  };
	    my @scores    = @{ $self->getScores()     }; # May be empty
	    my @starlabs  = @{ $self->getStarLabels() }; # May be empty
	    my $i;

	    # Format Scores
	    for($i=0;$i<=$#scores;$i++) {		
		$scores[$i] = sprintf("%.6f",$scores[$i]);
	    }

	    ## Add orthnorm terms if present
	    #for($i=0; $i<=$#originals; $i++ ) {
		#if( exists $self->{stemorthnorm}->{$i} ) {
		    #$originals[$i] .= " orthonorm\:$self->{stemorthnorm}->{$i}";
		#}
	    #}
	    
	    my $score;
	    my $star;
	    my $outline;
	    my $numtopscores = 0;
	    my $lastscore = "";

	    if( $sort && $self->hasScores() ) {  ## Most common setting; print in order of scores
		#Sort by score
		my %s = ();
		for( $i=0; $i<=$#scores; $i++) {
		    $s{$i} = $scores[$i];
		}
		foreach( sort {$s{$b} <=> $s{$a}} keys %s ) {
		    
		    if( defined $scores[$_] ) { $score = $scores[$_]; }
		    else { $score = ""; }

		    if( $score ne $lastscore ) {  
			$lastscore = $score; 
			$numtopscores++;
		    }

		    if( defined $starlabs[$_] ) { $star = $starlabs[$_]; }
		    else { $star = ""; }
		    
		    $outline = $originals[$_];
		    $outline =~ s/^[\*\^\_]\-?[\d\.]*\s+//;  # Remove any score from the original line, if present, and replace
		    $outline = $star . $score . " $outline";
		    $outline =~ s/^\s+//;

		    
		    if( $reduced eq "all" ) {
			print $filehandle "$outline\n"; # Print All: Use original analysis line in output
		    }
		    elsif( $reduced eq "stars" ) {
			if( $star eq "\*" ) {
			    print $filehandle "$outline\n"; # Print Stars only: Use original analysis line in output			    
			}
		    }
		    elsif( $reduced =~ /^(\d+)$/ ) {
			if( $numtopscores <= $1 ) {
			    print $filehandle "$outline\n"; # Print only top scores: Use original analysis line in output
			}
		    }
		    

		}
	    }
	    elsif( $sort ) {  ## Sort by star label -- there are no scores for this MADAWord
		my @stars = ();
		my @c = ();
		my @u = ();
		my @o = ();
		my $i;
		
		# Divide indices by star labels; print in order of label
		for( $i=0; $i<=$#starlabs; $i++) {
		    if( $starlabs[$i] eq "*" ) {
			push @stars, $i;
		    }
		    elsif( $starlabs[$i] eq "^"  && $reduced ne "stars" ) {
			push @c, $i;
		    }
		    elsif( $starlabs[$i] eq "_" && $reduced ne "stars" ) {
			push @u, $i;
		    }
		    elsif ($reduced ne "stars" ) { 
			push @o, $i; 
		    }
		}
		
		#print "Nlabels = " . scalar( @labels ) . "\n";
		#print "Nstars  = " . scalar( @stars ) . "\n";
		#print "Nc      = " . scalar( @c ) . "\n";
		#print "Nu      = " . scalar( @u ) . "\n";
		#print "No      = " . scalar( @o ) . "\n";		

		foreach( @stars ) {  ## Stars
		    if( defined $scores[$_] ) { $score = $scores[$_]; }
		    else { $score = ""; }
		    if( $score ne $lastscore ) {  
			$lastscore = $score; 
			$numtopscores++;
		    }


		    $outline = $originals[$_];
		    $outline =~ s/^[\*\^\_]\-?[\d\.]*\s+//;  # Remove any score from the original line, if present
		    $outline = "*$score $outline";
		    #print $filehandle "$outline\n";

		    if( $reduced eq "all" ) {
			print $filehandle "$outline\n"; # Print All: Use original analysis line in output
		    }
		    elsif( $reduced =~ /^(\d+)$/ ) {
			if( $numtopscores <= $1 ) {
			    print $filehandle "$outline\n"; # Print only top scores: Use original analysis line in output
			}
		    }

		    
		}
		foreach( @c ) {  ## Carats
		    if( defined $scores[$_] ) { $score = $scores[$_]; }
		    else { $score = ""; }
		    if( $score ne $lastscore ) {  
			$lastscore = $score; 
			$numtopscores++;
		    }

		    $outline = $originals[$_];
		    $outline =~ s/^[\*\^\_]\-?[\d\.]*\s+//;  # Remove any score from the original line, if present
		    $outline = "^$score $outline";
		    #print $filehandle "$outline\n";
		    if( $reduced eq "all" ) {
			print $filehandle "$outline\n"; # Print All: Use original analysis line in output
		    }
		    elsif( $reduced =~ /^(\d+)$/ ) {
			if( $numtopscores <= $1 ) {
			    print $filehandle "$outline\n"; # Print only top scores: Use original analysis line in output
			}
		    }

		}
		foreach( @u ) {  ## Underscores
		    if( defined $scores[$_] ) { $score = $scores[$_]; }
		    else { $score = ""; }
		    if( $score ne $lastscore ) {  
			$lastscore = $score; 
			$numtopscores++;
		    }

		    $outline = $originals[$_];
		    $outline =~ s/^[\*\^\_]\-?[\d\.]*\s+//;  # Remove any score from the original line, if present
		    $outline = "_$score $outline";
		    #print $filehandle "$outline\n";
		    if( $reduced eq "all" ) {
			print $filehandle "$outline\n"; # Print All: Use original analysis line in output
		    }
		    elsif( $reduced =~ /^(\d+)$/ ) {
			if( $numtopscores <= $1 ) {
			    print $filehandle "$outline\n"; # Print only top scores: Use original analysis line in output
			}
		    }

		}
		foreach( @o ) {  ## Others?
		    if( defined $scores[$_] ) { $score = $scores[$_]; }
		    else { $score = ""; }
		    if( $score ne $lastscore ) {  
			$lastscore = $score; 
			$numtopscores++;
		    }

		    $outline = $originals[$_];
		    $outline =~ s/^[\*\^\_]\-?[\d\.]*\s+//;  # Remove any score from the original line, if present
		    $outline = "$score $outline";
		    $outline =~ s/^\s+//;
		    #print $filehandle "$outline\n";
		    if( $reduced eq "all" ) {
			print $filehandle "$outline\n"; # Print All: Use original analysis line in output
		    }
		    elsif( $reduced =~ /^(\d+)$/ ) {
			if( $numtopscores <= $1 ) {
			    print $filehandle "$outline\n"; # Print only top scores: Use original analysis line in output
			}
		    }

		}
	    }
	    else { 
		#  No sorting; may have scores in MADAWord
		for($i=0; $i<=$#originals; $i++ ) {

		    if( defined $scores[$i] ) { $score = $scores[$i]; }
		    else { $score = ""; }

		    if( $score ne $lastscore ) {  
			$lastscore = $score; 
			$numtopscores++;
		    }

		    if( defined $starlabs[$i] ) { $star = $starlabs[$i]; }
		    else { $star = ""; }

		    $outline = $originals[$i];
		    $outline =~ s/^[\*\^\_]\-?[\d\.]*\s+//;  # Remove any score from the original line, if present		    
		    $outline = $star . $score . " $outline";
		    $outline =~ s/^\s+//;
		    #print $filehandle "$outline\n";

		    if( $reduced eq "all" ) {
			print $filehandle "$outline\n"; # Print All: Use original analysis line in output
		    }
		    elsif( $reduced eq "stars" ) {
			if( $star eq "\*" ) {
			    print $filehandle "$outline\n"; # Print Stars only: Use original analysis line in output			    
			}
		    }
		    elsif( $reduced =~ /^(\d+)$/ ) {
			if( $numtopscores <= $1 ) {
			    print $filehandle "$outline\n"; # Print only top scores: Use original analysis line in output
			}
		    }
		}

	    }
	}
    }


    print $filehandle "--------------\n";
    return 1;
	
}


##################################################################################

=head4 compareAnalyses

    MADAWord::compareAnalyses($one,$two)

    my $cmp = $mword->compareAnalyses(0,3);  
    # Compare the first and fourth analysis of this MADAWord

    This method compares all the elements of the two analyses indicated by the 
    provided indices. It returns a space-delimited string of features for which 
    the two analyses differ. This string can contain any of the elements from
    the "total" feature set, including starlabel and score. 

    If one or both of the provided indices is out-of-bounds, the function will 
    return the string "InvalidIndices". The same will happen if the MADAWord is 
    empty, if the MADAWord represents a SENTENCE BREAK, or if the MADAWord is 
    tagged as having NO-ANALYSIS.

    If there are no differences between the two analyses, or if the two provided 
    indices are identical, the returned string will be "".

=cut

sub compareAnalyses {
    my $self = shift;
    my ($one,$two) = @_;

    my $ret = "";
    my $num = $self->getNumAnalyses();

    if( $self->isSentenceBreak() || $self->isPass() || 	$self->isNoAnalysis() || 
	$one < 0 || $two < 0 || $one >= $num ||	$two >= $num ) {
	
	$ret = 'InvalidIndices';
    }
    else {

	my $f;
	foreach $f ( keys %{ $self->getFeatHash($one) } ) {
	    if( $self->getFeature($f,$one) ne 
		$self->getFeature($f,$two) ) {
		$ret .= "$f ";
	    }
	}

	$ret =~ s/\s+$//;

    }

    return $ret;

}

##################################################################################


=head4 removeAnalysesWithFeatureValue

    MADAWord::removeAnalysesWithFeatureValue($f,$v)

    my $n = $mword->removeAnalysesWithFeatureValue("pos","V");       
            # Removes all analyses which have a POS value of "V"
    $n = $mword->removeAnalysesWithFeatureValue("lex","DEFAULT"); 
            # Removes all analyses which have a lexeme = "DEFAULT"
    $n = $mword->removeFeatureWithFeatureValue("starlabel","*");
            # Removes all starred analyses

    Given a feature and a particular value, this function removes all analyses from 
    this MADAWord which use that value for that feature.  Valid features are any
    of those from the "total" feature set.

    If the feature or provided value is invalid, nothing happens to the MADAWord.

    If the MADAWord is a SENTENCE BREAK, has NO-ANALYSIS, or is marked as PASS, 
    nothing is done to it.

    After removing analyses, any previously determined analysis index values may 
    no longer be accurate.

    Returns the number of analyses removed.


=cut

sub removeAnalysesWithFeatureValue {
    my $self = shift;
    my ($f,$v) = @_;

    if( $self->isSentenceBreak() || $self->isNoAnalysis() ||
	$self->isPass() ) {
	return 0;
    }

    my $i;
    my @removes = ();
    my $num = $self->getNumAnalyses();
    for( $i=0; $i<$num; $i++ ) {
	if( $self->getFeature($f,$i) eq $v ) {
	    push @removes, $i;
	}
    }

    
    return $self->removeAnalyses( \@removes );
}


##################################################################################


=head4 removeAllButOneAnalysis

    MADAWord::removeAllButOneAnalysis($keep)

    my $n = $mword->removeAllButOneAnalysis($keep);       
            # Removes all analyses except for the one with index $keep

    Given an analysis index, this function removes all analyses from 
    this MADAWord that do not have that index.

    If the index is invalid, nothing happens to the MADAWord.

    If the MADAWord is a SENTENCE BREAK, has NO-ANALYSIS, or is marked as PASS, 
    nothing is done to it.

    After removing analyses, any previously determined analysis index values may 
    no longer be accurate.

    Returns the number of analyses removed.


=cut

sub removeAllButOneAnalysis {
    my $self = shift;
    my $keep = shift;

    if( $self->isSentenceBreak() || $self->isNoAnalysis() ||
	$self->isPass() ) {
	return 0;
    }

    my $num = $self->getNumAnalyses();
    if( $keep < 0 || $keep >= $num ) {
	return 0;
    }


    my $i;
    my @removes = ();
    for( $i=0; $i<$num; $i++ ) {
	if( $keep != $i ) {
	    push @removes, $i;
	}
    }
    
    $self->{starlabels}->[$keep] = "*";

    return $self->removeAnalyses( \@removes );
}


##################################################################################

=head4 removeAnalyses

    MADAWord::removeAnalyses(\@indicesToRemove)

    my @remove = (0,3,4);
    my $n = $mword->removeAnalyses(\@remove); 
            # Remove the first, fourth and fifth analyses from this MADAWord

    Given a reference to an array of indices, this function removes the analyses 
    referred to by those indices from this MADAWord. If a specified index is 
    out-of-bounds, it is ignored.

    After removing analyses, any previously determined analysis index values may 
    no longer be accurate.

    If the MADAWord is a SENTENCE BREAK, has NO-ANALYSIS, or is marked as PASS, 
    nothing is done to it.
   
    Returns the number of analyses that were removed.

=cut

sub removeAnalyses {
    my $self = shift;
    my $rref = shift;

    if( $self->isSentenceBreak() || $self->isNoAnalysis() ||
	$self->isPass() ) {
	return 0;
    }

    my %removes = ();
    my $index;
    my $num = $self->getNumAnalyses();
    foreach $index ( @{ $rref } ) { 
	if( $index >= 0 && $index < $num ) {
	    $removes{$index} = 1; 
	}
    }

    # Return if all the provided indices are invalid
    if( scalar( keys %removes ) == 0 ) { return 0; } 

    my $n = 0;
    
    my $i;
    my @scores  = ();    my @labels  = ();
    my @feats   = ();    my @originals = ();


    for( $i = 0; $i<$num; $i++ ) {

	if( ! exists $removes{$i} ) {
	    push @labels, $self->{starlabels}->[$i];
	    push @feats, $self->{feats}->[$i];
	    push @originals, $self->{origanalyses}->[$i];

	    if( defined $self->{scores}->[$i] ) {
		push @scores, $self->{scores}->[$i];
	    }	    
	}
	else { $n++; }
    }

    if( $n > 0 ) {
	
	$self->{feats}       = \@feats;
	$self->{starlabels}  = \@labels;
	$self->{scores}      = \@scores;
	$self->{origanalyses} = \@originals;
	$self->{numanalyses} -= $n;
    }

    return $n;

}


##################################################################################


=head4 conflateAnalyses

    MADAWord::conflateAnalyses()

    my $n = $mword->conflateAnalyses();

    This function goes through the analyses in MADAWord and removes those which are 
    identical to ones already present in the MADAWord. It compares the features 
    individually (via the compareAnalysis function), rather than the MADA file 
    analysis line as a whole. It ignores differences in score and the star label.

    This function is typically used after processing has altered the features. For 
    example, choosing to drop the lexeme distinctions, or choosing to drop one 
    or more features entirely. This function reduces the number of duplicates 
    produced when such distinctions are removed.

    If the MADAWord is a SENTENCE BREAK, has NO-ANALYSIS, or is marked as PASS, 
    nothing is done to it.
    
    Returns the total number of duplicates that are removed.

=cut

sub conflateAnalyses {
    my $self = shift;

    if( $self->isSentenceBreak() || $self->isNoAnalysis() ||
	$self->isPass() ) {
	return 0;
    }

    my $i;
    my $j;

    my %removes = ();

    my $num = $self->getNumAnalyses();
    my $diff;
    for( $i = 0; $i<$num; $i++ ) {
	if( ! exists $removes{$i} ) {
	    for( $j = $i + 1; $j < $num; $j++ ) {
	    
		if( ! exists $removes{$j} ) {
		    $diff = $self->compareAnalyses($i,$j);

		    # Ignore labels and score
		    $diff =~ s/starlabel//;
		    $diff =~ s/score//;
		    $diff =~ s/\s+//g;

		    if( $diff eq ""  ) { 
			# If $j has a star, remove $i; otherwise remove $j
			if( $self->getStarLabel($j) ne "*" ) {
			    $removes{$j} = 1; 
			}
			else { 
			    $removes{$i} = 1; 
			    last;
			}
		    }
		    

		}

	    }
	}
    }

    # %removes now contains duplicate indices

    my @r = keys %removes;
    my $n = 0;
    if( scalar( @r ) > 0 ) {
	$n = $self->removeAnalyses( \@r );
    }

    return $n;
}


##################################################################################


=head4 normalizeLexemesAndConflate

    MADAWord::normalizeLexemesAndConflate()

    my $n = $mword->normalizeLexemesAndConflate();

    This function goes through all the analyses and removes the "_\d+" tags from the
    tail of the lexeme entries in $mword->{lexes}. 

    After removing the lexeme suffixes, the function calls conflateAnalyses()
    to remove any duplicate entries that are produced when these distinctions 
    are removed.

    If the MADAWord is a SENTENCE BREAK, has NO-ANALYSIS, or is marked as PASS, 
    nothing is done to it.

    Returns the total number of analyses that are removed.

=cut

sub normalizeLexemesAndConflate {
    my $self = shift;

    if( $self->isSentenceBreak() || $self->isNoAnalysis() ||
	$self->isPass() ) {
	return 0;
    }

    my $num = $self->getNumAnalyses();
    my $i;
    for( $i = 0; $i<$num; $i++ ) {
	$self->{feats}->[$i]->{lex} = 
	    &MADATools::normalizeLex( $self->{feats}->[$i]->{lex} );
    }
    
    return $self->conflateAnalyses();    
}

##################################################################################


=head4 removeFeatureDistinction

    MADAWord::removeFeatureDistinction($f,$v)

    my $n = $mword->removeFeatureDistinction("gen", "f");
      # Replaces the value of gen with "f" for each analysis, and then
      #  returns the number of analyses that didn't have gen:f to begin with
    my $n = $mword->removeFeatureDistinction("lex");
      # Replaces the lexeme with "na" for each analysis, and then
      #  returns the number of analyses that had their lexeme changed. 

    This function goes through all the analyses and replaces the value of the
    specified feature with the specified value. 
    
    Valid Features are any from the "main" feature set. If the specified value
    is not possible for the given feature, 0 is returned with no change to the 
    MADAWord.
   
    If a value is not specified, a default of "na" will be used for the 
    principal features. Scores and starlabels cannot be changed with this method.

    If the MADAWord is a SENTENCE BREAK, has NO-ANALYSIS, or is marked as PASS, 
    nothing is done to it.

    Returns the total number of analyses for which that feature was changed.

=cut

sub removeFeatureDistinction {
    my $self = shift;
    my ($f,$v) = @_;

    if( defined $f ) { 
	$f = lc( $f ); 
	#if( ! exists $features{$f} ) { return 0; }      
    }
    else{ return 0; }

    if( $self->isSentenceBreak() || 
	$self->isNoAnalysis() ||
	$self->isPass() ) {
	return 0;
    }

    my $n = 0;

    if( ! defined $v ) {
	$v = "na";
    }
    #elsif ( ! exists $features{$f}->{"open"} && ! exists $features{$f}->{$v} ) {
	#return 0;
    #}



    my $num = $self->getNumAnalyses();
    my $i;
    for( $i = 0; $i<$num; $i++ ) {
	if( exists $self->{feats}->[$i]->{$f} ) {
	    $self->{feats}->[$i]->{$f} = $v;
	}
    }
    
    return $n;
}




##################################################################################



=head4 setPass

    MADAWord::setPass($val)

    my $result = $mword->setPass(1);  # sets the $self->{pass} variable to 1
    $result = $mword->setPass(0);  # sets the $self->{pass} variable to 0

    This function can control the value of the $self->{pass} variable. If this is on,
    it is a signal that this MADAWord should not be processed. It is up to the scripts
    which use this library to check the value of this variable via isPass() and act
    accordingly.

    The function does nothing if the provided argument is not 0 or 1.

    Returns the new value of the $self->{pass} variable.

=cut

sub setPass {
    my $self = shift;
    my $val = shift;
    if( $val == 0 || $val == 1 ) { $self->{pass} = $val; }
    return $self->{pass};
}


##################################################################################

=head3 Private Class Methods

    These methods are not linked to a particular MADAWord object instance;
    rather they perform simple text processing on their input arguments
    and return a result. 

=head4 _readFeatures

    MADAWord::_readFeatures($aline)

    my %feats = %{ &MADAWord->_readFeatures($analysisline) };
    
    Private class method -- this should not be used outside this module.

    Takes a word and a feature line (i.e., diac:val lex:val bw:...etc. format) 
    and generates a hash of feature key-value pairs. Returns a reference to this
    hash.

    The function ensures that each read feature value is allowable for that feature
    before recording it (if not, that part of the line entry is ignored).

    This version of the function labels feature values with "*"
    if their value cannot be determined directly from the line. 

=cut

sub _readFeatures {

    my ($aline) = @_;

    ## Load default values
    ##my %newfeats = ( "diac"=>"*", "lex"=>"*", "bw"=>"*", "gloss"=>"*",
	          ##"pos"=>"*", "prc0"=>"*", "prc1"=>"*", "prc2"=>"*", "prc3"=>"*",
	          ##"per"=>"*", "asp"=>"*", "vox"=>"*", "mod"=>"*", "gen"=>"*", 
	          ##"num"=>"*", "stt"=>"*", "cas"=>"*", "enc0"=>"*", "enc1"=>"*",
	          ##"enc2"=>"*", "rat"=>"*" );

    my %newfeats = ();

    my @toks = split(/\s+/,$aline);
    foreach my $t ( @toks ) {

	if( $t =~ /^([^\:\s]+)\:(\S+)$/ ) {
	    my $f = lc( $1 );
	    my $v = $2;
	    $newfeats{$f} = $v;

	    #if ( exists $features{$f}->{$v} || exists $features{$f}->{"open"} ) {
	      #$newfeats{$f} = $v;
	    #}

	}


    }

    return \%newfeats;
}







##################################################################################

=head1 KNOWN BUGS

    Currently in Development.  No bugs known.

=cut


=head1 SEE ALSO

    MADATools, TOKAN, ALMOR3

=cut

=head1 AUTHOR

    Ryan Roth, Nizar Habash, Owen Rambow
    
    Center for Computational Learning Systems
    Columbia University
    
    Copyright (c) 2007,2008,2009,2010 Columbia University in the City of New York

=cut


1;
