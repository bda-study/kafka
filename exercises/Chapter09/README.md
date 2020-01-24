# Ksql Tutorials

See [Ksql tutorials](https://docs.confluent.io/current/ksql/docs/tutorials/)

## How to run

```bash
docker-compose up -d
```

### 데이터 생성하기

```bash
docker run --network chapter09_default --rm --name datagen-pageviews \
confluentinc/ksql-examples:5.3.1 \
ksql-datagen \
    bootstrap-server=kafka:39092 \
    quickstart=pageviews \
    format=delimited \
    topic=pageviews \
    maxInterval=100 \
    iterations=100
```

```bash
docker run --network chapter09_default --rm --name datagen-users \
confluentinc/ksql-examples:5.3.1 \
ksql-datagen \
    bootstrap-server=kafka:39092 \
    quickstart=users \
    format=json \
    topic=users \
    maxInterval=100 \
    iterations=100
```

## KSQL을 이용한 스트림 분석

1. ksql client 실행

    ```bash
    docker run --network chapter09_default --rm --interactive --tty \
    confluentinc/cp-ksql-cli:5.3.1 \
    http://ksql-server:8088
    ```

2. ksql에서 현재 토픽 확인하기

    ```sql
    SHOW TOPICS;
    ```

    ```
    Kafka Topic        | Registered | Partitions | Partition Replicas | Consumers | ConsumerGroups
    ------------------------------------------------------------------------------------------------
    _confluent-metrics | false      | 12         | 1                  | 0         | 0
    _schemas           | false      | 1          | 1                  | 0         | 0
    pageviews          | true       | 1          | 1                  | 0         | 0
    users              | true       | 1          | 1                  | 0         | 0
    ------------------------------------------------------------------------------------------------
    ```

3. 기본 스트림과 테이블 생성

    ```sql
    CREATE STREAM pageviews_original
    (viewtime bigint, userid varchar, pageid varchar)
    WITH (kafka_topic='pageviews', value_format='DELIMITED');
    ```

    ```sql
    CREATE TABLE users_original
    (registertime bigint, gender varchar, regionid varchar, userid varchar)
    WITH (kafka_topic='users', value_format='JSON');
    ```

4. 스키마 확인

    ```sql
    DESCRIBE pageviews_original;
    ```

    ```
    Name                 : PAGEVIEWS_ORIGINAL
    Field    | Type
    --------------------------------------
    ROWTIME  | BIGINT           (system)
    ROWKEY   | VARCHAR(STRING)  (system)
    VIEWTIME | BIGINT
    USERID   | VARCHAR(STRING)
    PAGEID   | VARCHAR(STRING)
    --------------------------------------
    ```

    ```sql
    DESCRIBE users_original;
    ```

    ```
    Name                 : USERS_ORIGINAL
    Field        | Type
    ------------------------------------------
    ROWTIME      | BIGINT           (system)
    ROWKEY       | VARCHAR(STRING)  (system)
    REGISTERTIME | BIGINT
    GENDER       | VARCHAR(STRING)
    REGIONID     | VARCHAR(STRING)
    USERID       | VARCHAR(STRING)
    ------------------------------------------
    ```

3. 쿼리를 통해 데이터 조회하기

    ```sql
    SELECT userid FROM users_original LIMIT 3;
    ```
