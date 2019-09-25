# 6. 카프카 운영 가이드

- 카프카 필수 명령어
- 스케일 아웃
- JMX를 활용한 카프카 모니터링
- 카프카 매니저 활용
- FAQ

## 카프카 명령어

### 토픽 생성

- 명령어: `bin/kafka-topics.sh [options] --create`
- 옵션
  - `--zookeeper`: 주키퍼 정보
  - `--replication-factor`: 복제 개수
  - `--partitions`: 파티션 개수
  - `--topic`: 토픽 이름
- example

  ```bash
  bin/kafka-topics.sh \
  --zookeeper zookeeper01:2181,zookeeper02:2181,zookeeper03:2181 \
  --replication-factor 1 \
  --partitions 3 \
  --topic my-topic \
  --create
  ```

### 토픽 리스트 확인

- 명령어: `bin/kafka-topics.sh [options] --list`
- 옵션
  - `--zookeeper`: 주키퍼 정보
- example

  ```bash
  bin/kafka-topics.sh \
  --zookeeper zookeeper01:2181,zookeeper02:2181,zookeeper03:2181 \
  --list
  ```

### 토픽 상세 확인

- 명령어: `bin/kafka-topics.sh [options] --describe`
- 옵션
  - `--zookeeper`: 주키퍼 정보
  - `--topic`: 토픽 이름
- example

  ```bash
  bin/kafka-topics.sh \
  --zookeeper zookeeper01:2181,zookeeper02:2181,zookeeper03:2181 \
  --topic my-topic \
  --list
  ```

### 토픽 설정 변경

- 명령어: `bin/kafka-configs.sh [options] --alter`
- 옵션
  - `--zookeeper`: 주키퍼 정보
  - `--entity-type`: 변경 대상 엔티티
  - `--entity-name`: 변경 대상 이름
  - `--add-config`: 변경 값 추가
  - `--delete-config`: 변경 값 삭제
- example

  ```bash
  # add
  bin/kafka-configs.sh \
  --zookeeper zookeeper01:2181,zookeeper02:2181,zookeeper03:2181 \
  --entity-type topics \
  --entity-name my-topic \
  --add-config retention.ms=3600000 \
  --alter
  ```

  ```bash
  # delete
  bin/kafka-configs.sh \
  --zookeeper zookeeper01:2181,zookeeper02:2181,zookeeper03:2181 \
  --entity-type topics \
  --entity-name my-topic \
  --delete-config retention.ms \
  --alter
  ```

### 토픽 파티션 변경

- 명령어: `bin/kafka-topics.sh [options] --alter`
- 옵션
  - `--zookeeper`: 주키퍼 정보
  - `--partitions`: 파티션 개수
  - `--topic`: 토픽 이름
- 주의할 점
  - **파티션은 증가만 가능하고 감소 불가능**
  - 파티션을 증가시켜 주더라도 컨슈머가 늘어나지 않는다면 처리 성능 늘어날 수 없음
- example

  ```bash
  bin/kafka-topics.sh \
  --zookeeper zookeeper01:2181,zookeeper02:2181,zookeeper03:2181 \
  --partitions 2 \
  --topic my-topic \
  --alter
  ```

### 토픽 리플리케이션 팩터 변경

- 명령어: `bin/kafka-reassign-partitions.sh [options] --execute`
- 옵션
  - `--zookeeper`: 주키퍼 정보
  - `--reassignment-json-file`: 리플리케이션 팩터 변경을 위한 사용자 정의 json 파일 경로
  
    ```json
    {
      "version": 1,
      "partitions": [
        {
          "topic": "my-topic",
          "partitions": 0,      // 파티션 번호
          "replicas": [1,2]     // 리더: 1번 브로커 (첫 번째 인덱스)
        },
        {
          "topic": "my-topic",
          "partitions": 1,
          "replicas": [2,3]     // 리더: 2번 브로커
        }
      ]
    }
    ```

- example

  ```bash
  bin/kafka-reassign-partitions.sh \
  --zookeeper zookeeper01:2181,zookeeper02:2181,zookeeper03:2181 \
  --reassignment-json-file /path/to/rf.json \
  --execute
  ```

### 컨슈머 그룹 리스트 확인

