#!/usr/bin/env perl
use warnings;
use strict;
use Getopt::Long;
use FindBin qw($Bin);
use lib "$FindBin::Bin/../source";
use CF::Constants;
use CF::Helpers;

##########################################################################
# Copyright 2014, Philip Ewels (phil.ewels@scilifelab.se)                #
#                                                                        #
# This file is part of Cluster Flow.                                     #
#                                                                        #
# Cluster Flow is free software: you can redistribute it and/or modify   #
# it under the terms of the GNU General Public License as published by   #
# the Free Software Foundation, either version 3 of the License, or      #
# (at your option) any later version.                                    #
#                                                                        #
# Cluster Flow is distributed in the hope that it will be useful,        #
# but WITHOUT ANY WARRANTY; without even the implied warranty of         #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          #
# GNU General Public License for more details.                           #
#                                                                        #
# You should have received a copy of the GNU General Public License      #
# along with Cluster Flow.  If not, see <http://www.gnu.org/licenses/>.  #
##########################################################################

# Module requirements
my %requirements = (
	'cores' 	=> ['1','4'],
	'memory' 	=> '5G',
	'modules' 	=> ['subread'],
	'time' 		=> sub {
		my $cf = $_[0];
		my $num_files = $cf->{'num_starting_merged_aligned_files'};
		$num_files = ($num_files > 0) ? $num_files : 1;
		# Bismark alignment typically takes less than an hour per BAM file
		return CF::Helpers::minutes_to_timestamp ($num_files * 2 * 60);
	}
);


# Help text
my $helptext = "".("-"x15)."\n featureCounts Module\n".("-"x15)."\n
Counts reads overlapping exons in a GTF file, grouped by gene.
Takes an aligned BAM file as input and returns a counts file.\n
Use parameter stranded or stranded_rev to count in stranded or reverse
stranded modes. Defaults to not stranded.\n
featureCounts is part of the Subread package.\n\n";

# Setup
my %cf = CF::Helpers::module_start(\%requirements, $helptext);

# MODULE

# Check that we have a GTF file defined
if(!defined($cf{'refs'}{'gtf'})){
   die "\n\n###CF Error: No GTF path found in run file $cf{run_fn} for job $cf{job_id}. Exiting.. ###";
} else {
    warn "\nUsing GTF file $cf{refs}{gtf}\n\n";
}

open (RUN,'>>',$cf{'run_fn'}) or die "###CF Error: Can't write to $cf{run_fn}: $!";

# Print version information about the module.
warn "---------- featureCounts version information ----------\n";
warn `featureCounts -v`;
warn "\n------- End of featureCounts version information ------\n";

# Read any options from the pipeline parameters
my $stranded = defined($cf{'params'}{'stranded'}) ? "-s 1" : '';
$stranded =  defined($cf{'params'}{'stranded_rev'}) ? "-s 2" : $stranded;

# Get the ID tag from parameters, or try to determine from GTF file
my $id_tag = defined($cf{'params'}{'id_tag'}) ? $cf{'params'}{'id_tag'} : 0;
$id_tag = get_gtf_id($cf{'refs'}{'gtf'}) if(!$id_tag);
if(!$id_tag){
	warn "###CF Warning: Can't determine ID tag to use. Trying default 'ID'\n";
	$id_tag = 'ID';
}

# Go through each supplied file and run HTSeq Counts
foreach my $file (@{$cf{'prev_job_files'}}){
	my $timestart = time;

	# Is this a paired end file?
	my $paired = '';
	if(CF::Helpers::is_bam_paired_end($file)){
        $paired = '-p';
    }

	my $counts_file = $file."_counts.txt";
	my $command = "featureCounts -T $cf{cores} $paired $stranded -t exon -g $id_tag -a $cf{refs}{gtf} -o $counts_file $file";
	warn "\n###CFCMD $command\n\n";

	if(!system ($command)){
		my $duration =  CF::Helpers::parse_seconds(time - $timestart);
		warn "###CF featureCounts successfully exited, took $duration\n";
		if(-e $counts_file){
			print RUN "$cf{job_id}\t$counts_file\n";
		} else {
			warn "\n###CF Error! featureCounts counts file $counts_file not found..\n";
		}
	} else {
		print "###CF Error! Error - featureCounts failed for input file '$file': $? $!\n";
	}
}

close (RUN);


# Function to try to guess ID label from GTF file
# Pretty crude - could look for ENSG? Seems to usually be gene_name though.
sub get_gtf_id {
	my $gtf_file = $_[0];
	my $id_tag = 0;
	open (GTF,'<',$gtf_file) or die "###CF Error: Can't open GTF file $gtf_file: $!";
	while (<GTF>) {
		chomp;
		if(/gene_id/){
			$id_tag = 'gene_id';
		} elsif(/ID/){
			$id_tag = 'ID';
		}
		last if($id_tag);
	}
	close(GTF);
	return $id_tag;
}
