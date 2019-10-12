# Filebeat-Kafka-Nifi on docker-compose

Filebeat, Kafka, Nifi를 docker-compose로 구성하여 실습해보는 것이 목표입니다.

## Requirements

- OSX (Tested on Mac)
- docker
- docker-compose (version: 3+)

## How to Run

```bash
docker-compose up -d
```

### weblogs 데이터 흘려보내기

```bash
# sleep으로 간격 조정
while true; do ./script/generate.sh; sleep 5; done
```

### Nifi에서 weblogs 데이터 kafka로 reproduce하기

1. 브라우저에서 `localhost:8080/nifi`로 접속
2. Consume processor 추가 (Processor 드래그 > Filter에 kafka 검색 > ConsumerKafka 선택 후 ADD 클릭)
3. Properties 변경
  - Kafka Brokers: kafka:29092
  - Topic Name(s): weblogs
  - Group ID: weblogs-consumer-group
4. Publish processor 추가 (Processor 드래그 > Filter에 kafka 검색 > PublishKafka 선택 후 ADD 클릭)
5. Properties 변경
  - Kafka Brokers: kafka:29092
  - Topic Name: weblogs-reproduced
6. Consume/Publish processor 시작하기

### 생성된 데이터 확인하기

1. kafka 인스턴스 접속: `docker-compose exec kafka bash`
2. kafka console consumer 실행: `kafka-console-consumer --bootstrap-server localhost:9092 --topic weblogs-reproduced`
