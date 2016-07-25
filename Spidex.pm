=head1 CONTACT                                                                                                       

 Daniel Birnbaum <danpbirnbaum@gmail.com>
 
=cut

=head1 NAME

 ssDist

=head1 SYNOPSIS

 mv ssDist.pm ~/.vep/Plugins
 perl variant_effect_predictor.pl -i variations.vcf --plugin ssDist

=head1 DESCRIPTION

 A VEP plugin that computes the distance to the nearest donor and acceptor splice sites.

=cut

package Spidex;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);
use Bio::Perl;
use DBI;

sub get_header_info {
    return {
    	dpsi_max_tissue => "The delta PSI. This is the predicted change in percent-inclusion due to the variant, reported as the maximum across tissues (in percent).",
    	dpsi_zscore => "This is the z-score of dpsi_max_tissue relative to the distribution of dPSI that are due to common SNPs.",
        spidex_transcript => "The affected RefSeq transcript according to SPIDEX",
        spidex_gene => "The affected gene according to SPIDEX"
    };
}

sub feature_types {
    return ['Transcript'];
}

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);   
    $self->{spidex_dbname} = $self->{spidex_dbname} || 'mysql';
    if ($self->{spidex_dbname} eq 'mysql') {
        my $db_info = "DBI:mysql:mysql_read_default_group=loftee;mysql_read_default_file=~/.my.cnf";
        $self->{spidex_database} = DBI->connect($db_info, undef, undef) or die "Cannot connect to mysql using " . $db_info . "\n";
    } else {
        $self->{spidex_database} = DBI->connect("dbi:SQLite:dbname=" . $self->{spidex_dbname}, "", "") or die "Cannot connect to " . $self->{spidex_dbname} . "\n";
    }
    return $self;
}

sub run {
    my ($self, $transcript_variation_allele) = @_;
    my $allele = $transcript_variation_allele->allele_string();
    my $indel = $allele =~ "-";
    return {} if $indel;

    # if SNP, look for corresponding row in MySQL table ..
    
    # get values to query from table
    my ($ref, $alt) = split /\//, ($allele);
    my $slice = $transcript_variation_allele->variation_feature->feature_Slice();
    my $chrom = 'chr' . $slice->seq_region_name();
    my $pos = $slice->start;

    # perform query
    my $db = $self->{spidex_database};
    my $sql_query = "SELECT * FROM spidex WHERE chromosome = ? AND position = ? AND ref_allele = ? AND mut_allele = ?;";
    my $sql_query_obj = $db->prepare($sql_query);
    $sql_query_obj->execute($chrom, $pos, $ref, $alt) or die("MySQL ERROR: $!");

    # get results
    my $results = $sql_query_obj->fetchrow_hashref;
    $sql_query_obj->finish();
    if (defined $results) {
        return { dpsi_max_tissue => $results->{dpsi_max_tissue}, dpsi_zscore => $results->{dpsi_zscore}, 
                 spidex_transcript => $results->{transcript}, spidex_gene => $results->{gene} };
    }
    return {};
}

sub DESTROY {
    my $self = shift;
    $self->{spidex_database}->disconnect();
}


1;