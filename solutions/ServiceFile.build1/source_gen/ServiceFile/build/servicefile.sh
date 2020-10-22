#!/bin/sh

# ---------------------------------------------------------------------
# ServiceFile startup script
# ---------------------------------------------------------------------
# Generated by MPS

message()
{
  TITLE="Cannot start ServiceFile"
  if [ -n `which zenity` ]; then
    zenity --error --title="$TITLE" --text="$1"
  elif [ -n `which kdialog` ]; then
    kdialog --error --title "$TITLE" "$1"
  elif [ -n `which xmessage` ]; then
    xmessage -center "ERROR: $TITLE: $1"
  elif [ -n `which notify-send` ]; then
    notify-send "ERROR: $TITLE: $1"
  else
    echo "ERROR: $TITLE\n$1"
  fi
}

UNAME=`which uname`
GREP=`which egrep`
GREP_OPTIONS=""
CUT=`which cut`
READLINK=`which readlink`
XARGS=`which xargs`
DIRNAME=`which dirname`
MKTEMP=`which mktemp`
RM=`which rm`
CAT=`which cat`
TR=`which tr`

if [ -z "$UNAME" -o -z "$GREP" -o -z "$CUT" -o -z "$MKTEMP" -o -z "$RM" -o -z "$CAT" -o -z "$TR" ]; then
  message "Required tools are missing - check beginning of \"$0\" file for details."
  exit 1
fi

OS_TYPE=`"$UNAME" -s`

# ---------------------------------------------------------------------
# Ensure IDE_HOME points to the directory where the IDE is installed.
# ---------------------------------------------------------------------
SCRIPT_LOCATION="$0"
if [ -x "$READLINK" ]; then
  while [ -L "$SCRIPT_LOCATION" ]; do
    SCRIPT_LOCATION=`"$READLINK" -e "$SCRIPT_LOCATION"`
  done
fi

cd "`dirname "$SCRIPT_LOCATION"`"
IDE_BIN_HOME=`pwd`
IDE_HOME=`dirname "$IDE_BIN_HOME"`
cd "$OLDPWD"

# ---------------------------------------------------------------------
# Locate a JDK installation directory which will be used to run the IDE.
# Try (in order): ServiceFile_JDK, servicefile.jdk, ../jre, JDK_HOME, JAVA_HOME, "java" in PATH.
# ---------------------------------------------------------------------
if [ -n "$ServiceFile_JDK" -a -x "$ServiceFile_JDK/bin/java" ]; then
  JDK="$ServiceFile_JDK"
elif [ -s "$HOME/.ServiceFile1.0/config/servicefile.jdk" ]; then
  JDK=`"$CAT" $HOME/.ServiceFile1.0/config/servicefile.jdk`
  if [ ! -d "$JDK" ]; then
    JDK="$IDE_HOME/$JDK"
  fi
elif [ -x "$IDE_HOME/jbr/bin/java" ] && "$IDE_HOME/jbr/bin/java" -version > /dev/null 2>&1 ; then
  JDK="$IDE_HOME/jbr"
elif [ -x "$IDE_HOME/jre/jre/bin/java" ] && "$IDE_HOME/jre/jre/bin/java" -version > /dev/null 2>&1 ; then
  JDK="$IDE_HOME/jre"
elif [ -n "$JDK_HOME" -a -x "$JDK_HOME/bin/java" ]; then
  JDK="$JDK_HOME"
elif [ -n "$JAVA_HOME" -a -x "$JAVA_HOME/bin/java" ]; then
  JDK="$JAVA_HOME"
else
  JAVA_BIN_PATH=`which java`
  if [ -n "$JAVA_BIN_PATH" ]; then
    if [ "$OS_TYPE" = "FreeBSD" -o "$OS_TYPE" = "MidnightBSD" ]; then
      JAVA_LOCATION=`JAVAVM_DRYRUN=yes java | "$GREP" '^JAVA_HOME' | "$CUT" -c11-`
      if [ -x "$JAVA_LOCATION/bin/java" ]; then
        JDK="$JAVA_LOCATION"
      fi
    elif [ "$OS_TYPE" = "SunOS" ]; then
      JAVA_LOCATION="/usr/jdk/latest"
      if [ -x "$JAVA_LOCATION/bin/java" ]; then
        JDK="$JAVA_LOCATION"
      fi
    elif [ "$OS_TYPE" = "Darwin" ]; then
      JAVA_LOCATION=`/usr/libexec/java_home`
      if [ -x "$JAVA_LOCATION/bin/java" ]; then
        JDK="$JAVA_LOCATION"
      fi
    fi

    if [ -z "$JDK" -a -x "$READLINK" -a -x "$XARGS" -a -x "$DIRNAME" ]; then
      JAVA_LOCATION=`"$READLINK" -f "$JAVA_BIN_PATH"`
      case "$JAVA_LOCATION" in
        */jre/bin/java)
          JAVA_LOCATION=`echo "$JAVA_LOCATION" | "$XARGS" "$DIRNAME" | "$XARGS" "$DIRNAME" | "$XARGS" "$DIRNAME"`
          if [ ! -d "$JAVA_LOCATION/bin" ]; then
            JAVA_LOCATION="$JAVA_LOCATION/jre"
          fi
          ;;
        *)
          JAVA_LOCATION=`echo "$JAVA_LOCATION" | "$XARGS" "$DIRNAME" | "$XARGS" "$DIRNAME"`
          ;;
      esac
      if [ -x "$JAVA_LOCATION/bin/java" ]; then
        JDK="$JAVA_LOCATION"
      fi
    fi
  fi
