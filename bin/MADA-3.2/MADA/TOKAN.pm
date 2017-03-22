package TOKAN;

#######################################################################
# TOKAN.pm
# Copyright (c) 2005-2012 Columbia University in 
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
# October 13, 2010 Patch: support for GLOSS FORM mode added
#######################################################################


=head1 NAME

    TOKAN.pm  -- A package containing functions used with TOKAN-related scripts.

=head1 DESCRIPTION

    These functions are used to initialize or parse TOKAN data structures or
    schemes.

=cut

use strict;
use warnings;
use MADA::ALMOR3;
use MADA::MADATools;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( initialize_POSTAGS parse_scheme tokenize BW2CATIB BW2PENN );



################################################################################
###    Global, "Static" Variables


my %POSTAGS = ();  ##  Essentially a lookup table for converting between different POS tagsets

##################################################################################

=head2 Methods



=head3 initialize_POSTAGS

    &TOKAN::initialize_POSTAGS();

    This function takes no arguments.

    This function fills the POSTAGS lookup-table with POS conversion information.
    This table is never changes; this function need only be called once.

    This function must be called before other TOKAN.pm functions are used.

=cut

sub initialize_POSTAGS {

    my %POS2SPOS = ( 'noun' => 'N', 'noun_num' => 'N', 'noun_quant' => 'N', 
		     'noun_prop' => 'PN', 'adj' => 'AJ', 'adj_comp' => 'AJ', 
		     'adj_num' => 'AJ', 'adv' => 'AV', 'adv_interrog' => 'Q', 
		     'adv_rel' => 'REL', 'pron' => 'PRO', 'pron_dem' => 'D', 
		     'pron_exclam' => 'PRO', 'pron_interrog' => 'Q', 
		     'pron_rel' => 'REL', 'verb' => 'V', 'verb_pseudo' => 'P', 
		     'part' => 'P', 'part_det' => 'D', 'part_focus' => 'P', 
		     'part_fut' => 'P', 'part_interrog' => 'P', 'part_neg' => 'NEG', 
		     'part_restrict' => 'P', 'part_verb' => 'P', 'part_voc' => 'P',
		     'prep' => 'P', 'abbrev' => 'AB', 'punc' => 'PX', 'conj' => 'C',
		     'conj_sub' => 'P', 'interj' => 'IJ', 'digit' => 'NUM', 'latin' => 'F',
		     'det' => 'D', 'rel' => 'REL', 'neg' => 'NEG', 'voc' => 'P', 
		     'ques' => 'P', 'sub' => 'P', 'interrog' => 'Q', 'emph' => 'P', 
		     'rc' => 'P', 'jus' => 'P', 'fut' => 'P', 'conn' => 'P', 'dem' => 'D',
		     'poss' => 'PRO', 'pron' => 'PRO', 'dobj' => 'PRO');
    $POSTAGS{"POS2SPOS"}=\%POS2SPOS;


    my %POS2CATIB = ( 'noun' => 'NOM', 'noun_num' => 'NOM', 'noun_quant' => 'NOM', 
		     'noun_prop' => 'PROP', 'adj' => 'NOM', 'adj_comp' => 'NOM', 
		     'adj_num' => 'NOM', 'adv' => 'NOM', 'adv_interrog' => 'NOM', 
		     'adv_rel' => 'NOM', 'pron' => 'NOM', 'pron_dem' => 'NOM', 
		     'pron_exclam' => 'NOM', 'pron_interrog' => 'NOM', 
		     'pron_rel' => 'NOM', 'verb' => 'VRB,VRB_PASS', 'verb_pseudo' => 'PRT', 
		     'part' => 'PRT', 'part_det' => 'PRT', 'part_focus' => 'PRT', 
		     'part_fut' => 'PRT', 'part_interrog' => 'PRT', 'part_neg' => 'PRT', 
		     'part_restrict' => 'PRT', 'part_verb' => 'PRT', 'part_voc' => 'PRT',
		     'prep' => 'PRT', 'abbrev' => 'PROP', 'punc' => 'PNX', 'conj' => 'PRT',
		     'conj_sub' => 'PRT', 'interj' => 'NOM', 'digit' => 'NUM', 'latin' => 'NOM',
		     'det' => 'PRT', 'rel' => 'NOM', 'neg' => 'PRT', 'voc' => 'PRT', 
		     'ques' => 'PRT', 'sub' => 'PRT', 'interrog' => 'PRT', 'emph' => 'PRT', 
		     'rc' => 'PRT', 'jus' => 'PRT', 'fut' => 'PRT', 'conn' => 'PRT', 'dem' => 'PRT',
		     'poss' => 'NOM', 'pron' => 'NOM', 'dobj' => 'NOM');
    $POSTAGS{"POS2CATIB"}=\%POS2CATIB;

    #based on ATB3v3.1
    my %POS2PENN = ( 'adj_num' => 'ADJ_NUM', 'conj' => 'CC', 'noun_num' => 'CD',
		     'det' => 'DT', 'pron_dem' => 'DT', 'dem' => 'DT', 'part_det' => 'DT',
		     'prep' => 'IN', 'conj_sub' => 'IN', 'adj' => 'JJ,VN', 'adj_comp' => 'JJR',
		     'punc' => 'PUNC', 'abbrev' => 'NN,NNS', 'latin' => 'NN,NNS',
		     'noun' => 'NN,NNS,VBG', 'noun_prop' => 'NNP,NNPS', 'noun_quant' => 'NOUN_QUANT',
		     'poss' => 'PRP$', 'pron' => 'PRP', 'dobj' =>'PRP', 'adv' => 'RB',
		     'part' => 'RP', 'part_focus' => 'RP', 'part_fut' => 'RP',
		     'part_neg' => 'RP', 'part_restrict' => 'RP', 'part_voc' => 'RP',
		     'verb' => 'VB,VBN,VBD,VBP', 'verb_pseudo' => 'VBP', 'adv_interrog' => 'WRB',
		     'adv_rel' => 'WRB', 'interj' =>'UH', 'pron_exclam' => 'WP',
		     'pron_interrog' => 'WP', 'rel' => 'WP', 'pron_rel' => 'WP',
		     'part_interrog' => 'RP', 'part_verb' => 'RP', 'digit' => 'CD',
		     'pron' => 'PRP', 'neg' => 'RP', 'voc' => 'RP', 'ques' => 'RP',
		     'sub' => 'IN', 'interrog'=> 'RP', 'emph' => 'RP', 'rc' => 'RP',
		     'jus' => 'RP', 'fut' => 'RP', 'conn'=> 'RP' );
    $POSTAGS{"POS2PENN"}=\%POS2PENN;

    

    my @MAP=("enc0:1p_dobj CVSUFF_DO:1P",   "enc0:1p_dobj IVSUFF_DO:1P", "enc0:1p_dobj PVSUFF_DO:1P",
	     "enc0:1p_poss POSS_PRON_1P",   "enc0:1p_pron PRON_1P",      "enc0:1s_dobj CVSUFF_DO:1S",
	     "enc0:1s_dobj IVSUFF_DO:1S",   "enc0:1s_dobj PVSUFF_DO:1S", "enc0:1s_poss POSS_PRON_1S",
	     "enc0:1s_pron PRON_1S",        "enc0:2d_dobj IVSUFF_DO:2D", "enc0:2d_dobj PVSUFF_DO:2D",
	     "enc0:2d_poss POSS_PRON_2D",   "enc0:2d_pron PRON_2D",      "enc0:2fp_dobj IVSUFF_DO:2FP",
	     "enc0:2fp_dobj PVSUFF_DO:2FP", "enc0:2fp_poss POSS_PRON_2FP", "enc0:2fp_pron PRON_2FP",
	     "enc0:2fs_dobj IVSUFF_DO:2FS", "enc0:2fs_dobj PVSUFF_DO:2FS", "enc0:2fs_poss POSS_PRON_2FS",
	     "enc0:2fs_pron PRON_2FS",      "enc0:2mp_dobj IVSUFF_DO:2MP", "enc0:2mp_dobj PVSUFF_DO:2MP",
	     "enc0:2mp_poss POSS_PRON_2MP", "enc0:2mp_pron PRON_2MP",      "enc0:2ms_dobj IVSUFF_DO:2MS",
	     "enc0:2ms_dobj PVSUFF_DO:2MS", "enc0:2ms_poss POSS_PRON_2MS", "enc0:2ms_pron PRON_2MS",
	     "enc0:3d_dobj CVSUFF_DO:3D",   "enc0:3d_dobj IVSUFF_DO:3D",   "enc0:3d_dobj PVSUFF_DO:3D",
	     "enc0:3d_poss POSS_PRON_3D",   "enc0:3d_pron PRON_3D",        "enc0:3fp_dobj CVSUFF_DO:3FP",
	     "enc0:3fp_dobj IVSUFF_DO:3FP", "enc0:3fp_dobj PVSUFF_DO:3FP", "enc0:3fp_poss POSS_PRON_3FP",
	     "enc0:3fp_pron PRON_3FP",      "enc0:3fs_dobj CVSUFF_DO:3FS", "enc0:3fs_dobj IVSUFF_DO:3FS",
	     "enc0:3fs_dobj PVSUFF_DO:3FS", "enc0:3fs_poss POSS_PRON_3FS", "enc0:3fs_pron PRON_3FS",
	     "enc0:3mp_dobj CVSUFF_DO:3MP", "enc0:3mp_dobj IVSUFF_DO:3MP", "enc0:3mp_dobj PVSUFF_DO:3MP",
	     "enc0:3mp_poss POSS_PRON_3MP", "enc0:3mp_pron PRON_3MP",      "enc0:3ms_dobj CVSUFF_DO:3MS",
	     "enc0:3ms_dobj IVSUFF_DO:3MS", "enc0:3ms_dobj PVSUFF_DO:3MS", "enc0:3ms_poss POSS_PRON_3MS",
	     "enc0:3ms_pron PRON_3MS",      "enc0:Ah_voc VOC_PART",        "enc0:mA_interrog INTERROG_PRON",
	     "enc0:mA_rel REL_PRON",        "enc0:mA_sub SUB_CONJ",        "enc0:ma_interrog INTERROG_PRON",
	     "enc0:ma_rel REL_PRON",        "enc0:ma_sub SUB_CONJ",        "enc0:man_interrog INTERROG_PRON",
	     "enc0:man_rel REL_PRON",       "enc0:lA_neg NEG_PART",        "enc0:mA_neg NEG_PART",
	     "prc0:Al_det DET",             "prc0:lA_neg NEG_PART",        "prc0:lA_neg PSEUDO_VERB",
	     "prc0:mA_neg NEG_PART",        "prc0:mA_part PART",           "prc0:mA_rel REL_PRON",
	     "prc1:bi_part PART",           "prc1:bi_prep PREP",           "prc1:fiy_prep PREP",
	     "prc1:hA_dem DEM_PRON",        "prc1:ka_prep PREP",           "prc1:la_emph EMPHATIC_PART",
	     "prc1:la_prep PREP",           "prc1:la_rc RC_PART",          "prc1:li_jus JUS_PART",
	     "prc1:li_prep PREP",           "prc1:sa_fut FUT_PART",        "prc1:ta_prep PREP",
	     "prc1:wA_voc VOC_PART",        "prc1:wa_prep PREP",           "prc1:yA_voc VOC_PART",
	     "prc2:fa_conj CONJ",           "prc2:fa_conn CONNEC_PART",    "prc2:fa_rc RC_PART",
	     "prc2:fa_sub SUB_CONJ",        "prc2:wa_conj CONJ",           "prc2:wa_part PART",
	     "prc2:wa_sub SUB_CONJ",        "prc3:>a_ques INTERROG_PART");    
    my %POS2BW=();

    foreach my $pair (@MAP){
	my ($almr,$bw)=split('\s',$pair);
	push @{$POS2BW{"$almr"}},$bw;
    }
    
    $POSTAGS{"POS2BW"}=\%POS2BW;
    
    my %BW2PENN = ( 
	"ABBREV" => "NNP",          "ADJ" => "JJ",                 "ADJ_COMP" => "ADJ_COMP",
	"ADJ_NUM" => "ADJ_NUM",     "ADJ_PROP" => "JJ",            "ADJ.VN" => "JJ",
	"ADV" => "RB",              "CASE_DEF_ACC" => "UNDEF*",    "CASE_DEF_GEN" => "UNDEF*",
	"CASE_DEF_NOM" => "UNDEF*", "CASE_INDEF_ACC" => "UNDEF*",  "CASE_INDEF_GEN" => "UNDEF*",
	"CASE_INDEF_NOM" => "UNDEF*",  "CONJ" => "CC",             "CONNEC_PART" => "AN",
	"CV" => "VB",               "CVSUFF_DO:1P" => "PRP",       "CVSUFF_DO:1S" => "PRP",
	"CVSUFF_DO:3D" => "PRP",    "CVSUFF_DO:3FP" => "PRP",      "CVSUFF_DO:3FS" => "PRP",
        "CVSUFF_DO:3MP" => "PRP",   "CVSUFF_DO:3MS" => "PRP",      "CVSUFF_SUBJ:2FS" => "UNDEF*",
        "CVSUFF_SUBJ:2MP" => "UNDEF*", "CVSUFF_SUBJ:2MS" => "UNDEF*",  "DEM" => "DEM",
	"DEM_PRON" => "DEM",        "DEM_PRON_D" => "DEM",         "DEM_PRON_F" => "DEM",
	"DEM_PRON_FD" => "DEM",     "DEM_PRON_FP" => "DEM",        "DEM_PRON_FS" => "DEM",
	"DEM_PRON_MD" => "DEM",     "DEM_PRON_MP" => "DEM",        "DEM_PRON_MS" => "DEM",
	"DEM_PRON_P" =>	"DEM",      "DET" => "DT",                 "DIALECT" => "NN",
	"EMPH_PART" => "RP",        "EMPHATIC_PART" => "RP",       "EMPHATIC_PARTICLE" => "RP",
	"EXCLAM_PRON" => "PRP*",    "FOCUS_PART" => "RP",          "FOREIGN" => "NNP",
	"FUNC_WORD" => "IN",        "FUT_PART" => "RP",            "GRAMMAR_PROBLEM" => "NN",
	"INTERJ" => "UH",           "INTERROG_ADV" => "WRB",       "INTERROG_PART" => "RP",
	"INTERROG_PRON" => "WP",    "IV" => "VBP",                 "IV_PASS" => "VBN",
	"IV1P" => "UNDEF*",         "IV1S" => "UNDEF*",            "IV2D" => "UNDEF*",
	"IV2FP" => "UNDEF*",        "IV2FS" => "UNDEF*",           "IV2MP" => "UNDEF*",
	"IV2MS" => "UNDEF*",        "IV3FD" => "UNDEF*",           "IV3FP" => "UNDEF*",
	"IV3FS" => "UNDEF*",        "IV3MD" => "UNDEF*",           "IV3MP" => "UNDEF*",
	"IV3MS" => "UNDEF*",        "IVSUFF_DO:1P" => "PRP",       "IVSUFF_DO:1S" => "PRP",
	"IVSUFF_DO:2D" => "PRP",    "IVSUFF_DO:2FP" => "PRP",      "IVSUFF_DO:2FS" => "PRP",
        "IVSUFF_DO:2MP" => "PRP",   "IVSUFF_DO:2MS" => "PRP",      "IVSUFF_DO:3D" => "PRP",
        "IVSUFF_DO:3FP" => "PRP",   "IVSUFF_DO:3FS" => "PRP",      "IVSUFF_DO:3MP" => "PRP",
        "IVSUFF_DO:3MS" => "PRP",   "IVSUFF_MOOD:I" => "UNDEF*",   "IVSUFF_MOOD:J" => "UNDEF*",
        "IVSUFF_MOOD:S" => "UNDEF*",            "IVSUFF_SUBJ:2FS_MOOD:I" => "UNDEF*", 
	"IVSUFF_SUBJ:2FS_MOOD:SJ" => "UNDEF*",  "IVSUFF_SUBJ:3D" => "UNDEF*", 
	"IVSUFF_SUBJ:3D_MOOD:I" => "UNDEF*",    "IVSUFF_SUBJ:3FP" => "UNDEF*",
        "IVSUFF_SUBJ:3MP_MOOD:I" => "UNDEF*",   "IVSUFF_SUBJ:3MP_MOOD:SJ" => "UNDEF*",
        "IVSUFF_SUBJ:D_MOOD:I" => "UNDEF*",     "IVSUFF_SUBJ:D_MOOD:SJ" => "UNDEF*",
        "IVSUFF_SUBJ:FP" => "UNDEF*",           "IVSUFF_SUBJ:MP_MOOD:I" => "UNDEF*",
        "IVSUFF_SUBJ:MP_MOOD:SJ" => "UNDEF*",   "JUS_PART" => "RP",
	"LATIN" => "NN",               "NEG_PART" => "RP*",          "NO_FUNC" => "NN",
	"NOUN" => "NN",                "NOUN_NUM" => "NN",            "NOUN_PROP" => "NNP",
	"NOUN_QUANT" => "NOUN_QUANT",  "NOUN.VN" => "NN",             "NSUFF_FEM_DU_ACC" => "#S",
	"NSUFF_FEM_DU_ACC_POSS" => "#S",        "NSUFF_FEM_DU_GEN" => "#S",	
	"NSUFF_FEM_DU_GEN_POSS" => "#S",        "NSUFF_FEM_DU_NOM" => "#S",
	"NSUFF_FEM_DU_NOM_POSS" => "#S",        "NSUFF_FEM_PL" => "#S",
	"NSUFF_FEM_SG" => "UNDEF*",        "NSUFF_MASC_DU_ACC" => "#S",      "NSUFF_MASC_DU_ACC_POSS" => "#S",
	"NSUFF_MASC_DU_GEN" => "#S",       "NSUFF_MASC_DU_GEN_POSS" => "#S", "NSUFF_MASC_DU_NOM" => "#S",
	"NSUFF_MASC_DU_NOM_POSS" => "#S",  "NSUFF_MASC_PL_ACC" => "#S",      "NSUFF_MASC_PL_ACC_POSS" => "#S",
	"NSUFF_MASC_PL_GEN" => "#S",       "NSUFF_MASC_PL_GEN_POSS" => "#S", "NSUFF_MASC_PL_NOM" => "#S",
	"NSUFF_MASC_PL_NOM_POSS" => "#S",  "NUM" => "CD",                    "NUMERIC_COMMA" => "PUNC",
	"PART" => "RP",              "POSS_PRON_1P" => "PRP\$",   "POSS_PRON_1S" => "PRP\$",
	"POSS_PRON_2D" => "PRP\$",   "POSS_PRON_2FP" => "PRP\$",  "POSS_PRON_2FS" => "PRP\$",
	"POSS_PRON_2MP" => "PRP\$",  "POSS_PRON_2MS" => "PRP\$",  "POSS_PRON_3D" => "PRP\$",
	"POSS_PRON_3FP" => "PRP\$",  "POSS_PRON_3FS" => "PRP\$",  "POSS_PRON_3MP" => "PRP\$",
	"POSS_PRON_3MS" => "PRP\$",  "PREP" => "IN*",             "PRON_1P" => "PRP",
	"PRON_1S" => "PRP",          "PRON_2D" => "PRP",          "PRON_2FP" => "PRP",
	"PRON_2FS" => "PRP",         "PRON_2MP" => "PRP",         "PRON_2MS" => "PRP",
	"PRON_3D" => "PRP",          "PRON_3FP" => "PRP",         "PRON_3FS" => "PRP",
	"PRON_3MP" => "PRP",         "PRON_3MS" => "PRP",         "PSEUDO_VERB" => "AN",
	"PUNC" => "PUNC",            "PV" => "VBD",               "PV_PASS" => "VBN",
        "PVSUFF_DO:1P" => "PRP",     "PVSUFF_DO:1S" => "PRP",     "PVSUFF_DO:2D" => "PRP",
        "PVSUFF_DO:2FP" => "PRP",    "PVSUFF_DO:2FS" => "PRP",    "PVSUFF_DO:2MP" => "PRP",
        "PVSUFF_DO:2MS" => "PRP",    "PVSUFF_DO:3D" => "PRP",     "PVSUFF_DO:3FP" => "PRP",
        "PVSUFF_DO:3FS" => "PRP",    "PVSUFF_DO:3MP" => "PRP",    "PVSUFF_DO:3MS" => "PRP",
        "PVSUFF_SUBJ:1P" => "UNDEF*","PVSUFF_SUBJ:1S" => "UNDEF*","PVSUFF_SUBJ:2D" => "UNDEF*",
        "PVSUFF_SUBJ:2FP" => "UNDEF*",  "PVSUFF_SUBJ:2FS" => "UNDEF*",  "PVSUFF_SUBJ:2MP" => "UNDEF*",
        "PVSUFF_SUBJ:2MS" => "UNDEF*",  "PVSUFF_SUBJ:3FD" => "UNDEF*",  "PVSUFF_SUBJ:3FP" => "UNDEF*",
        "PVSUFF_SUBJ:3FS" => "UNDEF*",  "PVSUFF_SUBJ:3MD" => "UNDEF*",  "PVSUFF_SUBJ:3MP" => "UNDEF*",
        "PVSUFF_SUBJ:3MS" => "UNDEF*",  "RC_PART" => "RP",        "REL_ADV" => "WRB",
	"REL_PRON" => "WP",             "RESTRIC_PART" => "RP",   "SUB" => "AN",
	"SUB_CONJ" => "AN",             "TYPO" => "NN",           "VERB" => "VB",
	"VERB_IMPERFECT_PASSIVE" => "VBN",  "VERB_PART" => "RP",  "VERB_PERFECT" => "VBD",
	"VERB_PERFECT_PASSIVE" => "VBN",    "VOC_PART" => "UH" );


    my %BW2CATIB = ( 
	"ABBREV" => "PROP",           "ADJ" => "NOM",               "ADJ_COMP" => "NOM",
	"ADJ_NUM" => "NOM",           "ADJ_PROP" => "NOM",          "ADJ.VN" => "NOM",
	"ADV" => "NOM",               "CASE_DEF_ACC" => "UNDEF*",   "CASE_DEF_GEN" => "UNDEF*",
	"CASE_DEF_NOM" => "UNDEF*",   "CASE_INDEF_ACC" => "UNDEF*", "CASE_INDEF_GEN" => "UNDEF*",
	"CASE_INDEF_NOM" => "UNDEF*", "CONJ" => "PRT",              "CONNEC_PART" => "PRT",
	"CV" => "VRB",                "CVSUFF_DO:1P" => "NOM",      "CVSUFF_DO:1S" => "NOM",
	"CVSUFF_DO:3D" => "NOM",      "CVSUFF_DO:3FP" => "NOM",     "CVSUFF_DO:3FS" => "NOM",
        "CVSUFF_DO:3MP" => "NOM",     "CVSUFF_DO:3MS" => "NOM",     "CVSUFF_SUBJ:2FS" => "UNDEF*",
        "CVSUFF_SUBJ:2MP" => "UNDEF*",   "CVSUFF_SUBJ:2MS" => "UNDEF*",   "DEM" => "NOM",
	"DEM_PRON" => "NOM",          "DEM_PRON_D" => "NOM",        "DEM_PRON_F" => "NOM",
	"DEM_PRON_FD" => "NOM",       "DEM_PRON_FP" => "NOM",       "DEM_PRON_FS" => "NOM",
	"DEM_PRON_MD" => "NOM",       "DEM_PRON_MP" => "NOM",       "DEM_PRON_MS" => "NOM",
	"DEM_PRON_P" =>	"NOM",        "DET" => "PRT*",              "DIALECT" => "NOM",
	"EMPH_PART" => "PRT",         "EMPHATIC_PART" => "PRT",     "EMPHATIC_PARTICLE" => "PRT",
	"EXCLAM_PRON" => "NOM*",      "FOCUS_PART" => "PRT",        "FOREIGN" => "PROP",
	"FUNC_WORD" => "PRT",         "FUT_PART" => "PRT",          "GRAMMAR_PROBLEM" => "NOM",
	"INTERJ" => "PRT",            "INTERROG_ADV" => "NOM",      "INTERROG_PART" => "PRT",
	"INTERROG_PRON" => "NOM",     "IV" => "VRB",                "IV_PASS" => "VRB-PASS",
	"IV1P" => "UNDEF*",           "IV1S" => "UNDEF*",           "IV2D" => "UNDEF*",
	"IV2FP" => "UNDEF*",          "IV2FS" => "UNDEF*",          "IV2MP" => "UNDEF*",
	"IV2MS" => "UNDEF*",          "IV3FD" => "UNDEF*",          "IV3FP" => "UNDEF*",
	"IV3FS" => "UNDEF*",          "IV3MD" => "UNDEF*",          "IV3MP" => "UNDEF*",
	"IV3MS" => "UNDEF*",          "IVSUFF_DO:1P" => "NOM",      "IVSUFF_DO:1S" => "NOM",
	"IVSUFF_DO:2D" => "NOM",      "IVSUFF_DO:2FP" => "NOM",     "IVSUFF_DO:2FS" => "NOM",
        "IVSUFF_DO:2MP" => "NOM",     "IVSUFF_DO:2MS" => "NOM",     "IVSUFF_DO:3D" => "NOM",
        "IVSUFF_DO:3FP" => "NOM",     "IVSUFF_DO:3FS" => "NOM",     "IVSUFF_DO:3MP" => "NOM",
        "IVSUFF_DO:3MS" => "NOM",     "IVSUFF_MOOD:I" => "UNDEF*",  "IVSUFF_MOOD:J" => "UNDEF*",
        "IVSUFF_MOOD:S" => "UNDEF*",            "IVSUFF_SUBJ:2FS_MOOD:I" => "UNDEF*", 
	"IVSUFF_SUBJ:2FS_MOOD:SJ" => "UNDEF*",  "IVSUFF_SUBJ:3D" => "UNDEF*", 
	"IVSUFF_SUBJ:3D_MOOD:I" => "UNDEF*",    "IVSUFF_SUBJ:3FP" => "UNDEF*",
        "IVSUFF_SUBJ:3MP_MOOD:I" => "UNDEF*",   "IVSUFF_SUBJ:3MP_MOOD:SJ" => "UNDEF*",
        "IVSUFF_SUBJ:D_MOOD:I" => "UNDEF*",     "IVSUFF_SUBJ:D_MOOD:SJ" => "UNDEF*",
        "IVSUFF_SUBJ:FP" => "UNDEF*",           "IVSUFF_SUBJ:MP_MOOD:I" => "UNDEF*",
        "IVSUFF_SUBJ:MP_MOOD:SJ" => "UNDEF*",   "JUS_PART" => "PRT",
	"LATIN" => "NOM",             "NEG_PART" => "PRT*",          "NO_FUNC" => "NOM",
	"NOUN" => "NOM",              "NOUN_NUM" => "NOM",           "NOUN_PROP" => "PROP",
	"NOUN_QUANT" => "NOM",        "NOUN.VN" => "NOM",            "NSUFF_FEM_DU_ACC" => "UNDEF*",
	"NSUFF_FEM_DU_ACC_POSS" => "UNDEF*",        "NSUFF_FEM_DU_GEN" => "UNDEF*",	
	"NSUFF_FEM_DU_GEN_POSS" => "UNDEF*",        "NSUFF_FEM_DU_NOM" => "UNDEF*",
	"NSUFF_FEM_DU_NOM_POSS" => "UNDEF*",        "NSUFF_FEM_PL" => "UNDEF*",
	"NSUFF_FEM_SG" => "UNDEF*",                 "NSUFF_MASC_DU_ACC" => "UNDEF*",      
	"NSUFF_MASC_DU_ACC_POSS" => "UNDEF*",       "NSUFF_MASC_DU_GEN" => "UNDEF*",       
	"NSUFF_MASC_DU_GEN_POSS" => "UNDEF*",       "NSUFF_MASC_DU_NOM" => "UNDEF*",
	"NSUFF_MASC_DU_NOM_POSS" => "UNDEF*",       "NSUFF_MASC_PL_ACC" => "UNDEF*",      
	"NSUFF_MASC_PL_ACC_POSS" => "UNDEF*",       "NSUFF_MASC_PL_GEN" => "UNDEF*",       
	"NSUFF_MASC_PL_GEN_POSS" => "UNDEF*",       "NSUFF_MASC_PL_NOM" => "UNDEF*",
	"NSUFF_MASC_PL_NOM_POSS" => "UNDEF*",       "NUM" => "NOM",     "NUMERIC_COMMA" => "PNX",
	"PART" => "PRT",             "POSS_PRON_1P" => "NOM",     "POSS_PRON_1S" => "NOM",
	"POSS_PRON_2D" => "NOM",     "POSS_PRON_2FP" => "NOM",    "POSS_PRON_2FS" => "NOM",
	"POSS_PRON_2MP" => "NOM",    "POSS_PRON_2MS" => "NOM",    "POSS_PRON_3D" => "NOM",
	"POSS_PRON_3FP" => "NOM",    "POSS_PRON_3FS" => "NOM",    "POSS_PRON_3MP" => "NOM",
	"POSS_PRON_3MS" => "NOM",    "PREP" => "PRT*",            "PRON_1P" => "NOM",
	"PRON_1S" => "NOM",          "PRON_2D" => "NOM",          "PRON_2FP" => "NOM",
	"PRON_2FS" => "NOM",         "PRON_2MP" => "NOM",         "PRON_2MS" => "NOM",
	"PRON_3D" => "NOM",          "PRON_3FP" => "NOM",         "PRON_3FS" => "NOM",
	"PRON_3MP" => "NOM",         "PRON_3MS" => "NOM",         "PSEUDO_VERB" => "PRT",
	"PUNC" => "PNX",             "PV" => "VRB",               "PV_PASS" => "VRB-PASS",
        "PVSUFF_DO:1P" => "NOM",     "PVSUFF_DO:1S" => "NOM",     "PVSUFF_DO:2D" => "NOM",
        "PVSUFF_DO:2FP" => "NOM",    "PVSUFF_DO:2FS" => "NOM",    "PVSUFF_DO:2MP" => "NOM",
        "PVSUFF_DO:2MS" => "NOM",    "PVSUFF_DO:3D" => "NOM",     "PVSUFF_DO:3FP" => "NOM",
        "PVSUFF_DO:3FS" => "NOM",       "PVSUFF_DO:3MP" => "NOM",       "PVSUFF_DO:3MS" => "NOM",
        "PVSUFF_SUBJ:1P" => "UNDEF*",   "PVSUFF_SUBJ:1S" => "UNDEF*",   "PVSUFF_SUBJ:2D" => "UNDEF*",
        "PVSUFF_SUBJ:2FP" => "UNDEF*",  "PVSUFF_SUBJ:2FS" => "UNDEF*",  "PVSUFF_SUBJ:2MP" => "UNDEF*",
        "PVSUFF_SUBJ:2MS" => "UNDEF*",  "PVSUFF_SUBJ:3FD" => "UNDEF*",  "PVSUFF_SUBJ:3FP" => "UNDEF*",
        "PVSUFF_SUBJ:3FS" => "UNDEF*",  "PVSUFF_SUBJ:3MD" => "UNDEF*",  "PVSUFF_SUBJ:3MP" => "UNDEF*",
        "PVSUFF_SUBJ:3MS" => "UNDEF*",  "RC_PART" => "PRT",             "REL_ADV" => "NOM",
	"REL_PRON" => "NOM",            "RESTRIC_PART" => "PRT",        "SUB" => "PRT",
	"SUB_CONJ" => "PRT",            "TYPO" => "NOM",                "VERB" => "VRB",
	"VERB_IMPERFECT_PASSIVE" => "VRB-PASS",  "VERB_PART" => "PRT",  "VERB_PERFECT" => "VRB",
	"VERB_PERFECT_PASSIVE" => "VRB-PASS",    "VOC_PART" => "PRT" );


    $POSTAGS{"BW2PENN"} = \%BW2PENN;
    $POSTAGS{"BW2CATIB"} = \%BW2CATIB;


}


