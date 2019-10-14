$KAFKA/bin/kafka-console-consumer.sh \
--bootstrap-server localhost:9092 \
--topic $1 --from-beginning \
--formatter kafka.tools.DefaultMessageFormatter \
--property print.key=false  \
--property print.value=true \
--property value.deserializer=org.apache.kafka.common.serialization.StringDeserializer
