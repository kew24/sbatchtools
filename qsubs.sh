#!/bin/bash

#---------- Set Default Values
DEBUG=0
CORES=1
QUEUE=shortq
WALLTIME=24
UMASK=0022

#---------- Colors
RED() { echo "$(tput setaf 1)$*$(tput sgr0)"; }
GREEN() { echo -n "$(tput setaf 2)$*$(tput sgr0)"; }
MAGENTA() { echo "$(tput setaf 5)$*$(tput sgr0)"; }
CYAN() { echo "$(tput setaf 6)$*$(tput sgr0)"; }

#---------- Usage
usage()
{
	CYAN '------------------------------  QSUB SUBMITTER HELP ------------------------------ 
---------- PROGRAM		== qsubs (qsub submitter)
---------- VERSION		== 2.0.2
---------- DATE			== 2022_01_28
---------- CONTACT		== lee.marshall@vai.org
---------- DISCRIPTION		== automates creation and submition of PBS qsub scripts
---------- PATH			== export PATH=\$PATH:/path/to/qsubs/directory

-------------------- COMMANDS --------------------
---------- USAGE		== qsubs [options]* -s "command"
---------- FLAGS
	[ -d | --debug ]		== creates job script but does not execute
	[ -h | --help ]			== help function
---------- OPTIONS
	[ -a | --array <file> ]		== file containing column of sample names for array, 
						use SAMPLE as variable for sample name in command or script
	[ -c | --cores <int> ]		== number of cores per job 1 to 80, default 1 core
	[ -n | --name <name> ]		== name specific to job, default user name and date
	[ -q | --queue <name> ]		== specify queue name, default any queue
	[ -r | --rscript <"command"> or <file> ]	== command enclosed in double quotes or script file		
	[ -s | --script <"command"> or <file> ]	== command enclosed in double quotes or script file
	[ --script_args <args> ]	== positional arguments passed to your bash script file
	[ -u | --umask <umask>]		== umask value, default 0022 (group read)
	[ -w | --walltime <int> ]	== number of hours per job 1 to 744, default 24 hours

-------------------- MULTIPLE COMMANDS --------------------
---------- USAGE		== containg multiple compands with double quotes, 
					with each command on seperate line, see example
---------- COMMAND VARIABLES	== must start with a backslash \$1

-------------------- EXAMPLES --------------------
touch sample_data.txt
qsubs -n gzip_file -s "gzip sample_data.txt"

touch sample1_data.txt
touch sample2_data.txt
echo sample1 > sample_names
echo sample2 >> sample_names
qsubs -n zip_comand -a sample_names -s "zip SAMPLE_data.zip SAMPLE_data.txt"

echo "zip SAMPLE_data.zip SAMPLE_data.txt" > sample_script
qsubs -n zip_script -a sample_names -s sample_script -d
------------------------------  QSUB SUBMITTER HELP ---------------------------LLM'
	exit 2
}

#---------- Set Arguments
PARSED_ARGUMENTS=$(getopt -a -n qsubs -o dha:c:n:q:r:s:u:w: --long debug,help,array:,cores:,name:,queue:,rscript:,script:,script_args:,umask:,walltime: -- "$@")

VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
	RED "---------- INVALID ARGUMENTS ----------"
	usage
fi

eval set -- "$PARSED_ARGUMENTS"
while :
do
  case "$1" in
    -d | --debug)      DEBUG=1         ; shift   ;;
    -h | --help)       usage           ; shift   ;;
    -a | --array)      ARRAY="$2"      ; shift 2 ;;
    -c | --cores)      CORES="$2"      ; shift 2 ;;
    -n | --name)       NAME="$2"       ; shift 2 ;;
    -q | --queue)      QUEUE="$2"      ; shift 2 ;;
    -r | --rscript)    RSCRIPT="$2"    ; shift 2 ;;
    -s | --script)     SCRIPT="$2"     ; shift 2 ;;
    --script_args)     ARGS+=("$2")    ; shift 2 ;;
	-u | --umask)      UMASK="$2"      ; shift 2 ;;
    -w | --walltime)   WALLTIME="$2"   ; shift 2 ;;
    # -- means the end of the arguments; drop this, and break out of the while loop
    --) shift; break ;;
    # If invalid options were passed, then getopt should have reported an error,
    # which we checked as VALID_ARGUMENTS when getopt was called...
    *) RED "---------- UNEXPECTED ARGUMENTS == $1 ----------"
       usage ;;
  esac
