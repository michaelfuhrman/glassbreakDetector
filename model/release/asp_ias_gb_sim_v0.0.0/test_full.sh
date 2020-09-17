#!/bin/bash

./rampsim_ias_loop.sh settings/gb_files_clean.csv FULL
./rampsim_ias_loop.sh settings/gb_files_mixed.csv FULL
./rampsim_ias_loop.sh settings/gb_files_clean.csv IAS
./rampsim_ias_loop.sh settings/gb_files_mixed.csv IAS
