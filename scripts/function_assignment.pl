#!/usr/bin/perl

# MANUAL FOR function_assignment.pl

=pod

=head1 NAME

function_assignment.pl -- Calculate per-ORF and overall functional counts from BLAST output

=head1 SYNOPSIS

 function_assignment.pl --btab=/Path/to/input.btab --out=/Path/to/output.txt [--abundance=/Path/to/abun.txt]
                     [--help] [--manual]

=head1 DESCRIPTION

 Calculates per-ORF functional assignment using the btab output of a BLASTp
 against the Phage SEED database. Function is assigned based on max(sum(bit score))
 for each function that a query has.

 If an ORF abundance file is passed (--abundnace) then the abundances for each ORF will be calculated
 and reported for each function. Otherwise raw counts will be used.
 
=head1 OPTIONS

=over 3

=item B<-b, --btab>=FILENAME

BLAST tabular output from a search against Phage SEED. (Required)

=item B<-a, --abundance>=FILENAME

ORF abundance file (Optional).

=item B<-o, --out>=FILENAME

Output file in txt format. (Required)

=item B<-h, --help>

Displays the usage message.  (Optional) 

=item B<-m, --manual>

Displays full manual.  (Optional) 

=back

=head1 DEPENDENCIES

Requires the following Perl libraries.



=head1 AUTHOR

Written by Daniel Nasko, 
Center for Bioinformatics and Computational Biology, University of Maryland.

=head1 REPORTING BUGS

Report bugs to dnasko@umiacs.umd.edu

=head1 COPYRIGHT

Copyright 2017 Daniel Nasko.  
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.  
This is free software: you are free to change and redistribute it.  
There is NO WARRANTY, to the extent permitted by law.  

Please acknowledge author and affiliation in published work arising from this script's 
usage <http://bioinformatics.udel.edu/Core/Acknowledge>.

=cut


use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use Pod::Usage;

#ARGUMENTS WITH NO DEFAULT
my($btab,$abundance,$outfile,$help,$manual);

GetOptions (	
                                "b|btab=s"	=>	\$btab,
                                "a|abundance=s" =>      \$abundance,
				"o|out=s"	=>	\$outfile,
				"h|help"	=>	\$help,
				"m|manual"	=>	\$manual);

# VALIDATE ARGS
pod2usage(-verbose => 2)  if ($manual);
pod2usage( {-exitval => 0, -verbose => 2, -output => \*STDERR} )  if ($help);
pod2usage( -msg  => "\n\n ERROR!  Required argument --btab not found.\n\n", -exitval => 2, -verbose => 1)  if (! $btab );
pod2usage( -msg  => "\n\n ERROR!  Required argument -outfile not found.\n\n", -exitval => 2, -verbose => 1)  if (! $outfile);

my %Abundance;
my @Order;
my %Results;
my %ViromeResults;

my $out_per_query = $outfile . "_per_query.txt";
my $out_whole_set = $outfile . "_whole_virome.txt";

open(IN,"<$btab") || die "\n Error: Cannot open the file: $btab\n";
while(<IN>) {
    chomp;
    my @a = split(/\t/, $_);
    my $fxn = get_fxn($a[12]);
    unless (exists $Results{$a[0]}) {
	push(@Order, $a[0]);
    }
    $Results{$a[0]}{$fxn} += $a[11];
}
close(IN);

if ($abundance) {
    open(IN,"<$abundance") || die "\n Cannot open the abundance file: $abundance\n";
    while(<IN>) {
        chomp;
        my @a = split(/\t/, $_);
        $Abundance{$a[0]} = $a[1];
    }
    close(IN);
}

open(OUT,">$out_per_query") || die "\n Cannot open the file: $out_per_query\n";
foreach my $i (@Order) {
    my $max=0;
    my $fxn;
    foreach my $j (keys %{$Results{$i}}) {
	if ($Results{$i}{$j} > $max) {
	    $Results{$i}{$j} = $max;
	    $fxn = $j;
	}
    }
    print OUT $i . "\t";
    if ($abundance) {
	if (exists $Abundance{$i}) {
	    print OUT $Abundance{$i} . "\t";
	    $ViromeResults{$fxn} += $Abundance{$i};
	}
	else { print OUT "0\t"; }
    }
    else {
	print OUT "1\t";
	$ViromeResults{$fxn}++;
    }
    print OUT $fxn . "\n";
}
close(OUT);

open(OUT,">$out_whole_set") || die "\n Cannot open the file: $out_whole_set\n";
foreach my $i (sort { $ViromeResults{$b} <=> $ViromeResults{$a} } keys %ViromeResults) {
    print OUT $ViromeResults{$i} . "\t" . $i . "\n";
}
close(OUT);

sub get_fxn
{
    my $s = $_[0];
    $s =~ s/.*? //;
    return $s;
}

exit 0;
