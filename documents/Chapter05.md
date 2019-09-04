# 5. 카프카 컨슈머

- 카프카 컨슈머 : 토픽의 메시지를 가져와서 소비하는 역할을 하는 애플리케이션, 서버 등
- 컨슈머의 역할 : 메시지 요청, 오프셋 명시
    - 메시지 재요청 가능. RabbitMQ는 안됨


## 5.1 컨슈머 주요 옵션

- 컨슈머 종류
  - 올드 컨슈머 : 컨슈머의 오프셋을 주키퍼의 지노드에 저장
  - 뉴 컨슈머 : 컨슈머의 오프셋을 카프카 토픽에 저장 (v0.9 ~)

-  컨슈머 옵션
   -  bootstrap.servers : 처음 연결을 위한 서버 정보
      -  호스트 하나도 가능. 장애 대응 등을 위해 모두 기입 추천

   -  fetch.min.bytes : 한번에 가져올 수 있는 최소 데이터 사이즈
      -  이 보다 작으면 요청에 응답 않고 계속 기다림

   -  group.id : 컨슈머 그룹 ID

   -  enable.auto.commit : 오프셋 커밋을 자동으로

   -  auto.offset.reset : 초기 오프셋 없거나, 존재하지 않은 경우
      -  earliest : 가장 초기 오프셋 값
      -  latest : 가장 마지막 오프셋 값
      -  none : 에러

   -  fetch.max.bytes : 한번에 가져올 수 있는 최대 데이터 사이즈

   -  request.timeout.ms : 요청에 대한 응답을 기다리는 최대 시간
   
   -  hearbeat.interval.ms : poll() 메소드로 하트비트를 얼마나 자주 보낼 것인지 조정 (default : 3초, session timout 1/3 적당)
   
   -  session.timeout.ms : 컨슈머와 브로커 사이의 세션 타임 아웃
      -  컨슈머가 이 시간 동안 하트비트를 보내지 않는다면, 장애로 인식하여 컨슈머 그룹은 리밸런스 시도 (default : 10초)

   -  max.poll.records : 단일 poll()에 대한 최대 레코드 수

   -  max.poll.interval.ms : 하트비트만 보내고 poll() 안하는 경우 컨슈머 그룹에서 제외.
      -  무의미한 컨슈머가 파티션을 무한정 점유하는 것을 방지하기 위해

   -  auto.commit.interval.ms : 주기적으로 오프셋을 커밋하는 시간

   -  fetch.max.wait.ms : fetc.min.bytes 보다 적은 경우, 최대 대기 시간


## 5.2 콘솔 컨슈머

- 콘솔 컨슈머 실행
    ```bash
    $ bin/kafka-console-consumer.sh \
      --bootstrap-server kafka01:9092,kafka02:9092,kafka03:9092 \
      --topic peter \
      --from-beginning
    ```

- 컨슈머 실행시 항상 컨슈머 그룹이 필요. 미설정시 자동 생성
  - ex) console-consumer-xxxxx(숫자)

- 컨슈머 그룹 확인
     ```bash
     $ bin/kafka-consumer-groups.sh \
       --bootstrap-server kafka01:9092,kafka02:9092,kafka03:9092 \
       --list
     ```

- 컨슈머 그룹 지정하여, 컨슈머 실행
     ```bash
    $ bin/kafka-console-consumer.sh \
      --bootstrap-server kafka01:9092,kafka02:9092,kafka03:9092 \
      --topic peter \
      --group peter-consumer-group
      --from-beginning
     ```


## 5.3 자바와 파이썬

- 자바 예제
    ```java
    public class KafkaBookConsumer1 {
        public static void main(String[] args) {
            Properties props = new Properties();
            props.put("bootstrap.servers", "peter-kafka001:9092,peter-kafka002:9092,peter-kafka003:9092");
            props.put("group.id", "peter-consumer");
            props.put("enable.auto.commit", "true");
            props.put("auto.offset.reset", "latest");
            props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
            props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
            KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props);
            consumer.subscribe(Arrays.asList("peter-topic"));
            try {
              while (true) {
                ConsumerRecords<String, String> records = consumer.poll(100);
                for (ConsumerRecord<String, String> record : records)
                System.out.printf("Topic: %s, Partition: %s, Offset: %d, Key: %s, Value: %s\n", record.topic(), record.partition(), record.offset(), record.key(), record.value());
              }
            } finally {
              consumer.close();
            }
        }
    }
    ```
    - public ConsumerRecords<K,V> poll(long timeout)
      - 폴링을 계속 유지해야 함. 그렇지 않으면 파티션은 다른 컨슈머에게 전달됨
      - timeout : 데이터가 컨슈머 버퍼에 없을 때, 얼마나 오랫동안 블럭될지 조정
        - timeout 으로 정해진 시간 동안 대기. 0이면 즉시 리턴.4.


