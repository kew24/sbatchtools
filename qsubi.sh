#!/bin/bash

#---------- Set Default Values
DEBUG=0
CORES=1
NODE=1
NAME=STDIN
QUEUE=shortq
WALLTIME=24

#---------- Colors
RED() { echo "$(tput setaf 1)$*$(tput sgr0)"; }
GREEN() { echo -n "$(tput setaf 2)$*$(tput sgr0)"; }
MAGENTA() { echo "$(tput setaf 5)$*$(tput sgr0)"; }
CYAN() { echo "$(tput setaf 6)$*$(tput sgr0)"; }

#---------- Usage
usage()
{
	CYAN '------------------------------  QSUB INTERACTIVE HELP ------------------------------ 
---------- PROGRAM		== qsubi (qsub interactive)
---------- VERSION		== 2.0.1
---------- DATE			== 2021_10_18
---------- CONTACT		== lee.marshall@vai.org
---------- DISCRIPTION		== automates creation of PBS interactive job
---------- PATH			== export PATH=\$PATH:/path/to/qsubi/directory

-------------------- COMMANDS --------------------
---------- USAGE		== qsubs [options]* -s "command"
---------- FLAGS
	[ -d | --debug ]		== creates job script but does not execute
	[ -h | --help ]			== help function
---------- OPTIONS
	[ -c | --cores <int> ]		== number of cores per job 1 to 80, default 1 core
	[ -n | --node <node> ]		== name of specific node, default any node
	[ -N | --name <name> ]		== name specific to job, default STDIN
	[ -q | --queue <name> ]		== specify queue name, default any queue
	[ -w | --walltime <int> ]	== number of hours per job 1 to 744, default 24 hours

-------------------- EXAMPLES --------------------
qsubi -c 4 -q shortq
------------------------------  QSUB INTERACTIVE HELP ---------------------------LLM'
	exit 2
}

#---------- Set Arguments
PARSED_ARGUMENTS=$(getopt -a -n qsubi -o dhc:n:N:q:w: --long debug,help,cores:,node:,name:,queue:,walltime: -- "$@")

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
    -c | --cores)      CORES="$2"      ; shift 2 ;;
    -n | --node)       NODE="$2"       ; shift 2 ;;
    -N | --name)       NAME="$2"       ; shift 2 ;;
    -q | --queue)      QUEUE="$2"      ; shift 2 ;;
    -w | --walltime)   WALLTIME="$2"   ; shift 2 ;;
    # -- means the end of the arguments; drop this, and break out of the while loop
    --) shift; break ;;
    # If invalid options were passed, then getopt should have reported an error,
    # which we checked as VALID_ARGUMENTS when getopt was called...
    *) RED "---------- UNEXPECTED ARGUMENTS == $1 ----------"
       usage ;;
  esac
done

#---------- Check Arguments
CYAN "------------------------------ QSUB INTERACTIVE ------------------------------
---------- QSUBI ARGUMENTS == $PARSED_ARGUMENTS"

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

#---------- NODE
if [ ${NODE} == 1 ]
	then
	CYAN "---------- DEFAULT NODE == ${NODE} ----------"
else
	CYAN "---------- NODE == ${NODE} ----------"
fi

#---------- NAME
if [ ${NAME} ]
	then
	CYAN "---------- JOBNAME == ${NAME} ----------"
else
	CYAN "---------- DEFAULT JOBNAME == ${NAME} ----------"
fi

#---------- QUEUE 
if [ ${QUEUE} = shortq ]
	then
	CYAN "---------- DEFAULT QUEUE == ${QUEUE} ----------"
	CYAN "---------- QUEUE can be shortq,longq,lowprio,gpu,bbc,labrie"
else
	CYAN "---------- QUEUE == ${QUEUE} ----------"
	CYAN "---------- QUEUE can be shortq,longq,lowprio,gpu,bbc,labrie"
fi

#---------- QSUB
if [ ${DEBUG} == 1 ]
	then 
	MAGENTA "---------- DEBUG == qsub -I -l nodes=${NODE}:ppn=${CORES} -l walltime=${WALLTIME}:00:00 -N ${NAME} -q ${QUEUE} -d . -V"
	CYAN "------------------------------ QSUB INTERACTIVE ---------------------------LLM"
else
	GREEN "---------- JOB == " ; qsub -I -l nodes=${NODE}:ppn=${CORES} -l walltime=${WALLTIME}:00:00 -N ${NAME} -q ${QUEUE} -d . -V
fi
