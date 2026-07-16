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

# flutter_autofill_service : son provider de log tinylog personnalisé
# (DynamicLevelLoggingProvider) est résolu à l'exécution par ServiceLoader
# (META-INF/services) + tinylog.properties. R8 ne doit ni le supprimer ni le
# renommer, sinon tinylog retombe sur le provider par défaut → ClassCastException
# au setPreferences (chemin autofill sensible à R8).
-keep class com.keevault.flutter_autofill_service.DynamicLevelLoggingProvider { *; }
-keep class org.tinylog.** { *; }
