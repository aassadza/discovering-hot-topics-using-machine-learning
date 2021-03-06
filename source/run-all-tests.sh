#!/bin/bash
#
# This script runs all tests for the root CDK project, as well as any microservices, Lambda functions, or dependency
# source code packages. These include unit tests, integration tests, and snapshot tests.
#
# This script is called by the ../initialize-repo.sh file and the buildspec.yml file. It is important that this script
# be tested and validated to ensure that all available test fixtures are run.
#
# The if/then blocks are for error handling. They will cause the script to stop executing if an error is thrown from the
# node process running the test case(s). Removing them or not using them for additional calls with result in the
# script continuing to execute despite an error being thrown.

[ "$DEBUG" == 'true' ] && set -x
set -e

setup_python_env() {
	if [ -d "./.venv-test" ]; then
		echo "Reusing already setup python venv in ./.venv-test. Delete ./.venv-test if you want a fresh one created."
		return
	fi
	echo "Setting up python venv"
	python3 -m venv .venv-test
	echo "Initiating virtual environment"
	source .venv-test/bin/activate
	echo "Installing python packages"
	pip3 install -r requirements.txt --target .
	pip3 install -r requirements-dev.txt
	echo "deactivate virtual environment"
	deactivate
}

run_python_lambda_test() {
	lambda_name=$1
	lambda_description=$2
	echo "------------------------------------------------------------------------------"
	echo "[Test] Python Lambda: $lambda_name, $lambda_description"
	echo "------------------------------------------------------------------------------"
	cd $source_dir/lambda/$lambda_name

	rm -fr .venv-test

	setup_python_env

	echo "Initiating virtual environment"
	source .venv-test/bin/activate

	# setup coverage report path
	mkdir -p $source_dir/test/coverage-reports
	coverage_report_path=$source_dir/test/coverage-reports/$lambda_name.coverage.xml
	echo "coverage report path set to $coverage_report_path"

	# Use -vv for debugging
	python3 -m pytest --cov --cov-report=term-missing --cov-report "xml:$coverage_report_path"
	if [ "$?" = "1" ]; then
		echo "(source/run-all-tests.sh) ERROR: there is likely output above." 1>&2
		exit 1
	fi
	echo "deactivate virtual environment"
	deactivate
	rm -fr .venv-test
	# Note: leaving $source_dir/test/coverage-reports to allow further processing of coverage reports
	rm -fr coverage
	rm .coverage
}

run_javascript_lambda_test() {
	lambda_name=$1
	lambda_description=$2
	echo "------------------------------------------------------------------------------"
	echo "[Test] Javascript Lambda: $lambda_name, $lambda_description"
	echo "------------------------------------------------------------------------------"
	cd $source_dir/lambda/$lambda_name
	npm run clean
	npm ci
	npm test
	if [ "$?" = "1" ]; then
		echo "(source/run-all-tests.sh) ERROR: there is likely output above." 1>&2
		exit 1
	fi
	rm -fr coverage
}

run_cdk_project_test() {
	component_description=$1
	echo "------------------------------------------------------------------------------"
	echo "[Test] $component_description"
	echo "------------------------------------------------------------------------------"
	npm run clean
	npm ci
	npm run build
	npm run test -- -u
	if [ "$?" = "1" ]; then
		echo "(source/run-all-tests.sh) ERROR: there is likely output above." 1>&2
		exit 1
	fi
	rm -fr coverage
}


# Save the current working directory and set source directory
source_dir=$PWD
cd $source_dir

#
# Test the CDK project
#
run_cdk_project_test "CDK - Discovering Hot Topics using Machine Learning App"

#
# Test the attached Lambda functions
#
run_python_lambda_test firehose_topic_proxy "EventBridge - Firehose Topic Proxy"

run_javascript_lambda_test firehose-text-proxy "Storage - Firehose Text Proxy"

run_javascript_lambda_test ingestion-consumer "Ingestion - Consumer"

run_javascript_lambda_test ingestion-producer "Ingestion - Producer"

run_javascript_lambda_test integration "Storage - App Integragation Lambda"

run_python_lambda_test solution_helper "Solution Helper"

run_javascript_lambda_test storage-firehose-processor "Storage - Storage Firehose Processor"

run_python_lambda_test wf_publish_topic_model "Workflow - Publish Topic Model"

run_javascript_lambda_test wf-analyze-text "Workflow - Analyze Text"

run_javascript_lambda_test wf-check-topic-model "Workflow - Check Topic Model Job Status"

run_javascript_lambda_test wf-detect-moderation-labels "Workflow - Detect Moderation labels"

run_javascript_lambda_test wf-extract-text-in-image "Workflow - Analyze Text in Images"

run_javascript_lambda_test wf-publish-text-inference "Workflow - Publish Text Inference"

run_javascript_lambda_test wf-submit-topic-model "Storage - Submit Topic Model Job"

run_javascript_lambda_test wf-translate-text "Workflow - Transate Text"

run_python_lambda_test quicksight-custom-resources "Quicksight - Custom Resources"


# Return to the source/ level where we started
cd $source_dir