fi

JAVA_BIN="$JDK/bin/java"
if [ ! -x "$JAVA_BIN" ]; then
  JAVA_BIN="$JDK/jre/bin/java"
fi

if [ -z "$JDK" ] || [ ! -x "$JAVA_BIN" ]; then
  message "No JDK found. Please validate either ServiceFile_JDK, JDK_HOME or JAVA_HOME environment variable points to valid JDK installation."
  exit 1
fi

VERSION_LOG=`"$MKTEMP" -t java.version.log.XXXXXX`
JAVA_TOOL_OPTIONS= "$JAVA_BIN" -version 2> "$VERSION_LOG"
"$GREP" "64-Bit|x86_64" "$VERSION_LOG" > /dev/null
BITS=$?
"$RM" -f "$VERSION_LOG"
test ${BITS} -eq 0 && BITS="64" || BITS=""

# ---------------------------------------------------------------------
# Collect JVM options and properties.
# ---------------------------------------------------------------------
if [ -n "$ServiceFile_PROPERTIES" ]; then
  IDE_PROPERTIES_PROPERTY="-Didea.properties.file=$ServiceFile_PROPERTIES"
fi

VM_OPTIONS_FILE=""
if [ -n "$IDEA_VM_OPTIONS" -a -r "$IDEA_VM_OPTIONS" ]; then
  # explicit
  VM_OPTIONS_FILE="$IDEA_VM_OPTIONS"
elif [ -r "$IDE_HOME.vmoptions" ]; then
  # Toolbox
  VM_OPTIONS_FILE="$IDE_HOME.vmoptions"
elif [ -r "$HOME/.ServiceFile1.0/config/mps$BITS.vmoptions" ]; then
  # user-overridden
  VM_OPTIONS_FILE="$HOME/.ServiceFile1.0/config/mps$BITS.vmoptions"
elif [ -r "$IDE_BIN_HOME/servicefile$BITS.vmoptions" ]; then
  # default, standard installation
  VM_OPTIONS_FILE="$IDE_BIN_HOME/servicefile$BITS.vmoptions"
else
  # default, universal package
  test "$OS_TYPE" = "Darwin" && OS_SPECIFIC="mac" || OS_SPECIFIC="linux"
  VM_OPTIONS_FILE="$IDE_BIN_HOME/$OS_SPECIFIC/servicefile$BITS.vmoptions"
fi

VM_OPTIONS=""
if [ -r "$VM_OPTIONS_FILE" ]; then
  VM_OPTIONS=`"$CAT" "$VM_OPTIONS_FILE" | "$GREP" -v "^#.*"`
else
  message "Cannot find VM options file"
fi

IS_EAP="true"
if [ "$IS_EAP" = "true" ]; then
  OS_NAME=`echo "$OS_TYPE" | "$TR" '[:upper:]' '[:lower:]'`
  AGENT_LIB="yjpagent-$OS_NAME$BITS"
  if [ -r "$IDE_BIN_HOME/lib$AGENT_LIB.so" ]; then
    AGENT="-agentlib:$AGENT_LIB=disablealloc,delay=10000,sessionname=ServiceFile1.0"
  fi
fi

CLASSPATH="$IDE_HOME/lib/branding.jar"
CLASSPATH="$CLASSPATH:$IDE_HOME/lib/mps-boot.jar"
CLASSPATH="$CLASSPATH:$IDE_HOME/lib/mps-boot-util.jar"
CLASSPATH="$CLASSPATH:$IDE_HOME/lib/bootstrap.jar"
CLASSPATH="$CLASSPATH:$IDE_HOME/lib/extensions.jar"
CLASSPATH="$CLASSPATH:$IDE_HOME/lib/util.jar"
CLASSPATH="$CLASSPATH:$IDE_HOME/lib/jdom.jar"
CLASSPATH="$CLASSPATH:$IDE_HOME/lib/log4j.jar"
CLASSPATH="$CLASSPATH:$IDE_HOME/lib/trove4j.jar"
CLASSPATH="$CLASSPATH:$IDE_HOME/lib/jna.jar"
CLASSPATH="$CLASSPATH:$JDK/lib/tools.jar"
if [ -n "$ServiceFile_CLASSPATH" ]; then
  CLASSPATH="$CLASSPATH:$ServiceFile_CLASSPATH"
fi

# ---------------------------------------------------------------------
# Run the IDE.
# ---------------------------------------------------------------------
IFS="$(printf '\n\t')"
MAIN_CLASS=jetbrains.mps.Launcher
IDEA_PATHS_SELECTOR=ServiceFile1.0
LD_LIBRARY_PATH="$IDE_BIN_HOME:$LD_LIBRARY_PATH" "$JAVA_BIN" \
  ${AGENT} \
  -classpath "$CLASSPATH" \
  ${VM_OPTIONS} \
  "-XX:ErrorFile=$HOME/java_error_in_MPS_%p.log" \
  "-XX:HeapDumpPath=$HOME/java_error_in_IDEA.hprof" \
  -Didea.paths.selector=$IDEA_PATHS_SELECTOR \
  "-Djb.vmOptionsFile=$VM_OPTIONS_FILE" \
  ${IDE_PROPERTIES_PROPERTY} \
  ${IDE_JVM_ARGS} \
  -Didea.jre.check=true \
  ${MAIN_CLASS} \
  "$@"
