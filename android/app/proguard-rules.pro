# Règles R8/ProGuard pour le build release (shrinking + obfuscation actifs).
#
# kotlin-logging (tiré par flutter_autofill_service) référence des backends de
# log optionnels absents sur Android — logback, JNDI, java.lang.management,
# sun.reflect. Ces classes ne sont jamais chargées à l'exécution sur Android ;
# on supprime seulement les avertissements pour que R8 n'échoue pas. Liste
# générée par AGP dans build/app/outputs/mapping/release/missing_rules.txt.
-dontwarn ch.qos.logback.classic.Level
-dontwarn ch.qos.logback.classic.Logger
-dontwarn ch.qos.logback.classic.LoggerContext
-dontwarn ch.qos.logback.classic.spi.ILoggingEvent
-dontwarn ch.qos.logback.classic.spi.LoggingEvent
-dontwarn dalvik.system.VMStack
-dontwarn java.lang.ProcessHandle
-dontwarn java.lang.management.ManagementFactory
-dontwarn java.lang.management.RuntimeMXBean
-dontwarn javax.naming.InitialContext
-dontwarn javax.naming.NameNotFoundException
-dontwarn javax.naming.NamingException
-dontwarn sun.reflect.Reflection