- 명령어: `bin/kafka-consumer-groups.sh [options] --list`
- 옵션
  - `--zookeeper`: 주키퍼 정보 (old consumer)
  - `--bootstrap-server`: 카프카 브로커 정보 (new consumer)
- 주의할 점
  - 카프카 컨슈머에 따라서 **old consumer** 방식과 **new consumer** 방식이 다름 (old 방식은 deprecated 예정)
  - old consumer: 주키퍼의 지노드에 consumer 오프셋 정보 저장
  - new consumer: 브로커의 토픽에 consumer 오프셋 정보 저장
- example

  ```bash
  bin/kafka-consumer-groups.sh \
  --bootstrap-server kafka-broker01:9092,kafka-broker02:9092,kafka-broker03:9092 \
  --list
  ```

### 컨슈머 상태와 오프셋 확인

- 명령어: `bin/kafka-consumer-groups.sh [options] --describe`
- 옵션
  - `--zookeeper`: 주키퍼 정보 (old consumer)
  - `--bootstrap-server`: 카프카 브로커 정보 (new consumer)
  - `--group`: 컨슈머 그룹 이름
- example

  ```bash
  bin/kafka-consumer-groups.sh \
  --bootstrap-server kafka-broker01:9092,kafka-broker02:9092,kafka-broker03:9092 \
  --group my-consumer \
  --describe
  ```

## 스케일 아웃

### 주키퍼 스케일 아웃

- 주키퍼 앙상블 구성에 따른 성능 비교 후 선택
- scale-out example

  1. 추가 노드: zookeeper04, zookeeper05
  2. 각 서버에 주키퍼 설치
  3. myid 설정

    ```bash
    # zookeeper04
    echo "4" > /data/myid
    ```

  4. `zoo.cfg`파일 설정

    ```conf
    tickTime=2000
    initLimit=10
    syncLimit=5
    dataDir=/data
    clientPort=2181
    server.1=zookeeper01:2888:3888
    server.2=zookeeper02:2888:3888
    server.3=zookeeper03:2888:3888
    server.4=zookeeper04:2888:3888
    server.5=zookeeper05:2888:3888
    ```

  5. systemd 설정 및 주키퍼 서비스 시작

    ```bash
    systemctl enable zookeeper-server.service
    systemctl start zookeeper-server.service
    ```

  6. 기존 주키퍼 앙상블 업데이트를 위한 리더/팔로워 확인 (리더 변경을 막기 위해 리더를 마지막에 리스타트 하기 위한 작업)

    ```bash
    /path/to/zookeeper/bin/zkServer.sh status
    ```

    ```text
    ```

  7. 6번 과정에서 알아낸 팔로워, 리더를 순서대로 `zoo.cfg`파일 변경 후 서비스 재시작

    ```bash
    systemctl restart zookeeper-server.service
    ```

  8. 주키퍼 앙상블 정상 동작 확인

    ```bash
    echo mntr | nc localhost 2181 | grep zk_synced_followers
    ```

    ```text
    zk_synced_followers 4
    ```

### 카프카 스케일 아웃

- broker.id 추가 및 재실행
- partition reassign 수행 필요 (작업 시 모니터링 필수)
- scale-out example

  1. 추가 노드: kafka-broker04, kafka-broker05
  2. 각 서버에 카프카 설치
  3. `server.properties` 설정 (예제 2-5 참고)

    ```bash
    vi /path/to/kafka/config/server.properties

    # broker.id=4 <--- 해당 항목을 추가할 브로커 서버의 아이디로 설정
    ```

  4. systemd 설정 및 카프카 서비스 시작

    ```bash
    systemctl enable kafka-server.service
    systemctl start kafka-server.service
    ```

  5. zookeeper 통해서 카프카 클러스터 조인 여부 확인

    ```bash
    /path/to/zookeeper/bin/zkCli.sh
    ```

    ```text
    [zk: localhost:2181(CONNECTED) 0] ls /peter-kafka/brokers/ids
    ```

    ```text
    [1, 2, 3, 4, 5]
    ```

  6. 추가된 브로커로 파티션을 분산하기 위한 reassign 작업 (json 파일 필요)

    ```json
    // partition.json
    {
      "version": 1,
      "partitions": [
        {"topic": "peter5","partition":0,"replicas":[2,1]},
        {"topic": "peter5","partition":1,"replicas":[3,2]},
        {"topic": "peter5","partition":2,"replicas":[4,3]},
        {"topic": "peter5","partition":3,"replicas":[5,4]},
        {"topic": "peter5","partition":4,"replicas":[1,5]},
      ]
    }
    ```

    ```bash
    /path/to/kafka/bin/kafka-reassign-partitions.sh \
    --zookeeper zookeeper01:2181,zookeeper02:2181,zookeeper03:2181,zookeeper04:2181,zookeeper05:2181/peter-kafka \
    --reassignment-json-file /path/to/kafka/partition.json --execute
    ```

    > [주의사항]
    > 파티션 크기가 크거나, 데이터량이 많으면 브로커 간의 네트워크 인터페이스 사용량이 급증하면서
    > 너무 많은 부담을 주면서 장애 상황으로 이어질 수 있다.
    > 따라서, 카프카 사용량이 적은 시간대에 작업해야 하며, 토픽 보관주기를 축소하여 데이터를 줄인 상태에서 수행하는 것이 좋다.

