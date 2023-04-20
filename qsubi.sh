#!/bin/bash

#---------- Set Default Values
DEBUG=0
CORES=1
NODE=1
NAME=bash
PARTITION=short
WALLTIME=24

#---------- Colors
RED() { echo "$(tput setaf 1)$*$(tput sgr0)"; }
GREEN() { echo "$(tput setaf 2)$*$(tput sgr0)"; }
MAGENTA() { echo "$(tput setaf 5)$*$(tput sgr0)"; }
CYAN() { echo "$(tput setaf 6)$*$(tput sgr0)"; }

#---------- Usage
usage()
{
	CYAN '------------------------------  SRUN INTERACTIVE HELP ------------------------------ 
---------- PROGRAM		== sruni (srun interactive)
---------- VERSION		== 1.0.0
---------- DATE			== 2023_04_20
---------- CONTACT		== kew24 (template from lee.marshall@vai.org -- big thank you!)
---------- DISCRIPTION		== automates creation of slurm interactive job
---------- PATH			== export PATH=\$PATH:/path/to/sruni/directory

-------------------- COMMANDS --------------------
---------- USAGE		== sruni [options]*
---------- FLAGS
	[ -d | --debug ]		== creates job script but does not execute
	[ -h | --help ]			== help function
---------- OPTIONS
	[ -c | --cores <int> ]		== number of cores per job 1 to 80, default 1 core
	[ -n | --node <node> ]		== name of specific node, default any node
	[ -N | --name <name> ]		== name specific to job, default STDIN
	[ -p | --partition <name> ]	== specify partition name, default any partition
	[ -w | --walltime <int> ]	== number of hours per job 1 to 336, default 24 hours

-------------------- EXAMPLES --------------------
sruni -c 4 -p short
------------------------------  SRUN INTERACTIVE HELP ---------------------------KEW24'
	exit 2
}

#---------- Set Arguments
PARSED_ARGUMENTS=$(getopt -a -n sruni -o dhc:n:N:p:w: --long debug,help,cores:,node:,name:,partition:,walltime: -- "$@")

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
    -p | --partition)  PARTITION="$2"  ; shift 2 ;;
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
CYAN "------------------------------ SRUN INTERACTIVE ------------------------------
---------- SRUNI ARGUMENTS == $PARSED_ARGUMENTS"

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
	if [ ${WALLTIME} -gt 0 -a ${WALLTIME} -le 336 ]
		then
		CYAN "---------- WALLTIME == ${WALLTIME} ----------"
	else
		RED "---------- WALLTIME == ${WALLTIME} ----------"
		RED "----------[[ERROR]] WALLTIME HOURS NOT BETWEEN 1-336 ----------"
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

#---------- PARTITION 
if [ ${PARTITION} = short ]
	then
	CYAN "---------- DEFAULT PARTITION == ${PARTITION} ----------"
	CYAN "---------- PARTITION can be quick,short,long,big,bigmem,gpu"
else
	CYAN "---------- PARTITION == ${PARTITION} ----------"
	CYAN "---------- PARTITION can be quick,short,long,big,bigmem,gpu"
fi

#---------- SRUN
if [ ${DEBUG} == 1 ]
	then 
	MAGENTA "---------- DEBUG == srun -w ${NODE} --ntasks-per-node=1 --cpus-per-task=${CORES} --time=${WALLTIME}:00:00 -J ${NAME} -p ${PARTITION} --pty bash -i"
	CYAN "------------------------------ SRUN INTERACTIVE ---------------------------KEW24"
else
	GREEN "---------- JOB == submitted ----------" 
	srun -w ${NODE} --ntasks-per-node=1 --cpus-per-task=${CORES} --time=${WALLTIME}:00:00 -J ${NAME} -p ${PARTITION} --pty bash -i 
fi
