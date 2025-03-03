# Generated by vinca http://github.com/RoboStack/vinca.
# DO NOT EDIT!

set -eo pipefail

rm -rf build
mkdir build
cd build

# necessary for correctly linking SIP files (from python_qt_bindings)
export LINK=$CXX

if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" ]]; then
  PYTHON_EXECUTABLE=$PREFIX/bin/python
  PKG_CONFIG_EXECUTABLE=$PREFIX/bin/pkg-config
  OSX_DEPLOYMENT_TARGET="10.15"
else
  PYTHON_EXECUTABLE=$BUILD_PREFIX/bin/python
  PKG_CONFIG_EXECUTABLE=$BUILD_PREFIX/bin/pkg-config
  OSX_DEPLOYMENT_TARGET="11.0"
fi

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" == "1" ]]; then
  export QT_HOST_PATH="$BUILD_PREFIX"
else
  export QT_HOST_PATH="$PREFIX"
fi

echo "USING PYTHON_EXECUTABLE=${PYTHON_EXECUTABLE}"
echo "USING PKG_CONFIG_EXECUTABLE=${PKG_CONFIG_EXECUTABLE}"

export ROS_PYTHON_VERSION=`$PYTHON_EXECUTABLE -c "import sys; print('%i.%i' % (sys.version_info[0:2]))"`
echo "Using Python ${ROS_PYTHON_VERSION}"

# see https://github.com/conda-forge/cross-python-feedstock/issues/24
if [[ "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]]; then
  find $PREFIX/lib/cmake -type f -exec sed -i "s~\${_IMPORT_PREFIX}/lib/python${ROS_PYTHON_VERSION}/site-packages~${BUILD_PREFIX}/lib/python${ROS_PYTHON_VERSION}/site-packages~g" {} + || true
  find $PREFIX/share/rosidl* -type f -exec sed -i "s~$PREFIX/lib/python${ROS_PYTHON_VERSION}/site-packages~${BUILD_PREFIX}/lib/python${ROS_PYTHON_VERSION}/site-packages~g" {} + || true
  find $PREFIX/share/rosidl* -type f -exec sed -i "s~\${_IMPORT_PREFIX}/lib/python${ROS_PYTHON_VERSION}/site-packages~${BUILD_PREFIX}/lib/python${ROS_PYTHON_VERSION}/site-packages~g" {} + || true
  find $PREFIX/lib/cmake -type f -exec sed -i "s~message(FATAL_ERROR \"The imported target~message(WARNING \"The imported target~g" {} + || true
fi

if [[ $target_platform =~ linux.* ]]; then
    export CFLAGS="${CFLAGS} -D__STDC_FORMAT_MACROS=1"
    export CXXFLAGS="${CXXFLAGS} -D__STDC_FORMAT_MACROS=1"
fi;

# Needed for qt-gui-cpp ..
if [[ $target_platform =~ linux.* ]]; then
  ln -s $GCC ${BUILD_PREFIX}/bin/gcc
  ln -s $GXX ${BUILD_PREFIX}/bin/g++
fi;

# PYTHON_INSTALL_DIR should be a relative path, see
# https://github.com/ament/ament_cmake/blob/2.3.2/ament_cmake_python/README.md
# So we compute the relative path of $SP_DIR w.r.t. to $PREFIX,
# but it is not trivial to do this in bash scripting, so let's do it via python
export PYTHON_INSTALL_DIR=`python -c "import os;print(os.path.relpath(os.environ['SP_DIR'],os.environ['PREFIX']))"`
echo "Using site_packages: $PYTHON_INSTALL_DIR"

cmake \
    -G "Ninja" \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DAMENT_PREFIX_PATH=$PREFIX \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DPYTHON_EXECUTABLE=$PYTHON_EXECUTABLE \
    -DPython_EXECUTABLE=$PYTHON_EXECUTABLE \
    -DPython3_EXECUTABLE=$PYTHON_EXECUTABLE \
    -DPython3_FIND_STRATEGY=LOCATION \
    -DPKG_CONFIG_EXECUTABLE=$PKG_CONFIG_EXECUTABLE \
    -DPYTHON_INSTALL_DIR=$PYTHON_INSTALL_DIR \
    -DSETUPTOOLS_DEB_LAYOUT=OFF \
    -DCATKIN_SKIP_TESTING=$SKIP_TESTING \
    -DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP=True \
    -DBUILD_SHARED_LIBS=ON  \
    -DBUILD_TESTING=OFF \
    -DCMAKE_IGNORE_PREFIX_PATH="/opt/homebrew;/usr/local/homebrew" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=$OSX_DEPLOYMENT_TARGET \
    --compile-no-warning-as-error \
    $SRC_DIR/$PKG_NAME/src/work

cmake --build . --config Release --target install
