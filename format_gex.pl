#!/usr/bin/perl

################################################################################
#
# Add gene description field
#
#
#################################################################################


use strict;
use Compress::Zlib;
use MIME::Base64;

my ($i, $value, $gene, $snp, @geneSnp, $line, $gzip, @items);
my ($fh, $sample_annotation, $dataset, $comstr);
my $comheader = "";
my %geneDesc = {};
my %geneName = {};
my $VALSTART = 5;

if (defined $ARGV[0] && $ARGV[0] eq "help") {
	print "Usage: $0 <expression file>\n";
	exit;
}

open (FILE, "zcat /ngs-pubdata/data/annotation/gene/Ensembl_v75_hg19_Gencode.v19_human.txt.gz|") || die $@;
while ($line = <FILE>) {
	@items = split(/\t/, $line);
	$geneDesc{$items[3]} = $items[7];
	$geneName{$items[3]} = $items[6];
}
close (FILE);


open (FILE, $ARGV[0]) || die $@;

$line = <FILE>;
@items = split(/\t/,$line,$VALSTART+1);
for ($i=0; $i<$VALSTART; $i++) {
	print "description\t" if ($i==2);
	print "$items[$i]\t";
}
print "$items[$VALSTART]";

while ($line = <FILE>) {
	$line =~ s/\s+$//g;
	$line =~ s/^\s+//g;
	@items = split(/\t/, $line);

	$gene = $items[0];
	$gene =~ s/\.\d+$//g;

	print "$gene\t$geneName{$gene}\t$geneDesc{$gene}";
	for ($i=2;$i<$VALSTART; $i++) {
		print "\t$items[$i]";
	}
	for ($i=$VALSTART; $i<@items; $i++) {
		if ($items[$i] =~ m/NA/i) {
			$value = $items[$i];
		} else {
			$items[$i] = 0.001 if ($items[$i] < 0.001);
			$value = sprintf("%.3f", $items[$i]);
		}
		print "\t$value";
	}
	print "\n";
}