##################################################################################

=head3 parse_scheme

    my %PARAM = %{ TOKAN::parse_scheme($scheme, $quiet) };

    
    This function reads a TOKAN scheme (a string of TOKAN control options with
    a specific structure and format) and translates it into %PARAM,  a hash
    data structure with the parameters needed for running TOKAN.

    $quiet is 0 or 1 (defaults to 0).  If 0, all status messages will be repressed.

    Returns a reference to a hash.

=cut


sub parse_scheme {
    my ($scheme, $quiet) = @_;
    if( ! defined $quiet ) { $quiet = 0; }

    my %PARAM = ();


    $scheme = " $scheme ";
    if( ! $quiet ) {
	print STDERR "# Input <token-def> =($scheme)\n";
    }

    ##### A. CHECK FOR OBSOLETE/SUSPENDED COMMANDS #####
    
    #OBSOLETE

    if ($scheme=~/QUICKREADOFF/i)     { die "$0: Error - QUICKREADOFF is obsolete. Use \"SCHEME=DIAC\" instead\n"; }
    if ($scheme=~/ \+ \\\/ \+ /i)     { die "$0: Error - \"+ \/ +\" is	obsolete. Use \"[+ .. +]\" instead\n"; }
    if ($scheme=~/NOMADA/i)           { die "$0: Error - NOMADA is obsolete\n";}
    if ($scheme=~/NOSORT/i)           { die "$0: Error - NOSORT is obsolete\n";}
    if ($scheme=~/PASSATAT/i)         { die "$0: Error - PASSATAT is now default; use \"NOPASSATAT\" to drop \@\@s\n";}
    if ($scheme=~/TESTMODE/i)         { die "$0: Error - TESTMODE  is obsolete\n";}
    if ($scheme=~/(BIESPOS|MADAPOS)/i){ die "$0: Error - $1  is obsolete. Use POS:<TAGSET> or -TAG:<TAGSET> instead\n";}
    if ($scheme=~/(POS:RTS|TAG:RTS)/i){ die "$0: Error - The \"RTS\" tagset is the basic PennPOS. Use POS:PENN or -TAG:PENN instead\n";}
    if ($scheme=~/MORPH/i)            { die "$0: Error - MORPH is obsolete. Use BW instead.\n";}
    if ($scheme=~/CLITPLUS/i)         { die "$0: Error - CLITPLUS is obsolete. Use PROC/ENC:PLUS/HASH instead.\n";}
    if ($scheme=~/CLITSURF/i)         { die "$0: Error - CLITSURF is obsolete. Use clitic surface is only mode supported. Use POS:BW to get other forms.\n";}
    if ($scheme=~/ONEWORDPERLINE/i)   { die "$0: Error - ONEWORDPERLINE is obsolete. Use NEWLINE in SPLIT command.\n";}
    if ($scheme=~/NORMPAREN/i)        { die "$0: Error - NORMPAREN is obsolete. Use ESC:PAREN in FORM command.\n";}

    #SUSPENDED
    if ($scheme=~/(<<+>>|RECON)/i)    { die "$0: Error - RECON is no suppported in this version.\n";}
    #SEE FOR LATER SECTION AT END


    ###  Compatibility with old parsing of #SPLIT or #FORM:
    $scheme =~ s/\#(SCHEME)/::$1/ig;
    $scheme =~ s/\#(FORM)/::$1/ig;

    ####################################################
    ##### B. ALIASES ###################################

    ### Allow NORM:AY and such
    while ($scheme=~s/NORM:([AHYT][AHYT]+)/XXXNORMXXX/){
	my $out="";
	foreach my $norm (split('',$1)){
	    $out.="NORM:$norm ";
	}
	$scheme=~s/XXXNORMXXX/$out/;
    }
  

    ### READY-MADE SCHEMES

    #NEW 6-tier scheme
    $scheme=~s/ SCHEME=ATB4MT / ::SPLIT QUES CONJ PART NART REST PRON FDELIM:\x{00B7} ::FORM0 WORD PROCMARK:PLUS ENCMARK:PLUS ESC:PAREN ::FORM1 COPY0 NORM:A NORM:Y ::FORM2 LEXEME PROCMARK:PLUS ENCMARK:PLUS ESC:PAREN DIAC ::FORM3 POS:CATIB ::FORM4 POS:PENN ::FORM5 POS:BW /;


    $scheme=~s/ SCHEME=D1-3tier / ::SPLIT QUES CONJ REST FDELIM:\x{00B7} ::FORM0 WORD PROCMARK:PLUS ENCMARK:PLUS ESC:PAREN ::FORM1 COPY0 NORM:A NORM:Y ::FORM2 LEXEME PROCMARK:PLUS ENCMARK:PLUS ESC:PAREN DIAC  /;
    $scheme=~s/ SCHEME=D2-3tier / ::SPLIT  QUES CONJ PART REST FDELIM:\x{00B7} ::FORM0 WORD PROCMARK:PLUS ENCMARK:PLUS ESC:PAREN ::FORM1 COPY0 NORM:A NORM:Y ::FORM2 LEXEME PROCMARK:PLUS ENCMARK:PLUS ESC:PAREN DIAC /;
    $scheme=~s/ SCHEME=D3-3tier / ::SPLIT QUES CONJ PART ART REST PRON FDELIM:\x{00B7} ::FORM0 WORD PROCMARK:PLUS ENCMARK:PLUS ESC:PAREN ::FORM1 COPY0 NORM:A NORM:Y ::FORM2 LEXEME PROCMARK:PLUS ENCMARK:PLUS ESC:PAREN DIAC  /;
 

    $scheme=~s/ SCHEME=D14MT / ::SPLIT QUES CONJ REST FDELIM:\x{00B7} ::FORM0 WORD PROCMARK:PLUS ENCMARK:PLUS ESC:PAREN ::FORM1 COPY0 NORM:A NORM:Y ::FORM2 LEXEME PROCMARK:PLUS ENCMARK:PLUS ESC:PAREN DIAC ::FORM3 POS:CATIB ::FORM4 POS:PENN ::FORM5 POS:BW /;
    $scheme=~s/ SCHEME=D24MT / ::SPLIT  QUES CONJ PART REST FDELIM:\x{00B7} ::FORM0 WORD PROCMARK:PLUS ENCMARK:PLUS ESC:PAREN ::FORM1 COPY0 NORM:A NORM:Y ::FORM2 LEXEME PROCMARK:PLUS ENCMARK:PLUS ESC:PAREN DIAC ::FORM3 POS:CATIB ::FORM4 POS:PENN ::FORM5 POS:BW /;
    $scheme=~s/ SCHEME=D34MT / ::SPLIT QUES CONJ PART ART REST PRON FDELIM:\x{00B7} ::FORM0 WORD PROCMARK:PLUS ENCMARK:PLUS ESC:PAREN ::FORM1 COPY0 NORM:A NORM:Y ::FORM2 LEXEME PROCMARK:PLUS ENCMARK:PLUS ESC:PAREN DIAC ::FORM3 POS:CATIB ::FORM4 POS:PENN ::FORM5 POS:BW /;

    ###$scheme=~s/ SCHEME=ATB4MTold / ::SPLIT QUES CONJ PART NART REST PRON FDELIM:\x{00B7} ::FORM0 WORD PROCMARK:PLUS ENCMARK:PLUS ESC:PAREN ::FORM1 WORD PROCMARK:PLUS ENCMARK:PLUS ESC:PAREN NORM:A NORM:Y ::FORM2 LEXEME PROCMARK:PLUS ENCMARK:PLUS ESC:PAREN DIAC ::FORM3 POS:CATIB ::FORM4 POS:PENN ::FORM5 POS:BW /;
    
    $scheme=~s/ SCHEME=DIAC / ::FORM0 SURF DIAC /;

    #OLD ATB scheme
    $scheme=~s/ SCHEME=OLDATB / ::SPLIT f+ w+ b+ k+ l+ REST +P: +O: ::FORM0 WORD PROCMARK:PLUS ENCMARK:PLUS NORM:A NORM:Y ESC:PAREN /i;
    
    # ATB/D1/D2/D3 are updated to new tokenization
    
    #$scheme =~s/ SCHEME=TB# / SCHEME=ATB# /;  ## To avoid problems with config file reader
    $scheme =~s/ SCHEME=TB-HASH / SCHEME=ATB-HASH /;

    $scheme =~s/ SCHEME=TB / SCHEME=ATB /;

    #$scheme =~s/ SCHEME=ATB#\+POS / SCHEME=ATB# ::FORM1 POS:PENN /;
    $scheme =~s/ SCHEME=ATB-HASH\+POS / SCHEME=ATB-HASH ::FORM1 POS:PENN /;

    $scheme =~s/ SCHEME=ATB\+POS / SCHEME=ATB ::FORM1 POS:PENN /;
    
    #$scheme =~s/ SCHEME=ATB# / SCHEME=ATB ENCMARK:HASH /i; #overwrite ENCMARK
    $scheme =~s/ SCHEME=ATB-HASH / SCHEME=ATB ENCMARK:HASH /i; #overwrite ENCMARK

    $scheme=~s/ SCHEME=ATB / ::SPLIT QUES CONJ PART NART REST PRON ::FORM0 WORD PROCMARK:PLUS ENCMARK:PLUS NORM:A NORM:Y ESC:PAREN /i;
    
    #$scheme =~s/ SCHEME=D1# / SCHEME=D1 ENCMARK:HASH /i; #overwrite ENCMARK
    $scheme =~s/ SCHEME=D1-HASH / SCHEME=D1 ENCMARK:HASH /i; #overwrite ENCMARK
    $scheme =~s/ SCHEME=D1 / ::SPLIT QUES CONJ REST ::FORM0 WORD PROCMARK:PLUS ENCMARK:PLUS NORM:A NORM:Y ESC:PAREN /i;

    #$scheme =~s/ SCHEME=D2# / SCHEME=D2 ENCMARK:HASH /i; #overwrite ENCMARK
    $scheme =~s/ SCHEME=D2-HASH / SCHEME=D2 ENCMARK:HASH /i; #overwrite ENCMARK
    $scheme =~s/ SCHEME=D2 / ::SPLIT QUES CONJ PART REST ::FORM0 WORD PROCMARK:PLUS ENCMARK:PLUS NORM:A NORM:Y ESC:PAREN /i;

    #$scheme =~s/ SCHEME=D3# / SCHEME=D3 ENCMARK:HASH /i; #overwrite ENCMARK
    $scheme =~s/ SCHEME=D3-HASH / SCHEME=D3 ENCMARK:HASH /i; #overwrite ENCMARK
    $scheme =~s/ SCHEME=D3 / ::SPLIT QUES CONJ PART ART REST PRON ::FORM0 WORD PROCMARK:PLUS ENCMARK:PLUS NORM:A NORM:Y ESC:PAREN /i;

    #S1 and S2 from Badr et al 2008
    #$scheme =~s/ SCHEME=S1# / SCHEME=S1 ENCMARK:HASH /i; #overwrite ENCMARK
    $scheme =~s/ SCHEME=S1-HASH / SCHEME=S1 ENCMARK:HASH /i; #overwrite ENCMARK
    $scheme =~s/ SCHEME=S1 / ::SPLIT CONJ PART DART REST PRON ::FORM0 WORD PROCMARK:PLUS ENCMARK:PLUS NORM:A NORM:Y ESC:PAREN /i;
    #$scheme =~s/ SCHEME=S2# / SCHEME=S1 ENCMARK:HASH /i; #overwrite ENCMARK
    $scheme =~s/ SCHEME=S2-HASH / SCHEME=S1 ENCMARK:HASH /i; #overwrite ENCMARK
    $scheme =~s/ SCHEME=S2 / ::SPLIT TDELIM: [+ CONJ PART DART +] REST PRON ::FORM0 WORD PROCMARK:PLUS ENCMARK:PLUS NORM:A NORM:Y ESC:PAREN /i;

    #Other class components
    $scheme=~s/ QUES\+? / prc3 /;
    $scheme=~s/ CONJ\+? / prc2 /;
    #$scheme=~s/ PART\+? / prc1 /;
    $scheme=~s/ PART\+? / prc1:k prc1:f prc1:y prc1:w prc1:s prc1:h prc1:l prc1:b /; #ignore ta_prep .. should be handled better.
    $scheme=~s/ FUT\+? / prc1:sa /;
    $scheme=~s/ ART\+? / prc0 /;
    $scheme=~s/ DART\+? / prc0:Al /;
    $scheme=~s/ NART\+? / prc0:lA prc0:mA /;
    $scheme=~s/ \+?PRON / enc0 /;
    
    #Older scheme components
    $scheme=~s/ w\+ / prc2:w /;
    $scheme=~s/ f\+ / prc2:f /;
    $scheme=~s/ b\+ / prc1:b /;
    $scheme=~s/ l\+ / prc1:l /;
    $scheme=~s/ k\+ / prc1:k /;
    $scheme=~s/ s\+ / prc1:s /;
    $scheme=~s/ Al\+ / prc0:Al /;
    $scheme=~s/ \+P: / enc0:=_poss /;
    $scheme=~s/ \+O: / enc0:=_dobj enc0:=_pron /;
 
    ####################################################
    ##### C. PARSE SCHEME ##############################

    #Three classes of commands
    # SPLIT
    # FORM
    # GENERAL


    ##### GENERAL DEFAULTS ######
    
    $PARAM{"SENT_ID"}=0;
    $PARAM{"PASS_AT_AT"}=1;
    $PARAM{"MARK_NO_ANALYSIS"}=0;  #add param for how to mark?
    $PARAM{"TDELIM"}="_";
#   $PARAM{"FDELIM"}="·";
    $PARAM{"FDELIM"}="\x{00B7}"; ## Since binmode for output is set to :utf8 now, we need to specify the character this way.
    $PARAM{"load-almor"}=0; #default not to load ALMOR
    $PARAM{"GROUPTOKENS"}=0;
    $PARAM{"ENCODE ALL"}="";  ## Override option for all forms in scheme.  Options: "" (no override), BW, SafeBW, UTF8.
    $PARAM{"MAXFORM"} = 0;

   
    ##### PARSE ######

    my $mode="";

    foreach my $sch (split('\s+',$scheme)){
	#GENERAL
	if ($sch=~/^::SPLIT$/i){
	    $mode="SPLIT";
	    @{$PARAM{"$mode TOKENS"}}=();
	}elsif ($sch=~/^::(FORM(\d+))$/i){
	    $mode=$1;
	    $PARAM{"MAXFORM"} = $2;
	    #DEFAULTS
	    $PARAM{"$mode PROCMARK"}=""; #NONE
	    $PARAM{"$mode ENCMARK"}="";  #NONE
	    $PARAM{"$mode NORM:A"}=0; 
	    $PARAM{"$mode NORM:Y"}=0; 
	    $PARAM{"$mode NORM:H"}=0; 
	    $PARAM{"$mode NORM:T"}=0; 
	    $PARAM{"$mode ESC:PAREN"}=0; 
	    $PARAM{"$mode ESC:COMMA"}=0; 
	    $PARAM{"$mode ESC:PLUS"}=0; 
	    $PARAM{"$mode ESC:STAR"}=0; 
	    $PARAM{"$mode DIAC"}=0; #nodiac
	    $PARAM{"$mode BASE"}="WORD";
	    $PARAM{"$mode ENCODING"}="BW";  ## Default BW.  Other options:  UTF8, SafeBW.
	    @{$PARAM{"$mode WORD ADJUST"}}=(); #adjustments... only used for BASE=WORD
	    $PARAM{"$mode LEXEME SHOWINDEX"}=0; #default is no index. Index includes -u and such for FORM-I verbs 

	}elsif ($sch=~/^([TF]DELIM):(\S*)$/i){
	    $PARAM{"$1"}=$2;
	}elsif ($sch=~/^NOPASSATAT$/i){
	    $PARAM{"PASS_AT_AT"}=0;
	}elsif ($sch=~/^SENT\_ID$/i){
	    $PARAM{"SENT_ID"}=1;
	}elsif ($sch=~/^MARKNOANALYSIS$/i){
	    $PARAM{"MARK_NO_ANALYSIS"}=1;
	}elsif($sch=~/GROUPTOKENS/i){ 
	    $PARAM{"GROUPTOKENS"}=1;
	}elsif($sch=~/^ENCODEALL:(BW|SAFEBW|UTF8)$/i) {
	    $PARAM{"ENCODE ALL"} = uc($1);  
	}elsif (($mode eq "SPLIT")&&($sch=~/^(prc[0123](:\S+)?|enc0(:\S+)?|REST|\[\+|\+\]|\[\+\]|NEWLINE)$/i)){ #Add more options later
	    push @{$PARAM{"$mode TOKENS"}},$sch;

	#}elsif (($mode =~/^FORM/)&&($sch=~/^(WORD|POS:(CATIB|PENN|BIES|KULICK|ERTS|BW|MADA|POS|SPOS|ALMOR)|LEXEME|GLOSS|STEM|SURF)$/)){
	}elsif (($mode =~/^FORM/)&&($sch=~/^(WORD|POS:(CATIB|PENN|BW|ALMOR|MADA)|LEXEME|GLOSS|STEM|SURF|COPY\d+)$/i)){
	    $sch=~tr/a-z/A-Z/;
	    $PARAM{"$mode BASE"}=$sch;
	    if ($sch eq "WORD"){ $PARAM{"load-almor"}=1;}
	    if ($sch eq "SURF"){ $PARAM{"surface-mode"}=1;}
	    if ($sch=~/COPY(\d+)/){  #COPY only from WORD/LEXEME... no POS:*
		my $copy=$1;
		if ($copy>=$PARAM{"MAXFORM"}){
		    die "Only Copy from previous forms\n";
		}
	    }
	}elsif ($mode =~/^FORM/&&($PARAM{"$mode BASE"} eq "WORD")&&
		$sch=~/^(asp|cas|gen|mod|num|per|stt|vox|prc0|prc1|prc2|prc3|enc0):\S+:\S+$/i){
	    push @{$PARAM{"$mode WORD ADJUST"}},$sch;
	}elsif ($mode =~/^FORM/ && $sch =~ /^ENCODE:(BW|SAFEBW|UTF8)$/ ) {
	    my $enc = uc($1);
	    if( $PARAM{"$mode BASE"} =~ /^(WORD|LEXEME|STEM|SURF|COPY\d+)$/i ) {
		$PARAM{"$mode ENCODING"} = $enc;
	    }	    
	}elsif (($mode =~/^FORM/)&&($PARAM{"$mode BASE"} eq "LEXEME")&&($sch=~/^SHOWINDEX$/i)){
	    $PARAM{"$mode LEXEME SHOWINDEX"}=1;
	}elsif (($mode =~/^FORM/)&&($sch=~/^(NORM:[AYTH]|ESC:(PAREN|STAR|COMMA|PLUS)|DIAC)$/i)){
	    $sch=~tr/a-z/A-Z/;
	    $PARAM{"$mode $sch"}=1;
	}elsif (($mode =~/^FORM/)&&($sch=~/^(PROC|ENC)MARK:(PLUS|HASH|NONE)$/i)){
	    my $class="$1MARK"; 
	    $class=~tr/a-z/A-Z/;
	    my $mark=$2; 
	    if ($mark=~/NONE/i){ $PARAM{"$mode $class"}="";}
	    elsif ($mark=~/PLUS/i){ $PARAM{"$mode $class"}="+";}
	    elsif ($mark=~/HASH/i){ $PARAM{"$mode $class"}="#";}
	}elsif ($sch!~/^\s*$/) {
	    die "Unrecognized scheme parameter [$sch] in mode [$mode]\n";
	}
	
    }

    if ( (not exists $PARAM{"SPLIT TOKENS"}) || (@{$PARAM{"SPLIT TOKENS"}}==0) ){
	@{$PARAM{"SPLIT TOKENS"}}=("REST");
    }
    if ($PARAM{"GROUPTOKENS"}==1){
	@{$PARAM{"SPLIT TOKENS"}}=("[+", @{$PARAM{"SPLIT TOKENS"}} , "+]" );
    }

    if (($PARAM{"surface-mode"})&&(@{$PARAM{"SPLIT TOKENS"}}!=1)){
	die "Error - incompatible SPLIT and FORM modes: SURF only takes REST splits.\n";
    }
    


    return \%PARAM;


}


