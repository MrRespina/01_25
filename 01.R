# R + MongoDB 연동

# 1. 패키지 설치
install.packages("mongolite")

# 2. import
library(mongolite)

# 3. mongodb server On
# cmd 1번 > mongodb 실행파일 있는 위치로 가서
# mongod --dbpath C:\Users\sdedu\Desktop\Dev\mongo --bind_ip_all (MongoDB 서버 ON)
# cmd 2번 > mongo

# 4. mongoDB connection
# 접속 관련 함수로 현재 실행되어있는 mongoDB와 연결
# verbose = 함수 수행 시 발생하는 정보들을 자세히 봄.
# options = 접속시에 보안 설정.
con <- mongolite::mongo(collection ="exams",db="prac",url="mongodb://localhost",verbose=T,options=ssl_options())
con

# 5. 기존 collection 삭제
# 기존 collection이 있는 경우 삭제 (내용물)
if(con$count()>0) con$drop()

# 6. csv 파일 불러오기
# file로 첨부한 csv는 data.frame으로 로딩
library(dplyr)

exams <- read.csv("C:/Users/sdedu/Desktop/Dev/R/csv/exams.csv",fileEncoding='UTF-8')
View(exams)

# 7. document 삽입
# 다른 r - mongodb 연동하는 패키지는
# document 삽입 시 json으로 포맷을 해야하지만,
# mongolite의 경우에는 document 삽입 시에 
# method인 insert()가 직접 data.frame으로 전달해주기 때문에
# method 내부적으로 자동으로 json 형태로 변환,포맷이 가능.


con$insert(exams)

# mongoDB에서 확인
# use prac
# > db.exams.find().pretty()

# document 확인
# 원래 data.frame 갯수 = db에 있는 데이터
dim(exams)[1]
con$count()

# 8. db에 있는 document 받아오기
# 원래 data.frame(exams) 에 있는 데이터를 삭제
rm(exams)

# 새로 exams를 만들어서 mongoDB에 있는 데이터를 가져오기
# 조건문 사용시에는 중괄호 안에 조건절을 추가해 줄 것.
exams <- con$find(query='{}')
View(exams)
dim(exams)

# 성별이 여자, 수학 44점, 읽기 55점인 사람의 데이터 조회
exam <- con$find(query='{"gender":"female","math_score":44,"reading_score":55}')
View(exam)

# 9. data update
# con$update()
# 성별이 여자, 수학 44점, 읽기 55점인 사람  > 소속 그룹을 'group A'로 변경할 것.
con$update(query='{"gender":"female","math_score":44,"reading_score":55}',update='{"$set":{"race_ethnicity":"group A"}}')
exam <- con$find(query='{"gender":"female","math_score":44,"reading_score":55}')
View(exam)

# 10. 조건으로 document 찾기

# 수학 점수가 100점인 사람들의 데이터 조회
View(con$find(query='{"math_score":100}'))

# gender 변수의 값에 'f'가 포함되는 사람들의 데이터 조회
# 문자열을 포함하는 검색 / $regex
View(con$find(query='{"gender":{"$regex":"f"}}'))


# MongoDB 문자열 검색
# 포함 되어 있는지 확인 : {"$regex" : "문자열"}
# 특정한 단어로 시작하는지 : {"$regex" : "^문자열"}
# 특정한 단어로 끝나는지 : {"$regex" : "문자열$"}
# 대소문자 구분 없이 찾고 싶다 : {"$regex" : "문자열"},"$options" : "i"
exams <- con$find(query ='{}')
exams

dafr <- data.frame(exams)
dafr

# dafr로 > 그룹별 수학 평균점수를 > bar 그래프로 표현할 것.
library(tidyverse)
library(dplyr)
library(ggplot2)
dafr %>% group_by(`race_ethnicity`) %>% summarise(`평균점수`=mean(`math_score`))

# stat = "identity" : y축의 높이를 데이터 값으로 하는 bar 그래프의 형태로 지정
dafr %>% group_by(`race_ethnicity`) %>% summarise(`평균점수`=mean(`math_score`)) %>% ggplot(aes(x=`race_ethnicity`,y=`평균점수`)) + geom_bar(stat="identity",fill='gold')

# exams 데이터 > 성별을 기준으로 그룹화
# 각 표뵨들이 얼마나 있는지 console에 조회
data1 <- con$find(query='{}')
data1

data1 %>% group_by(gender) %>% summarise(count=n())


install.packages("echarts4r")
library(echarts4r)

# 툴팁 설정 가능.
data1 %>% group_by(gender) %>% summarise(count=n()) %>% e_chart(gender) %>% e_bar(count,barwidth=10) %>% e_tooltip(trigger = c('axis'))


# 접속(연결) 해제 : mongolite는 해제에 대한 명령어가 별도로 없다.
#                 : 접속 객체를 제거함.
rm(con)