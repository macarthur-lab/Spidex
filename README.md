# SPIDEX

###Overview
 
 VEP plugin that outputs splicing predictions from the method described in Barash et al, 2010: "Deciphering the Splicing Code".
 
###Installation

 PERL5LIB=~/.vep/Plugins/:$PERL5LIB;
 
 mv Spidex.pm ~/.vep/Plugins

###Example

 perl variant_effect_predictor.pl -i variations.vcf --plugin SPIDEX