done

#---------- Functions
SCRIPT_START () {
echo '#PBS -l nodes=1:ppn='${CORES}'
#PBS -l walltime='${WALLTIME}':00:00
#PBS -N '${NAME}'
#PBS -q '${QUEUE}'
#PBS -d .
#PBS -V
#PBS -W umask='${UMASK}
}

SCRIPT_START_ARRAY () {
echo '#PBS -t 1-'${SAMPLE_NUMBER}''
}

SCRIPT_INFO () {
echo '
#-------------------- PBS VARIABLES --------------------
#- #PBS -l nodes=1:ppn=1 == ppn=1 means using 1 core per job
#- #PBS -l mem=5gb == 5gb of ram per 1 core (if ppn=4 change mem=24gb)
#- #PBS -l waltime=24:00:00 == 24 hours max runtime
#- #PBS -q shortq == choose queue shortq < 72hrs, lowprio or longq > 72hrs (qstat -q)
#- #PBS -N Job_Name_Here == job name sepcific to your script
#- #PBS -t 1-20 == 20 samples and 20 jobs to submit
#- #PBS -j oe == job standard error and output files merged
#- #PBS -M First_Name.LastName@vai.org == vai email
#- #PBS -m abe == a = aborted email, b = start email, e = end email
#- #PBS -d . == stay at directory when moving to a node
#- #PBS -V == head node environment passed to job node environment
#- #PBS -W umask=0022 == group and others have read permissions

#-------------------- JOB INFO --------------------
echo -n "---------- START TIME == " ; date +"%Y_%m_%d %H:%M:%S"
echo "---------- USER == ${USER}"
echo "---------- HOSTNAME == ${HOSTNAME}"
echo "---------- PBS_JOBNAME == ${PBS_JOBNAME}"
echo "---------- PBS_JOBID == ${PBS_JOBID}"
echo "---------- PBS_NUM_PPN == ${PBS_NUM_PPN}"
echo "---------- PBS_O_QUEUE == ${PBS_O_QUEUE}"
echo "---------- PBS_O_WORKDIR == ${PBS_O_WORKDIR}"
echo "---------- PWD == ${PWD}"

#-------------------- QSUB COMMAND --------------------
echo "---------- QSUB COMMAND == qsub '${NAME}'.sh"'
}

SCRIPT_ARRAY () {
echo '
#-------------------- PBS ARRAY --------------------
echo "---------- PBS_ARRAYID == ${PBS_ARRAYID}"
PBS_ID=`head -n ${PBS_ARRAYID} '${ARRAY}' | tail -n1`
echo "---------- PBS_ID == ${PBS_ID}"'
}

