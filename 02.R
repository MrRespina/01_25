library(dplyr)

bike <- read.csv("C:/Users/sdedu/Desktop/Dev/R/csv/공공자전거 대여이력 정보_2021.01.csv",encoding = "UTF-8")
View(bike)

# "자전거번호","대여일시","대여 대여소번호","대여 대여소명", 
# "대여거치대","반납일시","반납대여소번호","반납대여소명",
# "반납거치대","이용시간","이용거리"

names(bike) = c("bike_num","rental_time","office_num","office_name","holder_count","return_time","r_office_num","r_office_name","r_holder_count","use_time","use_distance")
View(bike)
  
# rename을 사용해서도 가능.
bike <- bike %>% rename(bike_num='자전거번호',br_dt='대여일시',br_no='대여.대여소번호',br_nm='대여.대여소명',br_std='대여거치대',re_dt='반납일시',re_no='반납일시',re_nm='반납대여소명',re_std='반납거치대',ride_time='이용시간',ride_dist='이용거리')
View(bike)

# 대여.대여소명 많이 이용된 순서대로 조회
# office_num
dat1 <- bike %>% group_by(`office_name`) %>% summarise(used=n()) %>% arrange(desc(`used`))
View(dat1)
# 이 방식으로 줄여서 사용 가능하다.
bike %>% count(`office_name`,sort=T)

# 반납대여소명 / 어디에서 가장 많이 반납되었는지 순서대로 조회
dat2 <- bike %>% group_by(`r_office_name`) %>% summarise(returned = n()) %>% arrange(desc(`returned`))
View(dat2)
bike %>% count(`r_office_name`,sort=T)

# 쓸모없는 변수 제외 (자전거번호,대여거치대,반납거치대)
dat3 <- bike %>% select(-c(`bike_num`,`holder_count`,`r_holder_count`))
View(dat3)
  
# 이용 거리가 10m 이하인 곳 제외 / 현재 데이터 단위:m
dat4 <- dat3 %>% filter(`use_distance` > 10)
View(dat4)

# 이용 시간이 1분 이하면 제외. / 현재 데이터 단위:분
dat5 <- dat4 %>% filter(`use_time` > 1)
View(dat5)

# 이용거리, 이용시간에 대한 통계 수치 조회(최소,중앙,평균,최대)
dat6 <- dat5 %>% group_by(`office_name`) %>% summarise(dis_avg=mean(use_distance),time_avg=mean(use_time),dis_median=median(use_distance),
                                                       time_median=median(use_time),dis_min=min(use_distance),time_min=min(use_time),
                                                       dis_max=max(use_distance),time_max=max(use_time))
View(dat6)


# 대여.대여소명, 반납대여소명 빈도수가 많은 대로 내림차순
# > 상위 30곳만 출력할 것.
dat7 <- bike %>% group_by(`office_name`,`r_office_name`) %>% summarise(count=n()) %>% arrange(desc(`count`)) %>% head(30)
View(dat7)

dat7 <- bike %>% count(`office_name`,`r_office_name`,sort=T) %>% head(30)
View(dat7)



# 해당 조합이 몇 번 등장했는지 나타내는 것!
install.packages("ISOweek")
install.packages("lubridate")
library(ISOweek)
library(lubridate)  # 날짜.시간데이터를 다루는 패키지!
library(dplyr)


nbike <- bike %>% 
  # mutate() 함수는 dataframe 자료형에
  # 새롭게 파생되는 column을 만드는 함수
  mutate(wk = paste0(rental_time %>% isoweek(),'주차'),yoil = rental_time %>% wday(label=T),# 요일
         time = rental_time %>% substr(1,10), # 날짜 처리
         hour = rental_time %>% substr(12,13))

View(nbike)

# 일자별 자전거 이용량(건수)를 bar 그래프로 표현
#   > 주차별로 그래프색을 다르게 하고싶음.
library(echarts4r)


nbike %>% group_by(time,wk) %>% summarise(count=n()) %>% group_by(wk) %>% # 주차별로 색상을 나타내기 위해 한번 더 그룹핑해줌
  e_chart(time) %>% e_bar(count) %>% e_tooltip(trigger = c('axis'))
