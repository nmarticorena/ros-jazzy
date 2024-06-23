#!/bin/bash

set -x
set -e

export FEEDSTOCK_ROOT=`pwd`
export "CONDA_BLD_PATH=$HOME/conda-bld/"

curl -fsSL https://pixi.sh/install.sh | bash
export PATH="$HOME/.pixi/bin:$PATH"

for recipe in ${CURRENT_RECIPES[@]}; do
	pixi run rattler-build build \
		--recipe ${FEEDSTOCK_ROOT}/recipes/${recipe} \
		-m ${FEEDSTOCK_ROOT}/conda_build_config.yaml \
		-c robostack-jazzy -c conda-forge \
		--output-dir $CONDA_BLD_PATH \
		--target-platform=osx-arm64

	# -m ${FEEDSTOCK_ROOT}/.ci_support/conda_forge_pinnings.yaml \
done

pixi run upload ${CONDA_BLD_PATH}/osx-*/*.conda --force