- 파이썬 예제
    ```python
    from kafka import KafkaConsumer

    consumer = KafkaConsumer('peter-topic',group_id='peter-consumer',bootstrap_servers='peter-kafka001:9092,peter-kafka002:9092,peter-kafka003:9092', enable_auto_commit=True, auto_offset_reset='latest')
    
    for message in consumer:
        print "Topic: %s, Partition: %d, Offset: %d, Key: %s, Value: %s" % (message.topic, message.partition, message.offset, message.key, message.value.decode('utf-8'))
    ```


## 5.4 파티션과 메시지 순서

- 각 파티션의 오프셋 순서대로 메시지를 가져온다.
- 카프카는 파티션 내에서 순서 유지.
- 파티션이 여러 개인 경우, 메시지 순서 보장 불가 (파티션간 순서 보장 불가)
- 파티션이 하나인 경우, 메시지 순서 보장. 처리량 저하

- 5.4.1 파티션 3개

  | Producer1 | Producer2 | Consumer |
  |:---:|:---:|:---:|
  | > a <br> > b <br> > c <br> > d <br> > e | > 1 <br> > 2 <br> > 3 <br> > 4 <br> > 5 | a<br>d<br>1<br>4<br>b<br>e<br>2<br>5<br>c<br>3 |
  

    - 각 파티션별로 데이터 Consume
        ```bash
        $ bin/kafka-console-consumer.sh \
          --bootstrap-server kafka01:9092,kafka02:9092,kafka03:9092 \
          --topic peter \
          --partition 0 \ # --partition 1 # --partition 2
          --from-beginning
        ```
        | Consumer for Partition 0 | Partition 1 | Partition 2 |
        |:-:|:-:|:-:|
        | b <br> e <br> 2 <br> 5 | a <br> d <br> 1 <br> 4 | c <br> 3 <br> &nbsp; <br> &nbsp;|
        

- 5.4.2 파티션 1개

  | Producer1 | Producer2 | Consumer |
  |:---:|:---:|:---:|
  | > a <br> > b <br> > c <br> > d <br> > e | > 1 <br> > 2 <br> > 3 <br> > 4 <br> > 5 | a<br>b<br>c<br>d<br>e<br>1<br>2<br>3<br>4<br>5 |
  

    - 각 파티션별로 데이터 Consume
        ```bash
        $ bin/kafka-console-consumer.sh \
          --bootstrap-server kafka01:9092,kafka02:9092,kafka03:9092 \
          --topic peter \
          --partition 0 \
          --from-beginning
        ```
        | Consumer for Partition0 |
        |:-:|
        | a <br> b <br> c <br> d <br> e <br> 1 <br> 2 <br> 3 <br> 4 <br> 5 |
        

## 5.5 컨슈머 그룹

- 컨슈머 그룹 : 하나의 토픽에 여러 컨슈머 그룹이 동시에 저속해 메시지를 가져갈 수 있다.
- 파티션은 여러 컨슈머 그룹에 데이터 전달 가능
- 파티션은 한 컨슈머 그룹 안에서는 단 하나의 컨슈머에 데이터 제공
  
- 데이터 생산량 > 데이터 소비량
  - 컨슈머 확장 필요
  - 리밸런스 : 컨슈머 그룹을 동일하게 하여 컨슈머를 실행하면 파티션의 소유권이 이동하게 됨
  - 일시정지 : 리밸런스를 하는 동안 컨슈머 그룹 전체가 일시적으로 사용할 수 없게 되어 메시지를 가져올 수 없음.
  - 유효컨슈머 : 컨슈머가 파티션보다 많으면, 파티션에 할당되지 않은 컨슈머는 아무 일도 하지 않게 됨

- 하트 비트 : 컨슈머가 컨슈머 그룹 안에서 멤버로 유지, 파티션 소유권 유지 위해서는 하트 비트를 보내야 함
  - 1)컨슈머가 poll 할 때, 2)메시지의 오프셋을 커밋할 때 하트 비트 보냄
  - 오랫동안 하트비트 안 보내면, 세션은 타임아웃되고, 리밸런스 진행
  - 컨슈머가 줄어들면 처리량이 줄어들기 때문에 신속하게 복구 필요


