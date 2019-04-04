#!/bin/bash

# Filename: sca_env.bash
# Purpose:  Set environment variables to be used by the "Machine Learning and
#             Artificial Intelligence Assistant” (MAI Assistant) application
#             during deployment and at production runtime.
#           The prefix "SCA" refers to Security Controls Assessors who are the
#             initial target user of this application.
# Created:  March 2019

###############################################################################

# Steps:
# 1. Create database.
# - Record the hostname in SCA_PGHOST below.
# - Record the port in SCA_PGPORT.
# - Record the database name in SCA_PGDATABASE.
# 2. Create the schema owner.
# - Record the username in SCA_PGSCHEMA_OWNER.
# - Record the password in SCA_PGSCHEMA_OWNER_PASSWORD.
# 3. Create the application database user.
# - Record the username in SCA_PGREADER.
# - Record the password in SCA_PGREADER_PASSWORD.
# 4. Determine the port that Angular will run on.
# - Record the port in SCA_ANGULAR_PORT.
# 5. Determine the port that Express REST will run on.
# - Record the port in SCA_EXPRESS_PORT.
# 6. Determine the Gitlab credentials and repo
# - Record the username in SCA_GITLAB_USER.
# - Record the password in SCA_GITLAB_PASSWORD.
# - Record the repo name in SCA_GITLAB_REPO.

###############################################################################

# Postgres database connection variables.
# These are common values used to connect to the PG database.
export SCA_PGHOST="a4devmvp2.cfaumaizfanj.us-east-1.rds.amazonaws.com"
export SCA_PGPORT="5432"
export SCA_PGDATABASE="a4devmvp2"

# Postgres database schema owner.
# This is the PG user account that owns the SCA schema objects.
export SCA_PGSCHEMA_OWNER="a4devmvp2"
export SCA_PGSCHEMA_OWNER_PASSWORD="codeisfun"

# Postgres database application user.
# This is the PG user account that the SCA application
#   uses to log into the database. This user must be granted
#   privileges to select from the tables owned by the
#   schema owner.
export SCA_PGREADER="a4devmvp2"
export SCA_PGREADER_PASSWORD="codeisfun"

# Port on which the Angular and Express apps are running
export SCA_ANGULAR_HOST="ec2-54-211-243-221.compute-1.amazonaws.com"
export SCA_ANGULAR_PORT="4200"
export SCA_EXPRESS_HOST="ec2-54-211-243-221.compute-1.amazonaws.com"
export SCA_EXPRESS_PORT="3000"

# Gitlab repo that contains the application source code
export SCA_GITLAB_USER="bruce.h.goldfeder"
export SCA_GITLAB_PASSWORD=""
export SCA_GITLAB_REPO="gitlab.code.dicelab.net/DEEA-A4/A4/MVP2.git"
export SCA_GITLAB_REPO_NAME="MVP2"

# AWS Key location
export AWS_KEY_LOC="$HOME/Downloads/DEEA-CIO-GoldfederB.pem"
export EC2_USER="maintuser"
export EC2_URL="ec2-54-211-243-221.compute-1.amazonaws.com"
