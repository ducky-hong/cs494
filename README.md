CS494 Project
-------------

naver 오픈소스 프로젝트를 사용하기 위한 테스트 프로젝트.  

웹 서버는 ruby + sinatra + thin 으로 구성했고, 백엔드 서비스로 mysql, nbase-arc, arcus-memcached 를 사용한다.

3개의 API를 사용할 수 있다.

- `GET /mysql` : mysql 에서 데이터를 읽어 리턴
- `GET /arcus-memcached` : mysql 에서 데이터를 읽어 arcus-memcached 에 저장, 이후 request 는 cache 에서 데이터를 읽어 리턴
- `GET /nbase-arc` : 위와 같으나 nbase-arc 를 cache 로 사용

nbase-arc 와 arcus-memcached 전용 클라이언트를 사용하지 않았고, redis 와 memcached client (dalli) 를 사용했다. 간단한 명령어는 호환이 되어 사용하는데 큰 문제는 없다.

api server, mysql, nbase-arc, arcus-memcached, hubblemon, ngrinder 는 모두 docker 를 사용해서 띄울 수 있도록 했다. 가상 서버를 사용할 수 있고, 또는 VirtualBox, VMWare 에 리눅스를 설치해서 arcus-memcached, nbase-arc 등 모두 설치해서 환경 설정을 하는 방법이 있었다. 그러나 각자 요구하는 라이브러리가 다르고 (예를 들어 arcus 는 zookeeper custom build 를 사용한다), 서로 endpoint 만 노출해서 사용하도록 하는 방법이 깔끔해서 docker 를 사용했다. docker 를 사용하면 각자의 분리된 환경을 만들 수 있기 때문에 로컬 환경을 어지럽히지 않는다는 장점도 있다.

nbase-arc, arcus-memcached, hubblemon 은 docker image 를 제공하지 않아 Dockerfile 을 만들고 소스를 일부 수정하여 이미지를 빌드했다. 해당 이미지는 따로 registry 에 올리지 않고, 직접 로컬에서 빌드해야한다. 빌드 방법은 Usage 에 적혀있다. nbase-arc 는 docker image 를 만들기 어려웠는데, 환경 설정이 모두 fabirc 을 사용해야했기 때문이다. standalone 으로 띄우기도 어려워, ssh 와 fabric 을 docker image 에 설치하여 (ssh 를 사용하는 것은 anti-pattern), expect 를 사용해 자동화하였다.

mysql 에서 기본 테이블 구조와 데이터를 초기화 하기 위해 `fixture.sql` 파일을 생성했다. 이는 mysql docker 이미지가 지원하는 기능이다. migration 라이브러리를 사용할 수 있지만 지나치게 복잡해지는 것 같아 생략했다. 

docker 는 Mac 에서 바로 돌아가지 않기 때문에 linux 환경을 따로 설치해야한다. 기존에는 VirtualBox 에 boot2docker image 를 설치해서 사용했고, docker 에서는 Docker ToolBox 패키지를 지원해 사용하기가 편했다. 그러나 docker-machine 을 사용해야하고 volume 연동이 불편한 부분이 있었다. 운이 좋게도 Mac 에서 좀 더 편하게 사용할 수 있는 docker package 인 docker for mac beta 에 당첨이 되었고, 이번 프로젝트를 진행할 때는 docker for mac 을 사용했다. beta 였지만 사용하는데 큰 문제는 없었다.

mysql, nbase-arc, arcus-memcached 의 성능 측정을 위해 ngrinder 를 사용했다. ngrinder 는 이전에 사용해본 경험이 있기 때문에 사용하는데 큰 어려움은 없었다. 엄밀한 환경을 만들어 놓고 사용한 것이 아니라 결과는 크게 신뢰할 수 없지만, mysql 만 사용할 때보다 arcus-memcached, nbase-arc 를 캐시로 사용하면 향상된 TPS 를 보여주었다. 결과는 아래와 같다.

![mysql](https://raw.githubusercontent.com/ducky-hong/cs494/master/screenshots/mysql.png)
![arcus](https://raw.githubusercontent.com/ducky-hong/cs494/master/screenshots/arcus.png)
![nbase-arc](https://raw.githubusercontent.com/ducky-hong/cs494/master/screenshots/nbase-arc.png)

hubblemon 을 사용해 모니터링을 적용했다. 그러나 docker container 의 모니터링은 hubblemon 에서 지원하지 않기 때문에 엄밀하게 적용하지는 못했다. hubblemon 서버를 띄우고, 해당 서버의 cpu 사용량 등 psutil 을 사용하여 나온 값을 모니터링 하도록 했다.

![hubblemon](https://raw.githubusercontent.com/ducky-hong/cs494/master/screenshots/hubblemon.png)

Usage
-----

먼저 필요한 docker image 를 빌드한다.

__nbase-arc__  
1. `git clone -b feature/dockerize https://github.com/ducky-hong/nbase-arc.git`  
2. `docker build -t cs494/nbase-arc .`

__arcus-memcached__  
1. `git clone -b feature/dockerize https://github.com/ducky-hong/arcus-memcached.git`  
2. `docker build -t cs494/arcus-memcached`

The zookeeper archive is built from https://github.com/ducky-hong/arcus-zookeeper

__hubblemon__  
1. `git clone -b feature/dockerize https://github.com/ducky-hong/hubblemon.git`  
2. `docker build -t cs494/hubblemon-server`

__api & mysql__  
1. `docker-compose build`

웹 서버 실행 & 허블몬 실행

```bash
# nbase-arc docker image has restarting issue.
$ docker-compose up --force-recreate

# test api
$ curl http://localhost:4567/mysql

# manual tasks

# ngrinder-agent cannot download at initial startup
$ docker-compose start ngrinder-agent
# start hubblemon client
$ docker exec cs494_hubblemon_1 /bin/bash -c "python /usr/src/app/collect_client/run_client.py"
```