##################################################################################

=head3 BW2POS

    my $tag = TOKAN::BW2POS($bw, "CATIB");  ## Coverts BW tag to CATIB tag
    my $tag = TOKAN::BW2POS($bw, "PENN");   ## Coverts BW tag to PENN TAG
    my $tag = TOKAN::BW2POS($bw);           ## Coverts BW tag to PENN TAG (default)

    This function converts a Buckwalter POS tag to the Penn or CATIB tagset.

=cut

sub BW2POS {
    my ($bw, $tagset) = @_;
    if( ! defined $tagset ) { $tagset = "PENN"; }
    my $out = "";
    my $tagref;
    if( $tagset =~ /^CATIB$/i ) {
	$tagref = $POSTAGS{"BW2CATIB"}
    } elsif( $tagset =~ /^PENN$/i ) {
	$tagref = $POSTAGS{"BW2PENN"}
    } else { 
	die "$0: Error -- BW2POS doesn't understand the specified tagset $tagset\n";
    }

    my @toks = split(/\+/, $bw);
    my $i;
    my $new;

    for( $i=0; $i<=$#toks; $i++) {
	$new = $tagref->{$toks[$i]};
	if( ! defined $new ) {
	    die "$0: Error -- Unexpected BW tag type: $toks[$i]\n";
	}
	if( scalar(@toks) > 1 && $new =~ /\*$/ ) {
	    $new = "";  ## Delete extraneous * terms
	}
	$toks[$i] = $new;
    }

    if( scalar(@toks) == 1 ) {
	$toks[0] =~ s/\*$//;   ## only one term: If it ends with a *, drop it
	$out = $toks[0];
    } else {
	$out = join("+", @toks);
	$out =~ s/\++/\+/g; ## Collapse strings of + characters 
	if( $tagset =~ /^PENN$/i ) {
	    $out =~ s/(NN|NNP)\+\#S/$1S/g;  ## Attach S suffexes (PENN set only) 
	    $out =~ s/\+\#S//g;   ## Delete other #S terms (PENN set only)
	}
	$out =~ s/^\+|\+$//g;  ## Drop leading and trailing +'s
    }
    

    return $out;

}