SCRIPT_FILE () {
echo "
#-------------------- SCRIPT FILE --------------------
echo \"---------- SCRIPT FILE == ${SCRIPT}\"	
echo \"---------- SAMPLE SCRIPT == bash ${NAME}_\${PBS_ID}.sh\"
scp ${SCRIPT} ${NAME}_\${PBS_ID}.sh 
chmod +x ${NAME}_\${PBS_ID}.sh
sed -i 's/SAMPLE/'\${PBS_ID}'/g' ${NAME}_\${PBS_ID}.sh
bash ${NAME}_\${PBS_ID}.sh $(echo \"${ARGS[@]}\" | sed 's/ /\" \"/')"
# bash ${NAME}_\${PBS_ID}.sh ${'${ARGS[@]}'// /\" \"}"
# bash ${NAME}_\${PBS_ID}.sh \"${ARGS[@]@Q}\""
# bash ${NAME}_\${PBS_ID}.sh $(printf \"\'%s\' \" \"${ARGS[@]}\")"
# bash ${NAME}_\${PBS_ID}.sh \"${ARGS[@]}\""
# echo $(printf \" '%s' \" \"${ARGS[@]}\")
}

SCRIPT_COMMAND () {
echo '
#-------------------- SCRIPT COMMAND --------------------
echo "---------- SCRIPT COMMAND == '${SCRIPT}'"
'${SCRIPT}''
}

RSCRIPT_FILE () {
echo "
#-------------------- R SCRIPT FILE --------------------
echo \"---------- R SCRIPT FILE == ${RSCRIPT}\"	
echo \"---------- R SAMPLE SCRIPT == R --vanilla < ${NAME}_\${PBS_ID}.R\"
scp ${RSCRIPT} ${NAME}_\${PBS_ID}.R 
chmod +x ${NAME}_\${PBS_ID}.R
sed -i 's/SAMPLE/'\${PBS_ID}'/g' ${NAME}_\${PBS_ID}.R
R --vanilla < ${NAME}_\${PBS_ID}.R"
}

RSCRIPT_COMMAND () {
echo "
#-------------------- R SCRIPT COMMAND --------------------
echo \"---------- R SCRIPT COMMAND == R --vanilla < ${NAME}.R < ${RSCRIPT}\"
R --vanilla < ${NAME}.R"
}

SCRIPT_END () {
echo '
#-------------------- JOB INFO --------------------
echo -n "---------- QSTAT == " ; qstat -f ${PBS_JOBID}
echo "---------- PATH == ${PATH}"
echo -n "---------- END TIME == " ; date +"%Y_%m_%d %H:%M:%S"
'
}

#---------- Check Arguments
CYAN "------------------------------ QSUB SUBMITTER ------------------------------
---------- QSUBS ARGUMENTS == $PARSED_ARGUMENTS"

#---------- NAME
if [ ${NAME} ]
	then
	CYAN "---------- JOBNAME == ${NAME} ----------"
else
	NAME=`echo -n "${USER}" ; date +"_%Y_%m_%d_%H_%M_%S"`
	CYAN "---------- DEFAULT JOBNAME == ${NAME} ----------"
fi

#---------- QUEUE 
if [ ${QUEUE} = shortq ]
	then
	CYAN "---------- DEFAULT QUEUE == ${QUEUE} ----------"
else
	CYAN "---------- QUEUE == ${QUEUE} ----------"
fi

#---------- UMASK
if [ ${UMASK} == "0022" ]
	then
	CYAN "---------- DEFAULT UMASK == ${UMASK} ----------"
else
	if [ ${UMASK} == "0002" ]
	then
		CYAN "---------- UMASK == ${UMASK} ----------"
	else
		RED "---------- UMASK == ${UMASK} ----------"
		RED "---------- [[ERROR]] UMASK MUST BE 0022 or 0002 ----------"
		exit 0
	fi
fi

#---------- CORES
if [ ${CORES} == 1 ]
	then	
	CYAN "---------- DEFAULT CORES == ${CORES} ----------"
else
	if [ ${CORES} -gt 0 -a ${CORES} -le 80 ]
		then
		CYAN "---------- CORES == ${CORES} ----------"
	else
		RED "---------- CORES == ${CORES} ----------"
		RED "---------- [[ERROR]] CORES NOT GIVEN BETWEEN 1-80 ----------"
		exit 0
	fi
fi	

#---------- WALLTIME 
if [ ${WALLTIME} == 24 ]
	then
	CYAN "---------- DEFAULT WALLTIME == ${WALLTIME} ----------"
else
	if [ ${WALLTIME} -gt 0 -a ${WALLTIME} -le 744 ]
		then
		CYAN "---------- WALLTIME == ${WALLTIME} ----------"
	else
		RED "---------- WALLTIME == ${WALLTIME} ----------"
		RED "----------[[ERROR]] WALLTIME HOURS NOT BETWEEN 1-744 ----------"
		exit 0
	fi
fi

#---------- SCRIPT_ARGS 
if [ ${ARGS} ]
	then
	CYAN "---------- SCRIPT_ARGS == ${ARGS[@]} ----------"
fi

#---------- ARRAY
if [[ ( -f "${ARRAY}" && -s "${ARRAY}" ) ]]
	then
	CYAN "---------- ARRAY FILE == ${ARRAY} ----------"
	CYAN "---------- SAMPLE == used as variable for sample name ----------"
	SAMPLE_NUMBER=`cat ${ARRAY} | wc -l`
	CYAN "---------- SAMPLE_NUMBER == ${SAMPLE_NUMBER} ----------"
	#---------- Build JOB
	SCRIPT_START > ${NAME}.sh
	SCRIPT_START_ARRAY >> ${NAME}.sh
	SCRIPT_INFO >> ${NAME}.sh
	SCRIPT_ARRAY >> ${NAME}.sh
	#---------- SCRIPT + RSCRIPT
	if [ -n "${SCRIPT}" ] 
		then
		if [[ ( -f "${SCRIPT}" && -s "${SCRIPT}" ) ]]
			then 
			CYAN "---------- SCRIPT FILE == ${SCRIPT} ----------"
			SCRIPT_FILE >> ${NAME}.sh
		else
			SCRIPT=$(echo $SCRIPT | sed 's/SAMPLE/\${PBS_ID}/g')
			CYAN "---------- SCRIPT COMMAND == ${SCRIPT} ----------"
			SCRIPT_COMMAND >> ${NAME}.sh
		fi
	elif [ -n "${RSCRIPT}" ]
		then
		if [[ ( -f "${RSCRIPT}" && -s "${RSCRIPT}" ) ]]
			then 
			CYAN "---------- R SCRIPT FILE == R --vanilla < ${RSCRIPT} ----------"
			RSCRIPT_FILE >> ${NAME}.sh
		else
			echo ${RSCRIPT} | sed 's/SAMPLE/\${PBS_ID}/g' > ${NAME}.R 
			CYAN "---------- R SCRIPT COMMAND == R --vanilla < ${NAME}.R < ${RSCRIPT} ----------"
			RSCRIPT_COMMAND >> ${NAME}.sh
		fi
	else
		RED "---------- [[ERROR]] NO SHELL SCRIPT OR R SCRIPT ----------"
		exit 0
	fi
	#---------- Build JOB
	SCRIPT_END >> ${NAME}.sh
	chmod u+x ${NAME}.sh	
else
	CYAN "---------- DEFAULT ARRAY == NO ARRAY ----------"
	#---------- Build JOB
	SCRIPT_START > ${NAME}.sh
	SCRIPT_INFO >> ${NAME}.sh
	#---------- SCRIPT + RSCRIPT
	if [ -n "${SCRIPT}" ] 
		then
		if [[ ( -f "${SCRIPT}" && -s "${SCRIPT}" ) ]]
			then 
			CYAN "---------- SCRIPT FILE == bash ${SCRIPT} ----------"
			SCRIPT_FILE >> ${NAME}.sh
		else
			CYAN "---------- SCRIPT COMMAND == ${SCRIPT} ----------"
			SCRIPT_COMMAND >> ${NAME}.sh
		fi
	elif [ -n "${RSCRIPT}" ]
		then
		if [[ ( -f "${RSCRIPT}" && -s "${RSCRIPT}" ) ]]
			then 
			CYAN "---------- R SCRIPT FILE == R --vanilla < ${RSCRIPT} ----------"
			RSCRIPT_FILE >> ${NAME}.sh
		else
			CYAN "---------- R SCRIPT COMMAND == R --vanilla < ${NAME}.R < ${RSCRIPT} ----------"
			echo ${RSCRIPT} > ${NAME}.R 
			RSCRIPT_COMMAND >> ${NAME}.sh
		fi
	else
		RED "---------- [[ERROR]] NO SHELL SCRIPT OR R SCRIPT ----------"
		exit 0
	fi
	#---------- Build JOB
	SCRIPT_END >> ${NAME}.sh
	chmod u+x ${NAME}.sh
fi

#---------- QSUB
if [[ ( -f "${NAME}.sh" && -x "${NAME}.sh" && -s "${NAME}.sh" ) ]]
then
	CYAN "---------- QSUB == qsub ${NAME}.sh ----------"
	if [ ${DEBUG} == 1 ]
		then 
		MAGENTA "---------- DEBUG == file created, not submitted ----------"
	else
		GREEN "---------- Job ID == " ; qsub ${NAME}.sh
	fi
else
	RED "---------- [[ERROR]] SHELL FILE NOT CREATED, EMPTY OR EXECUTABLE ----------"
	exit 0
fi
CYAN "------------------------------ QSUB SUBMITTER ---------------------------LLM"

