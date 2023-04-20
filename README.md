<img align="right" src="sbatchtools.png" height="100px" width="100px">

# sbatchtools

sbatchtools is a suite of shell scripts to automate slurm submissions

## sruni

sruni automates the submission of creating and activating an interactive node  

```
------------------------------  SRUN INTERACTIVE HELP ------------------------------ 
---------- PROGRAM              == sruni (srun interactive)
---------- VERSION              == 1.0.0
---------- DATE                 == 2023_04_20
---------- CONTACT              == kew24 (template from lee.marshall@vai.org -- big thank you!)
---------- DISCRIPTION          == automates creation of slurm interactive job
---------- PATH                 == export PATH=\$PATH:/path/to/sruni/directory

-------------------- COMMANDS --------------------
---------- USAGE                == sruni [options]*
---------- FLAGS
        [ -d | --debug ]                == creates job script but does not execute
        [ -h | --help ]                 == help function
---------- OPTIONS
        [ -c | --cores <int> ]          == number of cores per job 1 to 80, default 1 core
        [ -N | --name <name> ]          == name specific to job, default STDIN
        [ -p | --partition <name> ]     == specify partition name, default any partition
        [ -w | --walltime <int> ]       == number of hours per job 1 to 336, default 24 hours

-------------------- EXAMPLES --------------------
sruni
sruni -c 4 -p short
------------------------------  SRUN INTERACTIVE HELP ---------------------------
```

## sbatchs

sbatchs automates the submission of creating and activating of job submissions. sbatchs will automate single and array based submissions as well as linux and R based submissions. 

```
------------------------------  SBATCH SUBMITTER HELP ------------------------------ 
---------- PROGRAM              == sbatchs (sbatch submitter)
---------- VERSION              == 1.0.0
---------- DATE                 == 2023_04_20
---------- CONTACT              == kew24 (template from lee.marshall@vai.org -- big thank you!)
---------- DISCRIPTION          == automates creation and submition of slurm sbatch scripts
---------- PATH                 == export PATH=\$PATH:/path/to/sbatchs/directory

-------------------- COMMANDS --------------------
---------- USAGE                == sbatchs [options]* -s "command"
---------- FLAGS
        [ -d | --debug ]                == creates job script but does not execute
        [ -h | --help ]                 == help function
---------- OPTIONS
        [ -a | --array <file> ]         == file containing column of sample names for array, 
                                                use SAMPLE as variable for sample name in command or script
        [ -c | --cores <int> ]          == number of cores per job 1 to 80, default 1 core
        [ -n | --name <name> ]          == name specific to job, default user name and date
        [ -p | --partition <name> ]     == specify partition name, default any partition
        [ -r | --rscript <"command"> or <file> ]        == command enclosed in double quotes or script file
        [ -s | --script <"command"> or <file> ] == command enclosed in double quotes or script file
        [ --script_args <args> ]        == positional arguments passed to your bash script file
        [ -w | --walltime <int> ]       == number of hours per job 1 to 336, default 24 hours

-------------------- MULTIPLE COMMANDS --------------------
---------- USAGE                == containg multiple compands with double quotes, 
                                        with each command on seperate line, see example
---------- COMMAND VARIABLES    == must start with a backslash \$1

-------------------- EXAMPLES --------------------
touch sample_data.txt
sbatchs -n gzip_file -s "gzip sample_data.txt"

touch sample1_data.txt
touch sample2_data.txt
echo sample1 > sample_names
echo sample2 >> sample_names
sbatchs -n zip_comand -a sample_names -s "zip SAMPLE_data.zip SAMPLE_data.txt"

echo "zip SAMPLE_data.zip SAMPLE_data.txt" > sample_script
sbatchs -n zip_script -a sample_names -s sample_script -d
------------------------------  SBATCH SUBMITTER HELP ---------------------------
```