##################################################################################

=head3 BW2PENN

    my $penn = TOKAN::BW2PENN($bw);

    This function converts a Buckwalter POS tag to the Penn TB tagset.

=cut


sub BW2PENN {
    #can be done more elegantly
    my ($bw)=@_;
    #my $orig = $bw;
    #print STDERR "BW2PENN: < $bw >\n";
    $bw=~s/^DET\+/DT+/;

    if( $bw=~s/NUMERIC_COMMA/PUNC/ ) { }
    elsif ($bw=~s/NOUN\_PROP\+NSUFF\_(MASC|FEM)\_(DU|PL).*/NNPS/){ }
    elsif ($bw=~s/(ABBREV|FOREIGN|NOUN\_PROP).*/NNP/){ }
    elsif ($bw=~s/(ADJ\_COMP|NOUN\_QUANT|ADJ\_NUM).*/$1/){ }
    elsif ($bw=~s/(ADJ\_PROP|ADJ\.VN|(NEG\_PART\+)?ADJ|INTERJ).*/JJ/){ }
    elsif ($bw=~s/^(DT\+)?NUM.*/$1CD/){ }
    elsif ($bw=~s/DEM\+NOUN.*/DEM+NN/){ }
    elsif ($bw=~s/DEM.*/DEM/){ }
    elsif ($bw=~s/.*(INTERROG\_PRON|REL\_PRON).*/WP/){ }
    elsif ($bw=~s/.*(INTERROG\_ADV|REL\_ADV).*/WRB/){ }
    elsif ($bw=~s/POSS\_PRON.*/PRP\$/){ }
    elsif ($bw=~s/([CPI]VSUFF\_DO:|PRON).*/PRP/){ }
    elsif ($bw=~s/NOUN(\.VN|\_NUM)?\+NSUFF\_(MASC|FEM)\_(DU|PL).*/NNS/){ }
    elsif ($bw=~s/(NEG\_PART\+|PART\+)?NOUN(\.VN|\_NUM)?.*/NN/){ }
    elsif ($bw=~s/ADV.*/RB/){ }
    elsif ($bw=~s/(TYPO|LATIN|DIALECT|NO\_FUNC|GRAMMAR\_PROBLEM)/NN/){ }    
    elsif ($bw=~s/(FUNC\_WORD|PREP.*)/IN/){ }
    elsif ($bw=~s/(VOC\_PART|INTERJ.*)/UH/){ }
    elsif ($bw=~s/^(CONNEC\_PART|SUB\_CONJ.*|SUB)$/AN/){ }
    elsif ($bw=~s/^(EMPHATIC\_PART|EMPHATIC\_PARTICLE|EMPH\_PART|EXCEPT\_PART|FOCUS\_PART|FUT\_PART|INTERROG\_PART|JUS\_PART|NEG\_PART|RC\_PART|RESTRIC\_PART|RESULT\_CLAUSE\_PARTICLE|SUBJUNC|VERB\_PART).*$/RP/){ }
    elsif ($bw=~s/^PART$/RP/){ }
    elsif ($bw=~s/.*([IP]V\_PASS|VERB\_(I?M?PERFECT\_)?PASSIVE).*/VBN/){ }
    elsif ($bw=~s/(NEG\_PART\+)?(PV|VERB\_PERFECT).*/VBD/){ }
    elsif ($bw=~s/(NEG\_PART\+)?IV.*/VBP/){ }
    elsif ($bw=~s/PSEUDO\_VERB/AN/){ }
    elsif ($bw=~s/(CV|VERB).*/VB/){ }
    elsif ($bw=~s/^PVSUFF\_SUBJ:.*/PRP/){ }
    elsif ($bw=~s/^CONJ$/CC/){ }
    elsif ($bw=~s/^DET$/DT/){ }
    #else same (DV, PUNC, NON_ALPHABETIC....) 
    #my $tempbw = $bw;
    if ($bw!~/^(ADJ\_COMP|ADJ\_NUM|AN|CC|DEM|DET|DT\+ADJ\_COMP|DT\+ADJ\_NUM|DT\+JJ|DT\+NN|DT\+NNP|DT\+NNPS|DT\+NNS|DT\+NOUN\_QUANT|IN|JJ|NN|NNP|NNPS|NNS|NOUN\_QUANT|PRP|PRP\$|PUNC|RB|RP|UH|VB|VBD|VBN|VBP|WP|WRB)$/){
	if ($bw=~/^.*?(ADJ\_COMP|ADJ\_NUM|AN|CC|DEM|DET|DT\+ADJ\_COMP|DT\+ADJ\_NUM|DT\+JJ|DT\+NN|DT\+NNP|DT\+NNPS|DT\+NNS|DT\+NOUN\_QUANT|IN|JJ|NN|NNP|NNPS|NNS|NOUN\_QUANT|PRP|PRP\$|PUNC|RB|RP|UH|VB|VBD|VBN|VBP|WP|WRB).*?/){
	    $bw=$1;
	}else{
	    $bw="NN";
	}
    }
    #print STDERR "    BW2PENN:  $orig  --> $tempbw --> $bw\n";

    return($bw);

}



