JAVA_HOME=@@ansible_alfresco_root_dir@@/java
JRE_HOME=$JAVA_HOME
JAVA_OPTS="@@ansible_alfresco_java_opts@@ -Djava.awt.headless=true -Dalfresco.home=@@ansible_alfresco_root_dir@@ -XX:ReservedCodeCacheSize=128m -Dcom.sun.management.jmxremote $JAVA_OPTS"
export JAVA_HOME
export JRE_HOME
export JAVA_OPTS
export LD_LIBRARY_PATH
