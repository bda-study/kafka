## 8.4 파이프 예제 프로그램 만들기

* Pipe 프로세스 : Chapter08/src/main/java/myapps/Pipe.java

* 코드 전체를 실행

```shell
streams.examples$ mvn clean package
streams.examples$ mvn exec:java -Dexec.mainClass=myapps.Pipe 
```

* streams-plaintext-input으로 입력을 보냄.

```shell
$ $KAFKA/bin/kafka-console-producer.sh --broker-list localhost:9092 --topic streams-plaintext-input
> test
> test1234
> kafka is best
```

* consumer 쪽에서 메시지 확인

```shell
Chapter08$ ./sink.sh streams-pipe-output
test
test1234
kafka is best
```

## 8.5 행 분리 예제 프로그램 만들기
* LineSplit 프로세스 : Chapter08/src/main/java/myapps/LineSplit.java

* 코드 전체를 실행

```shell
streams.examples$ mvn clean package
streams.examples$ mvn exec:java -Dexec.mainClass=myapps.LineSplit
```


* streams-plaintext-input으로 입력을 보냄.

```shell
$ KAFKA/bin/kafka-consoleoducer.sh --broker-list localhost:9092 --topic streams-plaintext-input
>apple is good
>kafka is good
>happy kafka and apple
```

* consumer 쪽에서 메시지 확인

```shell
~/kafka/exercises/Chapter08$ ./sink.sh streams-linesplit-output
apple 
is 
good
kafka
is 
good 
happy
kafka
and
apple
```

## 8.6 단어 빈도수 세기 예제 프로그램 만들기
* LineSplit 프로세스 : Chapter08/src/main/java/myapps/WordCount.java

* 코드 전체를 실행
```shell
~/streams.examples$ mvn clean package
~/streams.examples$ mvn exec:java -Dexec.mainClass=myapps.WordCount
```

* console-producer 실행

```shell
$ $KAFKA/bin/kafka-console-producer.sh --broker-list localhost:9092 --topic streams-plaintext-input
>andrew is good
>andrew is good
>apple is bad
>apple is good
>andres is bad
```

* console-consumer 결과 확인

```shell
kafka/exercises/Chapter08$ ./sink_cnt.sh
andrew  2
apple   2
good    3
andres  1
is      5
bad     2
```
