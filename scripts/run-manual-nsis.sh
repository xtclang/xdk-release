export REPO_ROOT=$HOME/src/xtc/xvm-plugin-final
echo "Repo root: $REPO_ROOT"
export NSIS_SRC=$REPO_ROOT/xdk/build/install/xdk
export NSIS_ICO=$REPO_ROOT/javatools_launcher/src/main/c/x.ico
export NSIS_OUT=$REPO_ROOT/xdk/build/distributions/xdk-0.4.42.exe
export NSIS_VER=0.4.42
makensis $REPO_ROOT/xdk/src/main/nsi/xdkinstall.nsi -NOCD