##################################################################################

=head3 BW2CATIB

    my $catib = TOKAN::BW2CATIB($bw);

    This function converts a Buckwalter POS tag to the CATiB POS tagset.

=cut


sub BW2CATIB {
    #can be done more elegantly
    my ($bw)=@_;

    $bw=~s/^DET\+//;
    if( $bw=~s/NUMERIC_COMMA/PNX/ ) { }
    elsif ($bw=~s/NOUN\_PROP\+NSUFF\_(MASC|FEM)\_(DU|PL).*/PROP/){ }
    elsif($bw=~s/(ABBREV|FOREIGN|NOUN\_PROP).*/PROP/){ }
    elsif($bw=~s/(ADJ\_COMP|NOUN\_QUANT|ADJ\_NUM).*/NOM/){ }
    elsif($bw=~s/^(DT\+)?NUM.*/NOM/){ }
    elsif($bw=~s/DEM\+NOUN.*/NOM/){ }
    elsif($bw=~s/DEM.*/NOM/){ }
    elsif($bw=~s/.*(INTERROG\_PRON|REL\_PRON).*/NOM/){ }
    elsif($bw=~s/.*(INTERROG\_ADV|REL\_ADV).*/NOM/){ }
    elsif($bw=~s/POSS\_PRON.*/NOM/){ }
    elsif($bw=~s/([CPI]VSUFF\_DO:|PRON).*/NOM/){ }
    elsif($bw=~s/NOUN(\.VN|\_NUM)?\+NSUFF\_(MASC|FEM)\_(DU|PL).*/NOM/){ }
    elsif($bw=~s/(NEG\_PART\+|PART\+)?NOUN(\.VN|\_NUM)?.*/NOM/){ }
    elsif($bw=~s/(ADJ\_PROP|ADJ\.VN|(NEG\_PART\+)?ADJ|INTERJ).*/NOM/){ }
    elsif($bw=~s/ADV.*/NOM/){ }
    elsif($bw=~s/(TYPO|LATIN|DIALECT|NO\_FUNC|GRAMMAR\_PROBLEM)/NOM/){ }    
    elsif($bw=~s/(FUNC\_WORD|PREP.*)/PRT/){ }

    elsif($bw=~s/(VOC\_PART|INTERJ.*)/PRT/){ }
    elsif($bw=~s/^(EMPHATIC\_PART|EMPHATIC\_PARTICLE|EMPH\_PART|EXCEPT\_PART|FOCUS\_PART|FUT\_PART|INTERROG\_PART|JUS\_PART|NEG\_PART|RC\_PART|RESTRIC\_PART|RESULT\_CLAUSE\_PARTICLE|SUBJUNC|VERB\_PART|CONNEC\_PART|SUB\_CONJ).*/PRT/){ }
    elsif($bw=~s/.*([IP]V\_PASS|VERB\_(I?M?PERFECT\_)?PASSIVE).*/VRB-PASS/){ }
    elsif($bw=~s/(NEG\_PART\+)?(PV|VERB\_PERFECT).*/VRB/){ }
    elsif($bw=~s/(NEG\_PART\+)?IV.*/VRB/){ }
    elsif($bw=~s/PSEUDO\_VERB/PRT/){ }
    elsif($bw=~s/(CV|VERB).*/VRB/){ }
    elsif($bw=~s/^PVSUFF\_SUBJ:.*/NOM/){ }
    elsif($bw=~s/PUNC/PNX/){ }
    elsif($bw=~s/^DET$/PRT/){ }
    elsif($bw=~s/^(SUB|PART)$/PRT/){ }
    elsif($bw=~s/CONJ/PRT/){}

    #making sure no problems happen
    if ($bw!~/^(NOM|PRT|PNX|VRB|VRB-PASS|PROP)$/){
	if ($bw=~/^.*?(NOM|PRT|PNX|VRB-PASS|VRB|PROP).*?/){
	    $bw=$1;
	}else{
	    $bw="NOM";
	}
    }
    
    return($bw);


}


