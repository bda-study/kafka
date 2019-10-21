# Chapter 09. KSQL

- 일반적인 빅데이터 플랫폼에서...
  - 단기간 처리는 스트리밍 플랫폼으로 하고
  - 장기 데이터는 별도의 장기 저장소와 별도의 배치 처리 시스템을 사용

- KSQL 을 사용하여 저장 기간에 관계 없이 스트리밍과 배치 처리 동시 가능

### 9.1 KSQL 등장 배경

- 보통, 카프카를 데이터 버스로 사용하고, 데이터 가공해서 다른 곳에 저장
    - 카멜, 스톰, 스파크 스트리밍, 삼자 등을 활용
    - 카프카는 특정 큐로 데이터 들어왔을 때 정해진 툴을 적용하는 "큐 라우팅" 기능이 약함

- 카카오 케미 (KEMI STATS)
    - ![카카오 케미](https://tech.kakao.com/files/kemi-stats.jpg)
    - KEMI : 알림 STATS, 로그 LOG
    - KEMI STATS : POLLING 방식, PUSH 방식
    - KEMI STATS POLLING (1분 주기)
        - 람다 아키텍처 적용
        - Job Controller : 모니터링 장비 목록 정의
        - etcd : 모니터링 항목 정의
        - Poller :
            - Producee의 장비 목록을 보고 있다가 etcd 항목을 실제 서버에서 수집
            - 연산이 필요한 것 (DISK usage 등)은 삼자를 통해 가공해서 카프카에 등록

    - 람다 아키텍처
        ![카프카 람다 아키텍처](https://3.bp.blogspot.com/-2FkpcBZrCQQ/WEkE1vZonmI/AAAAAAAAADw/Do4cCH3NcmkULhJdr1ZUchnjgIeAOqbSwCLcB/s1600/%25EB%259E%258C%25EB%258B%25A4%2B%25EC%2595%2584%25ED%2582%25A4%25ED%2585%258D%25EC%25B2%2598.PNG)
        - 데이터를  처리해서 기간과 용량에 따라 별도의 저장소를 가져가는 방식
        - 장점
            - 적절한 기술을 조합해서 쉽게 구축 가능
            - 병목시 특정 컴포넌트만 증가하여 확장 가능
        - 단점
            - 너무 많은 기술 사용
            - 단기, 장기 데이터를 별도 관리해야 해서 관리 비용 부담
            - 결국 작은 규모에서는 관리하기 어려움
         => 간단한 계산, 필터링은 카프카에서 수행, 장/단기 구분 없이 동일한 사용 원함 : 카파 아키텍처 등장


### 9.2 KSQL과 카파 아키텍처

-카파 아키텍처

  ![카프카 카파 아키텍처](https://1.bp.blogspot.com/-g6Ox9oXNZtA/WEkJSWvnOYI/AAAAAAAAAEY/4OobQTWa7SYqc6_HDjC8dp_5rEMxz1hPACEw/s1600/%25EC%25B9%25B4%25ED%258C%258C%25EC%2595%2584%25ED%2582%25A4%25ED%2585%258D%25EC%25B2%2598.PNG)

    - 크기나 기간에 관계없이 하나의 계산 프로그램 사용
    - 장기 데이터 따로 저장하지 않고 장기 데이터 조회가 필요한 경우 그때그때 계한하여 전달
    - 람다 아키텍처와의 비교
        - 데이터 제공 영역이 없어짐 => 언제나 계산을 통해 만들어 내는 것이 핵심
    - 저장 기간별 데이터 처리 방식
        - 단기 데이터 : 토픽에 저장하고, 스파크나 스톰 또는 삼자를 통해 결과를 만들어냄
        - 장기 데이터 : 하둡에 복사하고, 맵리듀스나 스파크를 통해 결과를 만들어냄
    - 저장 기간에 관계없이 통합하게 하면? => KSQL
    

### 9.3 KSQL 아키텍처

![KSQL architecture](https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTjzMqNs-uymjs88N_T56kCdbS7AgvVhtSaCVs_rlT-MC922cwM5w)

- 구성
    - KSQL 서버
        - REST API 서버 : 사용자 쿼리 받기
        - 쿼리 실행 엔진 : 논리적/물리적 실행 계획 생성 및 실행. 카프카 토픽 읽거나 생성
    - KSQL 클라이언트
        - 사용자가 SQL 쿼리문 작성하도록 인터페이스 제공
        - KSQL에 연결

- KSQL 서버
    - 쿼리 실행 절차
        - 쿼리 -> 쿼리 재작성 -> 논리 계획 작성 -> 물리 계획 작성 -> 쿼리 실행 -> 스토리지
    - 메타 정보 관리 방식
      - 계획 작성시 필요한 테이블 메타 정보는 KSQL 서버의 메모리에 존재
      - 필요한 경우 ksql__commands 라는 토픽에 저장
      - KSQL 서버 추가시 토픽 활용하여 메모리에 저장
    - 엔진 소스 상의 메타정보 초기화
      - 정해진 토픽에 메타 정보 저장 가능하게 하는 **메타 스토어** 초기화
      - 메타 스토어에 **DDL** 정보 저장할 수 있게 초기화 작업 수행
      - 쿼리 명령어 수행시 사용할 **엔진** 객체 초기화
      - **영구 쿼리** (명시적으로 종료하지 않으면 계속 실행) 등록위한 해시맵 초기화
      - **라이브 쿼리** (한번 수행 후 종료) 등록위한 해시맵 초기화
      - **KSQL 함수** 등록위한 해시맵 초기화

- KSQL 클라이언트
    - SQL문을 KSQL 서버에 전달하고, 결과 받는 툴
    - DDL, DML 지원
    - 스트림, 테이블 지원
      - 스트림 : 계속 기록, 변경 불가
      - 테이블 : 현재 상태, 변경 가능
    - 스트림테이블 생성
      - 지원 타입 : BOOLEAN, INTEGER, BIGINT, DOUBLE, VARHAR, 배열형, 해시형
      - 프로퍼티
        - KAFKA_TOPIC (필수) : 테이블에서 사용할 토픽
        - VALUE_FORMAT (필수) : 데이터 포맷, JSON과 DELIMETED만 지원
        - TIMESTAMP : 토픽의 시간 값 (timestamp)를 KSQL 컬럼과 연결. 윈도우 처리시 사용
      - 예시
        ```bash
        CREATE STREAM/TABLE pageviews (viewtime BIGINT, user_id VARCHAR, page_id VARCHAR)
        WITH (VALUE_FORMAT='JSON', KAFKA_TOPIC='my-topic')
        ...
        ```
        - 테이블도 생성 방식은 유사함
      - 지속적 입력 예시
        ```bash
        CREATE STREAM/TABLE pageviews (viewtime BIGINT, user_id VARCHAR, page_id VARCHAR)
        WITH (VALUE_FORMAT='JSON', KAFKA_TOPIC='my-topic')
        AS SELECT * FROM PAGEVIEWS
        PARTITION BY SITE_ID
        ```
        - 쿼리 결과활용시 프로퍼티에 PARTITIONS, REPLICATIONS 지정 가능


### 9.4 도커 이용한 KSQL 클러스터 설치

- 예제 실행 방법
    - KSQL 0.5.x 활용 예시
        ```bash
        $ git clone -b 0.5.x --single-branch https://github.com/confluentinc/ksql.git
        $ cd ksql/docs/quickstart
        $ docker-compose up -d --build
        ```

    - Confluent Platform 활용 예시
        ```bash
        $ git clone -b 5.3.1-post --single-branch https://github.com/confluentinc/examples
        $ cd cp-all-in-one
        $ docker-compose up -d --build
        ```
- KSQL docker-compose.yaml
  - KSQL 예제를 위해서는 zookeeper, kafka, schema-registry 총 3개 서비스 필요
  - kafka에 zookeeper를 depends_on으로 처리 가능
  - schema-registry 서비스는 AVRO(경량 RPC의 일종)의 스키마를 저장하고 가져가는 역할 SQL 스키마는 카프카 직접 저장

- 컨테이너 실행
    ```bash
    $ docker-compose up -d
    ...
    ```
    - docker-compose 파일에서 실행한 순서대로 실행 (주키퍼 -> 카프카 -> 스키마 레지스트리)

- 컨테이너 확인
    ```bash
    $ docker-compose ps
    ...
    $ docker-compose exec ksql-cli hostname
    ksql-cli
    ```

- KSQL 시행
    ```bash
    $ docker-compose exec ksql-cli ksql-cli local --bootstrap-server kafka:29092
    ...
    ksql> _
    ```
    - local 옵션을 통해 로컬에서 세션 생성


### 9.5 KSQL을 이용한 스트림 분석

- 예제 개요
  1. 데이터 생성기 2개
  2. 2개, 각각 토픽 1개씩
  3. 각각 스트림 1개, 테이블 1개
  4. 조합해서 스트립 2개, 테이블 1개
  5. 3개, 각각 토픽 1개씩

- 데이터 생성
  - 컨테이너 ksql-datagen-pageviews : pageviews 토픽 생성
  - 컨테이너 ksql-datagen-users : users 토픽 생성
    ```bash
    $ docker-compose exec kafka kafka-topics --list --zookeeper zookeeper:32181
    __consumer_offsets
    _confluent-metrics
    _schemas
    ksql__commands
    pageviews
    users
    ```

- 스트림과 테이블 생성
  - 스트림 생성 (p.360)
    ```bash
    ksql> CREATE STREAM pageviews_original \
        > ... \
        > WITH (kafka_topic='pageviews', ...;
    Message
    --------------
    Stream created
    --------------

    ksql> describe pageviews_original;
    ...
    ```

  - 테이블 생성 (p.361)
    ```bash
    ksql> CREATE TABLE users_original \
        > ... \
        > WITH (kafka_topic='users', ..., key='userid'); // 오류나서 key추가
    ...
    ```
    - 오류 발생해서 key 추가해서 실행함
    ```bash
    Cannot define a TABLE without providing the KEY column name in the WITH clause
    ```

- 쿼리를 이용한 스트림과 테이블 생성
  - 스트림 생성 (p.362)
  ```bash
  ksql> CREATE STREAM pageviews_female AS \
        > SELECT *  ...;
  Message
  --------------------------
  Stream created and running
  --------------------------
  
  ksql> select * from pageviews_female; // 영구적 쿼리. 계속 조회됨.
  ...

  $ docker-compose exec kafka kafka-topics --list --zookeeper zookeeper:32181
  PAGEVIEWS_FEMALE
  ...
  ksql_query_CSAS_PAGEVIEWS_FEMALE-KSTREAM-MAPVLAUES-...-repartitions
  ksql_query_CSAS_PAGEVIEWS_FEMALE-KSTREAM-REDUCE-STATE-STORE-...-changelog
  ...

  ```

- 스트림 생성 (p.364)
  ```bash
    ksql> CREATE TABLE pageviews_female_like_89 \
        > WITH (kafka_topic='pageviews_enriched_r8_r9', ... \
    ...
    
    $ docker-compose exec kafka kafka-topics --list --zookeeper zookeeper:32181
    ...
    pageviews_enriched_r8_r9
    ...
  ```

- 테이블 생성 (p.366)
  ```bash
  ksql> CREATE TABLE pageviews_regions AS \
      > SELECT ... \
      > WINDOW TUMBLING (size 30 second) \ // 30초 데이터를 모아서 처리
      > ...;
   
  $ docker-compose exec kafka kafka-topics --list --zookeeper zookeeper:32181
    ...
    PAGEVIEWS_REGIONS
    ...
  ```