## 카프카 모니터링

### JMX 설정 방법

- JMX(Java Management eXtensions): 자바 API로 제공되는 자바 애플리케이션 모니터링 도구
- MBean 객체로 표현

#### JMX 설정을 카프카에 추가하는 방법

1. kafka-server-start.sh 열기

  ```bash
  vi kafka-server-start.sh
  ```

2. 아래와 같이 환경변수 추가

  ```bash
  # ...
  # See the License for the specific language governing permissions and
  # limitations under the License.

  export JMX_PORT=9999 # <--- 추가
  if [ $# -lt 1 ];
  then
      echo "USAGE: $0 [-daemon] server.properties [--override
  property=value]*"
      exit 1
  fi
  ```

3. 서비스 재시작

  ```bash
  systemctl restart kafka-server.service
  ```

#### systemd의 환경변수 옵션을 이용하는 방법

1. jmx 파일 생성

  ```bash
  echo "JMX_PORT=9999" > /usr/local/kafka/config/jmx
  ```

2. systemd 설정 열기

  ```bash
  vi /etc/systemd/system/kafka-server.service
  ```

3. 아래와 같이 설정값 추가

  ```bash
  # ...
  ExecStop=/usr/local/kafka/bin/kafka-server-stop.sh
  EnvironmentFile=/usr/local/kafka/config/jmx # <--- 추가
  ```

4. 서비스 재시작

  ```bash
  systemctl daemon-reload
  systemctl restart kafka-server.service
  ```

### JMX 모니터링 지표

- 아래의 주요 지표 항목들을 기준으로 모니터링 구성
  - Message in rate
  - Byte in rate
  - Byte out rate
  - Under replicated partitions
  - Is controller active on broker
  - Partition counts
  - Leader counts
  - ISR shrink rate

## 카프카 매니저 활용

- GUI 기반 카프카 운영 도구
- https://github.com/yahoo/kafka-manager

### 카프카 매니저 설치

1. 깃허브에서 zip 파일 다운로드

  ```bash
  wget https://github.com/yahoo/kafka-manager/archive/2.0.0.0.zip
  ```

2. 압축 해제

  ```bash
  unzip 2.0.0.0.zip
  ```

3. 배포 파일 생성

  ```bash
  cd kafka-manager-2.0.0.0
  ./sbt clean dist
  ```

4. 배포 파일을 `/usr/local` 경로로 복사

  ```bash
  cp target/universal/kafka-manager-2.0.0.0.zip /usr/local/
  ```

5. 압축 해제

  ```
  unzip /usr/local/kafka-manager-2.0.0.0.zip
  ```

6. 설정 파일 변경

  ```bash
  vi /usr/local/kafka-manager-2.0.0.0/conf/application.conf

  kafka-manager.zkhosts="zookeeper01:2181,zookeeper02:2181,zookeeper03:2181" # <--- 변경
  ```

7. 카프카 매니저 실행

  ```bash
  /usr/local/kafka-manager-2.0.0.0/bin/kafka-manager \
  -Dconfig.file=/usr/local/kafka-manager-2.0.0.0/conf.application.conf \
  -Dhttp.port=9000
  ```

8. `localhost:9000` 접속