## 5.6 커밋과 오프셋

- 컨슈머 그룹 오프셋 : 컨슈머 그룹마다 각자 오프셋 관리, 컨슈머 그룹 간의 영향 없음
  - 컨슈머 그룹의 컨슈머들은 각각의 파티션에 자신이 가져간 메시지의 위치 정보를 기록
- 커밋 : 각 파티션에 대해 현재 위치를 업데이트하는 동작
- 오프셋 저장소 : 성능 등의 문제로 카프카 내에 별도로 내부에서 사용하는 토픽(__consumer_offsets)을 만들고 그 토픽에 오프셋 정보 저장

### 자동 커밋 (enable.auto.commit=true)

- 5초(auto.commit.interval.ms)마다 컨슈머는 poll() 호출할 때 가장 마지막 오프셋을 커밋
- poll() 요청시 커밋할 시간인지 아닌지 체크, 커밋할 시간이라면 마지막 오프셋 커밋
- 데이터 중복 : 마지막 커밋 후 5초 내에 장애 발생하면? => 데이터는 사용했지만 커밋하지 않아 => 리밸런스 후 데이터 중복

### 수동 커밋

- 메시지 처리가 완료된 후에 커밋이 필요한 경우에 사용
- 메시지를 가지고 오자마자 커밋하지 않고, 컨슈머에서 작업이 완료한 후에 커밋( commitSync() )
- 중복은 장애등의 이후로 피할 수 없지만, 손실은 없음을 보장할 수 있다.
    ```java
    public class KafkaBookConsumerMO {
        public static void `main(String[] args) {
            Properties props = new Properties();
            props.put("bootstrap.servers", "peter-kafka001:9092,peter-kafka002:9092,peter-kafka003:9092");
            props.put("group.id", "peter-manual");
            props.put("enable.auto.commit", "false");
            props.put("auto.offset.reset", "latest");
            props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
            props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
            KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props);
            consumer.subscribe(Arrays.asList("peter-topic"));
            while (true) {
              ConsumerRecords<String, String> records = consumer.poll(100);
              for (ConsumerRecord<String, String> record : records)
              {
                System.out.printf("Topic: %s, Partition: %s, Offset: %d, Key: %s, Value: %s\n", record.topic(), record.partition(), record.offset(), record.key(), record.value());
              }
              try {
                consumer.commitSync();
              } catch (CommitFailedException e) {
                System.out.printf("commit failed", e);
              }
            }
        }
    }
    ```

### 특정 파티션 할당

- 세밀하게 파티션 제어를 원하는 경우
  - 키-값 형태로 파티션 저장, 특정 파티션에 대해서만 메시지 가지고 오는 경우
  - 카프카가 컨슈머의 실패, 재조정 필요 없는 경우 (Yarn 등에서는 알아서 재시작)

  - 원하는 파티션에서 메시지 확인
    ```java
    public class KafkaBookConsumerPart {
    public static void main(String[] args) {
        Properties props = new Properties();
        props.put("bootstrap.servers", "peter-kafka001:9092,peter-kafka002:9092,peter-kafka003:9092");
        props.put("group.id", "peter-partition");
        props.put("enable.auto.commit", "false");
        props.put("auto.offset.reset", "latest");
        props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
        props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
        KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props);
        String topic = "peter-topic";
        TopicPartition partition0 = new TopicPartition(topic, 0);
        TopicPartition partition1 = new TopicPartition(topic, 1);
        consumer.assign(Arrays.asList(partition0, partition1));
        while (true) {
          ConsumerRecords<String, String> records = consumer.poll(100);
          for (ConsumerRecord<String, String> record : records)
          {
            System.out.printf("Topic: %s, Partition: %s, Offset: %d, Key: %s, Value: %s\n", record.topic(), record.partition(), record.offset(), record.key(), record.value());
          }
          try {
            consumer.commitSync();
          } catch (CommitFailedException e) {
            System.out.printf("commit failed", e);
          }
        }
    }
    }
    ```

### 특정 오프셋 지정

- 중복 처리 등의 이유로 오프셋 관리를 수동으로 하는 경우
- seek() 메소드 활용
    ```java
    public void seek(TopicPartition partition, long offset)
    ```