##################################################################################

=head3 chooseForm

    my $form = TOKAN::chooseForm($word,$morph,&ALMOR::generateSolutions($morph,$ALMOR3DB));

    Chooses a tokenized form in those cases where there is ambiguity in generation.
    
    ***Should be moved to ALMOR eventually.***

    Input is the diacritized word form, feature list ($morph), and solutions made by ALMOR.
    Output is a given tokenized form.

    ADJUSTED TO TAKE AN ARRAY REFERENCE AS THIRD ARGUMENT.

=cut


sub chooseForm {

    my ($word,$morph,$stemsref)=@_;

    my @stems = @{ $stemsref };
    #print "\n  ##CF##  $word : $morph => (@stems) ##\n  ";
    #$word=~s/(.)(y|nA|h|hA|hm|hn|hmA|k|km|kmA|kn)/$1/;
    my $x="";
    my $bw="";
    my @newstems=();
    #disallow enco:0 and pronouns...
    for (my $i=0; $i<@stems; $i++){
	($stems[$i],$x,$bw)=split(/\t/,$stems[$i]);
	if (($morph=~/enc0:0/)&&($bw=~/POSS\_PRON/)){
	    #bad case
	}else{
	    push @newstems,$stems[$i];
	}
    }
    if (@newstems>0){
	@stems=@newstems;
    }

    if (@stems==1){
	return($stems[0]);
    }else{
	my $stem="";
	my $score=1000000;
	my $editscore=0;

	foreach my $astem (@stems){
	    $editscore=&minedit($word,$astem,1,1,1);
	    if ($editscore<$score){
		$score=$editscore;
		$stem=$astem;
	    }
	}
	return($stem);
    }    


}



##################################################################################

=head3 minedit

    my $score = TOKAN::minedit($target,$source,$rcost,$icost,$dcost);

    Implementation of Levenshtein min-edit distance code modified 
    from http://www.cs.sfu.ca/~anoop/distrib/editdist/min-edit-distance.pl

    Output is a score value.

=cut

sub minedit {

    my ($target,$source,$replacecost,$insertcost,$deletecost)=@_;

    my @target = split('',$target);
    my @source = split('',$source);
    my $n = @target;
    my $m = @source;
    my @dist = ();

    $dist[0][0] = 0;
    for (my $i = 1; $i <= $n; $i++) { $dist[$i][0] = $dist[$i-1][0] + $insertcost; }
    for (my $j = 1; $j <= $m; $j++) { $dist[0][$j] = $dist[0][$j-1] + $deletecost; }

    for (my $j = 1; $j <= $m; $j++) {
	for (my $i = 1; $i <= $n; $i++) {
	    my $inscost = $insertcost + $dist[$i-1][$j];
	    my $delcost = $deletecost + $dist[$i][$j-1];
	    my $add = ($source[$j-1] ne $target[$i-1]) ? $replacecost : 0;
	    my $substcost = $add + $dist[$i-1][$j-1];
	    $dist[$i][$j] = min($substcost, $inscost, $delcost);
	}
    }
    return($dist[$n][$m]);

}


##################################################################################

=head3 min

    my $minval = TOKAN::min($a,$b,$c,$d...);

    Returns the minimum value of the passed arguments.

=cut

sub min(@) {
    my $minval = shift;
    my $i;
    while ($i = shift) {
        $minval = $i if ($i < $minval);
    }
    return $minval;
}



##################################################################################

=head3 tokenize

    my $token = TOKAN::tokenize(\%PARAM,$word,$feats,$ALMOR3DB,\%TOKANMEM);

    Determines a tokenization based on %PARAM, the word, and its morphological feats.
    Makes use of %TOKANMEM so that previously seen word/feat combinations are
    reused rather than recomputed.

=cut


