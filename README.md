# Cluster Flow

Cluster Flow is a pipelining tool to automate and standardise bioinformatics analyses on high-performance cluster environments. It is designed to be easy to use, quick to set up and flexible to configure.

## Documentation
For Cluster Flow documentation with information and examples, see: **[http://clusterflow.io](http://clusterflow.io)**

## Download
You can find stable versions to download on the [releases page](https://github.com/ewels/clusterflow/releases).

You can get the development version of the code by cloning this repository:
```
git clone https://github.com/ewels/clusterflow.git
```
Alternatively, you can download a [.zip file](https://github.com/ewels/clusterflow/archive/master.zip)

## Change Log

#### v0.4 devel
* **Warning: Break of backwards compatability**
	* The way that genome references are handled has been rewritten.
		* Genome references are no longer tied to specific types, they are now agnostic.
	      to the type of reference, making it far easier to whatever type of reference you need.
	      Additionally, the wizard to add genome paths has been written and is now largely automated,
	      making it super fast to add new genomes.
		* A consequence of this change is any `genomes.config` files written before v0.3 of
	      Cluster Flow will no longer work. Thankfully the fix is easy! Replace `@bowtie_path`
	      with `@reference  bowtie`. `@gtf_path` changes to `@reference gtf` and so on.
	      `@genome_path` changes to `@reference  fasta`.
		* If you have any custom pipelines these will also need to be updated. `@require_bowtie`
	      changes to `@require_reference bowtie`and so on. See updated example module files
	      for examples on how to update custom modules.
		* Apologies for any inconvenience that this change incurs. Feel free to [get in touch](https://github.com/ewels)
	      if you have any problems.
	* `~/clusterflow/` directory moved to `~/.clusterflow/` to reduce home directory clutter.
		* Cluster Flow won't find your old config file - run `mv ~/clusterflow/ ~/.clusterflow/` to fix.

* New Stuff
	* You can now run Cluster Flow locally (new `@cluster_environment` `local` )
        * Tested on Mac OSX and Linux. Includes `--qstat` and `--qdel` functionality
        * Allows easy testing and use of pipelines for those without access to a HPC cluster.
		* New `--environment` command line option allows you to set this at run time.
	* The `--make_config` wizard has been renamed to `--setup` and does a lot more stuff
        * Should make first-run of Cluster Flow much easier - just download and run `cf --setup`
	* Support for STAR RNA-seq aligner (thanks to [@stu2](https://github.com/stu2))
	* New ChIP-Seq analysis pipeline (thanks to [@orzechoj](https://github.com/orzechoj))
		* Includes six new modules: `bedToNrf`, `bedtools_bamToBed`, `deeptools_bamCoverage`, `deeptools_bamFingerprint`, `phantompeaktools_runSpp` and `picard_dedup`
	* Modules are given more information via the run file to help
       decide the amount of memory and cores they bid for (eg. number of files, reference)
	* All perl scripts now have `env perl` in shebang to increase portability
	* Modules can now have file extensions, as long as they have `.cfmod` at the end of the basename
        * This helps editing tools with syntax highlighting, amongst other things
	* Python comes to Cluster Flow! The first Python module is up and running, along with a `Helpers.py` module file
        * See the `example_module.py` file for help in writing your own modules in Python
        * The basic Perl module helpers are now available in the Python packages as well, more translation to follow
	* Now using GRIDEngine `h_vmem` memory option instead of `vf`
        * Gives a hard memory limit instead of a request limit at job submission time
        * Thanks to  [@stu2](https://github.com/stu2) and [@s-andrews](https://github.com/s-andrews)
	* Support for explicit GRIDEngine queue nomination on the command line
	* Modules now print their software versions to the log where possible.
	* New `--merge` (command line) and `@merge_regex` (config file) options to automatically merge input files.
		* This is implemented using a new module, `cf_merge_files`, which can also be used in pipelines
		* If the supplied regexes only match single files, the module can be used to simply rename files
    * New `--runfile_prefix` option to help avoid potential filename clashes.
	* New `@cluster_project` config option to specify project for cluster jobs.
    * Added compatability with GRIDEngine `~/.sge_request files` (by ignoring them).
      Thanks to [@s-andrews](https://github.com/s-andrews)
    * New tophat module called `tophat` which introduces a workaround for buggy MAPQ
        reporting by tophat whilst keeping unique alignments. Thanks to [@FelixKrueger](https://github.com/FelixKrueger).
        * The previous tophat module is still available if you're not interested in MAPQ scores and
            would like slightly faster processing. This is now called `tophat_broken_MAPQ.cfmod`.
    * Pipeline completion e-mails are now written to disk as well (HTML and plain text)
    * New log file containing the job submission commands as well as the output received from the cluster at submission (usually numeric job identifiers)
    * Removed the `--qstatcols` command line option and added the `@colourful` config option to replace it
        * The config wizard is also updated to add this to your personal config
    * Added checks to make sure that we have at least one config file, and that the cluster environment is set
	* Added new `@environment_module_always` config option to _always_ load certain environment modules at run time.
	* Added new `@require_python_package` pipeline option to check that a Python pacakge is installed before pipeline launch
* Bugs Squashed
	* Fixed output filename problem in tophat with output cleaning
	* Fixed bugs causing minimum memory allocation regardless of availability
	* Fixed bug causing Bowtie2 to fail if Bowtie1 index absent
    * Cleaned up some unrecognised output that always made it into the log file

#### [v0.3](https://github.com/ewels/clusterflow/releases/tag/v0.3) - 2014-07-11
* New Stuff
	* Awesome new HTML report e-mails
		* Much more readable HTML report e-mails which look super-snazzy (see [example](http://ewels.github.io/clusterflow/example_report_good.html))
		* Any errors are highlighted making them quick to identify (see [example](http://ewels.github.io/clusterflow/example_report_bad.html))
		* Custom strings set in the config can flagged as [highlights](http://ewels.github.io/clusterflow/example_report_highlights.html) or as [warnings](http://ewels.github.io/clusterflow/example_report_warnings.html)
		* Designed to work on desktop and mobile phone screens
	* Cluster Flow now re-orders the log file so that output from different modules doesn't overlap
		* Made each module prepend its stdout and sterr with a CF module flag
		* Made the `cf_run_finished` module parse the above flag and print out module by module
	* Rewrote how the environment module loading works - now much more robust
		* Uses `modulecmd` to prepare perl syntax commands
		* Moved code into the `load_environment_modules` function in Helpers.pm
	* Added environment module aliases
		* This allows you to load specific environment module versions or use different names to those specified within CF modules
		* eg. Replace `fastqc` with `FastQC/0.11.2`
* Updates
	* Made the `bismark_methXtract` module create genome-wide coverage reports if GTF path is available
	* Added the `-q` parameter to the FastQC module to make the log files cleaner
	* Removed the now uneccesary `bismark_tidy` module and renamed `bismark_messy` to `bismark_report`
* Bugs Squashed
	* Fixed dependency bug introduced in v0.2 which was making all downloads fire simultaneously
	* Fixed issue where modules using the CF::Constants Perl Module couldn't load the central config file
	* Fixed typo in environment module loading in `bismark_align` module
	* Reordered loading of the environment modules in `trim_galore` so that FastQC is loaded first, fixing dependency issues

#### [v0.2](https://github.com/ewels/clusterflow/releases/tag/v0.2) - 2014-05-29
* New Stuff
	* Now compatable with SLURM
	* Customise batch job commands in the config (see the
		[docs](http://ewels.github.io/clusterflow/installation/#making_cluster_flow_work_with_your_environment))
	* Created new GitHub pages website to hold documentation: http://ewels.github.io/clusterflow
* Updates
	* Ported repository to github: https://github.com/ewels/clusterflow
	* Wrote new readme for github
* Bugs Squashed
	* Custom modules in `~/.clusterflow/modules/` weren't being found
	* General code clean-ups all over the place

#### [v0.1](https://github.com/ewels/clusterflow/releases/tag/v0.1) - 2014-04-25
* The first public release of Cluster Flow, although it's been in use at the Babraham Institute for around 6 months. It's been in heavy development throughout that time and is now approaching a state of being relatively stable.


## Credits

Cluster Flow was written by [Phil Ewels](http://phil.ewels.co.uk) whilst working in the
[Babraham Bioinformatics](http://www.bioinformatics.babraham.ac.uk/) group in Cambridge, UK.
He now maintains it whilst working at the [Science for Life Laboratory](http://www.scilifelab.se/) in Stockholm, Sweden.

Cluster Flow has also had contributions from [@stu2](https://github.com/stu2), [@orzechoj](https://github.com/orzechoj),
[@s-andrews](https://github.com/s-andrews) and [@FelixKrueger](https://github.com/FelixKrueger), amongst others.

## License
Cluster Flow is released with a GPL v3 licence. Cluster Flow is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version. For more information, see the licence that comes bundled with Cluster Flow.