sub tokenize {
    my ($PARAM,$word,$morph,$ALMOR3DB,$TOKANMEM)=@_;
    my $rest=-1;
    my $originalmorph=$morph;
    my $out="";
    my $bwrest="";

    #print "$word :  \n";

    if ($morph=~s/bw:(\S+)//){
	$bwrest=$1;
    }

    my @tokens=@{$$PARAM{"SPLIT TOKENS"}};

    my $mergestep=0; #controls whether a merge step is fired or not. depends on presence of merge commands [+/+]
    
    my $memkey=join(",",$word,$morph,@tokens);

    if (exists $$TOKANMEM{"$memkey"}){
	$out=$$TOKANMEM{"$memkey"};
    }else{

	my @out=();    #token

	#A. SPLIT 

	for (my $t=0; $t<@tokens; $t++){
	    ## In this loop, each of the specified SPLIT variables is examined
	    ## and @out is set up so that we know what pieces are required in the
	    ## output.

	    if ($tokens[$t] =~/^REST$/){
		$rest=$t;

	    }elsif ($tokens[$t] =~ /^(\[\+\])$/){
		$out[$t]="[-DELPLUS-]";

	    }elsif ($tokens[$t] =~ /^(\[\+|\+\])$/){
		$mergestep=1;
		$out[$t]=$tokens[$t];
		$out[$t]=~s/\+/MERGE/;

	    }elsif ($tokens[$t] =~ /^NEWLINE$/){
		$out[$t]="[-NEWLINE-]";
		
	    }elsif ($tokens[$t]=~/(prc[0123]|enc0):?(\S+)?/){
		my ($clitic,$cond)=($1,$2);
		if( ! defined $cond ) { $cond = ""; }

		if ($morph=~s/ $clitic:($cond\S*) / $clitic:0 /){
		    my $ctok=$1;		    
		    if ($ctok!~/^(0|na|)$/){
			my $pos="$ctok";
			my $lex="";
			my $bw="";
			my $diac="";

			foreach my $bwx (@{${$POSTAGS{"POS2BW"}}{"$clitic:$ctok"}}){
			    if ($bwrest=~s/([^\/\+]+)\/$bwx//){
				$diac=$1;
				$bw=$bwx;
				$lex=$diac;
				last;
			    }
			}

			$lex=$ctok;
			unless(($clitic=~/prc/)&&($lex=~s/prc\d:(\S+)\_.*/$1/)){
			    #or it is enc0:
			    $lex=~s/1s\_poss/iy/ig; 
			    $lex=~s/1s\_dobj/niy/ig;
			    $lex=~s/1s\_pron/iy/ig;   #ignoring nwn AlwqAyp in some cases
			    $lex=~s/1p.*/nA/ig;
			    $lex=~s/2ms.*/ka/ig;
			    $lex=~s/2fs.*/ki/ig;
			    $lex=~s/2[mf]?d.*/kumA/ig;
			    $lex=~s/2mp.*/kum/ig;
			    $lex=~s/2fp.*/kun~a/ig;
			    $lex=~s/3ms.*/hu/ig;
			    $lex=~s/3fs.*/hA/ig;
			    $lex=~s/3[mf]?d.*/humA/ig;
			    $lex=~s/3mp.*/hum/ig;
			    $lex=~s/3fp.*/hun~a/ig;
			    $lex=~s/([^\s\_]+)\_.*/$1/;
   			}

			$diac=$lex;

			# gloss:clitic will be changed in the future to come from BAMA databases used in ALMOR.
			$out[$t]="type:$clitic bw:$bw gloss:clitic lex:$lex pos:$pos diac:$diac";

		    }

		}
	    }
	}
	
	    
	if ($rest > -1){
	    $out[$rest]="type:main $morph";
	    
	    if ($bwrest ne ""){
		$out[$rest]=~s/  gloss:/ bw:$bwrest gloss:/;
	    }
	}

	#B. FORM

	#WORD|POS:(CATIB|PENN|BW|ALMOR)|LEXEME|STEM|SURF
	# TAG SETS DEFINED FOR SPECIFC split schemes...
	# FORM0 BASE = WORD
	# FORM0 DIAC = 0
	# FORM0 ENCMARK = +
	# FORM0 PROCMARK = +
	# FORM0 ESC:PAREN = 1
	# FORM0 LEXEME SHOWINDEX = 0
	# FORM0 NORM:A = 1
	# FORM0 NORM:H = 0
	# FORM0 NORM:T = 0
	# FORM0 NORM:Y = 1
        # GLOSS 

	#>>> not handled
	# WORD ADJUST = ()... not yet
	# FORM0 ESC:COMMA = 0
	# FORM0 ESC:PLUS = 0
	# FORM0 ESC:STAR = 0
	
	for (my $t=0; $t<@out; $t++){
	    ## In this loop, each of the SPLIT pieces of @out are 
	    ## examined, and each required FORM element is built

	    my @form=();
	    if( ! defined $out[$t] ) { $out[$t] = ""; }

	    if ($out[$t]=~s/^type:(\S+) //){
		my $type=$1;  ## main or enc# or prc#
		
		for (my $f=0; $f<=$$PARAM{"MAXFORM"}; $f++){
		   
		    if ($$PARAM{"FORM$f BASE"} =~/^(WORD|LEXEME|STEM|SURF|GLOSS|COPY\d+)$/){
			if ($$PARAM{"FORM$f BASE"} =~/^COPY(\d+)$/){
			    # Copy existing form
			    my $copy=$1;
			    $form[$f]=$form[$copy];
			}else{
			    if ($type=~/enc/){
				# Form of enclitics
				if ($$PARAM{"FORM$f BASE"} eq "GLOSS"){
				    if( $out[$t]=~/gloss:(\S+)/ ) { $form[$f]=$1; }
				    else { $form[$f] = "enclitic"; }
				    
				}elsif( $out[$t]=~/diac:(\S+)/ ) { 
				    $form[$f]=$1; 
				} else { $form[$f] = ""; }

				$form[$f]=$$PARAM{"FORM$f ENCMARK"}.$form[$f]
			    }elsif ($type=~/prc/){
				# Form of proclitics
				if ($$PARAM{"FORM$f BASE"} eq "GLOSS"){
				    if( $out[$t]=~/gloss:(\S+)/ ) { $form[$f]=$1; }
				    else { $form[$f] = "proclitic"; }
				    
				}elsif( $out[$t]=~/diac:(\S+)/ ) { 
				    $form[$f]=$1; 
				} else { $form[$f] = ""; }

				$form[$f].=$$PARAM{"FORM$f PROCMARK"};


		            }else{
			    
				if ($$PARAM{"FORM$f BASE"} eq "WORD"){
				    
				    #print "OLD $originalmorph\nNEW $out[$t]\n";
				    if ($out[$t] =~/NO-ANALYSIS/){
					$form[$f]=$word;
				    }elsif ($out[$t] eq $originalmorph){ #smart generation mode
					$form[$f]=$word;
					#print "SMART : $originalmorph\n";
				    }else{
					my $morph=$out[$t];

					
					#HARDCODED FIXES SHOULD GO TO ALMOR
					#problems with limited/erroneous generation...
                                        #lys lexeme issues!!
					$morph=~s/lex:layosa_2 (.*pos:verb.*prc3:0.* stem):>alayosa/lex:layosa_1 $1:layos/;
					$morph=~s/lex:layosa_2 (.*pos:part_neg.*prc3:0.* stem):>alayosa/lex:layosa_2 $1:layos/;
					#TAlmA lex issues
					$morph=~s/lex:TAlamA_1 (.*prc1:0.* stem):laTAlamA/lex:TAlamA_2 $1:TAlamA/;
					###############
					
					$morph=~s/(stem|stemcat|bw|gloss|rat|source):\S+//g;
					#print "##  $morph => ";
					
					my @extra=();

					## generateSolutions returns a reference to an array now
					($form[$f],@extra)= @{ &ALMOR3::generateSolutions($morph,$ALMOR3DB,"diac") };
				    	#print "$form[$f] (@extra)\n";
					
					if (@extra>0){

					    $morph=$out[$t];
					    $morph=~s/(bw|gloss|rat|source):\S+//g;
					    #print "##  $morph => \n";
					    #HARDCODED FIXES SHOULD GO TO ALMOR
					    #problems with unconstrained generation...

					    if ($morph=~s/lex:li-_1 (.* enc0:0)/lex:li_1 $1/){$morph=~s/stem:\S+//;}
					    $morph=~s/(lex:EalaY_1 .*enc0:0.* stem):(Ealay|EalAma)/$1:EalaY/;
					    $morph=~s/(lex:<ilaY_1 .*enc0:0.* stem):<ilay/$1:<ilaY/;
					    $morph=~s/(lex:ladaY_1 .*enc0:0.* stem):laday/$1:ladaY/;
					    $morph=~s/(lex:mivol_1 .*enc0:0.* stem):mivolamA/$1:mivol/; #problem is plural/other-form confusion...
					    $morph=~s/(lex:Hiyn_1 .*enc0:0.* stem):HiynamA/$1:Hiyn/;
					    $morph=~s/(lex:qal~-i_1 .*enc0:0.* stem):qal~amA/$1:qal~/;
					    $morph=~s/(lex:>an~a_1 .*prc1:0.*enc0:0.* stem):\S+/$1:>an~a/;
					    $morph=~s/(lex:kilA_1 .*num):[dp] (.*enc0:0.* stem):\S+/$1:s $2:kilA/;
					    $morph=~s/(lex:kAn-u_1 .*prc3:0.* stem):>akAn/$1:kAn/;
					    $morph=~s/(lex:zAl-a_1 .*prc0:0.* stem):mAzAl/$1:zAl/;
					    $morph=~s/(lex:zAl-a_1 .*prc0:0.* stem):mAzil/$1:zil/;
					    $morph=~s/(lex:Al~a\*iy_1 .*prc1:0.* stem):(biAl~a\*iy|kaAl~a\*iy|lil~a\*iy)/$1:Al~a*iy/;
					    $morph=~s/(lex:Al~a\*iy_1 .*prc1:0.* stem):(biAl~atiy|kaAl~atiy|lil~atiy)/$1:Al~atiy/;
					    $morph=~s/(lex:Al~a\*iy_1 .*prc1:0.* stem):(biAl~a\*iyna|kaAl~a\*iyna|lil~a\*iyna)/$1:Al~a\*ayoni/;
					    $morph=~s/(lex:All~\`h_1 .*prc1:0.* stem):(lil~\`hi|biAll~\`hi|waAll~\`hi)/$1:All~\`h/;
					    $morph=~s/lex:yAll~\`h_1 (.*prc1:0.* stem):(yAll~\`h)/lex:All~\`h_1 $1:All~\`h/;

					    #problem with overgeneration of cases wrA'/wrA}... bad entries!
					    $morph=~s/(lex:.*A\'\_\d+ .*enc0:0.* stem:\S+)A\}/$1A'/;
					    $morph=~s/(enc0:0.* stem:\S+)\& stemcat:Nuh/$1'/;
					    $morph=~s/(enc0:0.* stem:\S+)\} stemcat:Nihy/$1'/;
					    $morph=~s/(enc0:0.* stem:\S+)A stemcat:Nhy/$1aY/; #mEnY
					    
					    #bad stems ... unnecessary!! (English gloss irrelevant!)

					    $morph=~s/(lex:>ax_1 .*enc0:0.* stem):>axiy/$1:>ax/;
					    $morph=~s/(lex:>ab_1 .*enc0:0.* stem):>abiy/$1:>ab/;

					    #ALMOR- handle -p/h and -y'|} spelling variants...

					    #argh... bad stems!! >n and l>n..... mnzl,mnAzl,mnzly....
					    #All*y cases...
					    #detect ambig forms in database... >HyY|>HyA...
					    ####

					    $morph=~s/stemcat:\S+//g;

					    #print "#2# $morph => ";
					    $form[$f]= &chooseForm($word, $morph,&ALMOR3::generateSolutions($morph,$ALMOR3DB));
					    #print "$form[$f] (@extra)\n";
					}
				
					
				    }
				}elsif ($$PARAM{"FORM$f BASE"} eq "LEXEME"){
				    if ($out[$t] =~/NO-ANALYSIS/){
					$form[$f]=$word;
				    }else{
					#$out[$t]=~/lex:(\S+)/;
					#$form[$f]=$1;
					if( $out[$t]=~/lex:(\S+)/ ) { $form[$f]=$1; }
					else { $form[$f] = ""; }
				    }
				    if (not $$PARAM{"FORM$f LEXEME SHOWINDEX"}){
					$form[$f]=~s/(\-[uai]+)?\_\d+$//;
				    }
				}elsif ($$PARAM{"FORM$f BASE"} eq "STEM"){
				    if ($out[$t] =~/NO-ANALYSIS/){
					$form[$f]=$word;
				    }else{
					#$out[$t]=~/bw:(\S+)/;
					#$form[$f]=$1;
					if( $out[$t]=~/bw:(\S+)/ ) { $form[$f]=$1; }
					else { $form[$f] = ""; }
					$form[$f]=~s/\/[^\+]+//g;
					$form[$f]=~s/\+//g;
					$form[$f] =~ s/\(null\)//g;
				    }
				}elsif ($$PARAM{"FORM$f BASE"} eq "SURF"){
				    $form[$f]=$word;  #not elegenat ... make diac...

				}elsif ($$PARAM{"FORM$f BASE"} eq "GLOSS"){
				    if ($out[$t] =~/NO-ANALYSIS/){
					$form[$f]="NO-GLOSS";
				    }else{
					if( $out[$t]=~/gloss:(\S+)/ ) { $form[$f]=$1; }
					else { $form[$f] = "NO-GLOSS"; }
				    }
				}
				#print "FORM $f : |$form[$f]|\n--------------\n";
				if (! defined $form[$f] || $form[$f] eq ""){ $form[$f]="@@".$word."@@"; }  #default
				#if ($form[$f] eq ""){ $form[$f]="@@".$word."@@"; }  #default
			    }
			}

			#FORMAT DETAILS -- normalization, escaping, diacritic removal, encoding

			if ( $$PARAM{"FORM$f BASE"} ne "GLOSS") {
			    ## BASE is WORD, LEXEME, STEM, SURF or COPY

			    $form[$f]=~s/\{/A/g;   #do this always!! 
			    #if ($$PARAM{"FORM$f ESC:COMMA"}){ $form[$f]=~s/,/-COMMA-/g; } 
			    #ESC:PLUS
			    #ESC:STAR
			    if ($$PARAM{"FORM$f NORM:A"}==1){ $form[$f]=~s/[><\|\{]/A/g; }
			    if ($$PARAM{"FORM$f NORM:Y"}==1){ $form[$f]=~s/Y/y/g; }
			    if ($$PARAM{"FORM$f NORM:H"}==1){ $form[$f]=~s/[\&\}]/\'/g; }
			    if ($$PARAM{"FORM$f NORM:T"}==1){ $form[$f]=~s/p/h/g; }
			    if ( $$PARAM{"FORM$f DIAC"}==0 ){ 
				my $tempword=$form[$f];
				$form[$f]=~s/[aiuo~\`FKN]//g; 
				if ($form[$f] eq "") {$form[$f]=$tempword}
			    }

			    my $encoding = $$PARAM{"FORM$f ENCODING"};
			    if( $$PARAM{"ENCODE ALL"} ne "" ) { $encoding = $$PARAM{"ENCODE ALL"}; }
			    if( $encoding eq "SAFEBW" ) {
				$form[$f] = &MADATools::convertBuckwalterToSafeBW($form[$f]);
			    } elsif ( $encoding eq "UTF8" ) {
				$form[$f] = &MADATools::convertBuckwalterToUTF8($form[$f]);
			    }
			    
			    if ($$PARAM{"FORM$f ESC:PAREN"}){ 
				$form[$f]=~s/\(/-LRB-/g; 
				$form[$f]=~s/\)/-RRB-/g; 
			    } 


			}
		    }else{	
			################  POS modes  #####################
			#print "POS>$out[$t]\n";

			if ($$PARAM{"FORM$f BASE"} eq "POS:ALMOR"){
			    
			    if ($type=~/enc/){
				#$out[$t]=~/pos:(\S+)/;
				#$form[$f]=$1;
				if( $out[$t]=~/pos:(\S+)/ ) { $form[$f]=$1; }
				else { $form[$f] = ""; }
				$form[$f]=~s/^\S+_//;
				$form[$f]=$$PARAM{"FORM$f ENCMARK"}.$form[$f]
			    }elsif ($type=~/prc/){
				#$out[$t]=~/pos:(\S+)/;
				#$form[$f]=$1;
				if( $out[$t]=~/pos:(\S+)/ ) { $form[$f]=$1; }
				else { $form[$f] = ""; }
				$form[$f]=~s/^\S+_//;
				$form[$f].=$$PARAM{"FORM$f PROCMARK"};
		            }else{
				if ($out[$t] =~/NO-ANALYSIS/){
				    if ($$PARAM{"MARK_NO_ANALYSIS"}){
					$form[$f]="@@"."noun"."@@";
				    }else{
					$form[$f]="noun";
				    }
				}else{
				    #$out[$t]=~/pos:(\S+)/;
				    #$form[$f]=$1;
				    if( $out[$t]=~/pos:(\S+)/ ) { $form[$f]=$1; }
				    else { $form[$f] = ""; }

				}
			    }
			    
			}elsif ($$PARAM{"FORM$f BASE"} eq "POS:MADA"){
			    
			    if ($type=~/enc/){
				#$out[$t]=~/pos:(\S+)/;
				#$form[$f]="encpos:".$1;
				if( $out[$t]=~/pos:(\S+)/ ) { $form[$f]="encpos:".$1; }
				else { $form[$f] = ""; }
				#$form[$f]=~s/^\S+_//;
				$form[$f]=$$PARAM{"FORM$f ENCMARK"}.$form[$f]
			    }elsif ($type=~/prc/){
				#$out[$t]=~/pos:(\S+)/;
				#$form[$f]="prcpos:".$1;
				if( $out[$t]=~/pos:(\S+)/ ) { $form[$f]="prcpos:".$1; }
				else { $form[$f] = ""; }
				#$form[$f]=~s/^\S+_//;
				$form[$f].=$$PARAM{"FORM$f PROCMARK"};
		            }else{
				if ($out[$t] =~/NO-ANALYSIS/){
				    if ($$PARAM{"MARK_NO_ANALYSIS"}){
					$form[$f]="@@"."noun"."@@";
				    }else{
					$form[$f]="noun";
				    }
				}else{
				    #$out[$t]=~/(pos:\S+.*enc0:\S+)/;
				    #$form[$f]=$1;
				    if( $out[$t]=~/(pos:\S+.*enc0:\S+)/ ) { $form[$f]=$1; }
				    else { $form[$f] = ""; }
				    $form[$f]=~s/\s+/\#/g;
				}
			    }
			    
			}elsif ($$PARAM{"FORM$f BASE"}=~/^POS:(BW|PENN|CATIB)/){
			    
			    if ($out[$t] =~/NO-ANALYSIS/){
				if ($$PARAM{"FORM$f BASE"} eq "POS:PENN"){$form[$f]="NN"}
				elsif ($$PARAM{"FORM$f BASE"} eq "POS:CATIB"){$form[$f]="NOM"}
				else { $form[$f]="NOUN"}

				if ($$PARAM{"MARK_NO_ANALYSIS"}){
				    $form[$f]="@@".$form[$f]."@@";
				}
			    }else{
				if ($type=~/enc/){
				    #$out[$t]=~/bw:(\S+)/;
				    #$form[$f]=$1;
				    if( $out[$t]=~/bw:(\S+)/ ) { $form[$f]=$1; }
				    else { $form[$f] = ""; }

				    $form[$f]=~s/\+//g;
				    $form[$f]=$$PARAM{"FORM$f ENCMARK"}.$form[$f]
				}elsif ($type=~/prc/){
				    #$out[$t]=~/bw:(\S+)/;
				    #$form[$f]=$1;
				    if( $out[$t]=~/bw:(\S+)/ ) { $form[$f]=$1; }
				    else { $form[$f] = ""; }

				    $form[$f]=~s/\+//g;
				    $form[$f].=$$PARAM{"FORM$f PROCMARK"};
			        } else{
				    #$out[$t]=~/bw:(\S+)/;
				    #$form[$f]=$1;
				    if( $out[$t]=~/bw:(\S+)/ ) { $form[$f]=$1; }
				    else { $form[$f] = ""; }
				    $form[$f]=~s/[^\+\/]+\///g;
				    $form[$f]=~s/\++/+/g;
				    $form[$f]=~s/^\+//;
				    $form[$f]=~s/\+$//;
				    $form[$f]=~s/^\/+//;
				}
				if ($$PARAM{"FORM$f BASE"} eq "POS:PENN"){
				    #$form[$f]=&BW2PENN($form[$f]);
				    $form[$f]=&BW2POS($form[$f], "PENN");
				}elsif ($$PARAM{"FORM$f BASE"} eq "POS:CATIB"){
				    #$form[$f]=&BW2CATIB($form[$f]);
				    $form[$f]=&BW2POS($form[$f], "CATIB");
				}
			    }
			}
		    }
		}
		$out[$t]=join($$PARAM{"FDELIM"},@form);
	    }
	}
	



#For use with ADJUST mechanism

#	    }elsif ($tokens[$t]=~/(\S+):([^\s=]*)(=?)(\S*)\|(\S+)\|([^\s=]*)(=?)(\S*)/){ #clitics
#		# F:V|N|S
#		# V: pV = sV (pre) (suf)
#		# S: pS = sS (pre) (suf)
#		# value in = is what is copied...
#		my ($f,$pv,$ev,$sv,$n,$ps,$es,$ss)=($1,$2,$3,$4,$5,$6,$7,$8);
#
#		#print "CLITIC: ($f,$pv,$ev,$sv,$n,$ps,$es,$ss)\n";
#
#		if ($morph=~s/ ($f:$pv(\S*)$sv\S*) / $f:$n /){
#		    my $eq=$2;
#		    $posout[$t]=$1;
#
#		    if (($ev eq "=")&&($es eq "=")){
#			$out[$t]=$ps.$eq.$ss;
#		    }else{
#			$out[$t]=$ps.$ss;
#		    }
#
#		
#		}
#	    }



	#C. MERGE/JOIN

	if ($mergestep){
	    my $delim=" ";
	    $out="";

	    for (my $i=0; $i<@out; $i++){
		if ($out[$i] ne ""){
		    if ($out[$i] eq "[MERGE"){
			$delim=$$PARAM{"TDELIM"};
		    }elsif ($out[$i] eq "MERGE]"){
			$delim=" ";
		    }elsif ($out eq ""){
			$out=$out[$i];
		    }else{
			$out.=$delim.$out[$i];
		    }
		}
	    }
	}else{
	    $out=join(' ',@out);
	}


	$out=~s/\s+\[\-DELPLUS\-\]\s+//g;
	$out=~s/\s+/ /g;
	$out=~s/^\s+//;
	$out=~s/\s+$//;
	$out=~s/\[\-NEWLINE\-\]/\n/g;
	$$TOKANMEM{"$memkey"}=$out;
    }
    
    #print "$out\n";

    return($out);


}






##################################################################################

=head1 KNOWN BUGS

    Currently in Development.  No bugs known.

=cut

=head1 SEE ALSO

    MADAWord, MADATools, ALMOR3

=cut

=head1 AUTHOR

    Ryan Roth, Nizar Habash, Owen Rambow
    
    Center for Computational Learning Systems
    Columbia University
    
    Copyright (c) 2005,2006,2007,2008,2009,2010 Columbia University in the City of New York

=cut

1;
